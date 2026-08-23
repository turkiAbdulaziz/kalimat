/// «الإحصائيات» — stat cards, guess distribution, share.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/strings.dart';
import '../../core/theme/kalimat_colors.dart';
import '../../core/theme/kalimat_theme.dart';
import '../../core/theme/metrics.dart';
import '../../core/utils/arabic_digits.dart';
import '../engine/models.dart';
import '../engine/share_grid.dart';
import '../state/game_controller.dart';
import '../state/stats_controller.dart';
import '../widgets/distribution_bar.dart';
import '../widgets/kalimat_button.dart';
import '../widgets/kalimat_dialog.dart';
import '../widgets/stat_card.dart';

Future<void> showStatsDialog(BuildContext context) => showKalimatDialog(
      context: context,
      builder: (context) => const _StatsDialog(),
    );

class _StatsDialog extends ConsumerWidget {
  const _StatsDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.kalimatColors;
    final stats = ref.watch(statsProvider);
    final game = ref.watch(gameProvider);
    final won = game.status == GameStatus.won;
    final finished = game.finished;
    final maxDist = stats.dist.fold(1, (a, b) => a > b ? a : b);

    return KalimatDialogCard(
      title: won ? S.win : S.stats,
      footer: KalimatButton(
        label: S.shareResult,
        variant: KalimatButtonVariant.secondary,
        block: true,
        disabled: !finished,
        onPressed: finished
            ? () => SharePlus.instance.share(
                  ShareParams(
                    text: buildShareText(
                      puzzleNo: game.word.puzzleNo,
                      won: won,
                      rows: game.rowStates,
                    ),
                  ),
                )
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (won)
            Padding(
              padding: const EdgeInsets.only(bottom: Metrics.s4),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: c.accentSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'كلمات ${toArabicDigits('${game.word.puzzleNo}')} — '
                    '${toArabicDigits('${game.guesses.length}')}/٦',
                    style: TextStyle(
                      fontFamily: kFontUi,
                      fontSize: TypeScale.xs2,
                      fontWeight: FontWeight.w600,
                      color: BrownRamp.b800,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatCard(
                value: toArabicDigits('${stats.played}'),
                label: S.statPlayed,
              ),
              StatCard(
                value: toArabicPercent(stats.winRatePercent),
                label: S.statWinRate,
                emphasis: true,
              ),
              StatCard(
                value: toArabicDigits('${stats.streak}'),
                label: S.statStreak,
              ),
              StatCard(
                value: toArabicDigits('${stats.best}'),
                label: S.statBest,
              ),
            ],
          ),
          const SizedBox(height: Metrics.s6),
          Text(
            S.distributionTitle,
            style: TextStyle(
              fontFamily: kFontUi,
              fontSize: TypeScale.xs2,
              color: c.textSubtle,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: Metrics.s2),
          for (var i = 0; i < 6; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i < 5 ? 6 : 0),
              child: DistributionBar(
                guess: i + 1,
                count: stats.dist[i],
                max: maxDist,
                highlight: won && game.guesses.length == i + 1,
              ),
            ),
        ],
      ),
    );
  }
}
