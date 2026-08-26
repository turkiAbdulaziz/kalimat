/// Onboarding page shell: centred 500px column, 40/16/32 padding, 32px gaps,
/// with the bottom block pinned to the screen bottom. Scrolls only when it
/// must (small screens, keyboard open).
library;

import 'package:flutter/material.dart';

import '../core/theme/kalimat_colors.dart';
import '../core/theme/metrics.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({super.key, required this.bottom, required this.children});

  /// Pinned to the bottom of the screen (legal line / action buttons).
  final Widget bottom;

  /// Main blocks, separated by 32px gaps.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.kalimatColors;
    return Scaffold(
      backgroundColor: c.surfacePage,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Metrics.appMaxWidth),
            child: LayoutBuilder(
              builder: (context, viewport) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: viewport.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Metrics.gutter,
                      Metrics.s10,
                      Metrics.gutter,
                      Metrics.s8,
                    ),
                    child: Column(
                      // All slack lands between the content and the bottom
                      // block, pinning the latter to the screen bottom.
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final child in children) ...[
                              child,
                              const SizedBox(height: Metrics.s8),
                            ],
                          ],
                        ),
                        bottom,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
