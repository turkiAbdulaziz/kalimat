/// Riverpod providers for the backend layer.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../challenge/models.dart';
import 'auth_repository.dart';
import 'challenge_repository.dart';
import 'friends_repository.dart';
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

final challengeRepositoryProvider = Provider<ChallengeRepository>(
  (ref) => ChallengeRepository(),
);

final friendsRepositoryProvider = Provider<FriendsRepository>(
  (ref) => FriendsRepository(),
);

/// The signed-in uid, or null — duel outcomes are relative to it.
final currentUserIdProvider = Provider<String?>(
  (ref) => ref.watch(authUserProvider).value?.id,
);

/// «التحدّيات» list (empty when unconfigured / offline).
final myChallengesProvider = FutureProvider.autoDispose<List<ChallengeSummary>>(
  (ref) => ref.watch(challengeRepositoryProvider).fetchMine(),
);

final friendsProvider = FutureProvider.autoDispose<List<Friend>>(
  (ref) => ref.watch(friendsRepositoryProvider).fetchFriends(),
);

final friendRequestsProvider = FutureProvider.autoDispose<List<FriendRequest>>(
  (ref) => ref.watch(friendsRepositoryProvider).fetchRequests(),
);

final myPlayerCardProvider = FutureProvider<MyPlayerCard?>(
  (ref) => ref.watch(friendsRepositoryProvider).fetchMyCard(),
);

/// The header dot: a duel waiting on you, or a friend request to answer.
/// Not autoDispose — the game screen watches it for the whole session and
/// refreshes it on resume (sync_service).
final challengeBadgeProvider = FutureProvider<bool>((ref) async {
  if (!isSupabaseConfigured) return false;
  final challenges = await ref.watch(challengeRepositoryProvider).fetchMine();
  if (challenges.any((c) => c.turn == ChallengeTurn.yours)) return true;
  final requests = await ref.watch(friendsRepositoryProvider).fetchRequests();
  return requests.isNotEmpty;
});
