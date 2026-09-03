/// Staggered kalimat-rise for list/section entrances: each child fades in
/// and rises 8px, offset by [interval], all riding one controller. Runs
/// once per mount — event-driven motion, never idle.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/motion.dart';

class StaggeredRise extends StatefulWidget {
  const StaggeredRise({
    super.key,
    required this.children,
    required this.enabled,
    this.interval = const Duration(milliseconds: 30),
    this.maxStaggered = 8,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
  });

  final List<Widget> children;

  /// «حركة المربعات» — false jumps straight to the settled end state.
  final bool enabled;

  /// Per-child offset. Children beyond [maxStaggered] share the last slot
  /// so a long list doesn't tail off forever.
  final Duration interval;
  final int maxStaggered;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  State<StaggeredRise> createState() => _StaggeredRiseState();
}

class _StaggeredRiseState extends State<StaggeredRise>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  int get _slots => math.min(
    widget.children.length - 1,
    widget.maxStaggered,
  ).clamp(0, widget.maxStaggered);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Motion.base + widget.interval * _slots,
    );
    if (widget.enabled) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Animation<double> _riseFor(int index) {
    final totalMs = _controller.duration!.inMilliseconds;
    final startMs = widget.interval.inMilliseconds * math.min(index, _slots);
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(
        startMs / totalMs,
        (startMs + Motion.base.inMilliseconds) / totalMs,
        curve: Motion.easeOut,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: widget.crossAxisAlignment,
      children: [
        for (final (i, child) in widget.children.indexed)
          _Rise(animation: _riseFor(i), child: child),
      ],
    );
  }
}

class _Rise extends StatelessWidget {
  const _Rise({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, 8 * (1 - animation.value)),
          child: child,
        ),
        child: child,
      ),
    );
  }
}
