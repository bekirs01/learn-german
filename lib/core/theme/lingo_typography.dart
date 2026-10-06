import 'package:flutter/material.dart';
import 'package:lingo_core/core/theme/lingo_tokens.dart';

/// iOS-first type scale using the platform default family (San Francisco on
/// iOS, Roboto on Android) so Dynamic Type can still scale text.
final class LingoTypography {
  const LingoTypography(this.colors);

  final LingoColors colors;

  TextTheme get textTheme {
    return TextTheme(
      displayLarge: _style(
        size: 34,
        weight: FontWeight.w700,
        height: 1.18,
        letterSpacing: -0.5,
        color: colors.onSurface,
      ),
      displayMedium: _style(
        size: 32,
        weight: FontWeight.w700,
        height: 1.16,
        letterSpacing: -0.5,
        color: colors.onSurface,
      ),
      displaySmall: _style(
        size: 24,
        weight: FontWeight.w600,
        height: 1.22,
        letterSpacing: -0.24,
        color: colors.onSurface,
      ),
      headlineLarge: _style(
        size: 22,
        weight: FontWeight.w600,
        height: 1.25,
        letterSpacing: -0.22,
        color: colors.onSurface,
      ),
      headlineMedium: _style(
        size: 20,
        weight: FontWeight.w600,
        height: 1.28,
        letterSpacing: -0.16,
        color: colors.onSurface,
      ),
      headlineSmall: _style(
        size: 17,
        weight: FontWeight.w600,
        height: 1.3,
        letterSpacing: -0.08,
        color: colors.onSurface,
      ),
      titleLarge: _style(
        size: 20,
        weight: FontWeight.w600,
        height: 1.28,
        color: colors.onSurface,
      ),
      titleMedium: _style(
        size: 17,
        weight: FontWeight.w600,
        height: 1.3,
        color: colors.onSurface,
      ),
      titleSmall: _style(
        size: 15,
        weight: FontWeight.w600,
        height: 1.32,
        letterSpacing: 0.1,
        color: colors.onSurface,
      ),
      bodyLarge: _style(
        size: 17,
        weight: FontWeight.w400,
        height: 1.37,
        color: colors.onSurface,
      ),
      bodyMedium: _style(
        size: 15,
        weight: FontWeight.w400,
        height: 1.38,
        color: colors.onSurface,
      ),
      bodySmall: _style(
        size: 13,
        weight: FontWeight.w400,
        height: 1.36,
        letterSpacing: 0.12,
        color: colors.onSurfaceMuted,
      ),
      labelLarge: _style(
        size: 17,
        weight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.02,
        color: colors.onSurface,
      ),
      labelMedium: _style(
        size: 13,
        weight: FontWeight.w600,
        height: 1.24,
        letterSpacing: 0.16,
        color: colors.onSurfaceMuted,
      ),
      labelSmall: _style(
        size: 11,
        weight: FontWeight.w600,
        height: 1.22,
        letterSpacing: 0.28,
        color: colors.onSurfaceFaint,
      ),
    );
  }

  static TextStyle _style({
    required double size,
    required FontWeight weight,
    required Color color,
    double height = 1.3,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
    );
  }
}
