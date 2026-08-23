/// «الإعدادات» — dark mode, keyboard hints, tile motion.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../backend/supabase_config.dart';
import '../../core/strings.dart';
import '../../core/theme/kalimat_colors.dart';
import '../../core/theme/kalimat_theme.dart';
import '../../core/theme/metrics.dart';
import '../../core/utils/arabic_digits.dart';
import '../state/game_controller.dart';
import '../state/settings_controller.dart';
import '../widgets/kalimat_dialog.dart';
import '../widgets/kalimat_switch.dart';
import 'account_section.dart';

Future<void> showSettingsDialog(BuildContext context) => showKalimatDialog(
  context: context,
  builder: (context) => const _SettingsDialog(),
);

class _SettingsDialog extends ConsumerWidget {
  const _SettingsDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.kalimatColors;
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final puzzleNo = ref.watch(gameProvider).word.puzzleNo;

    return KalimatDialogCard(
      title: S.settings,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KalimatSwitch(
            label: S.settingDark,
            hint: S.settingDarkHint,
            checked: settings.dark,
            onChanged: controller.setDark,
          ),
          KalimatSwitch(
            label: S.settingHints,
            hint: S.settingHintsHint,
            checked: settings.hints,
            onChanged: controller.setHints,
          ),
          KalimatSwitch(
            label: S.settingMotion,
            checked: settings.motion,
            onChanged: controller.setMotion,
          ),
          if (isSupabaseConfigured) const AccountSection(),
          Padding(
            padding: const EdgeInsets.only(top: Metrics.s4),
            child: Text(
              'كلمات ${toArabicDigits('$puzzleNo')} · نسخة ١٫٠',
              style: TextStyle(
                fontFamily: kFontUi,
                fontSize: TypeScale.xs2,
                color: c.textSubtle,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
