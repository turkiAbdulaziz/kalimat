/// «التنبيه اليومي» dialog: enable switch + ١٢-hour time steppers + ص/م.
/// Stays in the Kalimat idiom — no Material time picker.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/strings.dart';
import '../core/theme/kalimat_colors.dart';
import '../core/theme/kalimat_theme.dart';
import '../core/theme/metrics.dart';
import '../core/theme/motion.dart';
import '../core/theme/motion_scope.dart';
import '../core/utils/arabic_digits.dart';
import '../game/data/local_store.dart';
import '../game/widgets/kalimat_button.dart';
import '../game/widgets/kalimat_dialog.dart';
import '../game/widgets/kalimat_switch.dart';
import '../game/widgets/segment_toggle.dart';
import '../notifications/reminder_controller.dart';

/// «٩:٠٠ ص» — the profile row's trailing value.
String formatReminderTime(ReminderSettings r) {
  final hour12 = r.hour % 12 == 0 ? 12 : r.hour % 12;
  final minutes = '${r.minute}'.padLeft(2, '0');
  final period = r.hour >= 12 ? S.pm : S.am;
  return '${toArabicDigits('$hour12:$minutes')} $period';
}

Future<void> showReminderDialog(BuildContext context) => showKalimatDialog(
  context: context,
  builder: (context) => const _ReminderDialog(),
);

class _ReminderDialog extends ConsumerStatefulWidget {
  const _ReminderDialog();

  @override
  ConsumerState<_ReminderDialog> createState() => _ReminderDialogState();
}

class _ReminderDialogState extends ConsumerState<_ReminderDialog> {
  late bool _enabled;
  late int _hour12; // ١–١٢
  late bool _pm;
  late int _minute;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final r = ref.read(reminderProvider);
    _enabled = r.enabled;
    _hour12 = r.hour % 12 == 0 ? 12 : r.hour % 12;
    _pm = r.hour >= 12;
    _minute = r.minute;
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final controller = ref.read(reminderProvider.notifier);
    final hour24 = (_hour12 % 12) + (_pm ? 12 : 0);
    await controller.setTime(hour24, _minute);
    await controller.setEnabled(_enabled);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return KalimatDialogCard(
      title: S.dailyReminder,
      footer: Row(
        children: [
          Expanded(
            child: KalimatButton(
              label: S.save,
              block: true,
              disabled: _busy,
              onPressed: _save,
            ),
          ),
          const SizedBox(width: Metrics.s2),
          Expanded(
            child: KalimatButton(
              label: S.cancel,
              variant: KalimatButtonVariant.secondary,
              block: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KalimatSwitch(
            label: S.reminderEnable,
            checked: _enabled,
            onChanged: (v) => setState(() => _enabled = v),
          ),
          const SizedBox(height: Metrics.s4),
          AnimatedOpacity(
            opacity: _enabled ? 1 : .45,
            duration: Motion.fast,
            curve: Motion.easeOut,
            child: IgnorePointer(
              ignoring: !_enabled,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Stepper(
                    value: toArabicDigits('$_hour12'),
                    onUp: () => setState(
                      () => _hour12 = _hour12 == 12 ? 1 : _hour12 + 1,
                    ),
                    onDown: () => setState(
                      () => _hour12 = _hour12 == 1 ? 12 : _hour12 - 1,
                    ),
                  ),
                  const _Colon(),
                  _Stepper(
                    value: toArabicDigits('$_minute'.padLeft(2, '0')),
                    onUp: () => setState(() => _minute = (_minute + 5) % 60),
                    onDown: () => setState(() => _minute = (_minute + 55) % 60),
                  ),
                  const SizedBox(width: Metrics.s4),
                  SegmentToggle(
                    options: const [S.am, S.pm],
                    selected: _pm ? 1 : 0,
                    onChanged: (i) => setState(() => _pm = i == 1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.onUp,
    required this.onDown,
  });

  final String value;
  final VoidCallback onUp;
  final VoidCallback onDown;

  @override
  Widget build(BuildContext context) {
    final c = context.kalimatColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        KalimatIconButton(
          icon: LucideIcons.chevronUp,
          label: S.increase,
          onPressed: onUp,
        ),
        // Digits roll via a mini rise on change instead of snapping.
        AnimatedSwitcher(
          duration: context.motionDuration(Motion.fast),
          switchInCurve: Motion.easeOut,
          switchOutCurve: Motion.easeOut,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, .25),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: Text(
            value,
            key: ValueKey(value),
            style: TextStyle(
              fontFamily: kFontDisplay,
              fontSize: TypeScale.xl,
              fontWeight: FontWeight.w700,
              color: c.textBody,
              letterSpacing: 0,
              height: 1,
            ),
          ),
        ),
        KalimatIconButton(
          icon: LucideIcons.chevronDown,
          label: S.decrease,
          onPressed: onDown,
        ),
      ],
    );
  }
}

class _Colon extends StatelessWidget {
  const _Colon();

  @override
  Widget build(BuildContext context) {
    final c = context.kalimatColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Metrics.s2),
      child: Text(
        ':',
        style: TextStyle(
          fontFamily: kFontDisplay,
          fontSize: TypeScale.xl,
          fontWeight: FontWeight.w700,
          color: c.textMuted,
          letterSpacing: 0,
          height: 1,
        ),
      ),
    );
  }
}
