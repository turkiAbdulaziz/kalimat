/// Color tokens (tokens/colors.css) encoded as a ThemeExtension.
///
/// The palette is a single brown hue plus one desaturated taupe; game state
/// is communicated by brown value (dark = correct), never by red/green.
/// Shadows are always warm brown, never neutral black.
library;

import 'package:flutter/material.dart';

/// Raw brown → light-brown ramp (the only hue in the system).
abstract final class BrownRamp {
  static const b950 = Color(0xFF231911);
  static const b900 = Color(0xFF2E211A);
  static const b800 = Color(0xFF4A3728);
  static const b700 = Color(0xFF6B4F3A);
  static const b600 = Color(0xFF8A6544);
  static const b500 = Color(0xFFA97F55);
  static const b400 = Color(0xFFC69C6D);
  static const b300 = Color(0xFFDDBD97);
  static const b200 = Color(0xFFEBD9C0);
  static const b100 = Color(0xFFF5EADC);
  static const b50 = Color(0xFFFBF6EF);
  static const b0 = Color(0xFFFFFDFA);

  // Taupe: used only for "not in the word".
  static const t600 = Color(0xFF7C7168);
  static const t500 = Color(0xFF988D83);
  static const t300 = Color(0xFFC3BAB1);
  static const t100 = Color(0xFFE4DED8);

  /// Warm shadow base rgba(46,33,26,…).
  static const shadowBase = Color(0xFF2E211A);
}

@immutable
class KalimatColors extends ThemeExtension<KalimatColors> {
  const KalimatColors({
    required this.surfacePage,
    required this.surfaceCard,
    required this.surfaceSunken,
    required this.surfaceInverse,
    required this.surfaceOverlay,
    required this.textBody,
    required this.textMuted,
    required this.textSubtle,
    required this.textInverse,
    required this.textOnAccent,
    required this.lineStrong,
    required this.line,
    required this.lineSoft,
    required this.accent,
    required this.accentHover,
    required this.accentPress,
    required this.accentSoft,
    required this.tileEmptyBorder,
    required this.tileFilledBorder,
    required this.tileCorrect,
    required this.tilePresent,
    required this.tileAbsent,
    required this.tileTextOnState,
    required this.keyBg,
    required this.keyBgHover,
    required this.keyText,
    required this.keyWideBg,
    required this.focusRing,
  });

  final Color surfacePage;
  final Color surfaceCard;
  final Color surfaceSunken;
  final Color surfaceInverse;
  final Color surfaceOverlay;
  final Color textBody;
  final Color textMuted;
  final Color textSubtle;
  final Color textInverse;
  final Color textOnAccent;
  final Color lineStrong;
  final Color line;
  final Color lineSoft;
  final Color accent;
  final Color accentHover;
  final Color accentPress;
  final Color accentSoft;
  final Color tileEmptyBorder;
  final Color tileFilledBorder;
  final Color tileCorrect;
  final Color tilePresent;
  final Color tileAbsent;
  final Color tileTextOnState;
  final Color keyBg;
  final Color keyBgHover;
  final Color keyText;
  final Color keyWideBg;
  final Color focusRing;

  /// Exact mapping of the CSS semantic variables.
  factory KalimatColors.light() => const KalimatColors(
    surfacePage: BrownRamp.b50,
    surfaceCard: BrownRamp.b0,
    surfaceSunken: BrownRamp.b100,
    surfaceInverse: BrownRamp.b900,
    surfaceOverlay: Color(0x8C2E211A), // rgba(46,33,26,.55)
    textBody: BrownRamp.b900,
    textMuted: BrownRamp.b700,
    textSubtle: BrownRamp.t600,
    textInverse: BrownRamp.b50,
    textOnAccent: BrownRamp.b0,
    lineStrong: BrownRamp.b400,
    line: BrownRamp.b300,
    lineSoft: BrownRamp.b200,
    accent: BrownRamp.b600,
    accentHover: BrownRamp.b700,
    accentPress: BrownRamp.b800,
    accentSoft: BrownRamp.b200,
    tileEmptyBorder: BrownRamp.b300,
    tileFilledBorder: BrownRamp.b500,
    tileCorrect: BrownRamp.b700,
    tilePresent: BrownRamp.b400,
    tileAbsent: BrownRamp.t500,
    tileTextOnState: BrownRamp.b0,
    keyBg: BrownRamp.b200,
    keyBgHover: BrownRamp.b300,
    keyText: BrownRamp.b900,
    keyWideBg: BrownRamp.b300,
    focusRing: Color(0x598A6544), // rgba(138,101,68,.35)
  );

