import 'package:flutter/material.dart';
import 'package:lingo_core/core/theme/lingo_identity.dart';

/// True inside `flutter_test`. Skips plugin audio and photo decode that
/// keep widget tests from hanging on platform channels.
bool get lingoInWidgetTest {
  try {
    return WidgetsBinding.instance.runtimeType.toString().contains(
      'TestWidgetsFlutterBinding',
    );
  } on Object {
    return false;
  }
}

/// Shared visual states for interactive Lingo components.
enum LingoComponentState {
  enabled,
  pressed,
  disabled,
  loading,
  selected,
  focused,
  success,
  error,
}

/// Outcome styling for actions and cards.
enum LingoStatus { idle, success, error }

enum LingoSizeClass { compact, regular, expanded }

enum LingoElevationLevel { flat, rest, raised, overlay, pressed }

/// Semantic colors derived from a [LingoIdentity] and the current brightness.
final class LingoColors {
  const LingoColors({
    required this.brightness,
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.primaryDepth,
    required this.successDepth,
    required this.warningDepth,
    required this.dangerDepth,
    required this.tertiaryDepth,
    required this.accent,
    required this.onAccent,
    required this.accentContainer,
    required this.onAccentContainer,
    required this.accentDepth,
    required this.tertiary,
    required this.onTertiary,
    required this.tertiaryContainer,
    required this.onTertiaryContainer,
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.danger,
    required this.onDanger,
    required this.dangerContainer,
    required this.canvas,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceSunken,
    required this.surfaceDepth,
    required this.onSurface,
    required this.onSurfaceMuted,
    required this.onSurfaceFaint,
    required this.hairline,
    required this.overlay,
    required this.focusRing,
    required this.scrim,
    required this.disabledFill,
    required this.onDisabled,
    required this.shadow,
    required this.inverseSurface,
    required this.onInverseSurface,
    required this.inversePrimary,
  });

  final Brightness brightness;
  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color primaryDepth;
  final Color successDepth;
  final Color warningDepth;
  final Color dangerDepth;
  final Color tertiaryDepth;
  final Color accent;
  final Color onAccent;
  final Color accentContainer;
  final Color onAccentContainer;
  final Color accentDepth;
  final Color tertiary;
  final Color onTertiary;
  final Color tertiaryContainer;
  final Color onTertiaryContainer;
  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color danger;
  final Color onDanger;
  final Color dangerContainer;
  final Color canvas;
  final Color surface;
  final Color surfaceRaised;
  final Color surfaceSunken;
  final Color surfaceDepth;
  final Color onSurface;
  final Color onSurfaceMuted;
  final Color onSurfaceFaint;
  final Color hairline;
  final Color overlay;
  final Color focusRing;
  final Color scrim;
  final Color disabledFill;
  final Color onDisabled;
  final Color shadow;
  final Color inverseSurface;
  final Color onInverseSurface;
  final Color inversePrimary;

  bool get isDark => brightness == Brightness.dark;

  /// Translucent cream used by Settings groups and similar chrome.
  Color get paperFill {
    final Color frost = _mix(
      _mix(surfaceRaised, canvas, isDark ? 0.36 : 0.38),
      primary,
      isDark ? 0.05 : 0.04,
    );
    return frost.withValues(alpha: isDark ? 0.50 : 0.52);
  }

  /// Opaque cream for tactile cards so they are not a generic white slab.
  Color get cardFill {
    return _mix(
      _mix(surfaceRaised, canvas, isDark ? 0.22 : 0.28),
      primary,
      isDark ? 0.03 : 0.025,
    );
  }

  /// Hairline mixed with a light rim so paper cards are not stark white.
  Color get paperRim {
    return _mix(
      const Color(0xFFFFFFFF).withValues(alpha: isDark ? 0.24 : 0.68),
      hairline,
      isDark ? 0.30 : 0.20,
    );
  }

