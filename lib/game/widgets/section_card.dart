/// Section pattern: an 11px subtle label above a bordered surface-card.
/// Shared by «حسابي» and «التحدّيات».
library;

import 'package:flutter/material.dart';

import '../../core/theme/kalimat_colors.dart';
import '../../core/theme/kalimat_theme.dart';
import '../../core/theme/metrics.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.label,
    required this.child,
    this.trailing,
    this.padded = true,
  });

  final String label;
  final Widget child;

  /// Optional action on the label row (e.g. «إضافة صديق»).
  final Widget? trailing;

  /// False lets rows run edge to edge inside the card.
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final c = context.kalimatColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: Metrics.s2),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: kFontUi,
                    fontSize: TypeScale.xs2,
                    fontWeight: FontWeight.w600,
                    color: c.textSubtle,
                    letterSpacing: 0,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(padded ? Metrics.s4 : Metrics.s2),
          decoration: BoxDecoration(
            color: c.surfaceCard,
            border: Border.all(color: c.lineSoft),
            borderRadius: BorderRadius.circular(Metrics.rCard),
            boxShadow: c.shadowSm,
          ),
          child: child,
        ),
      ],
    );
  }
}

/// The subtle centred line used for empty and error states inside a card.
class SectionNote extends StatelessWidget {
  const SectionNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.kalimatColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Metrics.s4),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: kFontUi,
            fontSize: TypeScale.xs,
            color: c.textSubtle,
            letterSpacing: 0,
            height: 1.6,
          ),
        ),
      ),
    );
  }
}
