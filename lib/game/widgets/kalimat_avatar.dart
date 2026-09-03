/// Monogram avatar (components/core/Avatar.jsx): accent circle, first letter
/// of the display name in the display font. Monogram only — no photos.
library;

import 'package:flutter/material.dart';

import '../../core/theme/kalimat_colors.dart';
import '../../core/theme/kalimat_theme.dart';
import 'press_scale.dart';

class KalimatAvatar extends StatelessWidget {
  const KalimatAvatar({
    super.key,
    required this.name,
    this.size = 44,
    this.onTap,
    this.semanticLabel,
  });

  final String name;
  final double size;
  final VoidCallback? onTap;

  /// Announced instead of the letter when the avatar is a button.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.kalimatColors;
    final trimmed = name.trim();
    final initial = trimmed.isEmpty ? '؟' : trimmed.characters.first;

    final circle = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
      child: Text(
        initial,
        style: TextStyle(
          fontFamily: kFontDisplay,
          fontSize: (size * .42).roundToDouble(),
          fontWeight: FontWeight.w700,
          color: c.textOnAccent,
          letterSpacing: 0,
          height: 1,
        ),
      ),
    );

    if (onTap == null) return ExcludeSemantics(child: circle);
    return Semantics(
      button: true,
      label: semanticLabel,
      child: PressScale(onTap: onTap, child: circle),
    );
  }
}
