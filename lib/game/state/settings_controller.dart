/// Settings state (dark / hints / motion / haptics), persisted to LocalStore.
/// The motion flag («حركة المربعات») gates all app *movement*: board
/// animations, screen transitions (core/rise_route.dart, flow/root_flow.dart),
/// and — via core/theme/motion_scope.dart — the shared widgets' translation/
/// scale/stagger/blur. Micro-feedback crossfades (≤140ms color/opacity, 80ms
/// press scale) are exempt by design: see the MotionScope doc comment.
library;

import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_store.dart';

/// Overridden with the real instance in main().
final localStoreProvider = Provider<LocalStore>(
  (ref) => throw UnimplementedError('localStoreProvider must be overridden'),
);

final settingsProvider = NotifierProvider<SettingsController, GameSettings>(
  SettingsController.new,
);

class SettingsController extends Notifier<GameSettings> {
  @override
  GameSettings build() {
    final store = ref.read(localStoreProvider);
    // Until the user saves a preference, honor the platform's
    // reduce-animations accessibility setting.
    if (!store.hasStoredSettings &&
        WidgetsBinding
            .instance
            .platformDispatcher
            .accessibilityFeatures
            .disableAnimations) {
      return const GameSettings(motion: false);
    }
    return store.settings;
  }

  void setDark(bool v) => _update(state.copyWith(dark: v));

  void setHints(bool v) => _update(state.copyWith(hints: v));

  void setMotion(bool v) => _update(state.copyWith(motion: v));

  void setHaptics(bool v) => _update(state.copyWith(haptics: v));

  void _update(GameSettings next) {
    state = next;
    ref.read(localStoreProvider).setSettings(next);
  }
}
