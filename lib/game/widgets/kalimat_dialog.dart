/// Dialog chrome: brown overlay wash + 2px blur, centered card (12px radius,
/// warm shadow-lg), rise-and-fade transition, title + close.
library;

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/strings.dart';
import '../../core/theme/kalimat_colors.dart';
import '../../core/theme/metrics.dart';
import '../../core/theme/motion.dart';
import 'kalimat_button.dart';

Future<T?> showKalimatDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  final colors = context.kalimatColors;
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: S.close,
    barrierColor: colors.surfaceOverlay,
    transitionDuration: Motion.base,
    pageBuilder: (context, _, _) => builder(context),
    transitionBuilder: (context, animation, _, child) {
      final t = CurvedAnimation(parent: animation, curve: Motion.easeOut);
      return BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 2 * animation.value,
          sigmaY: 2 * animation.value,
        ),
        child: FadeTransition(
          opacity: t,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, .02),
              end: Offset.zero,
            ).animate(t),
            child: child,
          ),
        ),
      );
    },
  );
}

class KalimatDialogCard extends StatelessWidget {
  const KalimatDialogCard({
    super.key,
    required this.title,
    required this.child,
    this.footer,
  });

  final String title;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final c = context.kalimatColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Metrics.s4),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(Metrics.s6),
              decoration: BoxDecoration(
                color: c.surfaceCard,
                borderRadius: BorderRadius.circular(Metrics.rCard),
                border: Border.all(color: c.lineSoft),
                boxShadow: c.shadowLg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      KalimatIconButton(
                        icon: LucideIcons.x,
                        label: S.close,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: Metrics.s4),
                  Flexible(child: SingleChildScrollView(child: child)),
                  if (footer != null) ...[
                    const SizedBox(height: Metrics.s6),
                    footer!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
