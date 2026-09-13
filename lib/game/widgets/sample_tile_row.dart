/// The «كتاب» demo row: correct/present/absent/correct, flipping
/// in once with the usual 120ms stagger when motion is on. The sign-in
/// hero and empty states that should breathe once share it.
library;

import 'package:flutter/material.dart';

import '../../core/theme/metrics.dart';
import '../../core/theme/motion.dart';
import '../engine/models.dart';
import 'tile.dart';

class SampleTileRow extends StatelessWidget {
  const SampleTileRow({super.key, required this.animate, this.tileSize = 44});

  final bool animate;
  final double tileSize;

  static const _cells = [
    ('ك', TileState.correct),
    ('ت', TileState.present),
    ('ا', TileState.absent),
    ('ب', TileState.correct),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final (i, cell) in _cells.indexed) ...[
          if (i > 0) const SizedBox(width: Metrics.tileGap),
          Tile(
            letter: cell.$1,
            state: cell.$2,
            size: tileSize,
            reveal: animate,
            revealDelay: Motion.flipStagger * i,
          ),
        ],
      ],
    );
  }
}
