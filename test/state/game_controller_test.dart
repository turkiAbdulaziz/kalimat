/// GameController use cases at the state level: board restore after a
/// process kill, win/loss finishing (stats + offline result queue), the
/// applyServerWord never-interrupt rule, and guess validation.
///
/// Motion is forced off via stored settings so the reveal choreography is
/// synchronous; the remaining toast/dialog timers are cancelled by the
/// controller's onDispose when the container tears down.
library;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalimat/core/strings.dart';
import 'package:kalimat/game/data/dictionary.dart';
import 'package:kalimat/game/data/local_store.dart';
import 'package:kalimat/game/engine/models.dart';
import 'package:kalimat/game/state/game_controller.dart';
import 'package:kalimat/game/state/settings_controller.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

// Real asset I/O — must load outside the tests (see rtl_smoke_test).
late GuessDictionary _dictionary;

final _today = DailyWord(
  date: DateTime(2026, 9, 1),
  puzzleNo: 1,
  word: 'وردة',
  fromServer: false,
);

late LocalStore _store;

Future<ProviderContainer> _game({
  List<String> savedGuesses = const [],
  String? savedDate,
}) async {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.withData({
        'settings': '{"dark":false,"hints":true,"motion":false}',
        if (savedGuesses.isNotEmpty)
          'board': jsonEncode({
            'date': savedDate ?? '2026-09-01',
            'guesses': savedGuesses,
          }),
      });
  _store = await LocalStore.create();
  final container = ProviderContainer(
    overrides: [
      localStoreProvider.overrideWithValue(_store),
      dictionaryProvider.overrideWithValue(_dictionary),
      initialWordProvider.overrideWithValue(_today),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void _submit(ProviderContainer c, String word) {
  final game = c.read(gameProvider.notifier);
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

  group('guess validation', () {
    test('a valid guess is recorded and the board saved immediately', () async {
      final c = await _game();
      _submit(c, 'كتاب');
      final s = c.read(gameProvider);
      expect(s.guesses, ['كتاب']);
      expect(s.rowStates, hasLength(1));
      expect(s.status, GameStatus.playing);
      // Saved before the app can be killed.
      expect(_store.board!.guesses, ['كتاب']);
    });

    test('a non-word is rejected with a toast and consumes no row', () async {
      final c = await _game();
      _submit(c, 'زززز');
      final s = c.read(gameProvider);
      expect(s.toast, S.notInDictionary);
      expect(s.guesses, isEmpty);
      expect(s.current, hasLength(4)); // typed letters stay for editing
      expect(_store.board, isNull);
    });

    test('a short row is rejected with the too-short toast', () async {
      final c = await _game();
      final game = c.read(gameProvider.notifier);
      game.onKey('م');
      game.onEnter();
      expect(c.read(gameProvider).toast, S.tooShort);
      expect(c.read(gameProvider).guesses, isEmpty);
    });
  });

  test(
    'four-letter boundary, delete, invalid key and normalized win',
    () async {
      final c = await _game();
      final game = c.read(gameProvider.notifier);
      for (final letter in 'وردهز'.split('')) {
        game.onKey(letter);
      }
      game.onKey('abc');
      expect(c.read(gameProvider).current.join(), 'ورده');
      game.onDelete();
      expect(c.read(gameProvider).current.join(), 'ورد');
      game.onKey('ة');
      game.onEnter();
      expect(c.read(gameProvider).status, GameStatus.won);
      expect(c.read(gameProvider).gridString, '2222');
    },
  );

  test('old, mixed and oversized saves are rejected as a whole', () async {
    for (final guesses in [
      ['مدرسة'],
      ['كتاب', 'مدرسة'],
      List.filled(7, 'كتاب'),
    ]) {
      final c = await _game(savedGuesses: guesses);
      expect(c.read(gameProvider).guesses, isEmpty);
      expect(c.read(gameProvider).status, GameStatus.playing);
    }
  });

  test('stale server answers cannot replace an untouched game', () async {
    final c = await _game();
    c
        .read(gameProvider.notifier)
        .applyServerWord(
          DailyWord(
            date: _today.date,
            puzzleNo: 1,
            word: 'مدرسة',
            fromServer: true,
          ),
        );
    expect(c.read(gameProvider).word.word, 'وردة');
    _submit(c, 'ورده');
    expect(c.read(gameProvider).status, GameStatus.won);
  });

  group('finishing', () {
    test('winning updates authoritative stats and queues the result', () async {
      final c = await _game();
      _submit(c, 'كتاب');
      _submit(c, 'وردة'); // the answer is always accepted
      final s = c.read(gameProvider);
      expect(s.status, GameStatus.won);
      expect(s.toast, S.win);
      expect(s.revealAnswer, isFalse);

      final stats = _store.stats;
      expect(stats.played, 1);
      expect(stats.wins, 1);
      expect(stats.streak, 1);
      expect(stats.dist[1], 1); // won in 2 guesses

      final q = _store.pendingResults;
      expect(q, hasLength(1));
      expect(q.single.won, isTrue);
      expect(q.single.guesses, 2);
      expect(q.single.date, _today.date);
      expect(q.single.grid.split('|').last, '2222');
    });

    test(
      'six wrong guesses lose, reveal the answer, and reset the streak',
      () async {
        final c = await _game();
        for (var i = 0; i < 6; i++) {
          _submit(c, 'كتاب');
        }
        final s = c.read(gameProvider);
        expect(s.status, GameStatus.lost);
        expect(s.revealAnswer, isTrue); // badge shows «الكلمة: …»
        expect(s.guesses, hasLength(6));

        final stats = _store.stats;
        expect(stats.played, 1);
        expect(stats.wins, 0);
        expect(stats.streak, 0);

        final q = _store.pendingResults;
        expect(q.single.won, isFalse);
        expect(q.single.guesses, isNull); // losses carry no guess count
        expect(q.single.grid.split('|'), hasLength(6));
      },
    );

    test('input is ignored after the game ends', () async {
      final c = await _game();
      _submit(c, 'وردة');
      final game = c.read(gameProvider.notifier);
      game.onKey('م');
      game.onEnter();
      final s = c.read(gameProvider);
      expect(s.current, isEmpty);
      expect(s.guesses, hasLength(1));
    });
  });

  group('board restore (process kill mid-game)', () {
    test("today's save rebuilds rows, key hints, and win status", () async {
      final c = await _game(savedGuesses: ['كتاب', 'وردة']);
      final s = c.read(gameProvider);
      expect(s.guesses, ['كتاب', 'وردة']);
      expect(s.rowStates, hasLength(2));
      expect(s.status, GameStatus.won);
      expect(s.keyStates, isNotEmpty);
    });

    test('a full board without the answer restores as lost', () async {
      final c = await _game(savedGuesses: List.filled(6, 'كتاب'));
      final s = c.read(gameProvider);
      expect(s.status, GameStatus.lost);
      expect(s.revealAnswer, isTrue);
    });

    test("another day's board is ignored", () async {
      final c = await _game(savedGuesses: ['كتاب'], savedDate: '2026-08-31');
      final s = c.read(gameProvider);
      expect(s.guesses, isEmpty);
      expect(s.status, GameStatus.playing);
    });
  });

  group('applyServerWord (server authority, never interrupts)', () {
    final tomorrow = DailyWord(
      date: DateTime(2026, 9, 2),
      puzzleNo: 2,
      word: 'جميل',
      fromServer: true,
    );

    test('an untouched game adopts the new word', () async {
      final c = await _game();
      c.read(gameProvider.notifier).applyServerWord(tomorrow);
      final s = c.read(gameProvider);
      expect(s.word.word, 'جميل');
      expect(s.guesses, isEmpty);
    });

    test('typed letters block the swap', () async {
      final c = await _game();
      c.read(gameProvider.notifier).onKey('م');
      c.read(gameProvider.notifier).applyServerWord(tomorrow);
      final s = c.read(gameProvider);
      expect(s.word.word, 'وردة');
      expect(s.current, ['م']); // in-progress row untouched
    });

    test('a submitted guess blocks the swap', () async {
      final c = await _game();
      _submit(c, 'كتاب');
      c.read(gameProvider.notifier).applyServerWord(tomorrow);
      expect(c.read(gameProvider).word.word, 'وردة');
    });

    test('a finished game adopts the new word (fresh board)', () async {
      final c = await _game();
      _submit(c, 'وردة');
      c.read(gameProvider.notifier).applyServerWord(tomorrow);
      final s = c.read(gameProvider);
      expect(s.word.word, 'جميل');
      expect(s.status, GameStatus.playing);
      expect(s.guesses, isEmpty);
    });

    test('the same word is a no-op', () async {
      final c = await _game();
      _submit(c, 'كتاب');
      c.read(gameProvider.notifier).applyServerWord(_today);
      expect(c.read(gameProvider).guesses, ['كتاب']);
    });
  });
}
