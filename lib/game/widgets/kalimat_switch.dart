/// Settings row: label + optional hint + pill switch, bottom hairline.
library;

import 'package:flutter/material.dart';

import '../../core/theme/kalimat_colors.dart';
import '../../core/theme/kalimat_theme.dart';
import '../../core/theme/metrics.dart';
import '../../core/theme/motion.dart';

class KalimatSwitch extends StatelessWidget {
  const KalimatSwitch({
    super.key,
    required this.label,
    this.hint,
    required this.checked,
    required this.onChanged,
  });

  final String label;
  final String? hint;
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.kalimatColors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: Metrics.s3),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.lineSoft)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: kFontUi,
                    fontSize: TypeScale.sm,
                    fontWeight: FontWeight.w500,
                    color: c.textBody,
                    letterSpacing: 0,
                  ),
                ),
                if (hint != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      hint!,
                      style: TextStyle(
                        fontFamily: kFontUi,
                        fontSize: TypeScale.xs2,
                        color: c.textSubtle,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: Metrics.s4),
          Semantics(
            toggled: checked,
            label: label,
            child: GestureDetector(
              onTap: () => onChanged(!checked),
              child: AnimatedContainer(
                duration: Motion.base,
                curve: Motion.easeOut,
                width: 46,
                height: 28,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: checked ? c.accent : BrownRamp.t300,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: AnimatedAlign(
                  duration: Motion.base,
                  curve: Motion.easeOut,
                  alignment: checked
                      ? AlignmentDirectional.centerEnd
                      : AlignmentDirectional.centerStart,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: BrownRamp.b0,
                      shape: BoxShape.circle,
                      boxShadow: c.shadowSm,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
