/// Swaps the home surface on the flow step with the house kalimat-rise
/// transition: the incoming screen fades in and rises 8px (Motion.base,
/// Motion.easeOut) while the outgoing screen fades in place. Instant when
/// «حركة المربعات» is off. The very first screen never animates
/// (AnimatedSwitcher shows its initial child without a transition).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/rise_route.dart';
import '../core/theme/motion.dart';
import '../game/game_screen.dart';
import '../game/state/settings_controller.dart';
import '../onboarding/name_screen.dart';
import '../onboarding/sign_in_screen.dart';
import 'flow_controller.dart';

class RootFlow extends ConsumerWidget {
  const RootFlow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = ref.watch(flowProvider);
    final motion = ref.watch(settingsProvider.select((s) => s.motion));
    final screen = switch (step) {
      FlowStep.signin => const SignInScreen(),
      FlowStep.name => const NameScreen(),
      FlowStep.game => const GameScreen(),
    };
    // The screens share the page background; painting it behind the
    // cross-fade keeps the window color from bleeding through mid-switch.
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: AnimatedSwitcher(
        duration: motion ? Motion.base : Duration.zero,
        switchInCurve: Motion.easeOut,
        switchOutCurve: Motion.easeOut,
        transitionBuilder: (child, animation) =>
            kalimatRise(animation, child, sinkOnExit: false),
        layoutBuilder: (current, previous) => Stack(
          fit: StackFit.expand,
          children: [...previous, ?current],
        ),
        child: KeyedSubtree(key: ValueKey(step), child: screen),
      ),
    );
  }
}
