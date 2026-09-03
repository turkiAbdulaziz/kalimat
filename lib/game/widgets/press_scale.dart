/// Press acknowledgment for tappable things that aren't buttons: scale to
/// .97 at 80ms while held, exactly like KalimatButton. Micro-feedback —
/// deliberately exempt from the motion gate (see MotionScope).
library;

import 'package:flutter/widgets.dart';

import '../../core/theme/motion.dart';

class PressScale extends StatefulWidget {
  const PressScale({super.key, this.onTap, required this.child});

  final VoidCallback? onTap;
  final Widget child;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _held = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: widget.onTap == null
          ? null
          : (_) => setState(() => _held = true),
      onTapUp: (_) => setState(() => _held = false),
      onTapCancel: () => setState(() => _held = false),
      child: AnimatedScale(
        scale: _held ? .97 : 1,
        duration: Motion.instant,
        curve: Motion.easeOut,
        child: widget.child,
      ),
    );
  }
}
