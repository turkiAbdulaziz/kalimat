/// The single game surface: header / badge+toast slot / board / keyboard.
/// The app never scrolls — tiles shrink on short screens instead.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../backend/sync_service.dart';
import '../core/theme/metrics.dart';
import '../flow/flow_controller.dart';
import '../profile/profile_screen.dart';
import 'dialogs/help_dialog.dart';
import 'dialogs/stats_dialog.dart';
import 'engine/letters.dart';
import 'engine/models.dart';
import 'state/game_controller.dart';
import 'state/settings_controller.dart';
import 'widgets/app_header.dart';
import 'widgets/guess_grid.dart';
import 'widgets/keyboard.dart';
import 'widgets/toast_slot.dart';

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
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focus.dispose();
    super.dispose();
  }

  /// Instant swap, matching the prototype — screen motion is dialogs-only.
  void _openProfile() {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, _, _) => const ProfileScreen(),
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
                    avatarName: ref.watch(displayNameProvider),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Metrics.gutter,
                        vertical: Metrics.s4,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final tileSize = _tileSize(constraints);
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ToastSlot(
                                puzzleNo: game.word.puzzleNo,
                                toast: game.toast,
                                toastIsWin: game.toastIsWin,
                                revealedAnswer: game.revealAnswer
                                    ? stripMarks(game.word.word)
                                    : null,
                              ),
                              const SizedBox(height: Metrics.s4),
                              GuessGrid(
                                guesses: game.guesses,
                                rowStates: game.rowStates,
                                current: game.current,
                                shakeRow: game.shakeRow,
                                revealRow: game.revealRow,
                                animatePop: settings.motion,
                                tileSize: tileSize,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Metrics.s2,
                      Metrics.s2,
                      Metrics.s2,
                      Metrics.s4,
                    ),
                    child: GameKeyboard(
                      letterStates: settings.hints
                          ? game.keyStates
                          : const <String, TileState>{},
                      disabled: game.finished,
                      onKey: controller.onKey,
                      onEnter: controller.onEnter,
                      onDelete: controller.onDelete,
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

  /// Tiles shrink before anything else on small screens (keyboard height
  /// stays fixed).
  double _tileSize(BoxConstraints c) {
    final wFit =
        (c.maxWidth - (kWordLength - 1) * Metrics.tileGap) / kWordLength;
    final gridH =
        c.maxHeight -
        Metrics.toastSlotHeight -
        Metrics.s4 -
        (kMaxGuesses - 1) * Metrics.gridGap;
    final hFit = gridH / kMaxGuesses;
    return math.min(Metrics.tileSize, math.min(wFit, hFit));
  }
}
