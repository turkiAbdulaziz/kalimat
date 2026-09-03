/// Arabic-Indic count-up: the number ticks from ٠ to its value with an
/// ease-out deceleration, giving stats a sense of arrival. One-shot on
/// mount; a changed [value] animates from the current displayed number.
library;

import 'package:flutter/widgets.dart';

import '../theme/motion.dart';
import '../utils/arabic_digits.dart';

class CountUpText extends StatelessWidget {
  const CountUpText({
    super.key,
    required this.value,
    required this.enabled,
    this.suffix = '',
    this.style,
  });

  final int value;

  /// «حركة المربعات» — false renders the final number in a single frame.
  final bool enabled;

  /// Appended after the digits, e.g. '٪'.
  final String suffix;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return Text('${toArabicDigits('$value')}$suffix', style: style);
    }
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: Motion.slow,
      curve: Motion.easeOut,
      builder: (context, v, _) =>
          Text('${toArabicDigits('$v')}$suffix', style: style),
    );
  }
}
