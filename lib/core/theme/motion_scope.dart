/// Ambient «حركة المربعات» flag for shared leaf widgets.
///
/// Installed once above the Navigator (app.dart, MaterialApp.builder) so
/// dialogs and pushed routes inherit it; widgets stay Riverpod-free and read
/// it like they read [KalimatColors] from the theme. Defaults to true when
/// absent so leaf-widget tests need no wrapper.
///
/// The gate's principled cut (mirrors reduced-motion guidance — replace,
/// don't remove): gate anything that translates, scales beyond a sub-100ms
/// press acknowledgment, staggers, or blurs. Color/opacity crossfades at
/// `Motion.fast` or shorter and the 80ms press-down scale are exempt — they
/// are state legibility, and their end state is identical either way.
library;

import 'package:flutter/widgets.dart';

class MotionScope extends InheritedWidget {
  const MotionScope({super.key, required this.enabled, required super.child});

  final bool enabled;

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MotionScope>()?.enabled ??
      true;

  @override
  bool updateShouldNotify(MotionScope oldWidget) => enabled != oldWidget.enabled;
}

extension MotionContext on BuildContext {
  bool get motionEnabled => MotionScope.of(this);

  /// Token duration when motion is on, zero (single-frame swap) when off.
  Duration motionDuration(Duration token) =>
      motionEnabled ? token : Duration.zero;
}
