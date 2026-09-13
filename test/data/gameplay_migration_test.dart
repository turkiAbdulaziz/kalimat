import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kalimat/backend/remote_word_source.dart';
import 'package:kalimat/game/data/local_store.dart';
import 'package:kalimat/game/data/startup_word.dart';
import 'package:kalimat/game/engine/game_rules.dart';
import 'package:kalimat/game/engine/models.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

final class FailingPreferences extends InMemorySharedPreferencesAsync {
  FailingPreferences(super.data) : super.withData();
  bool fail = true;
  @override
  Future<bool> clear(
    ClearPreferencesParameters parameters,
    SharedPreferencesOptions options,
  ) async {
    if (fail && parameters.filter.allowList!.contains('stats')) {
      throw StateError('Simulated interrupted write');
    }
    return super.clear(parameters, options);
  }
}

Map<String, Object> oldData() => {
  'cached_word': jsonEncode({
    'date': '2026-09-01',
    'puzzleNo': 1,
    'word': 'مدرسة',
  }),
  'board': jsonEncode({
    'date': '2026-09-01',
    'guesses': ['مدرسة'],
  }),
  'challenge_boards': jsonEncode({
    'old': {
      'guesses': ['مدرسة'],
    },
  }),
  'pending_results': jsonEncode([
    {'date': '2026-09-01', 'won': true, 'guesses': 1, 'grid': '22222'},
  ]),
  'stats': jsonEncode(const GameStats(played: 8, wins: 5).toJson()),
  'help_seen': true,
  'onboarded': true,
  'display_name': 'ليلى',
  'settings': jsonEncode(
    const GameSettings(
      dark: true,
      hints: false,
      motion: false,
      haptics: false,
    ).toJson(),
  ),
  'reminder': jsonEncode(
    const ReminderSettings(enabled: true, hour: 20, minute: 15).toJson(),
  ),
  'supabase.auth.token': 'retained-identity-fixture',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'reset clears only gameplay, once, then new saves restore normally',
    () async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.withData(oldData());
      final store = await LocalStore.create();
      await store.migrateGameplay();
      expect(store.cachedWord, isNull);
      expect(store.board, isNull);
      expect(store.challengeBoards, isEmpty);
      expect(store.pendingResults, isEmpty);
      expect(store.stats.played, 0);
      expect(store.helpSeen, isFalse);
      expect(store.onboarded, isTrue);
      expect(store.displayName, 'ليلى');
      expect(
        store.settings.toJson(),
        const GameSettings(
          dark: true,
          hints: false,
          motion: false,
          haptics: false,
        ).toJson(),
      );
      expect(
        store.reminder.toJson(),
        const ReminderSettings(enabled: true, hour: 20, minute: 15).toJson(),
      );
      expect(
        await SharedPreferencesAsyncPlatform.instance!.getString(
          'supabase.auth.token',
          const SharedPreferencesOptions(),
        ),
        'retained-identity-fixture',
      );
      await store.setBoard(
        BoardSave(date: DateTime(2026, 9, 1), guesses: ['كتاب']),
      );
      await store.setChallengeBoard(
        'new',
        const ChallengeBoardSave(guesses: ['جميل']),
      );
      await store.setStats(const GameStats(played: 1, wins: 1));
      await store.setHelpSeen();
      final reopened = await LocalStore.create();
      await reopened.migrateGameplay();
      expect(reopened.board!.guesses, ['كتاب']);
      expect(reopened.challengeBoard('new')!.guesses, ['جميل']);
      expect(reopened.stats.played, 1);
      expect(reopened.helpSeen, isTrue);
    },
  );

  test(
    'a failed clearing does not mark completion and retries after restart',
    () async {
      final prefs = FailingPreferences(oldData());
      SharedPreferencesAsyncPlatform.instance = prefs;
      await expectLater(
        (await LocalStore.create()).migrateGameplay(),
        throwsStateError,
      );
      expect(
        await prefs.getInt(
          'gameplay_version',
          const SharedPreferencesOptions(),
        ),
        isNull,
      );
      prefs.fail = false;
      final reopened = await LocalStore.create();
      await reopened.migrateGameplay();
      expect(reopened.stats.played, 0);
      expect(
        await prefs.getInt(
          'gameplay_version',
          const SharedPreferencesOptions(),
        ),
        kGameplayVersion,
      );
      expect(reopened.displayName, 'ليلى');
    },
  );

  test('stale or malformed cached answers fall back before startup', () async {
    for (final word in ['مدرسة', 'abcد', 'ورد', 'وَرْدَة']) {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.withData({
            'gameplay_version': kGameplayVersion,
            'cached_word': jsonEncode({
              'date': '2026-09-01',
              'puzzleNo': 1,
              'word': word,
            }),
          });
      final store = await LocalStore.create();
      final resolved = await resolveStartupWord(store, DateTime(2026, 9, 1));
      expect(resolved.word, 'كتاب');
      expect(resolved.fromServer, isFalse);
    }
  });

  test('compatible startup cache survives later launches', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final store = await LocalStore.create();
    await store.migrateGameplay();
    await store.setCachedWord(
      DailyWord(
        date: DateTime(2026, 9, 1),
        puzzleNo: 1,
        word: 'وردة',
        fromServer: true,
      ),
    );
    expect(
      (await resolveStartupWord(store, DateTime(2026, 9, 1))).word,
      'وردة',
    );
  });

  test(
    'remote five-letter answers are rejected; correct spelling survives',
    () {
      for (final word in ['مدرسة', 'ورد', 'وردx']) {
        expect(parseDailyWordRow({'word': word}), isNull);
      }
      expect(
        parseDailyWordRow({
          'word': 'إوزة',
          'word_date': '2026-09-01',
          'puzzle_no': 1,
        })!.word,
        'إوزة',
      );
    },
  );
}
