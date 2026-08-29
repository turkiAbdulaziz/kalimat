/// Duel model types and the winner rule. Pure Dart — no Flutter imports, so
/// the rule can be unit-tested next to the engine.
///
/// [decideOutcome] must stay in lockstep with submit_challenge_result() in
/// supabase/migrations/0005_challenge_functions.sql — the server decides the
/// duel, the client only renders that decision (and predicts it locally while
/// a result is still in flight).
library;

/// Server lifecycle of a duel.
enum ChallengeStatus { active, complete, expired }

/// What the viewer sees on a finished duel.
enum ChallengeOutcome { won, lost, draw, pending }

/// Which side of the list a duel belongs on.
enum ChallengeTurn { yours, waiting, done }

/// One player's line in a duel.
class ChallengeSide {
  const ChallengeSide({
    this.guesses = 0,
    this.finished = false,
    this.won = false,
    this.durationMs,
    this.grid,
  });

  /// Guesses submitted so far — live progress while [finished] is false.
  final int guesses;
  final bool finished;
  final bool won;
  final int? durationMs;

  /// Only ever populated once the player has finished.
  final String? grid;

  static ChallengeSide fromRow(Map<String, dynamic> row, String prefix) =>
      ChallengeSide(
        guesses: (row['${prefix}guesses'] as int?) ?? 0,
        finished: (row['${prefix}finished'] as bool?) ?? false,
        won: (row['${prefix}won'] as bool?) ?? false,
        durationMs: row['${prefix}duration_ms'] as int?,
        grid: row['${prefix}grid'] as String?,
      );
}

/// An unknown clock sorts last, matching the SQL's coalesce(…, int max).
const int _unknownClock = 2147483647;

/// The winner rule: a win beats a loss → fewer guesses → the faster solve.
/// Returns [ChallengeOutcome.pending] until both sides are in.
ChallengeOutcome decideOutcome(ChallengeSide mine, ChallengeSide theirs) {
  if (!mine.finished || !theirs.finished) return ChallengeOutcome.pending;
  if (mine.won != theirs.won) {
    return mine.won ? ChallengeOutcome.won : ChallengeOutcome.lost;
  }
  if (!mine.won) return ChallengeOutcome.draw; // both lost
  if (mine.guesses != theirs.guesses) {
    return mine.guesses < theirs.guesses
        ? ChallengeOutcome.won
        : ChallengeOutcome.lost;
  }
  final a = mine.durationMs ?? _unknownClock;
  final b = theirs.durationMs ?? _unknownClock;
  if (a == b) return ChallengeOutcome.draw;
  return a < b ? ChallengeOutcome.won : ChallengeOutcome.lost;
}

/// A row on the «التحدّيات» list. Never carries the word.
class ChallengeSummary {
  const ChallengeSummary({
    required this.id,
    required this.opponentId,
    required this.opponentName,
    required this.status,
    required this.mine,
    required this.theirs,
    this.winnerId,
  });

  final String id;
  final String opponentId;
  final String opponentName;
  final ChallengeStatus status;
  final String? winnerId;
  final ChallengeSide mine;
  final ChallengeSide theirs;

  ChallengeTurn get turn {
    if (status != ChallengeStatus.active) return ChallengeTurn.done;
    return mine.finished ? ChallengeTurn.waiting : ChallengeTurn.yours;
  }

  /// The server's verdict once it exists; the local rule until then (an
  /// expired duel nobody completed is a draw).
  ChallengeOutcome outcome(String myId) {
    if (status == ChallengeStatus.complete) {
      if (winnerId == null) return ChallengeOutcome.draw;
      return winnerId == myId ? ChallengeOutcome.won : ChallengeOutcome.lost;
    }
    if (status == ChallengeStatus.expired) {
      final decided = decideOutcome(mine, theirs);
      return decided == ChallengeOutcome.pending
          ? ChallengeOutcome.draw
          : decided;
    }
    return decideOutcome(mine, theirs);
  }

