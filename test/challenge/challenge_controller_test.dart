/// The duel session at the state level: live progress pushed per guess, a
/// write-once result, a board that survives a kill, daily stats left alone,
/// and a duel already finished on the server refusing to be replayed.
///
/// Motion is forced off via stored settings so the reveal is synchronous.
library;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalimat/backend/backend_providers.dart';
import 'package:kalimat/backend/challenge_repository.dart';
import 'package:kalimat/challenge/challenge_controller.dart';
import 'package:kalimat/challenge/models.dart';
import 'package:kalimat/game/data/dictionary.dart';
import 'package:kalimat/game/data/local_store.dart';
import 'package:kalimat/game/engine/models.dart';
import 'package:kalimat/game/state/game_controller.dart';
import 'package:kalimat/game/state/settings_controller.dart';
import 'package:kalimat/game/state/stats_controller.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

late GuessDictionary _dictionary;
late LocalStore _store;

/// Records what the board sends to the server; the network is never touched.
class _FakeChallengeRepository extends ChallengeRepository {
  final List<int> progress = [];
  final List<Map<String, Object?>> submissions = [];

  @override
  Future<void> pushProgress(String id, int guesses) async {
    progress.add(guesses);
  }

  @override
  Future<bool> submitResult({
    required String id,
    required bool won,
    required int guesses,
    required int? durationMs,
    required String grid,
  }) async {
    submissions.add({
      'id': id,
      'won': won,
      'guesses': guesses,
      'durationMs': durationMs,
      'grid': grid,
    });
    return true;
  }

  @override
  Stream<ChallengeSide> watchOpponent(String challengeId, String opponentId) =>
      const Stream<ChallengeSide>.empty();
}

ChallengeDetail _detail({
  ChallengeSide mine = const ChallengeSide(),
  ChallengeSide theirs = const ChallengeSide(),
}) => ChallengeDetail(
  id: 'duel-1',
  word: 'مدرسة',
  opponentId: 'them',
  opponentName: 'ليلى',
  status: ChallengeStatus.active,
  mine: mine,
  theirs: theirs,
);

/// A container with the duel already open, plus the fake repository.
Future<(ProviderContainer, _FakeChallengeRepository)> _duel({
  ChallengeDetail? detail,
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.withData({
        'settings': '{"dark":false,"hints":true,"motion":false}',
        ...prefs,
      });
  _store = await LocalStore.create();
  final repo = _FakeChallengeRepository();
  final container = ProviderContainer(
    overrides: [
      localStoreProvider.overrideWithValue(_store),
      dictionaryProvider.overrideWithValue(_dictionary),
      challengeRepositoryProvider.overrideWithValue(repo),
    ],
  );
  addTearDown(container.dispose);
  container.read(activeChallengeProvider.notifier).open(detail ?? _detail());
  return (container, repo);
}

void _submit(ProviderContainer c, String word) {
  final game = c.read(challengeGameProvider.notifier);
  for (final letter in word.split('')) {
    game.onKey(letter);
  }
  game.onEnter();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    _dictionary = GuessDictionary();
    await _dictionary.ensureLoaded();
  });

  test('every guess pushes live progress to the opponent', () async {
    final (c, repo) = await _duel();
    _submit(c, 'عندما');
    _submit(c, 'مكتبة');
    expect(repo.progress, [1, 2]);
    // A rejected word never reaches the server.
    _submit(c, 'ززززز');
    expect(repo.progress, [1, 2]);
  });

  test('a win submits once, with the grid and a measured clock', () async {
    final (c, repo) = await _duel();
    _submit(c, 'عندما');
    _submit(c, 'مدرسة');

    expect(repo.submissions, hasLength(1));
    final sent = repo.submissions.single;
    expect(sent['id'], 'duel-1');
    expect(sent['won'], true);
    expect(sent['guesses'], 2);
    expect(sent['grid'], c.read(challengeGameProvider).gridString);
    expect(sent['durationMs'], isA<int>());
    expect(c.read(challengeGameProvider).status, GameStatus.won);
  });

  test('a loss submits with won=false after six guesses', () async {
    final (c, repo) = await _duel();
    for (var i = 0; i < 6; i++) {
      _submit(c, 'عندما');
    }
    expect(repo.submissions, hasLength(1));
    expect(repo.submissions.single['won'], false);
    expect(repo.submissions.single['guesses'], 6);
    expect(c.read(challengeGameProvider).status, GameStatus.lost);
  });

  test('daily stats and the daily result queue are untouched', () async {
    final (c, _) = await _duel();
    _submit(c, 'مدرسة');

    expect(c.read(challengeGameProvider).status, GameStatus.won);
    expect(c.read(statsProvider).played, 0);
    expect(_store.stats.played, 0);
    expect(_store.pendingResults, isEmpty);
    expect(_store.board, isNull); // the daily board is a different save
  });

  test('the duel board is persisted per challenge and restored', () async {
    final (c, _) = await _duel();
    _submit(c, 'عندما');

    final saved = _store.challengeBoard('duel-1');
    expect(saved?.guesses, ['عندما']);
    expect(saved?.startedAtMs, isA<int>());

    // A fresh container over the same store rebuilds the row and its clock.
    final (c2, _) = await _duel(
      prefs: {
        'challenge_boards': jsonEncode({
          'duel-1': {'guesses': ['عندما'], 'startedAtMs': 1000},
        }),
      },
    );
    final restored = c2.read(challengeGameProvider);
    expect(restored.guesses, ['عندما']);
    expect(restored.rowStates, hasLength(1));
    expect(restored.status, GameStatus.playing);
  });

  test('a duel already finished on the server cannot be replayed', () async {
    final (c, repo) = await _duel(
      detail: _detail(
        mine: const ChallengeSide(finished: true, won: true, guesses: 3),
      ),
    );

    final state = c.read(challengeGameProvider);
    expect(state.finished, isTrue);
    expect(state.status, GameStatus.won);

    _submit(c, 'مدرسة');
    expect(repo.submissions, isEmpty);
    expect(repo.progress, isEmpty);
  });
}
