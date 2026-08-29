/// «إضافة صديق» — type a friend's ٦-digit code. The tiles are the board's
/// own, and the server answers with what it did (sent / already friends /
/// no such code), which becomes the inline line under the field.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../backend/backend_providers.dart';
import '../core/strings.dart';
import '../core/theme/kalimat_colors.dart';
import '../core/theme/kalimat_theme.dart';
import '../core/theme/metrics.dart';
import '../game/widgets/code_field.dart';
import '../game/widgets/kalimat_button.dart';
import '../game/widgets/kalimat_dialog.dart';
import 'models.dart';

/// Resolves true when a request was sent or a friendship was formed.
Future<bool?> showAddFriendDialog(BuildContext context) =>
    showKalimatDialog<bool>(
      context: context,
      builder: (context) => const _AddFriendDialog(),
    );

class _AddFriendDialog extends ConsumerStatefulWidget {
  const _AddFriendDialog();

  @override
  ConsumerState<_AddFriendDialog> createState() => _AddFriendDialogState();
}

class _AddFriendDialogState extends ConsumerState<_AddFriendDialog> {
  String _code = '';
  String? _note;
  bool _busy = false;

  Future<void> _submit() async {
    if (_code.length != kFriendCodeLength || _busy) return;
    setState(() {
      _busy = true;
      _note = null;
    });
    final result = await ref.read(friendsRepositoryProvider).sendRequest(_code);
    if (!mounted) return;

    switch (result) {
      case AddFriendResult.sent:
      case AddFriendResult.pending:
        Navigator.of(context).pop(true);
      case AddFriendResult.accepted:
        Navigator.of(context).pop(true);
      case AddFriendResult.alreadyFriends:
        setState(() {
          _busy = false;
          _note = S.alreadyFriends;
        });
      case AddFriendResult.notFound:
      case AddFriendResult.self:
        setState(() {
          _busy = false;
          _note = S.codeNotFound;
        });
      case AddFriendResult.rateLimited:
      case AddFriendResult.failed:
        setState(() {
          _busy = false;
          _note = S.friendActionFailed;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.kalimatColors;
    return KalimatDialogCard(
      title: S.addFriend,
      footer: KalimatButton(
        label: S.addFriend,
        block: true,
        disabled: _busy || _code.length != kFriendCodeLength,
        onPressed: _submit,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            S.friendCodeLabel,
            style: TextStyle(
              fontFamily: kFontUi,
              fontSize: TypeScale.xs2,
              color: c.textSubtle,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: Metrics.s3),
          CodeField(
            onChanged: (v) => setState(() => _code = v),
            onSubmitted: (_) => _submit(),
          ),
          if (_note != null)
            Padding(
              padding: const EdgeInsets.only(top: Metrics.s3),
              child: Text(
                _note!,
                style: TextStyle(
                  fontFamily: kFontUi,
                  fontSize: TypeScale.xs2,
                  color: c.textDanger,
                  letterSpacing: 0,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
