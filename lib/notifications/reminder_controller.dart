/// «التنبيه اليومي» state: enabled + time, persisted to LocalStore, with the
/// actual (re)scheduling side effects.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/data/local_store.dart';
import '../game/state/settings_controller.dart';
import 'notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

final reminderProvider = NotifierProvider<ReminderController, ReminderSettings>(
  ReminderController.new,
);

class ReminderController extends Notifier<ReminderSettings> {
  @override
  ReminderSettings build() => ref.read(localStoreProvider).reminder;

  /// Returns false when the user denied the notification permission (the
  /// reminder stays off).
  Future<bool> setEnabled(bool enabled) async {
    final service = ref.read(notificationServiceProvider);
    if (enabled) {
      if (!await service.requestPermission()) {
        await _update(state.copyWith(enabled: false));
        return false;
      }
      await service.scheduleDaily(hour: state.hour, minute: state.minute);
    } else {
      await service.cancelDaily();
    }
    await _update(state.copyWith(enabled: enabled));
    return true;
  }

  Future<void> setTime(int hour, int minute) async {
    await _update(state.copyWith(hour: hour, minute: minute));
    if (state.enabled) {
      await ref
          .read(notificationServiceProvider)
          .scheduleDaily(hour: hour, minute: minute);
    }
  }

  Future<void> _update(ReminderSettings next) async {
    state = next;
    await ref.read(localStoreProvider).setReminder(next);
  }
}
