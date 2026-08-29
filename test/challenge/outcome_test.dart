/// The duel winner rule. This matrix is the client half of the contract in
/// submit_challenge_result() (supabase/migrations/0005_challenge_functions.sql)
/// — a win beats a loss, then fewer guesses, then the faster solve.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kalimat/challenge/models.dart';

ChallengeSide _side({
  bool finished = true,
  bool won = true,
  int guesses = 4,
  int? durationMs = 60000,
}) => ChallengeSide(
  finished: finished,
  won: won,
  guesses: guesses,
  durationMs: durationMs,
);

void main() {
  group('decideOutcome', () {
    test('pending until both sides are in', () {
      expect(
        decideOutcome(_side(), _side(finished: false)),
        ChallengeOutcome.pending,
      );
      expect(
        decideOutcome(_side(finished: false), _side()),
        ChallengeOutcome.pending,
      );
    });

    test('a win beats a loss regardless of guesses', () {
      expect(
        decideOutcome(_side(guesses: 6), _side(won: false, guesses: 6)),
        ChallengeOutcome.won,
      );
      expect(
        decideOutcome(_side(won: false, guesses: 6), _side(guesses: 6)),
        ChallengeOutcome.lost,
      );
    });

    test('both losing is a draw', () {
      expect(
        decideOutcome(_side(won: false), _side(won: false)),
        ChallengeOutcome.draw,
      );
    });

    test('fewer guesses wins', () {
      expect(
        decideOutcome(_side(guesses: 3), _side(guesses: 4)),
        ChallengeOutcome.won,
      );
      expect(
        decideOutcome(_side(guesses: 5), _side(guesses: 2)),
        ChallengeOutcome.lost,
      );
    });

    test('equal guesses fall through to the faster solve', () {
      expect(
        decideOutcome(
          _side(guesses: 3, durationMs: 62000),
          _side(guesses: 3, durationMs: 139000),
        ),
        ChallengeOutcome.won,
      );
      expect(
        decideOutcome(
          _side(guesses: 3, durationMs: 139000),
          _side(guesses: 3, durationMs: 62000),
        ),
        ChallengeOutcome.lost,
      );
    });

    test('an unknown clock loses to a measured one (SQL nulls last)', () {
      expect(
        decideOutcome(
          _side(durationMs: null),
          _side(durationMs: 600000),
        ),
        ChallengeOutcome.lost,
      );
      expect(
        decideOutcome(
          _side(durationMs: 600000),
          _side(durationMs: null),
        ),
        ChallengeOutcome.won,
      );
    });

    test('identical everything is a draw, unknown clocks included', () {
      expect(
        decideOutcome(_side(durationMs: 5000), _side(durationMs: 5000)),
        ChallengeOutcome.draw,
      );
      expect(
        decideOutcome(_side(durationMs: null), _side(durationMs: null)),
        ChallengeOutcome.draw,
      );
    });
  });

  group('ChallengeSummary', () {
    ChallengeSummary summary({
      required ChallengeStatus status,
      String? winnerId,
      ChallengeSide? mine,
      ChallengeSide? theirs,
    }) => ChallengeSummary(
      id: 'c1',
      opponentId: 'them',
      opponentName: 'ليلى',
      status: status,
      winnerId: winnerId,
      mine: mine ?? const ChallengeSide(),
      theirs: theirs ?? const ChallengeSide(),
    );

    test('turn: yours until you finish, then waiting, then done', () {
      expect(
        summary(status: ChallengeStatus.active).turn,
        ChallengeTurn.yours,
      );
      expect(
        summary(status: ChallengeStatus.active, mine: _side()).turn,
        ChallengeTurn.waiting,
      );
      expect(
        summary(status: ChallengeStatus.complete).turn,
        ChallengeTurn.done,
      );
      expect(summary(status: ChallengeStatus.expired).turn, ChallengeTurn.done);
    });

    test('a completed duel trusts the server verdict', () {
      expect(
        summary(status: ChallengeStatus.complete, winnerId: 'me').outcome('me'),
        ChallengeOutcome.won,
      );
      expect(
        summary(
          status: ChallengeStatus.complete,
          winnerId: 'them',
        ).outcome('me'),
        ChallengeOutcome.lost,
      );
      expect(
        summary(status: ChallengeStatus.complete).outcome('me'),
        ChallengeOutcome.draw,
      );
    });

    test('an expired duel nobody completed is a draw', () {
      expect(
        summary(status: ChallengeStatus.expired, mine: _side()).outcome('me'),
        ChallengeOutcome.draw,
      );
    });

    test('reads the RPC row shape', () {
      final s = ChallengeSummary.fromRow({
        'id': 'c9',
        'opponent_id': 'u2',
        'opponent_name': 'ليلى',
        'status': 'complete',
        'winner_id': 'u2',
        'my_guesses': 4,
        'my_finished': true,
        'my_won': true,
        'my_duration_ms': 90000,
        'their_guesses': 3,
        'their_finished': true,
        'their_won': true,
        'their_duration_ms': 45000,
      });
      expect(s.opponentName, 'ليلى');
      expect(s.mine.guesses, 4);
      expect(s.theirs.durationMs, 45000);
      expect(s.outcome('u1'), ChallengeOutcome.lost);
    });
  });

  group('formatClock', () {
    test('mm:ss, zero-padded, rounded to the nearest second', () {
      expect(formatClock(62000), '01:02');
      expect(formatClock(139400), '02:19');
      expect(formatClock(0), '00:00');
      expect(formatClock(3599000), '59:59');
    });

    test('an unmeasured solve renders as a dash', () {
      expect(formatClock(null), '—');
    });
  });
}
