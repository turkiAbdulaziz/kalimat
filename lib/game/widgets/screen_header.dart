/// The pushed-screen header: back arrow, centred title, 56px tall — the
/// counterpart to AppHeader on «حسابي» and «التحدّيات».
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/strings.dart';
import '../../core/theme/kalimat_colors.dart';
import '../../core/theme/kalimat_theme.dart';
import '../../core/theme/metrics.dart';
import 'kalimat_button.dart';

class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final c = context.kalimatColors;
    return Container(
      height: Metrics.headerHeight,
      padding: const EdgeInsets.symmetric(horizontal: Metrics.s3),
      decoration: BoxDecoration(
        color: c.surfaceCard,
        border: Border(bottom: BorderSide(color: c.lineSoft)),
      ),
      child: Row(
        children: [
          KalimatIconButton(
            icon: LucideIcons.arrowRight,
            label: S.back,
            onPressed: onBack,
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: kFontDisplay,
                fontSize: TypeScale.md,
                fontWeight: FontWeight.w700,
                color: c.textBody,
                letterSpacing: 0,
              ),
            ),
          ),
          // Optical balance for the leading 40px icon button.
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}
