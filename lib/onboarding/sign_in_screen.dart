/// Screen 1 — sign in: wordmark, one-line pitch, flip-in sample row,
/// Google / Apple / guest, legal line. Adapted from the designed email flow
/// to the shipped Google/Apple auth (per product decision).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../backend/auth_repository.dart';
import '../backend/backend_providers.dart';
import '../core/strings.dart';
import '../core/theme/kalimat_colors.dart';
import '../core/theme/kalimat_theme.dart';
import '../core/theme/metrics.dart';
import '../core/theme/motion.dart';
import '../core/theme/motion_scope.dart';
import '../game/state/settings_controller.dart';
import '../game/widgets/kalimat_button.dart';
import '../game/widgets/kalimat_spinner.dart';
import '../game/widgets/sample_tile_row.dart';
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
    final dark = Theme.brightnessOf(context) == Brightness.dark;

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
              SampleTileRow(animate: motion),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Google renders only once its web client ID is configured
            // (kGoogleSignInAvailable); until then Apple takes the primary
            // slot so the screen still has one clear call to action.
            if (kGoogleSignInAvailable) ...[
              KalimatButton(
                label: S.continueWithGoogle,
                large: true,
                block: true,
                disabled: _busy,
                onPressed: () =>
                    _start(ref.read(authRepositoryProvider).linkGoogle),
              ),
              const SizedBox(height: Metrics.s2),
            ],
            Directionality(
              textDirection: TextDirection.ltr,
              child: SignInWithAppleButton(
                onPressed: _busy
                    ? null
                    : () => _start(ref.read(authRepositoryProvider).linkApple),
                text: S.continueWithAppleOfficial,
                height: 52,
                style: dark
                    ? SignInWithAppleButtonStyle.white
                    : SignInWithAppleButtonStyle.black,
                borderRadius: const BorderRadius.all(
                  Radius.circular(Metrics.rPill),
                ),
                iconAlignment: SignInWithAppleIconAlignment.left,
              ),
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
            const SizedBox(height: Metrics.s1),
            Text(
              S.continueAsGuestEnglish,
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontFamily: kFontUi,
                fontSize: TypeScale.xs2,
                fontWeight: FontWeight.w400,
                color: c.textSubtle,
                letterSpacing: 0,
                height: 1.2,
              ),
            ),
            const SizedBox(height: Metrics.s2),
            SizedBox(
              height: Metrics.s4,
              child: Center(
                // Busy shows a real spinner; an error fades in instead of
                // snapping into the fixed-height slot.
                child: AnimatedSwitcher(
                  duration: context.motionDuration(Motion.fast),
                  switchInCurve: Motion.easeOut,
                  switchOutCurve: Motion.easeOut,
                  child: _busy
                      ? const KalimatSpinner(size: 14)
                      : Text(
                          _error ?? '',
                          key: ValueKey(_error),
                          style: TextStyle(
                            fontFamily: kFontUi,
                            fontSize: TypeScale.xs2,
                            color: c.textDanger,
                            letterSpacing: 0,
                          ),
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
