/// «حفظ التقدم» — account linking + display name (design extension,
/// shown in settings only when Supabase is configured).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../backend/auth_repository.dart';
import '../../backend/backend_providers.dart';
import '../../core/strings.dart';
import '../../core/theme/kalimat_colors.dart';
import '../../core/theme/kalimat_theme.dart';
import '../../core/theme/metrics.dart';
import '../widgets/kalimat_button.dart';
import '../widgets/kalimat_dialog.dart';

class AccountSection extends ConsumerStatefulWidget {
  const AccountSection({super.key});

  @override
  ConsumerState<AccountSection> createState() => _AccountSectionState();
}

class _AccountSectionState extends ConsumerState<AccountSection> {
  bool _busy = false;
  String? _note;
  final TextEditingController _name = TextEditingController();
  bool _nameLoaded = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

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

  Future<void> _saveName() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    setState(() => _busy = true);
    await ref.read(authRepositoryProvider).updateDisplayName(name);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.kalimatColors;
    final auth = ref.read(authRepositoryProvider);
    final user = ref.watch(authUserProvider).value;
    final linked = user != null && !(user.isAnonymous);

    if (linked && !_nameLoaded) {
      _nameLoaded = true;
      auth.fetchDisplayName().then((n) {
        if (mounted && n != null && _name.text.isEmpty) _name.text = n;
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: Metrics.s4, bottom: 2),
          child: Text(
            S.accountSection,
            style: TextStyle(
              fontFamily: kFontUi,
              fontSize: TypeScale.sm,
              fontWeight: FontWeight.w500,
              color: c.textBody,
              letterSpacing: 0,
            ),
          ),
        ),
        Text(
          linked ? S.accountLinked : S.accountHint,
          style: TextStyle(
            fontFamily: kFontUi,
            fontSize: TypeScale.xs2,
            color: c.textSubtle,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: Metrics.s3),
        if (!linked) ...[
          KalimatButton(
            label: S.continueWithGoogle,
            variant: KalimatButtonVariant.secondary,
            block: true,
            disabled: _busy,
            onPressed: () => _link(auth.linkGoogle),
          ),
          const SizedBox(height: Metrics.s2),
          KalimatButton(
            label: S.continueWithApple,
            variant: KalimatButtonVariant.secondary,
            block: true,
            disabled: _busy,
            onPressed: () => _link(auth.linkApple),
          ),
        ] else ...[
          Text(
            S.displayNameLabel,
            style: TextStyle(
              fontFamily: kFontUi,
              fontSize: TypeScale.xs2,
              color: c.textSubtle,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: Metrics.s1),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _name,
                  maxLength: 20,
                  style: TextStyle(
                    fontFamily: kFontUi,
                    fontSize: TypeScale.sm,
                    color: c.textBody,
                    letterSpacing: 0,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Metrics.rKey),
                      borderSide: BorderSide(color: c.line),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Metrics.rKey),
                      borderSide: BorderSide(color: c.accent),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Metrics.s2),
              KalimatButton(
                label: S.save,
                disabled: _busy,
                onPressed: _saveName,
              ),
            ],
          ),
        ],
        if (_note != null)
          Padding(
            padding: const EdgeInsets.only(top: Metrics.s2),
            child: Text(
              _note!,
              style: TextStyle(
                fontFamily: kFontUi,
                fontSize: TypeScale.xs2,
                color: c.textSubtle,
                letterSpacing: 0,
              ),
            ),
          ),
      ],
    );
  }
}
