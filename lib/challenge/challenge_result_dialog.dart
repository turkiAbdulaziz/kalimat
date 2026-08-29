/// «فزت» / «خسرت» / «تعادل» — the duel recap: both scores with their clocks,
/// your grid, a rematch, and the share line.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../backend/backend_providers.dart';
import '../core/rise_route.dart';
import '../core/strings.dart';
import '../core/theme/kalimat_colors.dart';
import '../core/theme/kalimat_theme.dart';
import '../core/theme/metrics.dart';
import '../core/utils/arabic_digits.dart';
import '../flow/flow_controller.dart';
import '../game/engine/share_grid.dart';
import '../game/state/settings_controller.dart';
import '../game/widgets/kalimat_avatar.dart';
import '../game/widgets/kalimat_button.dart';
import '../game/widgets/kalimat_dialog.dart';
import 'challenge_controller.dart';
import 'challenge_row.dart';
import 'challenge_screen.dart';
import 'models.dart';

Future<void> showChallengeResultDialog(BuildContext context) =>
    showKalimatDialog(
      context: context,
      builder: (context) => const _ChallengeResultDialog(),
    );

class _ChallengeResultDialog extends ConsumerWidget {
  const _ChallengeResultDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(activeChallengeProvider);
    if (detail == null) return const SizedBox.shrink();

    final game = ref.watch(challengeGameProvider);
    final mine = ref.read(challengeGameProvider.notifier).mySide;
    final theirs = ref.watch(opponentSideProvider).value ?? detail.theirs;
    final outcome = decideOutcome(mine, theirs);
    final myName = ref.watch(displayNameProvider);

    final title = switch (outcome) {
      ChallengeOutcome.won => S.challengeWon,
      ChallengeOutcome.lost => S.challengeLost,
      ChallengeOutcome.draw => S.challengeDraw,
      // Still waiting on the other side: state the fact, don't celebrate.
      ChallengeOutcome.pending => S.waitingOpponent,
    };

    return KalimatDialogCard(
      title: title,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KalimatButton(
            label: S.rematch,
            block: true,
            onPressed: () => _rematch(context, ref, detail.opponentId),
          ),
          const SizedBox(height: Metrics.s2),
          KalimatButton(
            label: S.shareResult,
            variant: KalimatButtonVariant.ghost,
            block: true,
            onPressed: () => SharePlus.instance.share(
              ShareParams(
                text: buildChallengeShareText(
                  myName: myName,
                  opponentName: detail.opponentName,
                  won: mine.won,
                  opponentWon: theirs.won,
                  opponentGuesses: theirs.guesses,
                  rows: game.rowStates,
                ),
              ),
            ),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ScoreLine(
            name: myName,
            side: mine,
            winner: outcome == ChallengeOutcome.won,
          ),
          const SizedBox(height: Metrics.s2),
          _ScoreLine(
            name: detail.opponentName,
            side: theirs,
            winner: outcome == ChallengeOutcome.lost,
          ),
        ],
      ),
    );
  }

  Future<void> _rematch(
    BuildContext context,
    WidgetRef ref,
    String opponentId,
  ) async {
    final navigator = Navigator.of(context);
    final motion = ref.read(settingsProvider).motion;
    final created = await ref
        .read(challengeRepositoryProvider)
        .create(opponentId);
    if (created == null) return;
    ref.invalidate(myChallengesProvider);
    navigator.pop(); // the result card
    // Replace the finished board rather than stacking a second one.
    navigator.pushReplacement(
      riseRoute(
        motion: motion,
        builder: (_) => ChallengeScreen(challengeId: created.id),
      ),
    );
  }
}

/// One player's line: monogram, name, score, and the solve clock.
class _ScoreLine extends StatelessWidget {
  const _ScoreLine({
    required this.name,
    required this.side,
    required this.winner,
  });

  final String name;
  final ChallengeSide side;
  final bool winner;

  @override
  Widget build(BuildContext context) {
    final c = context.kalimatColors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Metrics.s3,
        vertical: Metrics.s2,
      ),
      decoration: BoxDecoration(
        color: winner ? c.accentSoft : c.surfaceSunken,
        borderRadius: BorderRadius.circular(Metrics.rLg),
      ),
      child: Row(
        children: [
          KalimatAvatar(name: name, size: 32),
          const SizedBox(width: Metrics.s3),
          Expanded(
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: kFontUi,
                fontSize: TypeScale.sm,
                fontWeight: FontWeight.w600,
                color: winner ? c.textOnSoft : c.textBody,
                letterSpacing: 0,
              ),
            ),
          ),
          Text(
            scoreLabel(side),
            style: TextStyle(
              fontFamily: kFontUi,
              fontSize: TypeScale.sm,
              fontWeight: FontWeight.w600,
              color: winner ? c.textOnSoft : c.textBody,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(width: Metrics.s3),
          Text(
            toArabicDigits(formatClock(side.durationMs)),
            style: TextStyle(
              fontFamily: kFontUi,
              fontSize: TypeScale.xs,
              color: winner ? c.textOnSoft : c.textSubtle,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
