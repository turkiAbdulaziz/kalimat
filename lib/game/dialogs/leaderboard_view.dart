/// «المتصدرون» — daily / global leaderboard lists (design extension).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../backend/backend_providers.dart';
import '../../core/strings.dart';
import '../../core/theme/kalimat_colors.dart';
import '../../core/theme/kalimat_theme.dart';
import '../../core/theme/metrics.dart';
import '../../core/utils/arabic_digits.dart';
import '../widgets/segment_toggle.dart';

class LeaderboardView extends ConsumerStatefulWidget {
  const LeaderboardView({super.key});

  @override
  ConsumerState<LeaderboardView> createState() => _LeaderboardViewState();
}

class _LeaderboardViewState extends ConsumerState<LeaderboardView> {
  int _tab = 0; // 0 = daily, 1 = global

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: SegmentToggle(
            options: const [S.leaderboardDaily, S.leaderboardGlobal],
            selected: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
        ),
        const SizedBox(height: Metrics.s4),
        if (_tab == 0) const _DailyList() else const _GlobalList(),
      ],
    );
  }
}

class _DailyList extends ConsumerWidget {
  const _DailyList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dailyLeaderboardProvider);
    return async.when(
      loading: _loading,
      error: (_, _) => const _Note(S.leaderboardError),
      data: (rows) {
        if (rows == null) return const _Note(S.leaderboardError);
        if (rows.isEmpty) return const _Note(S.leaderboardEmpty);
        return Column(
          children: [
            for (final (i, e) in rows.indexed)
              _Row(
                rank: i + 1,
                name: e.displayName,
                value: e.won && e.guesses != null
                    ? '${toArabicDigits('${e.guesses}')}/٦'
                    : '—/٦',
                highlight: i == 0,
              ),
          ],
        );
      },
    );
  }
}

class _GlobalList extends ConsumerWidget {
  const _GlobalList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(globalLeaderboardProvider);
    return async.when(
      loading: _loading,
      error: (_, _) => const _Note(S.leaderboardError),
      data: (rows) {
        if (rows == null) return const _Note(S.leaderboardError);
        if (rows.isEmpty) return const _Note(S.leaderboardEmpty);
        return Column(
          children: [
            for (final (i, e) in rows.indexed)
              _Row(
                rank: i + 1,
                name: e.displayName,
                value:
                    '${toArabicDigits('${e.wins}')} ${S.winsLabel}'
                    '${e.avgGuesses == null ? '' : ' · ${_arabicDecimal(e.avgGuesses!)}'}',
                highlight: i == 0,
              ),
          ],
        );
      },
    );
  }

  static String _arabicDecimal(double v) =>
      toArabicDigits(v.toStringAsFixed(1)).replaceAll('.', '٫');
}

Widget _loading() => const Padding(
  padding: EdgeInsets.symmetric(vertical: Metrics.s6),
  child: Center(
    child: SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
  ),
);

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.kalimatColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Metrics.s6),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontFamily: kFontUi,
            fontSize: TypeScale.xs,
            color: c.textSubtle,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.rank,
    required this.name,
    required this.value,
    this.highlight = false,
  });

  final int rank;
  final String name;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final c = context.kalimatColors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: Metrics.s2),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.lineSoft)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              toArabicDigits('$rank'),
              style: TextStyle(
                fontFamily: kFontUi,
                fontSize: TypeScale.xs,
                fontWeight: FontWeight.w600,
                color: highlight ? c.accent : c.textSubtle,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(width: Metrics.s2),
          Expanded(
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: kFontUi,
                fontSize: TypeScale.sm,
                fontWeight: highlight ? FontWeight.w600 : FontWeight.w400,
                color: c.textBody,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(width: Metrics.s2),
          Text(
            value,
            style: TextStyle(
              fontFamily: kFontUi,
              fontSize: TypeScale.xs,
              fontWeight: FontWeight.w600,
              color: c.textMuted,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