  factory LingoColors.fromIdentity(
    LingoIdentity identity,
    Brightness brightness,
  ) {
    final bool isDark = brightness == Brightness.dark;
    final Color canvas = isDark ? identity.darkCanvas : identity.lightCanvas;
    final Color surface = isDark ? identity.darkSurface : identity.lightSurface;
    final Color ink = isDark ? identity.darkInk : identity.lightInk;

    final Color primary = isDark
        ? _shiftLightness(identity.primary, 0.28)
        : identity.primary;
    final Color accent = isDark
        ? _shiftLightness(identity.accent, 0.16)
        : identity.accent;
    final Color tertiary = isDark
        ? _shiftLightness(identity.tertiary, 0.22)
        : identity.tertiary;
    final Color success = isDark
        ? _shiftLightness(identity.success, 0.18)
        : identity.success;
    final Color warning = isDark
        ? _shiftLightness(identity.warning, 0.14)
        : identity.warning;
    final Color danger = isDark
        ? _shiftLightness(identity.danger, 0.12)
        : identity.danger;

    final Color raised = isDark ? identity.darkRaised : identity.lightRaised;
    final Color sunken = isDark
        ? _mix(surface, identity.darkInk, 0.08)
        : _mix(canvas, identity.primary, 0.04);
    final Color inverseSurface = isDark
        ? identity.lightCanvas
        : identity.darkSurface;
    final Color onInverseSurface = isDark
        ? identity.lightInk
        : identity.darkInk;

    return LingoColors(
      brightness: brightness,
      primary: primary,
      onPrimary: _onColor(primary),
      primaryContainer: _mix(surface, primary, isDark ? 0.28 : 0.14),
      onPrimaryContainer: isDark
          ? _shiftLightness(primary, 0.36)
          : _shiftLightness(primary, -0.18),
      primaryDepth: _depth(primary),
      successDepth: _depth(success),
      warningDepth: _depth(warning),
      dangerDepth: _depth(danger),
      tertiaryDepth: _depth(tertiary),
      accent: accent,
      onAccent: _onColor(accent),
      accentContainer: _mix(surface, accent, isDark ? 0.26 : 0.16),
      onAccentContainer: isDark
          ? _shiftLightness(accent, 0.28)
          : _shiftLightness(accent, -0.22),
      accentDepth: _depth(accent),
      tertiary: tertiary,
      onTertiary: _onColor(tertiary),
      tertiaryContainer: _mix(surface, tertiary, isDark ? 0.28 : 0.14),
      onTertiaryContainer: isDark
          ? _shiftLightness(tertiary, 0.32)
          : _shiftLightness(tertiary, -0.18),
      success: success,
      onSuccess: _onColor(success),
      successContainer: _mix(surface, success, isDark ? 0.26 : 0.14),
      warning: warning,
      onWarning: _onColor(warning),
      warningContainer: _mix(surface, warning, isDark ? 0.26 : 0.16),
      danger: danger,
      onDanger: _onColor(danger),
      dangerContainer: _mix(surface, danger, isDark ? 0.26 : 0.14),
      canvas: canvas,
      surface: surface,
      surfaceRaised: raised,
      surfaceSunken: sunken,
      surfaceDepth: _depth(raised),
      onSurface: ink,
      onSurfaceMuted: _mix(ink, canvas, isDark ? 0.32 : 0.38),
      onSurfaceFaint: _mix(ink, canvas, isDark ? 0.52 : 0.58),
      hairline: _mix(ink, canvas, isDark ? 0.78 : 0.86),
      overlay: _mix(
        raised,
        ink,
        isDark ? 0.04 : 0.08,
      ).withValues(alpha: isDark ? 0.72 : 0.88),
      focusRing: primary.withValues(alpha: 0.55),
      scrim: ink.withValues(alpha: isDark ? 0.56 : 0.32),
      disabledFill: _mix(surface, ink, isDark ? 0.12 : 0.08),
      onDisabled: _mix(ink, canvas, 0.62),
      shadow: ink,
      inverseSurface: inverseSurface,
      onInverseSurface: onInverseSurface,
      inversePrimary: isDark ? identity.primary : primary,
    );
  }

  ColorScheme toColorScheme() {
    return ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondary: accent,
      onSecondary: onAccent,
      secondaryContainer: accentContainer,
      onSecondaryContainer: onAccentContainer,
      tertiary: tertiary,
      onTertiary: onTertiary,
      tertiaryContainer: tertiaryContainer,
      onTertiaryContainer: onTertiaryContainer,
      error: danger,
      onError: onDanger,
      errorContainer: dangerContainer,
      onErrorContainer: isDark
          ? _shiftLightness(danger, 0.28)
          : _shiftLightness(danger, -0.18),
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceMuted,
      surfaceContainerLowest: isDark ? canvas : surfaceRaised,
      surfaceContainerLow: surface,
      surfaceContainer: _mix(surface, primary, isDark ? 0.06 : 0.03),
      surfaceContainerHigh: surfaceRaised,
      surfaceContainerHighest: _mix(
        surfaceRaised,
        primary,
        isDark ? 0.08 : 0.04,
      ),
      outline: hairline,
      outlineVariant: _mix(hairline, surface, 0.35),
      scrim: scrim,
      shadow: shadow,
      inverseSurface: inverseSurface,
      onInverseSurface: onInverseSurface,
      inversePrimary: inversePrimary,
    );
  }
}

Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t) ?? a;

