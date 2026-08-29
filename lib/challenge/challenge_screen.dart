/// The duel board. Same surface as «كلمة اليوم» — the only difference is the
/// badge slot, which names the opponent, shows their live progress, or the
/// score you have to beat.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../backend/backend_providers.dart';
import '../core/strings.dart';
import '../core/theme/kalimat_colors.dart';
import '../core/theme/metrics.dart';
import '../core/utils/arabic_digits.dart';
import '../game/engine/letters.dart';
import '../game/state/settings_controller.dart';
import '../game/widgets/game_surface.dart';
import '../game/widgets/screen_header.dart';
import '../game/widgets/section_card.dart';
import 'challenge_controller.dart';
import 'challenge_result_dialog.dart';
import 'challenge_row.dart';
import 'models.dart';

class ChallengeScreen extends ConsumerStatefulWidget {
  const ChallengeScreen({super.key, required this.challengeId});

  final String challengeId;

  @override
  ConsumerState<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends ConsumerState<ChallengeScreen> {
  final FocusNode _focus = FocusNode();
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  /// get_challenge() is the only call that hands over the word, and it also
  /// stamps started_at — so the board is only mounted once it returns.
  Future<void> _load() async {
    final detail = await ref
        .read(challengeRepositoryProvider)
        .open(widget.challengeId);
    if (!mounted) return;
    if (detail == null) {
      setState(() {
        _loading = false;
        _failed = true;
      });
      return;
    }
    ref.read(activeChallengeProvider.notifier).open(detail);
    setState(() => _loading = false);

    // Opened an already-played duel: go straight to the recap.
    if (ref.read(challengeGameProvider).finished && mounted) {
      showChallengeResultDialog(context);
    }
  }

  void _onKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final game = ref.read(challengeGameProvider.notifier);
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
    final c = context.kalimatColors;
    final detail = ref.watch(activeChallengeProvider);

    ref.listen(challengeGameProvider.select((s) => s.statsDialogTick), (
      prev,
      next,
    ) {
      if (prev != null && next > prev) showChallengeResultDialog(context);
    });

    final title = detail == null
        ? S.challenges
        : '${S.vsPrefix}${detail.opponentName}';

    return Scaffold(
      backgroundColor: c.surfacePage,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Metrics.appMaxWidth),
            child: Column(
              children: [
                ScreenHeader(
                  title: title,
                  onBack: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _failed || detail == null
                      ? const Center(child: SectionNote(S.openChallengeFailed))
                      : _keyboardListener(child: _Board(detail: detail)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _keyboardListener({required Widget child}) => KeyboardListener(
    focusNode: _focus,
    autofocus: true,
    onKeyEvent: _onKeyEvent,
    child: child,
  );
}

class _Board extends ConsumerWidget {
  const _Board({required this.detail});

  final ChallengeDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(challengeGameProvider);
    final controller = ref.read(challengeGameProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final opponent = ref.watch(opponentSideProvider).value ?? detail.theirs;

    return GameSurface(
      game: game,
      motion: settings.motion,
      hints: settings.hints,
      onKey: controller.onKey,
      onEnter: controller.onEnter,
      onDelete: controller.onDelete,
      badge: opponentBadge(detail.opponentName, opponent),
      revealedAnswer: stripMarks(game.word.word),
    );
  }
}

/// The badge slot's duel copy: the score to beat, live progress, or just who
/// you are playing.
String opponentBadge(String name, ChallengeSide side) {
  if (side.finished) return '$name: ${scoreLabel(side)}';
  if (side.guesses > 0) {
    return '$name${S.inAttempt}${toArabicDigits('${side.guesses}')}';
  }
  return '${S.vsPrefix}$name';
}