  /// Dark mode («خلفية بنية غامقة»). The design only specifies brown-900
  /// surfaces; this full mapping is a proposal (game-state colors unchanged,
  /// as in the reference App.jsx dark mode).
  factory KalimatColors.dark() => const KalimatColors(
    surfacePage: BrownRamp.b900,
    surfaceCard: BrownRamp.b800,
    surfaceSunken: BrownRamp.b950,
    surfaceInverse: BrownRamp.b50,
    surfaceOverlay: Color(0xB3231911), // deeper wash over dark
    textBody: BrownRamp.b50,
    textMuted: BrownRamp.b300,
    textSubtle: BrownRamp.t300,
    textInverse: BrownRamp.b900,
    textOnAccent: BrownRamp.b0,
    lineStrong: BrownRamp.b600,
    line: BrownRamp.b700,
    lineSoft: BrownRamp.b800,
    accent: BrownRamp.b500,
    accentHover: BrownRamp.b400,
    accentPress: BrownRamp.b600,
    accentSoft: BrownRamp.b800,
    tileEmptyBorder: BrownRamp.b700,
    tileFilledBorder: BrownRamp.b500,
    tileCorrect: BrownRamp.b700,
    tilePresent: BrownRamp.b400,
    tileAbsent: BrownRamp.t500,
    tileTextOnState: BrownRamp.b0,
    keyBg: BrownRamp.b800,
    keyBgHover: BrownRamp.b700,
    keyText: BrownRamp.b100,
    keyWideBg: BrownRamp.b700,
    focusRing: Color(0x59A97F55),
  );

  /// Warm shadow levels (never neutral black).
  static const List<BoxShadow> shadowSm = [
    BoxShadow(color: Color(0x0F2E211A), offset: Offset(0, 1), blurRadius: 2),
  ];
  static const List<BoxShadow> shadowMd = [
    BoxShadow(color: Color(0x142E211A), offset: Offset(0, 2), blurRadius: 8),
  ];
  static const List<BoxShadow> shadowLg = [
    BoxShadow(color: Color(0x292E211A), offset: Offset(0, 12), blurRadius: 32),
  ];

  @override
  KalimatColors copyWith() => this;

  @override
  KalimatColors lerp(ThemeExtension<KalimatColors>? other, double t) {
    if (other is! KalimatColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return KalimatColors(
      surfacePage: l(surfacePage, other.surfacePage),
      surfaceCard: l(surfaceCard, other.surfaceCard),
      surfaceSunken: l(surfaceSunken, other.surfaceSunken),
      surfaceInverse: l(surfaceInverse, other.surfaceInverse),
      surfaceOverlay: l(surfaceOverlay, other.surfaceOverlay),
      textBody: l(textBody, other.textBody),
      textMuted: l(textMuted, other.textMuted),
      textSubtle: l(textSubtle, other.textSubtle),
      textInverse: l(textInverse, other.textInverse),
      textOnAccent: l(textOnAccent, other.textOnAccent),
      lineStrong: l(lineStrong, other.lineStrong),
      line: l(line, other.line),
      lineSoft: l(lineSoft, other.lineSoft),
      accent: l(accent, other.accent),
      accentHover: l(accentHover, other.accentHover),
      accentPress: l(accentPress, other.accentPress),
      accentSoft: l(accentSoft, other.accentSoft),
      tileEmptyBorder: l(tileEmptyBorder, other.tileEmptyBorder),
      tileFilledBorder: l(tileFilledBorder, other.tileFilledBorder),
      tileCorrect: l(tileCorrect, other.tileCorrect),
      tilePresent: l(tilePresent, other.tilePresent),
      tileAbsent: l(tileAbsent, other.tileAbsent),
      tileTextOnState: l(tileTextOnState, other.tileTextOnState),
      keyBg: l(keyBg, other.keyBg),
      keyBgHover: l(keyBgHover, other.keyBgHover),
      keyText: l(keyText, other.keyText),
      keyWideBg: l(keyWideBg, other.keyWideBg),
      focusRing: l(focusRing, other.focusRing),
    );
  }
}

/// Convenience accessor: `context.kalimatColors`.
extension KalimatColorsX on BuildContext {
  KalimatColors get kalimatColors => Theme.of(this).extension<KalimatColors>()!;
}