Color _depth(Color color) {
  return _mix(color, const Color(0xFF000000), 0.18);
}

Color _onColor(Color background) {
  return background.computeLuminance() > 0.46
      ? const Color(0xFF142022)
      : const Color(0xFFFFFFFF);
}

Color _shiftLightness(Color color, double amount) {
  final HSLColor hsl = HSLColor.fromColor(color);
  return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
}

/// 4-point spacing scale. Use [LingoMetrics] for screen gutters.
abstract final class LingoSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;
  static const double massive = 48;

  static const double minTapTarget = 44;
  static const double toolbar = minTapTarget;
  static const double settingsRow = 52;
  static const double settingsRowCompact = 48;
  static const double settingsLeadingInset =
      LingoSpacing.lg + LingoIconSize.lg + LingoSpacing.md;
}

abstract final class LingoRadii {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double pill = 999;

  static const BorderRadius card = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius poster = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius button = BorderRadius.all(Radius.circular(md));
  static const BorderRadius field = BorderRadius.all(Radius.circular(md));
  static const BorderRadius chip = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius sheet = BorderRadius.all(Radius.circular(xxl));
}

/// Physical depth used by pressable surfaces, in logical pixels.
abstract final class LingoElevation {
  static const double flat = 0;
  static const double rest = 3.5;
  static const double raised = 5.5;
  static const double overlay = 8;
  static const double pressed = 0;

  static double depthFor(LingoElevationLevel level) {
    return switch (level) {
      LingoElevationLevel.flat => flat,
      LingoElevationLevel.rest => rest,
      LingoElevationLevel.raised => raised,
      LingoElevationLevel.overlay => overlay,
      LingoElevationLevel.pressed => pressed,
    };
  }
}

final class LingoShadows {
  const LingoShadows(this.colors);

  final LingoColors colors;

  List<BoxShadow> get rest => <BoxShadow>[
    BoxShadow(
      color: colors.shadow.withValues(alpha: colors.isDark ? 0.28 : 0.06),
      offset: const Offset(0, 2),
      blurRadius: 6,
    ),
    BoxShadow(
      color: colors.shadow.withValues(alpha: colors.isDark ? 0.18 : 0.04),
      offset: const Offset(0, 8),
      blurRadius: 18,
      spreadRadius: -6,
    ),
  ];

  /// Softer than [rest]; for translucent grouped chrome on the paper field.
  List<BoxShadow> get paper => <BoxShadow>[
    BoxShadow(
      color: colors.shadow.withValues(alpha: colors.isDark ? 0.22 : 0.045),
      offset: const Offset(0, 1),
      blurRadius: 4,
    ),
    BoxShadow(
      color: colors.shadow.withValues(alpha: colors.isDark ? 0.14 : 0.035),
      offset: const Offset(0, 6),
      blurRadius: 16,
      spreadRadius: -8,
    ),
  ];

  List<BoxShadow> get raised => <BoxShadow>[
    BoxShadow(
      color: colors.shadow.withValues(alpha: colors.isDark ? 0.32 : 0.07),
      offset: const Offset(0, 3),
      blurRadius: 8,
    ),
    BoxShadow(
      color: colors.shadow.withValues(alpha: colors.isDark ? 0.22 : 0.08),
      offset: const Offset(0, 14),
      blurRadius: 28,
      spreadRadius: -8,
    ),
  ];

  List<BoxShadow> get overlay => <BoxShadow>[
    BoxShadow(
      color: colors.shadow.withValues(alpha: colors.isDark ? 0.36 : 0.08),
      offset: const Offset(0, 6),
      blurRadius: 12,
    ),
    BoxShadow(
      color: colors.shadow.withValues(alpha: colors.isDark ? 0.28 : 0.12),
      offset: const Offset(0, 20),
      blurRadius: 40,
      spreadRadius: -10,
    ),
  ];

  List<BoxShadow> get none => const <BoxShadow>[];
}

final class LingoGradients {
  const LingoGradients(this.colors);

  final LingoColors colors;

  LinearGradient get primarySheen {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[
        _mix(colors.primary, colors.surfaceRaised, colors.isDark ? 0.10 : 0.08),
        colors.primary,
      ],
    );
  }

  LinearGradient get progress {
    return LinearGradient(
      begin: AlignmentDirectional.centerStart,
      end: AlignmentDirectional.centerEnd,
      colors: <Color>[
        colors.primary,
        _mix(colors.primary, colors.accent, 0.42),
      ],
    );
  }

  LinearGradient get canvasWash {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[
        colors.canvas,
        _mix(colors.canvas, colors.primary, colors.isDark ? 0.05 : 0.03),
      ],
    );
  }
}

