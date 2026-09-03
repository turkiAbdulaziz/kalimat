/// Haptic feedback behind the «الاهتزاز» setting. Semantic methods so
/// intensity tuning stays central; fired from the state layer at the exact
/// visual peak (per HIG), which also means haptics still land when
/// «حركة المربعات» is off — they carry the feedback motion no longer does.
///
/// Tests override [hapticsProvider] with a recording fake.
library;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_controller.dart';

final hapticsProvider = Provider<HapticsService>(HapticsService.new);

class HapticsService {
  HapticsService(this._ref);

  final Ref _ref;

  bool get _enabled => _ref.read(settingsProvider).haptics;

  /// Key press / small acknowledgment.
  void tap() {
    if (_enabled) HapticFeedback.selectionClick();
  }

  /// Win wave start, duel victory.
  void success() {
    if (_enabled) HapticFeedback.lightImpact();
  }

  /// Invalid word shake.
  void error() {
    if (_enabled) HapticFeedback.mediumImpact();
  }
}
