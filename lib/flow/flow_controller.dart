/// First-run flow state: sign-in → name → game, plus sign-out back to
/// sign-in. The whole flow exists only when Supabase is configured; dev
/// builds (and the widget-test suite) boot straight into the game.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../backend/auth_repository.dart';
import '../backend/backend_providers.dart';
import '../backend/supabase_config.dart';
import '../backend/supabase_service.dart';
import '../core/strings.dart';
import '../game/state/game_controller.dart';
import '../game/state/settings_controller.dart';
import '../game/state/stats_controller.dart';

enum FlowStep { signin, name, game }

final flowProvider = NotifierProvider<FlowController, FlowStep>(
  FlowController.new,
);

/// The name shown in the header avatar, profile, and first-run greeting.
/// Backed by the LocalStore cache so it renders offline.
final displayNameProvider = NotifierProvider<DisplayNameController, String>(
  DisplayNameController.new,
);

class DisplayNameController extends Notifier<String> {
  @override
  String build() => ref.read(localStoreProvider).displayName ?? S.guestName;

  Future<void> set(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    state = trimmed;
    await ref.read(localStoreProvider).setDisplayName(trimmed);
  }

  Future<void> clear() async {
    state = S.guestName;
    await ref.read(localStoreProvider).clearDisplayName();
  }
}

class FlowController extends Notifier<FlowStep> {
  @override
  FlowStep build() {
    if (!isSupabaseConfigured) return FlowStep.game;
    final store = ref.read(localStoreProvider);
    if (store.onboarded) return FlowStep.game;
    if (store.helpSeen || store.stats.played > 0) {
      // Existing install upgrading: never show the flow retroactively.
      store.setOnboarded();
      return FlowStep.game;
    }
    return FlowStep.signin;
  }

  Future<void> continueAsGuest() async {
    await ref.read(localStoreProvider).setOnboarded();
    state = FlowStep.game;
  }

  /// Runs a provider link (linkGoogle / linkApple) from the sign-in screen.
  /// Returns the error line to show, or null (success or user-cancelled).
  Future<String?> signInWith(Future<LinkOutcome> Function() link) async {
    if (!await SupabaseService.ensureSession()) return S.connectionFailed;

    final auth = ref.read(authRepositoryProvider);
    var outcome = await link();
    if (outcome == LinkOutcome.alreadyLinkedElsewhere) {
      // Pre-onboarding there is no device progress to protect — switch
      // without the confirm dialog (which lives in the profile's
      // «حفظ التقدم» section, where progress exists).
      outcome = await auth.confirmSwitch()
          ? LinkOutcome.switchedAccount
          : LinkOutcome.failed;
    }

    switch (outcome) {
      case LinkOutcome.linked:
        state = FlowStep.name;
        return null;
      case LinkOutcome.switchedAccount:
        // Returning player: reuse their saved name and skip the name screen.
        String? name;
        try {
          name = await auth.fetchDisplayName();
        } catch (_) {
          name = null;
        }
        if (name != null && name.trim().isNotEmpty) {
          await ref.read(displayNameProvider.notifier).set(name);
          await ref.read(localStoreProvider).setOnboarded();
          state = FlowStep.game;
        } else {
          state = FlowStep.name;
        }
        return null;
      case LinkOutcome.cancelled:
        return null;
      case LinkOutcome.alreadyLinkedElsewhere:
      case LinkOutcome.failed:
        return S.linkFailed;
    }
  }

  Future<void> completeName(String name) async {
    final trimmed = name.trim();
    if (trimmed.length < 2) return;
    await ref.read(displayNameProvider.notifier).set(trimmed);
    final auth = ref.read(authRepositoryProvider);
    if (!auth.isAnonymous) {
      try {
        await auth.updateDisplayName(trimmed);
      } catch (_) {
        // Offline is fine — the local cache is what the UI renders.
      }
    }
    await ref.read(localStoreProvider).setOnboarded();
    state = FlowStep.game;
  }

  Future<void> skipName() async {
    await ref.read(localStoreProvider).setOnboarded();
    state = FlowStep.game;
  }

  /// «تسجيل الخروج»: clears the board and identity, keeps local stats
  /// (they are authoritative), and returns to the sign-in screen.
  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    final store = ref.read(localStoreProvider);
    await store.clearBoard();
    await ref.read(displayNameProvider.notifier).clear();
    await store.clearOnboarded();
    ref.invalidate(gameProvider);
    state = FlowStep.signin;
  }

  /// «حذف الحساب»: the server account and everything it owns are gone, so
  /// unlike [signOut] this also wipes the device — stats, duel boards, the
  /// unsent result queue — and starts over at sign-in. Returns false and
  /// changes nothing when the server call fails.
  Future<bool> deleteAccount() async {
    if (!await ref.read(authRepositoryProvider).deleteAccount()) return false;
    final store = ref.read(localStoreProvider);
    await store.clearBoard();
    await store.clearStats();
    await store.clearChallengeBoards();
    await store.clearPendingResults();
    await ref.read(displayNameProvider.notifier).clear();
    await store.clearOnboarded();
    ref.invalidate(gameProvider);
    ref.invalidate(statsProvider);
    state = FlowStep.signin;
    return true;
  }
}
