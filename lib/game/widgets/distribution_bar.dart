/// One row of the guess distribution: guess number + proportional bar.
library;

import 'package:flutter/material.dart';

import '../../core/theme/kalimat_colors.dart';
import '../../core/theme/kalimat_theme.dart';
import '../../core/theme/motion.dart';
import '../../core/utils/arabic_digits.dart';

class DistributionBar extends StatelessWidget {
  const DistributionBar({
    super.key,
    required this.guess,
    required this.count,
    required this.max,
    this.highlight = false,
  });

  /// 1-based guess number.
  final int guess;
  final int count;
  final int max;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final c = context.kalimatColors;
    final fraction = max == 0 ? 0.0 : count / max;

    return Row(
      children: [
        SizedBox(
          width: 14,
          child: Text(
            toArabicDigits('$guess'),
            style: TextStyle(
              fontFamily: kFontUi,
              fontSize: TypeScale.xs,
              fontWeight: FontWeight.w500,
              color: c.textMuted,
              letterSpacing: 0,
              height: 1,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 22,
            decoration: BoxDecoration(
              color: c.surfaceSunken,
              borderRadius: BorderRadius.circular(4),
            ),
            clipBehavior: Clip.antiAlias,
            child: FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: (fraction < .06 ? .06 : fraction).clamp(.06, 1),
              child: AnimatedContainer(
                duration: Motion.slow,
                curve: Motion.easeOut,
                padding: const EdgeInsetsDirectional.only(start: 8),
                alignment: AlignmentDirectional.centerStart,
                decoration: BoxDecoration(
                  color: highlight ? c.tileCorrect : c.tileAbsent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  toArabicDigits('$count'),
                  style: TextStyle(
                    fontFamily: kFontUi,
                    fontSize: TypeScale.xs,
                    fontWeight: FontWeight.w600,
                    color: c.textInverse,
                    letterSpacing: 0,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
