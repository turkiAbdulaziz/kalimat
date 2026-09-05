/// «حذف الحساب» asks first — the same confirm shape as removing a friend —
/// and the body spells out what goes (server account, results, friends,
/// duels, this device's stats) and that it cannot be undone.
library;

import 'package:flutter/material.dart';

import '../core/strings.dart';
import '../core/theme/metrics.dart';
import '../game/widgets/kalimat_button.dart';
import '../game/widgets/kalimat_dialog.dart';

Future<bool?> showDeleteAccountDialog(BuildContext context) =>
    showKalimatDialog<bool>(
      context: context,
      builder: (context) => KalimatDialogCard(
        title: S.deleteAccountTitle,
        footer: Row(
          children: [
            Expanded(
              child: KalimatButton(
                label: S.deleteConfirm,
                block: true,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ),
            const SizedBox(width: Metrics.s2),
            Expanded(
              child: KalimatButton(
                label: S.cancel,
                variant: KalimatButtonVariant.secondary,
                block: true,
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ),
          ],
        ),
        child: Text(
          S.deleteAccountBody,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