abstract final class LingoIconSize {
  static const double sm = 16;
  static const double md = 20;
  static const double lg = 24;
  static const double xl = 28;
  static const double xxl = 32;
}

abstract final class LingoMotion {
  /// Finger-down compression. Keep this under 90 ms so press reads instantly.
  static const Duration pressDown = Duration(milliseconds: 72);

  /// Finger-up settle. Slightly slower than [pressDown], still under 140 ms.
  static const Duration pressUp = Duration(milliseconds: 112);

  /// Alias for [pressDown] used by older motion call sites.
  static const Duration press = pressDown;
  static const Duration quick = Duration(milliseconds: 160);
  static const Duration standard = Duration(milliseconds: 240);
  static const Duration entrance = Duration(milliseconds: 320);
  static const Duration progress = Duration(milliseconds: 420);
  static const Duration stagger = Duration(milliseconds: 36);
  static const Duration chromeShow = Duration(milliseconds: 210);
  static const Duration chromeHide = Duration(milliseconds: 300);
  static const Duration chromeIdleHide = Duration(milliseconds: 2800);
  static const Curve pressCurve = Curves.easeOutCubic;
  static const Curve standardCurve = Curves.easeInOutCubic;
  static const Curve entranceCurve = Curves.easeOutCubic;
  static const Curve chromeShowCurve = Curves.easeOutCubic;
  static const Curve chromeHideCurve = Curves.easeInCubic;
}

/// Responsive metrics derived from [MediaQuery]. Not part of [ThemeData]
/// because they depend on the current window and text scaler.
final class LingoMetrics {
  const LingoMetrics({
    required this.sizeClass,
    required this.size,
    required this.textScaler,
    required this.reduceMotion,
  });

  final LingoSizeClass sizeClass;
  final Size size;
  final TextScaler textScaler;
  final bool reduceMotion;

  factory LingoMetrics.of(BuildContext context) {
    final MediaQueryData media = MediaQuery.of(context);
    final double shortest = media.size.shortestSide;
    final LingoSizeClass sizeClass = shortest >= 600
        ? LingoSizeClass.expanded
        : shortest < 375
        ? LingoSizeClass.compact
        : LingoSizeClass.regular;

    return LingoMetrics(
      sizeClass: sizeClass,
      size: media.size,
      textScaler: media.textScaler,
      reduceMotion: media.disableAnimations,
    );
  }

  bool get isCompact => sizeClass == LingoSizeClass.compact;

  bool get isExpanded => sizeClass == LingoSizeClass.expanded;

  bool get isNarrow => isCompact || size.width < 390;

  bool get stackTightCards {
    return isNarrow || textScaler.scale(1) >= 1.3;
  }

  /// Category grids can stay two-up on small phones; large type still stacks.
  bool get stackCategoryGrid {
    return size.width < 340 || textScaler.scale(1) >= 1.3;
  }

  double get horizontalGutter {
    return switch (sizeClass) {
      LingoSizeClass.compact => LingoSpacing.xl,
      LingoSizeClass.regular => LingoSpacing.xxl,
      LingoSizeClass.expanded => LingoSpacing.huge,
    };
  }

  double get sectionGap {
    return switch (sizeClass) {
      LingoSizeClass.compact => LingoSpacing.xxxl,
      LingoSizeClass.regular => LingoSpacing.huge,
      LingoSizeClass.expanded => LingoSpacing.massive,
    };
  }

  double get cardSpacing => isExpanded ? LingoSpacing.xxl : LingoSpacing.xl;

  double get categoryGridGap {
    return isExpanded ? LingoSpacing.xl : LingoSpacing.lg;
  }

  double get listRowGap {
    return isNarrow ? LingoSpacing.md : LingoSpacing.lg;
  }

  double get rootTopGap {
    return isCompact ? LingoSpacing.md : LingoSpacing.lg;
  }

  /// Scroll padding so the last item clears the floating tab bar.
  double get floatingChromeClearance {
    return LingoSpacing.massive + LingoSpacing.huge;
  }

  double get maxContentWidth => isExpanded ? 720 : double.infinity;

  Duration motion(Duration duration) {
    return reduceMotion ? Duration.zero : duration;
  }

  double tapHeight(double base) {
    return textScaler.scale(base).clamp(LingoSpacing.minTapTarget, base * 1.45);
  }
}
