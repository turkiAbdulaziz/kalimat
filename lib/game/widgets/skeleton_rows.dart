/// Static skeleton placeholders for a list that is loading: sunken blocks
/// matching the real row layout, no shimmer — looping motion is forbidden;
/// the real rows rise in over them when the data lands.
library;

import 'package:flutter/material.dart';

import '../../core/theme/kalimat_colors.dart';
import '../../core/theme/metrics.dart';

class SkeletonRows extends StatelessWidget {
  const SkeletonRows({super.key, this.count = 4, this.rowHeight = 36});

  final int count;
  final double rowHeight;

  @override
  Widget build(BuildContext context) {
    final c = context.kalimatColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i < count - 1 ? 6 : 0),
            child: Container(
              height: rowHeight,
              decoration: BoxDecoration(
                color: c.surfaceSunken,
                borderRadius: BorderRadius.circular(Metrics.rKey),
              ),
            ),
          ),
      ],
    );
  }
}
