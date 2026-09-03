/// The playable surface shared by the daily puzzle and a duel: the 34px
/// badge/toast slot, the board, and the keyboard. Props-only — the screen
/// above it owns the header, the sync, and the dialogs.
///
/// The surface never scrolls; tiles shrink first on short screens (the
/// keyboard height is fixed).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/metrics.dart';
import '../engine/models.dart';
import '../state/word_game.dart';
import 'guess_grid.dart';
import 'keyboard.dart';
import 'toast_slot.dart';

class GameSurface extends StatelessWidget {
  const GameSurface({
    super.key,
    required this.game,
    required this.motion,
    required this.hints,
    required this.onKey,
    required this.onEnter,
    required this.onDelete,
    this.badge,
    this.revealedAnswer,
  });

  final GameState game;
  final bool motion;
  final bool hints;
  final ValueChanged<String> onKey;
  final VoidCallback onEnter;
  final VoidCallback onDelete;

  /// Replaces «كلمة اليوم …» in the badge slot — a duel shows the opponent
  /// there instead. Null keeps the day badge.
  final String? badge;

  /// The answer in its correct spelling, shown after a loss.
  final String? revealedAnswer;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Metrics.gutter,
              vertical: Metrics.s4,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tileSize = _tileSize(constraints);
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ToastSlot(
                      puzzleNo: game.word.puzzleNo,
                      badge: badge,
                      toast: game.toast,
                      toastIsWin: game.toastIsWin,
                      revealedAnswer: game.revealAnswer ? revealedAnswer : null,
                    ),
                    const SizedBox(height: Metrics.s4),
                    GuessGrid(
                      guesses: game.guesses,
                      rowStates: game.rowStates,
                      current: game.current,
                      shakeRow: game.shakeRow,
                      revealRow: game.revealRow,
                      waveRow: game.waveRow,
                      animatePop: motion,
                      tileSize: tileSize,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Metrics.s2,
            Metrics.s2,
            Metrics.s2,
            Metrics.s4,
          ),
          child: GameKeyboard(
            letterStates: hints ? game.keyStates : const <String, TileState>{},
            disabled: game.finished,
            onKey: onKey,
            onEnter: onEnter,
            onDelete: onDelete,
          ),
        ),
      ],
    );
  }

  /// Tiles shrink before anything else on small screens.
  double _tileSize(BoxConstraints c) {
    final wFit =
        (c.maxWidth - (kWordLength - 1) * Metrics.tileGap) / kWordLength;
    final gridH =
        c.maxHeight -
        Metrics.toastSlotHeight -
        Metrics.s4 -
        (kMaxGuesses - 1) * Metrics.gridGap;
    final hFit = gridH / kMaxGuesses;
    return math.min(Metrics.tileSize, math.min(wFit, hFit));
  }
}
