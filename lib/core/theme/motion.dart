/// Motion tokens from the design system (tokens/motion.css).
library;

import 'package:flutter/animation.dart';

abstract final class Motion {
  static const Duration instant = Duration(milliseconds: 80);
  static const Duration fast = Duration(milliseconds: 140);
  static const Duration base = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 420);
  static const Duration flipStagger = Duration(milliseconds: 120);
  static const Duration waveStagger = Duration(milliseconds: 70);
  static const Duration toastVisible = Duration(milliseconds: 1300);

  /// Default easing — cubic-bezier(.2,.8,.3,1).
  static const Curve easeOut = Cubic(.2, .8, .3, 1);

  /// Flip/shake easing — cubic-bezier(.4,0,.2,1).
  static const Curve easeInOut = Cubic(.4, 0, .2, 1);

  /// Pop overshoot — cubic-bezier(.34,1.4,.64,1). The only bounce allowed.
  static const Curve easePop = Cubic(.34, 1.4, .64, 1);
}
