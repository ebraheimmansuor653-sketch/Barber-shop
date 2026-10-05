import 'package:flutter/material.dart';

/// "Obsidian & Brass" tokens, copied from the approved DESIGN.md rather
/// than re-derived — this file should stay a 1:1 mirror of that document,
/// not drift into its own palette over time.
class ShopColors {
  ShopColors._();

  static const surface = Color(0xFF121316);
  static const surfaceContainerLowest = Color(0xFF0D0E11);
  static const surfaceContainerLow = Color(0xFF1B1B1F);
  static const surfaceContainer = Color(0xFF1F1F23);
  static const surfaceContainerHigh = Color(0xFF292A2D);
  static const surfaceContainerHighest = Color(0xFF343538);

  static const onSurface = Color(0xFFE3E2E6);
  static const onSurfaceVariant = Color(0xFFD1C5B4);

  static const outline = Color(0xFF9A8F80);
  static const outlineVariant = Color(0xFF4E4639);

  static const primary = Color(0xFFE9C176); // brass accent / CTAs
  static const onPrimary = Color(0xFF412D00);
  static const primaryContainer = Color(0xFFC5A059);

  static const secondary = Color(0xFFE7C272);

  static const error = Color(0xFFFFB4AB);
  static const onError = Color(0xFF690005);

  // Hairline card/section boundary used throughout the screenshots.
  static const hairline = Color(0xFF383D47);

  static const textPrimary = Color(0xFFF4F4F5); // "Warm Alabaster"
  static const textSecondary = Color(0xFFA1A1AA); // "Muted Cashmere"
  static const textMuted = Color(0xFF71717A); // "Deep Muted Zinc"
}

class ShopRadii {
  ShopRadii._();

  static const sm = 2.0;
  static const base = 4.0;
  static const md = 6.0;
  static const lg = 8.0;
}

class ShopSpacing {
  ShopSpacing._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

/// Space Grotesk / IBM Plex Sans Arabic per DESIGN.md. Both are Google
/// Fonts — add the `google_fonts` package (`flutter pub add google_fonts`)
/// if it isn't already a dependency, or swap these for bundled
/// FontFamily names if you'd rather ship the fonts locally.
class ShopTextStyles {
  ShopTextStyles._();

  static const _latinFamily = 'Space Grotesk';
  static const _arabicFamily = 'IBM Plex Sans Arabic';

  static TextStyle _style({
    required double size,
    required FontWeight weight,
    required double height,
    bool arabic = true,
    Color color = ShopColors.textPrimary,
  }) {
    return TextStyle(
      fontFamily: arabic ? _arabicFamily : _latinFamily,
      fontSize: size,
      fontWeight: weight,
      height: height / size,
      color: color,
    );
  }

  static TextStyle headlineLg({bool mobile = true}) => _style(
        size: mobile ? 22 : 28,
        weight: FontWeight.w600,
        height: mobile ? 28 : 36,
      );

  static TextStyle headlineMd() =>
      _style(size: 20, weight: FontWeight.w500, height: 28);

  static TextStyle headlineSm() =>
      _style(size: 18, weight: FontWeight.w500, height: 24);

  static TextStyle bodyLg({Color? color}) => _style(
      size: 16, weight: FontWeight.w400, height: 26, color: color ?? ShopColors.textPrimary);

  static TextStyle bodyMd({Color? color}) => _style(
      size: 14,
      weight: FontWeight.w400,
      height: 22,
      color: color ?? ShopColors.textSecondary);

  static TextStyle bodySm({Color? color}) => _style(
      size: 12,
      weight: FontWeight.w400,
      height: 18,
      color: color ?? ShopColors.textMuted);

  static TextStyle labelLg({Color? color}) => _style(
      size: 14,
      weight: FontWeight.w600,
      height: 20,
      color: color ?? ShopColors.textPrimary);

  static TextStyle labelMd({Color? color}) => _style(
      size: 12,
      weight: FontWeight.w500,
      height: 16,
      color: color ?? ShopColors.textSecondary);
}