  static ChallengeSummary fromRow(Map<String, dynamic> row) => ChallengeSummary(
    id: row['id'] as String,
    opponentId: row['opponent_id'] as String,
    opponentName: (row['opponent_name'] as String?) ?? '',
    status: statusFromName(row['status'] as String?),
    winnerId: row['winner_id'] as String?,
    mine: ChallengeSide.fromRow(row, 'my_'),
    theirs: ChallengeSide.fromRow(row, 'their_'),
  );
}

/// An opened duel: the list row plus the word the board needs.
class ChallengeDetail {
  const ChallengeDetail({
    required this.id,
    required this.word,
    required this.opponentId,
    required this.opponentName,
    required this.status,
    required this.mine,
    required this.theirs,
    this.winnerId,
  });

  final String id;
  final String word;
  final String opponentId;
  final String opponentName;
  final ChallengeStatus status;
  final String? winnerId;
  final ChallengeSide mine;
  final ChallengeSide theirs;

  static ChallengeDetail fromRow(Map<String, dynamic> row) => ChallengeDetail(
    id: row['id'] as String,
    word: row['word'] as String,
    opponentId: row['opponent_id'] as String,
    opponentName: (row['opponent_name'] as String?) ?? '',
    status: statusFromName(row['status'] as String?),
    winnerId: row['winner_id'] as String?,
    mine: ChallengeSide.fromRow(row, 'my_'),
    theirs: ChallengeSide.fromRow(row, 'their_'),
  );
}

ChallengeStatus statusFromName(String? name) => switch (name) {
  'complete' => ChallengeStatus.complete,
  'expired' => ChallengeStatus.expired,
  _ => ChallengeStatus.active,
};

class Friend {
  const Friend({
    required this.id,
    required this.displayName,
    required this.friendCode,
    this.wins = 0,
    this.losses = 0,
  });

  final String id;
  final String displayName;
  final String friendCode;

  /// Head-to-head record against you.
  final int wins;
  final int losses;

  static Friend fromRow(Map<String, dynamic> row) => Friend(
    id: row['user_id'] as String,
    displayName: (row['display_name'] as String?) ?? '',
    friendCode: (row['friend_code'] as String?) ?? '',
    wins: (row['wins'] as int?) ?? 0,
    losses: (row['losses'] as int?) ?? 0,
  );
}

class FriendRequest {
  const FriendRequest({required this.id, required this.displayName});

  final String id;
  final String displayName;

  static FriendRequest fromRow(Map<String, dynamic> row) => FriendRequest(
    id: row['user_id'] as String,
    displayName: (row['display_name'] as String?) ?? '',
  );
}

/// «رمزي» plus the lifetime duel record.
class MyPlayerCard {
  const MyPlayerCard({
    required this.friendCode,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
  });

  final String friendCode;
  final int wins;
  final int losses;
  final int draws;

  static MyPlayerCard fromRow(Map<String, dynamic> row) => MyPlayerCard(
    friendCode: (row['friend_code'] as String?) ?? '',
    wins: (row['wins'] as int?) ?? 0,
    losses: (row['losses'] as int?) ?? 0,
    draws: (row['draws'] as int?) ?? 0,
  );
}

/// Outcome of send_friend_request(). Mirrors the RPC's `result` word.
enum AddFriendResult {
  sent,
  accepted,
  pending,
  alreadyFriends,
  notFound,
  self,
  rateLimited,
  failed;

  static AddFriendResult fromName(String? name) => switch (name) {
    'sent' => AddFriendResult.sent,
    'accepted' => AddFriendResult.accepted,
    'pending' => AddFriendResult.pending,
    'already_friends' => AddFriendResult.alreadyFriends,
    'not_found' => AddFriendResult.notFound,
    'self' => AddFriendResult.self,
    'rate_limited' => AddFriendResult.rateLimited,
    _ => AddFriendResult.failed,
  };
}

/// mm:ss with Arabic-Indic digits applied by the caller.
String formatClock(int? ms) {
  if (ms == null) return '—';
  final total = (ms / 1000).round();
  final m = (total ~/ 60).toString().padLeft(2, '0');
  final s = (total % 60).toString().padLeft(2, '0');
  return '$m:$s';
}
