/// One duel in the «التحدّيات» list: opponent monogram + name, a state pill,
/// and the two scores once they exist.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/strings.dart';
import '../core/theme/kalimat_colors.dart';
import '../core/theme/kalimat_theme.dart';
import '../core/theme/metrics.dart';
import '../core/theme/motion.dart';
import '../core/utils/arabic_digits.dart';
import '../game/engine/game_rules.dart';
import '../game/widgets/kalimat_avatar.dart';
import 'models.dart';

/// «٣/٦» for a finished side, «—/٦» for a loss, «…» while still playing.
String scoreLabel(ChallengeSide side) {
  if (!side.finished) return '…';
  return side.won
      ? '${toArabicDigits('${side.guesses}')}/${toArabicDigits('$kMaxGuesses')}'
      : '—/${toArabicDigits('$kMaxGuesses')}';
}

class ChallengeRow extends StatefulWidget {
  const ChallengeRow({
    super.key,
    required this.challenge,
    required this.outcome,
    required this.onTap,
    this.divider = true,
  });

  final ChallengeSummary challenge;
  final ChallengeOutcome outcome;
  final VoidCallback? onTap;
  final bool divider;

  @override
  State<ChallengeRow> createState() => _ChallengeRowState();
}

class _ChallengeRowState extends State<ChallengeRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.kalimatColors;
    final ch = widget.challenge;

    // Your move needs no pill — it sits under the «دورك» heading already, and
    // the subtitle names the score to beat. A chevron marks it as actionable,
    // matching KalimatListRow.
    final (String pill, Color pillBg, Color pillFg) = switch (ch.turn) {
      ChallengeTurn.yours => ('', Colors.transparent, c.textSubtle),
      ChallengeTurn.waiting => (
        scoreLabel(ch.mine),
        c.surfaceSunken,
        c.textMuted,
      ),
      ChallengeTurn.done => (
        switch (widget.outcome) {
          ChallengeOutcome.won => S.challengeWon,
          ChallengeOutcome.lost => S.challengeLost,
          ChallengeOutcome.draw => S.challengeDraw,
          ChallengeOutcome.pending => S.challengeExpired,
        },
        widget.outcome == ChallengeOutcome.won
            ? c.tileCorrect
            : c.surfaceSunken,
        widget.outcome == ChallengeOutcome.won
            ? c.tileTextOnState
            : c.textMuted,
      ),
    };

    // Second line: both scores once the duel is over, the target to beat
    // while it is your move, nothing while you wait.
    final String? subtitle = switch (ch.turn) {
      ChallengeTurn.done => '${scoreLabel(ch.mine)} · ${scoreLabel(ch.theirs)}',
      ChallengeTurn.yours =>
        ch.theirs.finished
            ? '${ch.opponentName}: ${scoreLabel(ch.theirs)}'
            : S.notStarted,
      ChallengeTurn.waiting => null,
    };

    final row = AnimatedContainer(
      duration: Motion.fast,
      curve: Motion.easeOut,
      padding: const EdgeInsets.symmetric(
        horizontal: Metrics.s2,
        vertical: Metrics.s2,
      ),
      decoration: BoxDecoration(
        color: _hover ? c.surfaceSunken : Colors.transparent,
        borderRadius: BorderRadius.circular(Metrics.rLg),
        border: widget.divider
            ? Border(bottom: BorderSide(color: c.lineSoft))
            : null,
      ),
      child: Row(
        children: [
          KalimatAvatar(name: ch.opponentName, size: 36),
          const SizedBox(width: Metrics.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ch.opponentName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: kFontUi,
                    fontSize: TypeScale.sm,
                    fontWeight: FontWeight.w600,
                    color: c.textBody,
                    letterSpacing: 0,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: kFontUi,
                      fontSize: TypeScale.xs2,
                      color: c.textSubtle,
                      letterSpacing: 0,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: Metrics.s2),
          if (pill.isEmpty)
            Icon(LucideIcons.chevronLeft, size: 16, color: c.textSubtle)
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: pillBg,
                borderRadius: BorderRadius.circular(Metrics.rPill),
              ),
              child: Text(
                pill,
                style: TextStyle(
                  fontFamily: kFontUi,
                  fontSize: TypeScale.xs2,
                  fontWeight: FontWeight.w600,
                  color: pillFg,
                  letterSpacing: 0,
                ),
              ),
            ),
        ],
      ),
    );

    if (widget.onTap == null) return row;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: Semantics(
        button: true,
        child: GestureDetector(onTap: widget.onTap, child: row),
      ),
    );
  }
}
