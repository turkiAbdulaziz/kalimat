/// The brand mark: «كلمات» set in the display font at weight 800.
/// There is no logo — do not invent one.
library;

import 'package:flutter/material.dart';

import '../../core/strings.dart';
import '../../core/theme/kalimat_colors.dart';
import '../../core/theme/kalimat_theme.dart';

class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.size = TypeScale.xl4});

  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.kalimatColors;
    return Text(
      S.appTitle,
      style: TextStyle(
        fontFamily: kFontDisplay,
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: c.textWordmark,
        letterSpacing: 0,
        height: 1,
      ),
    );
  }
}
