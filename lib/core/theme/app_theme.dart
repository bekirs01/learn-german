import 'package:flutter/material.dart';
import 'package:lingo_core/core/theme/lingo_identity.dart';
import 'package:lingo_core/core/theme/lingo_tokens.dart';
import 'package:lingo_core/core/theme/lingo_typography.dart';

/// Custom tokens attached to [ThemeData]. Read with [LingoTheme.of].
final class LingoTheme extends ThemeExtension<LingoTheme> {
  const LingoTheme({
    required this.identity,
    required this.colors,
    required this.shadows,
    required this.gradients,
  });

  final LingoIdentity identity;
  final LingoColors colors;
  final LingoShadows shadows;
  final LingoGradients gradients;

  static LingoTheme of(BuildContext context) {
    final LingoTheme? theme = Theme.of(context).extension<LingoTheme>();
    if (theme == null) {
      throw StateError('LingoTheme is missing from ThemeData.');
    }
    return theme;
  }

  factory LingoTheme.fromIdentity(
    LingoIdentity identity,
    Brightness brightness,
  ) {
    final LingoColors colors = LingoColors.fromIdentity(identity, brightness);
    return LingoTheme(
      identity: identity,
      colors: colors,
      shadows: LingoShadows(colors),
      gradients: LingoGradients(colors),
    );
  }

  @override
  LingoTheme copyWith({
    LingoIdentity? identity,
    LingoColors? colors,
    LingoShadows? shadows,
    LingoGradients? gradients,
  }) {
    return LingoTheme(
      identity: identity ?? this.identity,
      colors: colors ?? this.colors,
      shadows: shadows ?? this.shadows,
      gradients: gradients ?? this.gradients,
    );
  }

  @override
  LingoTheme lerp(ThemeExtension<LingoTheme>? other, double t) {
    if (other is! LingoTheme) {
      return this;
    }
    if (t < 0.5) {
      return this;
    }
    return other;
  }
}

abstract final class AppTheme {
  static ThemeData light({LingoIdentity identity = LingoIdentity.lingoCore}) {
    return _build(identity: identity, brightness: Brightness.light);
  }

  static ThemeData dark({LingoIdentity identity = LingoIdentity.lingoCore}) {
    return _build(identity: identity, brightness: Brightness.dark);
  }

  static ThemeData _build({
    required LingoIdentity identity,
    required Brightness brightness,
  }) {
    final LingoTheme lingo = LingoTheme.fromIdentity(identity, brightness);
    final LingoColors colors = lingo.colors;
    final TextTheme textTheme = LingoTypography(colors).textTheme;
    final ColorScheme colorScheme = colors.toColorScheme();

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      primaryTextTheme: textTheme.apply(
        bodyColor: colors.onPrimary,
        displayColor: colors.onPrimary,
      ),
      scaffoldBackgroundColor: colors.canvas,
      canvasColor: colors.canvas,
      dividerColor: colors.hairline,
      splashFactory: NoSplash.splashFactory,
      highlightColor: colors.primary.withValues(alpha: 0.06),
      splashColor: Colors.transparent,
      extensions: <ThemeExtension<dynamic>>[lingo],
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: colors.scrim,
        dragHandleColor: colors.onSurfaceFaint,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(borderRadius: LingoRadii.sheet),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        toolbarHeight: LingoSpacing.toolbar,
        titleSpacing: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleMedium,
        iconTheme: IconThemeData(
          color: colors.onSurface,
          size: LingoIconSize.md,
        ),
        actionsIconTheme: IconThemeData(
          color: colors.onSurface,
          size: LingoIconSize.md,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surfaceRaised,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: LingoRadii.card),
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(
        color: colors.hairline,
        thickness: 0.5,
        space: 0.5,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll<Size>(
            Size(LingoSpacing.minTapTarget, 52),
          ),
          padding: const WidgetStatePropertyAll<EdgeInsets>(
            EdgeInsets.symmetric(horizontal: LingoSpacing.xxl),
          ),
          shape: const WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(borderRadius: LingoRadii.button),
          ),
          textStyle: WidgetStatePropertyAll<TextStyle?>(textTheme.labelLarge),
          elevation: const WidgetStatePropertyAll<double>(0),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll<Size>(
            Size(LingoSpacing.minTapTarget, 52),
          ),
          padding: const WidgetStatePropertyAll<EdgeInsets>(
            EdgeInsets.symmetric(horizontal: LingoSpacing.xxl),
          ),
          shape: const WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(borderRadius: LingoRadii.button),
          ),
          side: WidgetStatePropertyAll<BorderSide>(
            BorderSide(color: colors.hairline),
          ),
          foregroundColor: WidgetStatePropertyAll<Color>(colors.onSurface),
          textStyle: WidgetStatePropertyAll<TextStyle?>(textTheme.labelLarge),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceSunken,
        hintStyle: textTheme.bodyLarge?.copyWith(color: colors.onSurfaceFaint),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: LingoSpacing.lg,
          vertical: LingoSpacing.md,
        ),
        border: const OutlineInputBorder(
          borderRadius: LingoRadii.field,
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: LingoRadii.field,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: LingoRadii.field,
          borderSide: BorderSide(color: colors.primary, width: 1.4),
        ),
        disabledBorder: const OutlineInputBorder(
          borderRadius: LingoRadii.field,
          borderSide: BorderSide.none,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceSunken,
        selectedColor: colors.primaryContainer,
        disabledColor: colors.disabledFill,
        labelStyle: textTheme.labelMedium?.copyWith(color: colors.onSurface),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: colors.onPrimaryContainer,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: LingoSpacing.sm,
          vertical: LingoSpacing.xs,
        ),
        shape: const RoundedRectangleBorder(borderRadius: LingoRadii.chip),
        side: BorderSide(color: colors.hairline),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return colors.onDisabled;
          }
          if (states.contains(WidgetState.selected)) {
            return colors.onPrimary;
          }
          return colors.surfaceRaised;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return colors.disabledFill;
          }
          if (states.contains(WidgetState.selected)) {
            return colors.primary;
          }
          return colors.hairline;
        }),
        trackOutlineColor: const WidgetStatePropertyAll<Color>(
          Colors.transparent,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 64,
        backgroundColor: colors.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colors.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final Color color = states.contains(WidgetState.selected)
              ? colors.primary
              : colors.onSurfaceMuted;
          return IconThemeData(size: LingoIconSize.lg, color: color);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final Color color = states.contains(WidgetState.selected)
              ? colors.primary
              : colors.onSurfaceMuted;
          return textTheme.labelSmall?.copyWith(color: color);
        }),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
        linearTrackColor: colors.surfaceSunken,
        circularTrackColor: colors.surfaceSunken,
      ),
      iconTheme: IconThemeData(color: colors.onSurface, size: LingoIconSize.lg),
      listTileTheme: ListTileThemeData(
        iconColor: colors.onSurfaceMuted,
        textColor: colors.onSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: LingoSpacing.lg),
        minVerticalPadding: LingoSpacing.md,
      ),
    );
  }
}
