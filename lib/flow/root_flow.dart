/// Swaps the home surface on the flow step. Screens change with a hard cut,
/// matching the prototype — rise/fade motion belongs to dialogs only.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/game_screen.dart';
import '../onboarding/name_screen.dart';
import '../onboarding/sign_in_screen.dart';
import 'flow_controller.dart';

class RootFlow extends ConsumerWidget {
  const RootFlow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = ref.watch(flowProvider);
    return switch (step) {
      FlowStep.signin => const SignInScreen(),
      FlowStep.name => const NameScreen(),
      FlowStep.game => const GameScreen(),
    };
  }
}
