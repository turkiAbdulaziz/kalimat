/// 56px static header: help — wordmark — stats, duels, and the avatar (the
/// only route to the account screen).
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/strings.dart';
import '../../core/theme/kalimat_colors.dart';
import '../../core/theme/metrics.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/motion_scope.dart';
import 'kalimat_avatar.dart';
import 'kalimat_button.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    this.onHelp,
    this.onStats,
    this.onProfile,
    this.onChallenges,
    this.challengeBadge = false,
    this.avatarName = '',
  });

  final VoidCallback? onHelp;
  final VoidCallback? onStats;
  final VoidCallback? onProfile;

  /// Null hides the duels icon entirely (offline / unconfigured builds).
  final VoidCallback? onChallenges;

  /// A single accent dot: your turn in a duel, or a friend request waiting.
  final bool challengeBadge;

  final String avatarName;

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
              ).textTheme.displayMedium!.copyWith(color: c.textWordmark),
            ),
          ),
          KalimatIconButton(
            icon: LucideIcons.chartColumn,
            label: S.stats,
            onPressed: onStats,
          ),
          if (onChallenges != null)
            _Dotted(
              show: challengeBadge,
              child: KalimatIconButton(
                icon: LucideIcons.swords,
                label: S.challenges,
                onPressed: onChallenges,
              ),
            ),
          const SizedBox(width: Metrics.s1),
          KalimatAvatar(
            name: avatarName,
            size: 34,
            onTap: onProfile,
            semanticLabel: S.profileTitle,
          ),
        ],
      ),
    );
  }
}

/// 7px accent dot pinned to the top-trailing corner of an icon button.
class _Dotted extends StatelessWidget {
  const _Dotted({required this.child, required this.show});

  final Widget child;
  final bool show;

  @override
  Widget build(BuildContext context) {
    final c = context.kalimatColors;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        // The dot scales+fades in when «دورك» arrives — once, no pulsing.
        PositionedDirectional(
          top: 6,
          end: 6,
          child: ExcludeSemantics(
            excluding: !show,
            child: Semantics(
              label: S.yourTurn,
              child: AnimatedScale(
                scale: show ? 1 : 0,
                duration: context.motionDuration(Motion.fast),
                curve: Motion.easeOut,
                child: AnimatedOpacity(
                  opacity: show ? 1 : 0,
                  duration: context.motionDuration(Motion.fast),
                  curve: Motion.easeOut,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: c.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.surfaceCard, width: 1.5),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
