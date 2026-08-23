/// Riverpod providers for the backend layer.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_repository.dart';
import 'leaderboard_repository.dart';
import 'supabase_config.dart';
import 'supabase_service.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>(
  (ref) => LeaderboardRepository(),
);

/// The current auth user (null while signed out / unconfigured).
final authUserProvider = StreamProvider<User?>((ref) {
  if (!isSupabaseConfigured) return Stream<User?>.value(null);
  return SupabaseService.client.auth.onAuthStateChange
      .map((e) => e.session?.user)
      .distinct((a, b) => a?.id == b?.id && a?.isAnonymous == b?.isAnonymous);
});

/// Daily leaderboard (null = fetch failed / unconfigured).
final dailyLeaderboardProvider = FutureProvider.autoDispose<List<DailyEntry>?>((
  ref,
) async {
  await SupabaseService.ensureSession();
  return ref.watch(leaderboardRepositoryProvider).fetchDaily();
});

/// Global leaderboard (null = fetch failed / unconfigured).
final globalLeaderboardProvider =
    FutureProvider.autoDispose<List<GlobalEntry>?>((ref) async {
      await SupabaseService.ensureSession();
      return ref.watch(leaderboardRepositoryProvider).fetchGlobal();
    });
