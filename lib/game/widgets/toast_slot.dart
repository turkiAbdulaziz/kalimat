/// The 34px slot above the board: shows the day badge, the answer reveal
/// (after a loss), or a transient toast — switched with a rise-and-fade.
library;

import 'package:flutter/material.dart';

import '../../core/strings.dart';
import '../../core/theme/kalimat_colors.dart';
import '../../core/theme/kalimat_theme.dart';
import '../../core/theme/metrics.dart';
import '../../core/theme/motion.dart';
import '../../core/utils/arabic_digits.dart';

class ToastSlot extends StatelessWidget {
  const ToastSlot({
    super.key,
    required this.puzzleNo,
    this.toast,
    this.toastIsWin = false,
    this.revealedAnswer,
  });

  final int puzzleNo;
  final String? toast;
  final bool toastIsWin;

  /// Non-null after a loss: the answer in its correct spelling.
  final String? revealedAnswer;

  @override
  Widget build(BuildContext context) {
    final c = context.kalimatColors;

    final Widget child;
    if (toast != null) {
      child = _Pill(
        key: ValueKey('toast-$toast'),
        text: toast!,
        bg: toastIsWin ? c.tileCorrect : c.surfaceInverse,
        fg: c.textInverse,
        shadow: c.shadowMd,
        fontSize: TypeScale.xs,
      );
    } else if (revealedAnswer != null) {
      child = _Pill(
        key: const ValueKey('answer'),
        text: '${S.answerRevealPrefix}$revealedAnswer',
        bg: c.accentSoft,
        fg: c.textOnSoft,
        fontSize: TypeScale.xs,
      );
    } else {
      child = _Pill(
        key: const ValueKey('badge'),
        text: '${S.dayBadgePrefix}${toArabicDigits('$puzzleNo')}',
        bg: c.surfaceSunken,
        fg: c.textMuted,
        fontSize: TypeScale.xs2,
      );
    }

    return SizedBox(
      height: Metrics.toastSlotHeight,
      child: Center(
        child: AnimatedSwitcher(
          duration: Motion.fast,
          switchInCurve: Motion.easeOut,
          switchOutCurve: Motion.easeOut,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, .35),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    super.key,
    required this.text,
    required this.bg,
    required this.fg,
    required this.fontSize,
    this.shadow,
  });

  final String text;
  final Color bg;
  final Color fg;
  final double fontSize;
  final List<BoxShadow>? shadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        boxShadow: shadow,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: kFontUi,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: fg,
          letterSpacing: 0,
          height: 1.5,
        ),
      ),
    );
  }
}
