/// One row of the guess distribution: guess number + proportional bar.
/// The bar grows from the right (RTL start) over 420ms per the design spec;
/// [delay] lets the stats dialog fill bars top-to-bottom.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/kalimat_colors.dart';
import '../../core/theme/kalimat_theme.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/motion_scope.dart';
import '../../core/utils/arabic_digits.dart';

class DistributionBar extends StatefulWidget {
  const DistributionBar({
    super.key,
    required this.guess,
    required this.count,
    required this.max,
    this.highlight = false,
    this.delay = Duration.zero,
  });

  /// 1-based guess number.
  final int guess;
  final int count;
  final int max;
  final bool highlight;

  /// Growth start offset (staggered fills). Ignored when motion is off.
  final Duration delay;

  @override
  State<DistributionBar> createState() => _DistributionBarState();
}

class _DistributionBarState extends State<DistributionBar> {
  Timer? _timer;
  bool _scheduled = false;
  bool _grown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduled) return;
    _scheduled = true;
    if (context.motionEnabled && widget.delay > Duration.zero) {
      _timer = Timer(widget.delay, () {
        if (mounted) setState(() => _grown = true);
      });
    } else {
      _grown = true;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.kalimatColors;
    final motion = context.motionEnabled;
    final fraction = widget.max == 0 ? 0.0 : widget.count / widget.max;
    final target = _grown ? fraction : 0.0;

    return Row(
      children: [
        SizedBox(
          width: 14,
          child: Text(
            toArabicDigits('${widget.guess}'),
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
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: target),
              duration: motion ? Motion.slow : Duration.zero,
              curve: Motion.easeOut,
              builder: (context, value, child) => FractionallySizedBox(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: value.clamp(.06, 1.0),
                child: child,
              ),
              child: Container(
                padding: const EdgeInsetsDirectional.only(start: 8),
                alignment: AlignmentDirectional.centerStart,
                decoration: BoxDecoration(
                  color: widget.highlight ? c.tileCorrect : c.tileAbsent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  toArabicDigits('${widget.count}'),
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
