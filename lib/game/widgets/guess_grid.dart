/// The 6×5 board. Rows shake on invalid input; the revealed row flips its
/// tiles with a 120ms stagger (index order = right-to-left under RTL).
library;

import 'package:flutter/material.dart';

import '../../core/theme/metrics.dart';
import '../../core/theme/motion.dart';
import '../engine/models.dart';
import '../state/game_controller.dart';
import 'tile.dart';

class GuessGrid extends StatelessWidget {
  const GuessGrid({
    super.key,
    required this.guesses,
    required this.rowStates,
    required this.current,
    this.shakeRow = -1,
    this.revealRow = -1,
    this.animatePop = true,
    this.tileSize = Metrics.tileSize,
  });

  final List<String> guesses;
  final List<List<TileState>> rowStates;
  final List<String> current;
  final int shakeRow;
  final int revealRow;
  final bool animatePop;
  final double tileSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 0; r < kMaxGuesses; r++) ...[
          if (r > 0) const SizedBox(height: Metrics.gridGap),
          _ShakeRow(
            shaking: r == shakeRow,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var c = 0; c < kWordLength; c++) ...[
                  if (c > 0) const SizedBox(width: Metrics.tileGap),
                  _tileAt(r, c),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _tileAt(int r, int c) {
    if (r < guesses.length) {
      // Submitted row.
      final letters = guesses[r].split('');
      return Tile(
        letter: c < letters.length ? letters[c] : '',
        state: rowStates[r][c],
        size: tileSize,
        reveal: r == revealRow,
        revealDelay: Motion.flipStagger * c,
      );
    }
    if (r == guesses.length && c < current.length) {
      // Active row, typed letter.
      return Tile(
        letter: current[c],
        state: TileState.filled,
        size: tileSize,
        animatePop: animatePop,
      );
    }
    return Tile(size: tileSize);
  }
}

/// Horizontal shake: 0 → -6 → 6 → -4 → 4 → 0 over 420ms.
class _ShakeRow extends StatefulWidget {
  const _ShakeRow({required this.shaking, required this.child});

  final bool shaking;
  final Widget child;

  @override
  State<_ShakeRow> createState() => _ShakeRowState();
}

class _ShakeRowState extends State<_ShakeRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Motion.slow,
  );

  static final _offset = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0, end: -6), weight: 1),
    TweenSequenceItem(tween: Tween(begin: -6, end: 6), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 6, end: -4), weight: 1),
    TweenSequenceItem(tween: Tween(begin: -4, end: 4), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 4, end: 0), weight: 1),
  ]);

  @override
  void didUpdateWidget(_ShakeRow old) {
    super.didUpdateWidget(old);
    if (widget.shaking && !old.shaking) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Transform.translate(
        offset: Offset(_c.isAnimating ? _offset.transform(_c.value) : 0, 0),
        child: child,
      ),
      child: widget.child,
    );
  }
}
