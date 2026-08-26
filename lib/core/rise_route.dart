/// The house screen transition — kalimat-rise: fade in + 8px rise on
/// Motion.easeOut (220ms base); a route pop reverses it to sink + fade.
/// Shared by RootFlow's step switcher and the «حسابي» profile route.
/// Gated by «حركة المربعات»: motion off ⇒ instant swap.
library;

import 'package:flutter/widgets.dart';

import 'theme/motion.dart';

/// kalimat-rise travel distance (design/tokens/motion.css @keyframes).
const double kRisePx = 8;

/// Fade + absolute-px rise driven by an already-curved [animation]
/// (0 → 1 = fully entered). With [sinkOnExit] false, a reversing animation
/// fades in place without the downward translate — used by the RootFlow
/// switcher, where outgoing screens fade only (the sink belongs to route
/// pops).
Widget kalimatRise(
  Animation<double> animation,
  Widget child, {
  bool sinkOnExit = true,
}) {
  return FadeTransition(
    opacity: animation,
    child: AnimatedBuilder(
      animation: animation,
      builder: (_, inner) {
        final exiting =
            animation.status == AnimationStatus.reverse ||
            animation.status == AnimationStatus.dismissed;
        final dy = (sinkOnExit || !exiting)
            ? kRisePx * (1 - animation.value)
            : 0.0;
        return Transform.translate(offset: Offset(0, dy), child: inner);
      },
      child: child,
    ),
  );
}

/// Full-screen route with the kalimat-rise transition (pop = sink + fade).
/// No barrier, no blur — those are dialog chrome (kalimat_dialog.dart).
/// Pass the current «حركة المربعات» value; off ⇒ zero-duration swap.
Route<T> riseRoute<T>({required WidgetBuilder builder, required bool motion}) {
  final duration = motion ? Motion.base : Duration.zero;
  return PageRouteBuilder<T>(
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    pageBuilder: (context, _, _) => builder(context),
    transitionsBuilder: (context, animation, _, child) => kalimatRise(
      CurvedAnimation(
        parent: animation,
        curve: Motion.easeOut,
        reverseCurve: Motion.easeOut,
      ),
      child,
    ),
  );
}
