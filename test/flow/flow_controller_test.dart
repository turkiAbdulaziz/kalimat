/// FlowController store effects. Note: isSupabaseConfigured is compile-time
/// false under `flutter test`, so build() always short-circuits to game and
/// the signin branch itself is device-verified only — these tests cover the
/// transitions' persisted side effects.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalimat/backend/auth_repository.dart';
import 'package:kalimat/backend/backend_providers.dart';
import 'package:kalimat/core/strings.dart';
import 'package:kalimat/flow/flow_controller.dart';
import 'package:kalimat/game/data/local_store.dart';
import 'package:kalimat/game/state/settings_controller.dart';
import 'package:kalimat/game/state/stats_controller.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Stands in for the server call so the device-side wipe can be exercised
/// under `flutter test`, where Supabase is never configured.
class _DeletingAuth extends AuthRepository {
  @override
  Future<bool> deleteAccount() async => true;
}

void main() {
  late LocalStore store;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    store = await LocalStore.create();
    container = ProviderContainer(
      overrides: [localStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
  });

  test('unconfigured build boots straight into the game', () {
    expect(container.read(flowProvider), FlowStep.game);
  });

  test('continueAsGuest persists the onboarded flag', () async {
    await container.read(flowProvider.notifier).continueAsGuest();
    expect(container.read(flowProvider), FlowStep.game);
    expect(store.onboarded, isTrue);
  });

  test('completeName trims, caches, and finishes onboarding', () async {
    await container.read(flowProvider.notifier).completeName('  ليلى ');
    expect(store.displayName, 'ليلى');
    expect(container.read(displayNameProvider), 'ليلى');
    expect(store.onboarded, isTrue);
    expect(container.read(flowProvider), FlowStep.game);
  });

  test('completeName rejects names under 2 characters', () async {
    await container.read(flowProvider.notifier).completeName(' ل ');
    expect(store.displayName, isNull);
    expect(store.onboarded, isFalse);
  });

  test('signOut clears board, name, and onboarding but keeps stats', () async {
    await store.setBoard(
      BoardSave(date: DateTime(2026, 9, 1), guesses: const ['مدرسة']),
    );
    await store.setStats(const GameStats(played: 5, wins: 3, streak: 2));
    await container.read(flowProvider.notifier).completeName('ليلى');

    await container.read(flowProvider.notifier).signOut();

    expect(store.board, isNull);
    expect(store.displayName, isNull);
    expect(store.onboarded, isFalse);
    expect(container.read(displayNameProvider), S.guestName);
    expect(store.stats.played, 5); // local stats are authoritative
    expect(container.read(flowProvider), FlowStep.signin);
  });

  test('deleteAccount without a backend refuses and changes nothing', () async {
    await store.setStats(const GameStats(played: 5, wins: 3, streak: 2));
    await container.read(flowProvider.notifier).completeName('ليلى');

    final ok = await container.read(flowProvider.notifier).deleteAccount();

    expect(ok, isFalse);
    expect(store.stats.played, 5);
    expect(store.displayName, 'ليلى');
    expect(store.onboarded, isTrue);
    expect(container.read(flowProvider), FlowStep.game);
  });

  test(
    'deleteAccount wipes the device — stats included, unlike signOut',
    () async {
      final c = ProviderContainer(
        overrides: [
          localStoreProvider.overrideWithValue(store),
          authRepositoryProvider.overrideWithValue(_DeletingAuth()),
        ],
      );
      addTearDown(c.dispose);
      await store.setBoard(
        BoardSave(date: DateTime(2026, 9, 1), guesses: const ['مدرسة']),
      );
      await store.setStats(const GameStats(played: 5, wins: 3, streak: 2));
      await store.setChallengeBoard(
        'duel-1',
        const ChallengeBoardSave(guesses: ['كتاب'], startedAtMs: 1),
      );
      await store.setPendingResults([
        PendingResult(
          date: DateTime(2026, 9, 1),
          won: true,
          guesses: 3,
          grid: '00000',
        ),
      ]);
      await c.read(flowProvider.notifier).completeName('ليلى');
      expect(c.read(statsProvider).played, 5);

      final ok = await c.read(flowProvider.notifier).deleteAccount();

      expect(ok, isTrue);
      expect(store.board, isNull);
      expect(store.stats.played, 0);
      expect(c.read(statsProvider).played, 0);
      expect(store.challengeBoards, isEmpty);
      expect(store.pendingResults, isEmpty);
      expect(store.displayName, isNull);
      expect(store.onboarded, isFalse);
      expect(c.read(displayNameProvider), S.guestName);
      expect(c.read(flowProvider), FlowStep.signin);
    },
  );
}
