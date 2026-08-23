/// A single statistic: big Kufi numeral over a subtle label.
library;

import 'package:flutter/material.dart';

import '../../core/theme/kalimat_colors.dart';
import '../../core/theme/kalimat_theme.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.value,
    required this.label,
    this.emphasis = false,
  });

  final String value;
  final String label;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final c = context.kalimatColors;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 64),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: kFontDisplay,
              fontSize: TypeScale.xl2,
              fontWeight: FontWeight.w700,
              color: emphasis ? c.accent : c.textBody,
              letterSpacing: 0,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: kFontUi,
              fontSize: TypeScale.xs2,
              color: c.textSubtle,
              letterSpacing: 0,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
