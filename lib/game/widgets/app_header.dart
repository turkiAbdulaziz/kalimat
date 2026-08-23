/// 56px static header: help — wordmark — stats + settings.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/strings.dart';
import '../../core/theme/kalimat_colors.dart';
import '../../core/theme/metrics.dart';
import 'kalimat_button.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key, this.onHelp, this.onStats, this.onSettings});

  final VoidCallback? onHelp;
  final VoidCallback? onStats;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    final c = context.kalimatColors;
    return Container(
      height: Metrics.headerHeight,
      padding: const EdgeInsets.symmetric(horizontal: Metrics.s3),
      decoration: BoxDecoration(
        color: c.surfaceCard,
        border: Border(bottom: BorderSide(color: c.lineSoft)),
      ),
      child: Row(
        children: [
          KalimatIconButton(
            icon: LucideIcons.circleHelp,
            label: S.help,
            onPressed: onHelp,
          ),
          Expanded(
            child: Text(
              S.appTitle,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.displayMedium!.copyWith(color: BrownRamp.b800),
            ),
          ),
          KalimatIconButton(
            icon: LucideIcons.chartColumn,
            label: S.stats,
            onPressed: onStats,
          ),
          const SizedBox(width: 2),
          KalimatIconButton(
            icon: LucideIcons.settings,
            label: S.settings,
            onPressed: onSettings,
          ),
        ],
      ),
    );
  }
}
