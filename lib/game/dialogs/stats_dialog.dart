/// «الإحصائيات» — stat cards, guess distribution, share.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../backend/supabase_config.dart';
import '../../core/strings.dart';
import '../../core/theme/kalimat_colors.dart';
import '../../core/theme/kalimat_theme.dart';
import '../../core/theme/metrics.dart';
import '../../core/utils/arabic_digits.dart';
import '../../profile/profile_screen.dart';
import '../engine/models.dart';
import '../engine/share_grid.dart';
import '../state/game_controller.dart';
import '../state/stats_controller.dart';
import '../widgets/distribution_bar.dart';
import '../widgets/kalimat_button.dart';
import '../widgets/kalimat_dialog.dart';
import '../widgets/segment_toggle.dart';
import '../widgets/stat_card.dart';
import 'leaderboard_view.dart';

Future<void> showStatsDialog(BuildContext context) => showKalimatDialog(
  context: context,
  builder: (context) => const _StatsDialog(),
);

class _StatsDialog extends ConsumerStatefulWidget {
  const _StatsDialog();

  @override
  ConsumerState<_StatsDialog> createState() => _StatsDialogState();
}

class _StatsDialogState extends ConsumerState<_StatsDialog> {
  int _tab = 0; // 0 = stats, 1 = leaderboard

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameProvider);
    final won = game.status == GameStatus.won;
    final finished = game.finished;

    return KalimatDialogCard(
      title: won ? S.win : S.stats,
      footer: _tab == 0
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KalimatButton(
                  label: S.shareResult,
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
                const SizedBox(height: Metrics.s2),
                KalimatButton(
                  label: S.viewProfile,
                  variant: KalimatButtonVariant.ghost,
                  block: true,
                  onPressed: () {
                    final navigator = Navigator.of(context);
                    navigator.pop();
                    navigator.push(
                      PageRouteBuilder(
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                        pageBuilder: (_, _, _) => const ProfileScreen(),
                      ),
                    );
                  },
                ),
              ],
            )
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isSupabaseConfigured) ...[
            Center(
              child: SegmentToggle(
                options: const [S.stats, S.leaderboard],
                selected: _tab,
                onChanged: (i) => setState(() => _tab = i),
              ),
            ),
            const SizedBox(height: Metrics.s4),
          ],
          if (_tab == 1) const LeaderboardView() else _StatsContent(won: won),
        ],
      ),
    );
  }
}

class _StatsContent extends ConsumerWidget {
  const _StatsContent({required this.won});

  final bool won;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.kalimatColors;
    final stats = ref.watch(statsProvider);
    final game = ref.watch(gameProvider);
    final maxDist = stats.dist.fold(1, (a, b) => a > b ? a : b);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (won)
          Padding(
            padding: const EdgeInsets.only(bottom: Metrics.s4),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
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
                    color: c.textOnSoft,
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
            StatCard(value: toArabicDigits('${stats.best}'), label: S.statBest),
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
    );
  }
}
