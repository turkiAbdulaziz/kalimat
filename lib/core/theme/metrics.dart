/// Layout metrics from the design tokens (tokens/spacing.css, radii.css).
library;

abstract final class Metrics {
  // Game
  static const double tileSize = 58;
  static const double tileGap = 6;
  static const double gridGap = 6;
  static const double keyHeight = 52;
  static const double keyGap = 5;
  static const double hitMin = 44;

  // Layout
  static const double appMaxWidth = 500;
  static const double gutter = 16;
  static const double headerHeight = 56;
  static const double toastSlotHeight = 34;

  // Radii
  static const double rTile = 6;
  static const double rKey = 6;
  static const double rLg = 10;
  static const double rCard = 12;
  static const double rPill = 999;

  // Spacing scale (4px base)
  static const double s1 = 4, s2 = 8, s3 = 12, s4 = 16, s5 = 20;
  static const double s6 = 24, s8 = 32, s10 = 40, s12 = 48;
}
