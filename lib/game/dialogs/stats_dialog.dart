/// «الإحصائيات» — stat cards, guess distribution, share.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../backend/supabase_config.dart';
import '../../core/motion/celebration_pop.dart';
import '../../core/rise_route.dart';
import '../../core/strings.dart';
import '../../core/theme/kalimat_colors.dart';
import '../../core/theme/kalimat_theme.dart';
import '../../core/theme/metrics.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/motion_scope.dart';
import '../../core/utils/arabic_digits.dart';
import '../../profile/profile_screen.dart';
import '../engine/models.dart';
import '../engine/share_grid.dart';
import '../state/game_controller.dart';
import '../state/settings_controller.dart';
import '../state/stats_controller.dart';
import '../widgets/answer_tiles.dart';
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
                    // The dialog's 220ms dismissal overlaps the profile's
                    // 220ms rise — one continuous gesture.
                    final navigator = Navigator.of(context);
                    final motion = ref.read(settingsProvider).motion;
                    navigator.pop();
                    navigator.push(
                      riseRoute(
                        motion: motion,
                        builder: (_) => const ProfileScreen(),
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
          AnimatedSwitcher(
            duration: context.motionDuration(Motion.fast),
            switchInCurve: Motion.easeOut,
            switchOutCurve: Motion.easeOut,
            child: _tab == 1
                ? const LeaderboardView()
                : _StatsContent(key: const ValueKey('stats'), won: won),
          ),
        ],
      ),
    );
  }
}

/// Streak values that earn the win pill's one extra beat. Rarity is the
/// point (see design/inspo/app-wide-motion.md) — never celebrate day 47.
const Set<int> kStreakLandmarks = {7, 30, 100};

/// The «كلمات ن — ٣/٦» pill. On a landmark streak the fill steps
/// accentSoft→accent and back over one short breath — copy never changes.
class _WinPill extends StatelessWidget {
  const _WinPill({required this.text, required this.landmark});

  final String text;
  final bool landmark;

  @override
  Widget build(BuildContext context) {
    final c = context.kalimatColors;
    final beat = landmark && context.motionEnabled;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: beat ? 1 : 0),
      duration: Motion.fast * 2,
      curve: Motion.easeInOut,
      builder: (context, t, _) {
        final flash = math.sin(t * math.pi);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: Color.lerp(c.accentSoft, c.accent, flash),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontFamily: kFontUi,
              fontSize: TypeScale.xs2,
              fontWeight: FontWeight.w600,
              color: Color.lerp(c.textOnSoft, c.textInverse, flash),
              letterSpacing: 0,
            ),
          ),
        );
      },
    );
  }
}

class _StatsContent extends ConsumerWidget {
  const _StatsContent({super.key, required this.won});

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
        if (!won && game.finished) ...[
          // Loss: no celebration, just the answer in the board's language.
          Center(
            child: Text(
              S.statsAnswerLabel,
              style: TextStyle(
                fontFamily: kFontUi,
                fontSize: TypeScale.xs2,
                color: c.textSubtle,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(height: Metrics.s2),
          AnswerTiles(word: game.word.word),
          const SizedBox(height: Metrics.s4),
        ],
        if (won)
          Padding(
            padding: const EdgeInsets.only(bottom: Metrics.s4),
            child: Center(
              child: _WinPill(
                text:
                    'كلمات ${toArabicDigits('${game.word.puzzleNo}')} — '
                    '${toArabicDigits('${game.guesses.length}')}/${toArabicDigits('$kMaxGuesses')}',
                landmark: kStreakLandmarks.contains(stats.streak),
              ),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            StatCard(value: stats.played, label: S.statPlayed),
            StatCard(
              value: stats.winRatePercent,
              suffix: arabicPercent,
              label: S.statWinRate,
              emphasis: true,
            ),
            // The streak's moment: pops once as its count-up lands, only
            // when this game grew it.
            CelebrationPop(
              celebrateOnMount: won,
              delay: Motion.slow,
              child: StatCard(value: stats.streak, label: S.statStreak),
            ),
            StatCard(value: stats.best, label: S.statBest),
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
        // Bars fill top to bottom so the sequence ends on today's
        // highlighted row — the eye is delivered to the result.
        for (var i = 0; i < kMaxGuesses; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i < kMaxGuesses - 1 ? 6 : 0),
            child: DistributionBar(
              guess: i + 1,
              count: stats.dist[i],
              max: maxDist,
              highlight: won && game.guesses.length == i + 1,
              delay: Duration(milliseconds: 60 * i),
            ),
          ),
      ],
    );
  }
}
