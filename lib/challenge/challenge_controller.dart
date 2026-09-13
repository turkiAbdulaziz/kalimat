/// The duel session: the shared word-game loop plus duel-only concerns —
/// per-duel board persistence, live progress pushed on every guess, and a
/// write-once result. It never touches [statsProvider]: streaks and the
/// distribution stay a property of «كلمة اليوم».
///
/// Only one duel is ever on screen (the board is a pushed route), so the
/// session is a single provider fed by [activeChallengeProvider] rather than
/// a family.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../backend/backend_providers.dart';
import '../game/data/local_store.dart';
import '../game/engine/models.dart';
import '../game/state/settings_controller.dart';
import '../game/state/word_game.dart';
import 'models.dart';

/// The duel currently open, set by ChallengeScreen before it mounts the board.
final activeChallengeProvider =
    NotifierProvider<ActiveChallengeController, ChallengeDetail?>(
      ActiveChallengeController.new,
    );

class ActiveChallengeController extends Notifier<ChallengeDetail?> {
  @override
  ChallengeDetail? build() => null;

  /// Swaps in a duel and restarts the board on it.
  bool open(ChallengeDetail detail) {
    if (!isPlayableWord(detail.word) ||
        [
          detail.mine.grid,
          detail.theirs.grid,
        ].any((grid) => grid != null && !isCompatibleGrid(grid))) {
      return false;
    }
    state = detail;
    ref.invalidate(challengeGameProvider);
    return true;
  }
}

/// The opponent's side: the value the board was opened with, then every
/// Realtime update to their row.
final opponentSideProvider = StreamProvider.autoDispose<ChallengeSide>((
  ref,
) async* {
  final detail = ref.watch(activeChallengeProvider);
  if (detail == null) return;
  yield detail.theirs;
  yield* ref
      .watch(challengeRepositoryProvider)
      .watchOpponent(detail.id, detail.opponentId);
});

final challengeGameProvider =
    NotifierProvider<ChallengeGameController, GameState>(
      ChallengeGameController.new,
    );

class ChallengeGameController extends WordGameNotifier {
  /// Stamped once, when the game ends — the result card must not watch the
  /// clock keep running.
  int? _resultDurationMs;

  ChallengeDetail get _detail => ref.read(activeChallengeProvider)!;

  ChallengeBoardSave? get _saved =>
      ref.read(localStoreProvider).challengeBoard(_detail.id);

  /// A duel has no calendar date or puzzle number; only the word matters, and
  /// the badge slot names the opponent instead of the day.
  @override
  DailyWord get sessionWord => DailyWord(
    date: DateTime.now(),
    puzzleNo: 0,
    word: _detail.word,
    fromServer: true,
  );

  @override
  List<String> get restoredGuesses => _saved?.guesses ?? const [];

  @override
  int? get restoredStartedAtMs => _saved?.startedAtMs;

  @override
  GameState build() {
    final restored = super.build();
    // Finished on the server but not on this device (played elsewhere, or the
    // local save was pruned): lock the board rather than let it be replayed.
    final mine = _detail.mine;
    if (mine.finished && !restored.finished) {
      return restored.copyWith(
        status: mine.won ? GameStatus.won : GameStatus.lost,
        revealAnswer: !mine.won,
      );
    }
    return restored;
  }

  @override
  void persistBoard(List<String> guesses, int? startedAtMs) {
    ref
        .read(localStoreProvider)
        .setChallengeBoard(
          _detail.id,
          ChallengeBoardSave(guesses: guesses, startedAtMs: startedAtMs),
        );
  }

  @override
  void onGuessSubmitted(int guessCount) {
    // Fire and forget: the opponent's pill is nice to have, never blocking.
    ref.read(challengeRepositoryProvider).pushProgress(_detail.id, guessCount);
  }

  @override
  void onFinished({
    required bool won,
    required int guesses,
    required int? durationMs,
  }) {
    final id = _detail.id;
    final grid = state.gridString;
    _resultDurationMs = durationMs;
    ref
        .read(challengeRepositoryProvider)
        .submitResult(
          id: id,
          won: won,
          guesses: guesses,
          durationMs: durationMs,
          grid: grid,
        )
        .then((_) {
          ref.invalidate(myChallengesProvider);
          ref.invalidate(challengeBadgeProvider);
          ref.invalidate(myPlayerCardProvider);
        });
  }

  /// My own side, as the result card reads it. Falls back to the server's
  /// record when the duel was finished in an earlier session.
  ChallengeSide get mySide => ChallengeSide(
    guesses: state.guesses.isEmpty
        ? _detail.mine.guesses
        : state.guesses.length,
    finished: state.finished,
    won: state.status == GameStatus.won,
    durationMs: _resultDurationMs ?? _detail.mine.durationMs,
    grid: state.rowStates.isEmpty ? _detail.mine.grid : state.gridString,
  );
}
