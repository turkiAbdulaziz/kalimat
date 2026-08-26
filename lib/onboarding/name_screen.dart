/// Screen 3 — display name: «ما اسمك؟», one input, start / skip.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/strings.dart';
import '../core/theme/kalimat_colors.dart';
import '../core/theme/kalimat_theme.dart';
import '../core/theme/metrics.dart';
import '../flow/flow_controller.dart';
import '../game/widgets/kalimat_button.dart';
import '../game/widgets/kalimat_input.dart';
import '../game/widgets/wordmark.dart';
import 'auth_shell.dart';

class NameScreen extends ConsumerStatefulWidget {
  const NameScreen({super.key});

  @override
  ConsumerState<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends ConsumerState<NameScreen> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.kalimatColors;
    final flow = ref.read(flowProvider.notifier);
    final ready = _name.text.trim().length >= 2;

    return AuthShell(
      bottom: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KalimatButton(
            label: S.startPlaying,
            large: true,
            block: true,
            disabled: !ready,
            onPressed: () => flow.completeName(_name.text),
          ),
          const SizedBox(height: Metrics.s2),
          KalimatButton(
            label: S.skip,
            variant: KalimatButtonVariant.ghost,
            block: true,
            onPressed: flow.skipName,
          ),
        ],
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: Metrics.s2),
          child: Column(
            children: [
              const Wordmark(size: TypeScale.xl2),
              const SizedBox(height: Metrics.s3),
              Text(
                S.nameTitle,
                style: TextStyle(
                  fontFamily: kFontDisplay,
                  fontSize: TypeScale.xl,
                  fontWeight: FontWeight.w700,
                  color: c.textBody,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: Metrics.s3),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Text(
                  S.nameExplainer,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: kFontUi,
                    fontSize: TypeScale.sm,
                    color: c.textMuted,
                    letterSpacing: 0,
                    height: 1.75,
                  ),
                ),
              ),
            ],
          ),
        ),
        KalimatInput(
          label: S.nameFieldLabel,
          placeholder: S.namePlaceholder,
          controller: _name,
          maxLength: 20,
          onChanged: (_) => setState(() {}),
          onSubmitted: (v) => flow.completeName(v),
        ),
      ],
    );
  }
}
