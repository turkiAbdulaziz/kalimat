/// LocalStore persistence round-trips + GameStats math — the app's
/// durability story: the board survives a process kill mid-game, stats are
/// local and authoritative, and offline results queue until a sync flushes
/// them to the server.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kalimat/game/data/local_store.dart';
import 'package:kalimat/game/engine/models.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

Future<LocalStore> newStore([Map<String, Object> seed = const {}]) {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.withData(seed);
  return LocalStore.create();
}

void main() {
  group('GameStats.afterGame', () {
    test('win increments played/wins/streak and the right dist bucket', () {
      const before = GameStats(
        played: 3,
        wins: 2,
        streak: 2,
        best: 2,
        dist: [0, 1, 1, 0, 0, 0],
      );
      final after = before.afterGame(won: true, guesses: 4);
      expect(after.played, 4);
      expect(after.wins, 3);
      expect(after.streak, 3);
      expect(after.best, 3);
      expect(after.dist, [0, 1, 1, 1, 0, 0]);
    });

    test('loss resets the streak but keeps best and dist', () {
      const before = GameStats(
        played: 5,
        wins: 4,
        streak: 4,
        best: 4,
        dist: [1, 1, 1, 1, 0, 0],
      );
      final after = before.afterGame(won: false, guesses: 6);
      expect(after.played, 6);
      expect(after.wins, 4);
      expect(after.streak, 0);
      expect(after.best, 4);
      expect(after.dist, [1, 1, 1, 1, 0, 0]);
    });

    test('best only moves when a new streak passes it', () {
      const rebuilt = GameStats(played: 9, wins: 6, streak: 2, best: 5);
      expect(rebuilt.afterGame(won: true, guesses: 1).best, 5);
      const record = GameStats(played: 9, wins: 6, streak: 5, best: 5);
      expect(record.afterGame(won: true, guesses: 1).best, 6);
    });

    test('winRatePercent rounds to the nearest integer', () {
      expect(const GameStats().winRatePercent, 0); // no division by zero
      expect(const GameStats(played: 3, wins: 1).winRatePercent, 33);
      expect(const GameStats(played: 3, wins: 2).winRatePercent, 67);
    });
  });

  group('board persistence', () {
    test('round trip keeps the date and typed spellings', () async {
      final store = await newStore();
      await store.setBoard(
        BoardSave(date: DateTime(2026, 9, 1), guesses: const ['كتاب', 'جميل']),
      );
      final loaded = store.board!;
      expect(loaded.date, DateTime(2026, 9, 1));
      // Typed spellings survive verbatim — the board shows what the player
      // typed, states are recomputed on load.
      expect(loaded.guesses, ['كتاب', 'جميل']);
    });

    test('clearBoard removes the save', () async {
      final store = await newStore();
      await store.setBoard(
        BoardSave(date: DateTime(2026, 9, 1), guesses: const ['كتاب']),
      );
      await store.clearBoard();
      expect(store.board, isNull);
    });

    test('corrupt JSON reads as no board instead of crashing', () async {
      final store = await newStore({'board': 'not json{'});
      expect(store.board, isNull);
    });
  });

  group('pending results queue (offline sync)', () {
    test('win and loss shapes survive a round trip', () async {
      final store = await newStore();
      await store.setPendingResults([
        PendingResult(
          date: DateTime(2026, 9, 1),
          won: true,
          guesses: 3,
          grid: '0120|1102|2222',
          durationMs: 61234,
        ),
        PendingResult(
          date: DateTime(2026, 9, 2),
          won: false,
          guesses: null, // losses carry no guess count
          grid: '0000|0000|0000|0000|0000|0000',
        ),
      ]);
      final q = store.pendingResults;
      expect(q, hasLength(2));
      expect(q[0].won, isTrue);
      expect(q[0].guesses, 3);
      expect(q[0].grid, '0120|1102|2222');
      expect(q[0].durationMs, 61234);
      expect(q[1].won, isFalse);
      expect(q[1].guesses, isNull);
      expect(q[1].date, DateTime(2026, 9, 2));
    });

    test('a successful flush drains the queue', () async {
      final store = await newStore();
      await store.setPendingResults([
        PendingResult(
          date: DateTime(2026, 9, 1),
          won: true,
          guesses: 1,
          grid: '2222',
        ),
      ]);
      await store.setPendingResults(const []);
      expect(store.pendingResults, isEmpty);
    });

    test('corrupt queue reads as empty instead of crashing', () async {
      final store = await newStore({'pending_results': '][broken'});
      expect(store.pendingResults, isEmpty);
    });
  });

  group('settings and flags', () {
    test('hasStoredSettings flips only on an explicit save', () async {
      final store = await newStore();
      // The accessibility-driven motion default depends on this staying
      // false until the user actually saves.
      expect(store.hasStoredSettings, isFalse);
      await store.setSettings(const GameSettings(motion: false));
      expect(store.hasStoredSettings, isTrue);
      expect(store.settings.motion, isFalse);
      expect(store.settings.dark, isFalse);
      expect(store.settings.hints, isTrue);
    });

    test('reminder round trip keeps the 24h time', () async {
      final store = await newStore();
      await store.setReminder(
        const ReminderSettings(enabled: true, hour: 21, minute: 30),
      );
      final r = store.reminder;
      expect(r.enabled, isTrue);
      expect(r.hour, 21);
      expect(r.minute, 30);
    });

    test('display name caches and clears (offline profile render)', () async {
      final store = await newStore();
      expect(store.displayName, isNull);
      await store.setDisplayName('تركي');
      expect(store.displayName, 'تركي');
      await store.clearDisplayName();
      expect(store.displayName, isNull);
    });

    test('onboarded and helpSeen flags default off and persist', () async {
      final store = await newStore();
      expect(store.onboarded, isFalse);
      expect(store.helpSeen, isFalse);
      await store.setOnboarded();
      await store.setHelpSeen();
      expect(store.onboarded, isTrue);
      expect(store.helpSeen, isTrue);
      await store.clearOnboarded(); // sign-out path
      expect(store.onboarded, isFalse);
      expect(store.helpSeen, isTrue); // help stays seen across sign-outs
    });
  });

  test('cached word round trip (offline day-word fallback)', () async {
    final store = await newStore();
    await store.setCachedWord(
      DailyWord(
        date: DateTime(2026, 9, 3),
        puzzleNo: 3,
        word: 'جميل',
        fromServer: true,
      ),
    );
    final w = store.cachedWord!;
    expect(w.date, DateTime(2026, 9, 3));
    expect(w.puzzleNo, 3);
    expect(w.word, 'جميل');
    expect(w.fromServer, isTrue);
  });
}
