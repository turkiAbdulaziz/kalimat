/// «تعديل الاسم» — edits the cached display name (and the server profile
/// when the account is linked). Opened by tapping the name on the profile.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../backend/backend_providers.dart';
import '../core/strings.dart';
import '../core/theme/metrics.dart';
import '../flow/flow_controller.dart';
import '../game/widgets/kalimat_button.dart';
import '../game/widgets/kalimat_dialog.dart';
import '../game/widgets/kalimat_input.dart';

Future<void> showEditNameDialog(BuildContext context) => showKalimatDialog(
  context: context,
  builder: (context) => const _EditNameDialog(),
);

class _EditNameDialog extends ConsumerStatefulWidget {
  const _EditNameDialog();

  @override
  ConsumerState<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends ConsumerState<_EditNameDialog> {
  late final TextEditingController _name = TextEditingController(
    text: ref.read(displayNameProvider),
  );
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.length < 2) return;
    setState(() => _busy = true);
    await ref.read(displayNameProvider.notifier).set(name);
    final auth = ref.read(authRepositoryProvider);
    if (!auth.isAnonymous) {
      try {
        await auth.updateDisplayName(name);
      } catch (_) {
        // Offline: the local cache still wins for the UI.
      }
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return KalimatDialogCard(
      title: S.editName,
      footer: Row(
        children: [
          Expanded(
            child: KalimatButton(
              label: S.save,
              block: true,
              disabled: _busy || _name.text.trim().length < 2,
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
      child: KalimatInput(
        label: S.nameFieldLabel,
        controller: _name,
        maxLength: 20,
        autofocus: true,
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _save(),
      ),
    );
  }
}
