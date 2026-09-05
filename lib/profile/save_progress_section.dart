/// «حفظ التقدم» — links Google/Apple onto the anonymous user, shown on the
/// profile only while unlinked (and Supabase is configured). Here real
/// device progress exists, so "already linked elsewhere" asks first.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../backend/auth_repository.dart';
import '../backend/backend_providers.dart';
import '../core/strings.dart';
import '../core/theme/kalimat_colors.dart';
import '../core/theme/kalimat_theme.dart';
import '../core/theme/metrics.dart';
import '../flow/flow_controller.dart';
import '../game/widgets/kalimat_button.dart';
import '../game/widgets/kalimat_dialog.dart';

class SaveProgressSection extends ConsumerStatefulWidget {
  const SaveProgressSection({super.key});

  @override
  ConsumerState<SaveProgressSection> createState() =>
      _SaveProgressSectionState();
}

class _SaveProgressSectionState extends ConsumerState<SaveProgressSection> {
  bool _busy = false;
  String? _note;

  Future<void> _link(Future<LinkOutcome> Function() action) async {
    setState(() {
      _busy = true;
      _note = null;
    });
    var outcome = await action();

    if (outcome == LinkOutcome.alreadyLinkedElsewhere && mounted) {
      final approved = await _confirmSwitch();
      if (approved == true) {
        final ok = await ref.read(authRepositoryProvider).confirmSwitch();
        outcome = ok ? LinkOutcome.switchedAccount : LinkOutcome.failed;
      } else {
        outcome = LinkOutcome.cancelled;
      }
    }

    // Keep the cached display name in sync with the account we ended up on.
    final auth = ref.read(authRepositoryProvider);
    final names = ref.read(displayNameProvider.notifier);
    try {
      switch (outcome) {
        case LinkOutcome.linked:
          final local = ref.read(displayNameProvider);
          if (local != S.guestName) {
            await auth.updateDisplayName(local);
          } else {
            final server = await auth.fetchDisplayName();
            if (server != null && server.trim().isNotEmpty) {
              await names.set(server);
            }
          }
        case LinkOutcome.switchedAccount:
          final server = await auth.fetchDisplayName();
          if (server != null && server.trim().isNotEmpty) {
            await names.set(server);
          }
        case _:
          break;
      }
    } catch (_) {
      // Name sync is best-effort.
    }

    if (!mounted) return;
    setState(() {
      _busy = false;
      _note = switch (outcome) {
        LinkOutcome.failed => S.linkFailed,
        _ => null,
      };
    });
  }

  Future<bool?> _confirmSwitch() => showKalimatDialog<bool>(
    context: context,
    builder: (context) => KalimatDialogCard(
      title: S.switchAccountTitle,
      footer: Row(
        children: [
          Expanded(
            child: KalimatButton(
              label: S.switchConfirm,
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
        S.switchAccountBody,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final c = context.kalimatColors;
    final auth = ref.read(authRepositoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          S.accountHint,
          style: TextStyle(
            fontFamily: kFontUi,
            fontSize: TypeScale.xs2,
            color: c.textSubtle,
            letterSpacing: 0,
            height: 1.5,
          ),
        ),
        const SizedBox(height: Metrics.s3),
        if (kGoogleSignInAvailable) ...[
          KalimatButton(
            label: S.continueWithGoogle,
            variant: KalimatButtonVariant.secondary,
            block: true,
            disabled: _busy,
            onPressed: () => _link(auth.linkGoogle),
          ),
          const SizedBox(height: Metrics.s2),
        ],
        KalimatButton(
          label: S.continueWithApple,
          variant: KalimatButtonVariant.secondary,
          block: true,
          disabled: _busy,
          onPressed: () => _link(auth.linkApple),
        ),
        if (_note != null)
          Padding(
            padding: const EdgeInsets.only(top: Metrics.s2),
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
    );
  }
}
