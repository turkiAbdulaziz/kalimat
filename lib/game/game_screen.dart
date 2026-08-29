/// The daily puzzle screen: header + the shared game surface. The app never
/// scrolls — tiles shrink on short screens instead (see GameSurface).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../backend/backend_providers.dart';
import '../backend/supabase_config.dart';
import '../backend/sync_service.dart';
import '../challenge/challenges_screen.dart';
import '../core/rise_route.dart';
import '../core/theme/metrics.dart';
import '../flow/flow_controller.dart';
import '../profile/profile_screen.dart';
import 'dialogs/help_dialog.dart';
import 'dialogs/stats_dialog.dart';
import 'engine/letters.dart';
import 'state/game_controller.dart';
import 'state/settings_controller.dart';
import 'widgets/app_header.dart';
import 'widgets/game_surface.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with WidgetsBindingObserver {
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final store = ref.read(localStoreProvider);
      if (!store.helpSeen) {
        store.setHelpSeen();
        // First arrival: greet by name — the only time the product does.
        showHelpDialog(context, greetName: ref.read(displayNameProvider));
      }
      ref.read(syncServiceProvider).sync();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh the word (day may have rolled over) and retry queued uploads.
    if (state == AppLifecycleState.resumed) {
      ref.read(syncServiceProvider).sync();
      if (isSupabaseConfigured) ref.invalidate(challengeBadgeProvider);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focus.dispose();
    super.dispose();
  }

  /// Opens «حسابي» with the house rise transition (sink + fade on close).
  /// Board state survives the round trip because it lives in providers.
  void _openProfile() {
    Navigator.of(context).push(
      riseRoute(
        motion: ref.read(settingsProvider).motion,
        builder: (_) => const ProfileScreen(),
      ),
    );
  }

  void _openChallenges() {
    Navigator.of(context).push(
      riseRoute(
        motion: ref.read(settingsProvider).motion,
        builder: (_) => const ChallengesScreen(),
      ),
    );
  }

  /// Hardware keyboard (dev convenience on desktop/web + external keyboards).
  void _onKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final game = ref.read(gameProvider.notifier);
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      game.onEnter();
    } else if (event.logicalKey == LogicalKeyboardKey.backspace) {
      game.onDelete();
    } else {
      final ch = event.character;
      if (ch != null && kKeyboardLetters.contains(ch)) game.onKey(ch);
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameProvider);
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(gameProvider.notifier);

    ref.listen(gameProvider.select((s) => s.statsDialogTick), (prev, next) {
      if (prev != null && next > prev) showStatsDialog(context);
    });
    // Upload the result as soon as a game finishes.
    ref.listen(gameProvider.select((s) => s.finished), (prev, next) {
      if (prev == false && next) {
        ref.read(resultsRepositoryProvider).flushQueue();
      }
    });

    return Scaffold(
      body: SafeArea(
        child: KeyboardListener(
          focusNode: _focus,
          autofocus: true,
          onKeyEvent: _onKeyEvent,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: Metrics.appMaxWidth),
              child: Column(
                children: [
                  AppHeader(
                    onHelp: () => showHelpDialog(context),
                    onStats: () => showStatsDialog(context),
                    onProfile: _openProfile,
                    onChallenges: isSupabaseConfigured ? _openChallenges : null,
                    challengeBadge:
                        ref.watch(challengeBadgeProvider).value ?? false,
                    avatarName: ref.watch(displayNameProvider),
                  ),
                  Expanded(
                    child: GameSurface(
                      game: game,
                      motion: settings.motion,
                      hints: settings.hints,
                      onKey: controller.onKey,
                      onEnter: controller.onEnter,
                      onDelete: controller.onDelete,
                      revealedAnswer: stripMarks(game.word.word),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
