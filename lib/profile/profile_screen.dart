/// «حسابي» — identity, lifetime stats, distribution, preferences, sign out.
/// Reached only via the header avatar; board state survives the round trip
/// because it lives in providers.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../backend/backend_providers.dart';
import '../backend/supabase_config.dart';
import '../core/strings.dart';
import '../core/theme/kalimat_colors.dart';
import '../core/theme/kalimat_theme.dart';
import '../core/theme/metrics.dart';
import '../core/utils/arabic_digits.dart';
import '../flow/flow_controller.dart';
import '../game/engine/models.dart';
import '../game/engine/share_grid.dart';
import '../game/state/game_controller.dart';
import '../game/state/settings_controller.dart';
import '../game/state/stats_controller.dart';
import '../game/widgets/distribution_bar.dart';
import '../game/widgets/kalimat_avatar.dart';
import '../game/widgets/kalimat_button.dart';
import '../game/widgets/kalimat_list_row.dart';
import '../game/widgets/kalimat_switch.dart';
import '../game/widgets/stat_card.dart';
import '../notifications/notification_service.dart';
import '../notifications/reminder_controller.dart';
import 'edit_name_dialog.dart';
import 'reminder_dialog.dart';
import 'save_progress_section.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await ref.read(flowProvider.notifier).signOut();
    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.kalimatColors;
    final name = ref.watch(displayNameProvider);
    final user = ref.watch(authUserProvider).value;
    final linked = user != null && !user.isAnonymous;
    final stats = ref.watch(statsProvider);
    final game = ref.watch(gameProvider);
    final settings = ref.watch(settingsProvider);
    final settingsController = ref.read(settingsProvider.notifier);
    final reminder = ref.watch(reminderProvider);
    final maxDist = stats.dist.fold(1, (a, b) => a > b ? a : b);
    final won = game.status == GameStatus.won;

    return Scaffold(
      backgroundColor: c.surfacePage,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Metrics.appMaxWidth),
            child: Column(
              children: [
                _Header(onBack: () => Navigator.of(context).pop()),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Metrics.gutter,
                      vertical: Metrics.s6,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Identity(
                          name: name,
                          email: linked ? user.email : null,
                          streak: stats.streak,
                          onEditName: () => showEditNameDialog(context),
                        ),
                        const SizedBox(height: Metrics.s6),
                        _Section(
                          label: S.stats,
                          child: Row(
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
                        ),
                        const SizedBox(height: Metrics.s6),
                        _Section(
                          label: S.distributionTitle,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var i = 0; i < 6; i++)
                                Padding(
                                  padding: EdgeInsets.only(
                                    bottom: i < 5 ? 6 : 0,
                                  ),
                                  child: DistributionBar(
                                    guess: i + 1,
                                    count: stats.dist[i],
                                    max: maxDist,
                                    highlight:
                                        won && game.guesses.length == i + 1,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: Metrics.s6),
                        _Section(
                          label: S.preferences,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              KalimatSwitch(
                                label: S.settingDark,
                                hint: S.settingDarkHint,
                                checked: settings.dark,
                                onChanged: settingsController.setDark,
                              ),
                              KalimatSwitch(
                                label: S.settingHints,
                                hint: S.settingHintsHint,
                                checked: settings.hints,
                                onChanged: settingsController.setHints,
                              ),
                              KalimatSwitch(
                                label: S.settingMotion,
                                checked: settings.motion,
                                onChanged: settingsController.setMotion,
                              ),
                              if (NotificationService.supported)
                                KalimatListRow(
                                  icon: LucideIcons.bell,
                                  label: S.dailyReminder,
                                  value: reminder.enabled
                                      ? formatReminderTime(reminder)
                                      : S.reminderOff,
                                  onTap: () => showReminderDialog(context),
                                ),
                              KalimatListRow(
                                icon: LucideIcons.share2,
                                label: S.shareLastResult,
                                divider: linked,
                                onTap: game.finished
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
                              if (linked)
                                KalimatListRow(
                                  icon: LucideIcons.logOut,
                                  label: S.signOut,
                                  danger: true,
                                  divider: false,
                                  onTap: () => _signOut(context, ref),
                                ),
                            ],
                          ),
                        ),
                        if (isSupabaseConfigured && !linked) ...[
                          const SizedBox(height: Metrics.s6),
                          _Section(
                            label: S.accountSection,
                            child: const SaveProgressSection(),
                          ),
                        ],
                        const SizedBox(height: Metrics.s6),
                        Text(
                          _footerLine(user, linked),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: kFontUi,
                            fontSize: TypeScale.xs2,
                            color: c.textSubtle,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: Metrics.s6),
                        KalimatButton(
                          label: S.backToGame,
                          variant: KalimatButtonVariant.secondary,
                          block: true,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _footerLine(dynamic user, bool linked) {
    final version = '${S.versionPrefix}${S.versionValue}';
    if (linked) {
      final created = DateTime.tryParse(user.createdAt as String? ?? '');
      if (created != null) {
        final since =
            '${S.months[created.month - 1]} ${toArabicDigits('${created.year}')}';
        return '${S.memberSincePrefix}$since · $version';
      }
    }
    return version;
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

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
            icon: LucideIcons.arrowRight,
            label: S.back,
            onPressed: onBack,
          ),
          Expanded(
            child: Text(
              S.profileTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: kFontDisplay,
                fontSize: TypeScale.md,
                fontWeight: FontWeight.w700,
                color: c.textBody,
                letterSpacing: 0,
              ),
            ),
          ),
          // Optical balance for the leading 40px icon button.
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({
    required this.name,
    required this.email,
    required this.streak,
    required this.onEditName,
  });

  final String name;
  final String? email;
  final int streak;
  final VoidCallback onEditName;

  @override
  Widget build(BuildContext context) {
    final c = context.kalimatColors;
    return Row(
      children: [
        KalimatAvatar(name: name, size: 64),
        const SizedBox(width: Metrics.s4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                button: true,
                label: S.editName,
                child: GestureDetector(
                  onTap: onEditName,
                  child: Text(
                    name,
                    style: TextStyle(
                      fontFamily: kFontDisplay,
                      fontSize: TypeScale.xl,
                      fontWeight: FontWeight.w700,
                      color: c.textBody,
                      letterSpacing: 0,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
              if (email != null && email!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  email!,
                  style: TextStyle(
                    fontFamily: kFontUi,
                    fontSize: TypeScale.xs,
                    color: c.textSubtle,
                    letterSpacing: 0,
                  ),
                ),
              ],
              const SizedBox(height: Metrics.s2),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: c.accentSoft,
                    borderRadius: BorderRadius.circular(Metrics.rPill),
                  ),
                  child: Text(
                    '${S.streakBadgePrefix}${toArabicDigits('$streak')}',
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
            ],
          ),
        ),
      ],
    );
  }
}

/// Section pattern: 11px subtle label above a bordered surface-card.
class _Section extends StatelessWidget {
  const _Section({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.kalimatColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: Metrics.s2),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: kFontUi,
              fontSize: TypeScale.xs2,
              fontWeight: FontWeight.w600,
              color: c.textSubtle,
              letterSpacing: 0,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Metrics.s4),
          decoration: BoxDecoration(
            color: c.surfaceCard,
            border: Border.all(color: c.lineSoft),
            borderRadius: BorderRadius.circular(Metrics.rCard),
            boxShadow: c.shadowSm,
          ),
          child: child,
        ),
      ],
    );
  }
}
