import 'package:flutter/material.dart';

/// Central visual identity for a Lingo app.
///
/// Future language products rebrand by constructing a different instance and
/// passing it to [AppTheme.light] / [AppTheme.dark]. Widgets must read color,
/// depth, and haptic settings from [LingoTheme], never from local literals.
final class LingoIdentity {
  const LingoIdentity({
    required this.name,
    required this.primary,
    required this.accent,
    required this.tertiary,
    required this.success,
    required this.warning,
    required this.danger,
    required this.lightCanvas,
    required this.lightSurface,
    required this.darkCanvas,
    required this.darkSurface,
    this.lightInk = const Color(0xFF1A1F21),
    this.darkInk = const Color(0xFFE8E4DE),
    this.lightRaised = const Color(0xFFFFFDFB),
    this.darkRaised = const Color(0xFF1E2529),
    this.pressScale = 0.978,
    this.hapticsEnabled = true,
  });

  final String name;

  /// Signature brand hue. Harbor teal in Lingo Core.
  final Color primary;

  /// Warm highlight for progress and emphasis. Ember copper in Lingo Core.
  final Color accent;

  /// Supporting hue for categories and secondary grouping.
  final Color tertiary;

  final Color success;
  final Color warning;
  final Color danger;

  final Color lightCanvas;
  final Color lightSurface;
  final Color darkCanvas;
  final Color darkSurface;
  final Color lightInk;
  final Color darkInk;
  final Color lightRaised;
  final Color darkRaised;

  /// Scale applied while a pressable is held. Keep close to 1.0.
  final double pressScale;

  /// Master switch for haptic cues. Sound remains unbundled.
  final bool hapticsEnabled;

  /// Default Learn German identity: editorial, warm, and distinct from
  /// generic Material teal or game-like greens.
  static const LingoIdentity lingoCore = LingoIdentity(
    name: 'Learn German for Beginners',
    primary: Color(0xFF1B6568),
    accent: Color(0xFFC46A3C),
    tertiary: Color(0xFF6A5A86),
    success: Color(0xFF3A7F62),
    warning: Color(0xFFC3922A),
    danger: Color(0xFFC04545),
    lightCanvas: Color(0xFFF4EFE6),
    lightSurface: Color(0xFFFAF6EF),
    darkCanvas: Color(0xFF101417),
    darkSurface: Color(0xFF171C20),
    lightRaised: Color(0xFFFFFBF6),
    pressScale: 0.984,
  );

  LingoIdentity copyWith({
    String? name,
    Color? primary,
    Color? accent,
    Color? tertiary,
    Color? success,
    Color? warning,
    Color? danger,
    Color? lightCanvas,
    Color? lightSurface,
    Color? darkCanvas,
    Color? darkSurface,
    Color? lightInk,
    Color? darkInk,
    Color? lightRaised,
    Color? darkRaised,
    double? pressScale,
    bool? hapticsEnabled,
  }) {
    return LingoIdentity(
      name: name ?? this.name,
      primary: primary ?? this.primary,
      accent: accent ?? this.accent,
      tertiary: tertiary ?? this.tertiary,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      lightCanvas: lightCanvas ?? this.lightCanvas,
      lightSurface: lightSurface ?? this.lightSurface,
      darkCanvas: darkCanvas ?? this.darkCanvas,
      darkSurface: darkSurface ?? this.darkSurface,
      lightInk: lightInk ?? this.lightInk,
      darkInk: darkInk ?? this.darkInk,
      lightRaised: lightRaised ?? this.lightRaised,
      darkRaised: darkRaised ?? this.darkRaised,
      pressScale: pressScale ?? this.pressScale,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    );
  }
}
