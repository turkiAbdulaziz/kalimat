/// Two-option pill toggle (design extension built from badge/button styles).
library;

import 'package:flutter/material.dart';

import '../../core/theme/kalimat_colors.dart';
import '../../core/theme/kalimat_theme.dart';
import '../../core/theme/motion.dart';

class SegmentToggle extends StatelessWidget {
  const SegmentToggle({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<String> options;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.kalimatColors;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.surfaceSunken,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, label) in options.indexed)
            GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: Motion.fast,
                curve: Motion.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: i == selected ? c.surfaceCard : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: i == selected ? c.shadowSm : null,
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: kFontUi,
                    fontSize: TypeScale.xs,
                    fontWeight: FontWeight.w600,
                    color: i == selected ? c.textBody : c.textMuted,
                    letterSpacing: 0,
                    height: 1.4,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
