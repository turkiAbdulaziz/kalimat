/// The answer as a row of neutral filled tiles — the board's own visual
/// language, used in the stats dialog after a loss (and reusable by any
/// recap). Neutral on purpose: the correct-brown fill stays a win color.
library;

import 'package:flutter/material.dart';

import '../../core/theme/metrics.dart';
import '../engine/models.dart';
import 'tile.dart';

class AnswerTiles extends StatelessWidget {
  const AnswerTiles({super.key, required this.word, this.tileSize = 40});

  final String word;
  final double tileSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final (i, letter) in word.split('').indexed) ...[
          if (i > 0) const SizedBox(width: Metrics.tileGap),
          Tile(letter: letter, state: TileState.filled, size: tileSize),
        ],
      ],
    );
  }
}
