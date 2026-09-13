/// The daily puzzle session: the shared word-game loop (word_game.dart) plus
/// daily-only concerns — board persistence, local stats, and the offline
/// result queue.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_store.dart';
import '../engine/models.dart';
import 'settings_controller.dart';
import 'stats_controller.dart';
import 'word_game.dart';

export 'word_game.dart';

/// Overridden in main() with the word resolved at startup.
final initialWordProvider = Provider<DailyWord>(
  (ref) => throw UnimplementedError('initialWordProvider must be overridden'),
);

final gameProvider = NotifierProvider<GameController, GameState>(
  GameController.new,
);

class GameController extends WordGameNotifier {
  @override
  DailyWord get sessionWord => ref.read(initialWordProvider);

  /// Today's saved board, if the save is for today's date.
  BoardSave? get _saved {
    final saved = ref.read(localStoreProvider).board;
    if (saved == null || !_sameDate(saved.date, sessionWord.date)) return null;
    return saved;
  }

  @override
  List<String> get restoredGuesses => _saved?.guesses ?? const [];

  @override
  int? get restoredStartedAtMs => _saved?.startedAtMs;

  static bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Adopts a new word of the day (server authority or offline rollover).
  /// A game in progress is never interrupted — the new word is already
  /// cached and picked up on the next launch/rollover.
  void applyServerWord(DailyWord next) {
    if (!isPlayableWord(next.word)) return;
    final same =
        _sameDate(state.word.date, next.date) && state.word.word == next.word;
    if (same) return;
    final untouched = state.guesses.isEmpty && state.current.isEmpty;
    if (untouched || state.finished) resetTo(next);
  }

  @override
  void persistBoard(List<String> guesses, int? startedAtMs) {
    ref
        .read(localStoreProvider)
        .setBoard(
          BoardSave(
            date: state.word.date,
            guesses: guesses,
            startedAtMs: startedAtMs,
          ),
        );
  }

  @override
  void onFinished({
    required bool won,
    required int guesses,
    required int? durationMs,
  }) {
    ref.read(statsProvider.notifier).recordGame(won: won, guesses: guesses);

    final store = ref.read(localStoreProvider);
    store.setPendingResults([
      ...store.pendingResults,
      PendingResult(
        date: state.word.date,
        won: won,
        guesses: won ? guesses : null,
        grid: state.gridString,
        durationMs: durationMs,
      ),
    ]);
  }
}
