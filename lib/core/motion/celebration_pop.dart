/// One-shot celebration pop (scale 1→1.08→1, the tile pop's own curve) for
/// a badge or number that just earned a moment — the streak on a win, a
/// value incrementing while visible. Event-driven, runs once, never idles.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/motion.dart';
import '../theme/motion_scope.dart';

class CelebrationPop extends StatefulWidget {
  const CelebrationPop({
    super.key,
    required this.child,
    this.celebrateOnMount = false,
    this.popKey,
    this.delay = Duration.zero,
  });

  final Widget child;

  /// Pop once right after mount (e.g. the stats dialog opening on a win).
  final bool celebrateOnMount;

  /// Pops when this value changes while mounted (e.g. a streak counting up).
  final Object? popKey;

  /// Offset before the mount pop, so it can land after a count-up.
  final Duration delay;

  @override
  State<CelebrationPop> createState() => _CelebrationPopState();
}

class _CelebrationPopState extends State<CelebrationPop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: Motion.base,
  );
  Timer? _timer;
  bool _scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduled) return;
    _scheduled = true;
    if (widget.celebrateOnMount && context.motionEnabled) {
      if (widget.delay > Duration.zero) {
        _timer = Timer(widget.delay, () {
          if (mounted) _pop.forward(from: 0);
        });
      } else {
        _pop.forward(from: 0);
      }
    }
  }

  @override
  void didUpdateWidget(CelebrationPop old) {
    super.didUpdateWidget(old);
    if (widget.popKey != old.popKey && context.motionEnabled) {
      _pop.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pop,
      builder: (context, child) {
        final t = Motion.easePop.transform(_pop.value);
        final scale = _pop.isAnimating ? 1 + .08 * math.sin(t * math.pi) : 1.0;
        return Transform.scale(scale: scale, child: child);
      },
      child: widget.child,
    );
  }
}
