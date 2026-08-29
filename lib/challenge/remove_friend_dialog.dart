/// Removing a friend is destructive and one tap away, so it asks first —
/// the same confirm shape as «حساب محفوظ موجود» in «حفظ التقدم».
library;

import 'package:flutter/material.dart';

import '../core/strings.dart';
import '../core/theme/metrics.dart';
import '../game/widgets/kalimat_button.dart';
import '../game/widgets/kalimat_dialog.dart';

Future<bool?> showRemoveFriendDialog(BuildContext context, String name) =>
    showKalimatDialog<bool>(
      context: context,
      builder: (context) => KalimatDialogCard(
        title: S.removeFriendTitle,
        footer: Row(
          children: [
            Expanded(
              child: KalimatButton(
                label: S.remove,
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
          '${S.removeFriendPrefix}$name${S.removeFriendSuffix}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
