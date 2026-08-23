/// ThemeData builders wiring the token set into Flutter.
///
/// Type rules (tokens/typography.css): Arabic is cursive — letterSpacing is
/// ALWAYS 0; hierarchy is carried by size and weight only. Display = Noto
/// Kufi Arabic (wordmark, tiles, dialog titles); UI = IBM Plex Sans Arabic.
library;

import 'package:flutter/material.dart';

import 'kalimat_colors.dart';

const String kFontDisplay = 'NotoKufiArabic';
const String kFontUi = 'IBMPlexSansArabic';

/// Text size scale from tokens: 2xs 11, xs 13, sm 15, md 17, lg 20, xl 24,
/// 2xl 30, 3xl 38; tile text 30.
abstract final class TypeScale {
  static const double xs2 = 11, xs = 13, sm = 15, md = 17;
  static const double lg = 20, xl = 24, xl2 = 30, xl3 = 38;
  static const double tile = 30;
}

ThemeData kalimatTheme(Brightness brightness) {
  final colors = brightness == Brightness.dark
      ? KalimatColors.dark()
      : KalimatColors.light();

  TextStyle ui(
    double size,
    FontWeight weight, {
    Color? color,
    double height = 1.5,
  }) => TextStyle(
    fontFamily: kFontUi,
    fontSize: size,
    fontWeight: weight,
    color: color ?? colors.textBody,
    letterSpacing: 0,
    height: height,
  );

  TextStyle display(double size, FontWeight weight, {Color? color}) =>
      TextStyle(
        fontFamily: kFontDisplay,
        fontSize: size,
        fontWeight: weight,
        color: color ?? colors.textBody,
        letterSpacing: 0,
        height: 1.3,
      );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: kFontUi,
    scaffoldBackgroundColor: colors.surfacePage,
    colorScheme: ColorScheme.fromSeed(
      seedColor: colors.accent,
      brightness: brightness,
      surface: colors.surfacePage,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );

  return base.copyWith(
    extensions: [colors],
    textTheme: base.textTheme.copyWith(
      // Display roles (Noto Kufi Arabic)
      displayLarge: display(TypeScale.xl3, FontWeight.w800),
      displayMedium: display(TypeScale.xl, FontWeight.w800), // wordmark
      titleLarge: display(TypeScale.lg, FontWeight.w700), // dialog titles
      // UI roles (IBM Plex Sans Arabic); body leading is generous (1.75)
      bodyLarge: ui(TypeScale.md, FontWeight.w400, height: 1.75),
      bodyMedium: ui(TypeScale.sm, FontWeight.w400, height: 1.75),
      bodySmall: ui(TypeScale.xs, FontWeight.w400, color: colors.textMuted),
      labelLarge: ui(TypeScale.sm, FontWeight.w600),
      labelMedium: ui(TypeScale.xs, FontWeight.w600),
      labelSmall: ui(TypeScale.xs2, FontWeight.w600, color: colors.textSubtle),
    ),
    iconTheme: IconThemeData(color: colors.textMuted, size: 20),
    dividerTheme: DividerThemeData(color: colors.lineSoft, thickness: 1),
  );
}
