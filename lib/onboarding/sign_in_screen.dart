/// Screen 1 — sign in: wordmark, one-line pitch, flip-in sample row,
/// Google / Apple / guest, legal line. Adapted from the designed email flow
/// to the shipped Google/Apple auth (per product decision).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../backend/auth_repository.dart';
import '../backend/backend_providers.dart';
import '../core/strings.dart';
import '../core/theme/kalimat_colors.dart';
import '../core/theme/kalimat_theme.dart';
import '../core/theme/metrics.dart';
import '../core/theme/motion.dart';
import '../game/engine/models.dart';
import '../game/state/settings_controller.dart';
import '../game/widgets/kalimat_button.dart';
import '../game/widgets/tile.dart';
import '../game/widgets/wordmark.dart';
import '../flow/flow_controller.dart';
import 'auth_shell.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _start(Future<LinkOutcome> Function() link) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await ref.read(flowProvider.notifier).signInWith(link);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.kalimatColors;
    final motion = ref.watch(settingsProvider.select((s) => s.motion));

    return AuthShell(
      bottom: Text(
        S.legalLine,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: kFontUi,
          fontSize: TypeScale.xs2,
          color: c.textSubtle,
          letterSpacing: 0,
          height: 1.75,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: Metrics.s8),
          child: Column(
            children: [
              const Wordmark(),
              const SizedBox(height: Metrics.s4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Text(
                  S.signInPitch,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: kFontUi,
                    fontSize: TypeScale.md,
                    color: c.textMuted,
                    letterSpacing: 0,
                    height: 1.75,
                  ),
                ),
              ),
              const SizedBox(height: Metrics.s4),
              _SampleRow(animate: motion),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KalimatButton(
              label: S.continueWithGoogle,
              large: true,
              block: true,
              disabled: _busy,
              onPressed: () =>
                  _start(ref.read(authRepositoryProvider).linkGoogle),
            ),
            const SizedBox(height: Metrics.s2),
            KalimatButton(
              label: S.continueWithApple,
              variant: KalimatButtonVariant.secondary,
              large: true,
              block: true,
              disabled: _busy,
              onPressed: () =>
                  _start(ref.read(authRepositoryProvider).linkApple),
            ),
            const SizedBox(height: Metrics.s2),
            KalimatButton(
              label: S.continueAsGuest,
              variant: KalimatButtonVariant.ghost,
              block: true,
              disabled: _busy,
              onPressed: () =>
                  ref.read(flowProvider.notifier).continueAsGuest(),
            ),
            const SizedBox(height: Metrics.s2),
            SizedBox(
              height: Metrics.s4,
              child: Center(
                child: Text(
                  _error ?? '',
                  style: TextStyle(
                    fontFamily: kFontUi,
                    fontSize: TypeScale.xs2,
                    color: c.textDanger,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The «كلمات» demo row: correct/correct/present/absent/correct, flipping in
/// with the usual 120ms stagger when motion is on.
class _SampleRow extends StatelessWidget {
  const _SampleRow({required this.animate});

  final bool animate;

  static const _cells = [
    ('ك', TileState.correct),
    ('ل', TileState.correct),
    ('م', TileState.present),
    ('ا', TileState.absent),
    ('ت', TileState.correct),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final (i, cell) in _cells.indexed) ...[
          if (i > 0) const SizedBox(width: Metrics.tileGap),
          Tile(
            letter: cell.$1,
            state: cell.$2,
            size: 44,
            reveal: animate,
            revealDelay: Motion.flipStagger * i,
          ),
        ],
      ],
    );
  }
}
