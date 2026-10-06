import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lingo_core/core/assets/lingo_assets.dart';
import 'package:lingo_core/core/theme/app_theme.dart';
import 'package:lingo_core/core/theme/lingo_tokens.dart';

int lingoCacheWidth(BuildContext context, double logicalWidth) {
  final double dpr = MediaQuery.devicePixelRatioOf(context);
  return (logicalWidth * dpr).round().clamp(1, 4096);
}

/// Widget tests rasterize decoded photographs with the glass nav blur so
/// slowly that the first frame never returns. Layout still uses placeholders.
bool get lingoSkipDecodedPhotos => lingoInWidgetTest;

/// Shared category hue used by cards and fallback still-lifes.
Color lingoArtTint(LingoArtKind art, LingoColors colors) {
  return switch (art) {
    LingoArtKind.animals ||
    LingoArtKind.nature ||
    LingoArtKind.weather ||
    LingoArtKind.doctor ||
    LingoArtKind.health ||
    LingoArtKind.pharmacy ||
    LingoArtKind.places => colors.success,
    LingoArtKind.food ||
    LingoArtKind.drinks ||
    LingoArtKind.restaurant ||
    LingoArtKind.cafe ||
    LingoArtKind.sports ||
    LingoArtKind.emergency ||
    LingoArtKind.travel ||
    LingoArtKind.greetings => colors.accent,
    LingoArtKind.emotions ||
    LingoArtKind.family ||
    LingoArtKind.people ||
    LingoArtKind.colors ||
    LingoArtKind.introductions ||
    LingoArtKind.hotel ||
    LingoArtKind.socialSituations => colors.tertiary,
    LingoArtKind.body ||
    LingoArtKind.home ||
    LingoArtKind.clothing ||
    LingoArtKind.shopping ||
    LingoArtKind.shoppingPhrases ||
    LingoArtKind.dailyConversation ||
    LingoArtKind.time =>
      Color.lerp(colors.accent, colors.tertiary, 0.35) ?? colors.accent,
    _ => colors.primary,
  };
}

/// Loads a bundled PNG and falls back to painted art if the file is absent.
class LingoArtwork extends StatelessWidget {
  const LingoArtwork({
    super.key,
    required this.art,
    this.assetPath,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
  });

  final LingoArtKind art;
  final String? assetPath;
  final BoxFit fit;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final String? assetPath = this.assetPath;
    if (assetPath == null || lingoSkipDecodedPhotos) {
      return LingoCategoryArt(art: art);
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        return Image.asset(
          assetPath,
          fit: fit,
          alignment: alignment,
          cacheWidth: lingoCacheWidth(context, width),
          filterQuality: FilterQuality.medium,
          gaplessPlayback: true,
          errorBuilder:
              (BuildContext context, Object error, StackTrace? stackTrace) {
                return LingoCategoryArt(art: art);
              },
        );
      },
    );
  }
}

/// Category-specific still-life used only when a generated image is missing.
class LingoCategoryArt extends StatelessWidget {
  const LingoCategoryArt({super.key, required this.art});

  final LingoArtKind art;

  @override
  Widget build(BuildContext context) {
    final LingoColors colors = LingoTheme.of(context).colors;
    final Color tint = lingoArtTint(art, colors);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color.lerp(colors.surfaceRaised, tint, 0.22) ??
                colors.surfaceRaised,
            Color.lerp(colors.canvas, tint, 0.14) ?? colors.canvas,
          ],
        ),
      ),
      child: CustomPaint(
        painter: _CategoryStillLifePainter(art: art, tint: tint),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _CategoryStillLifePainter extends CustomPainter {
  const _CategoryStillLifePainter({required this.art, required this.tint});

  final LingoArtKind art;
  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    final _Ink ink = _Ink(canvas, size, tint);
    switch (art) {
      case LingoArtKind.basics:
        ink.rrect(0.50, 0.58, 0.58, 0.38, 0.04, 0.22, mix: 0.35);
        ink.rrect(0.46, 0.54, 0.42, 0.30, 0.03, 0.34);
        ink.oval(0.72, 0.42, 0.18, 0.16, 0.30, mix: 0.20);
        ink.circle(0.72, 0.68, 0.09, 0.40);
      case LingoArtKind.numbers:
        ink.rrect(0.50, 0.70, 0.42, 0.22, 0.03, 0.38);
        ink.rrect(0.50, 0.52, 0.30, 0.18, 0.03, 0.30, mix: 0.12);
        ink.rrect(0.50, 0.36, 0.20, 0.14, 0.03, 0.24, mix: 0.28);
      case LingoArtKind.colors:
        ink.circle(0.34, 0.54, 0.16, 0.42);
        ink.circle(0.50, 0.42, 0.16, 0.34, mix: 0.22);
        ink.circle(0.66, 0.56, 0.16, 0.28, mix: 0.40);
      case LingoArtKind.family:
        ink.figure(0.32, 0.56, 0.14, 0.42, 0.32);
        ink.figure(0.50, 0.52, 0.16, 0.50, 0.40);
        ink.figure(0.68, 0.58, 0.13, 0.38, 0.26, mix: 0.22);
      case LingoArtKind.people:
        ink.figure(0.38, 0.54, 0.18, 0.52, 0.36);
        ink.figure(0.62, 0.56, 0.17, 0.48, 0.30, mix: 0.24);
      case LingoArtKind.body:
        ink.oval(0.50, 0.46, 0.38, 0.46, 0.30);
        ink.oval(0.50, 0.72, 0.46, 0.16, 0.18, mix: 0.20);
        ink.circle(0.50, 0.22, 0.10, 0.26, mix: 0.12);
      case LingoArtKind.emotions:
        ink.circle(0.36, 0.50, 0.18, 0.34);
        ink.circle(0.64, 0.52, 0.16, 0.26, mix: 0.28);
        ink.oval(0.36, 0.54, 0.10, 0.04, 0.20, mix: 0.50);
        ink.oval(0.64, 0.56, 0.09, 0.03, 0.18, mix: 0.50);
      case LingoArtKind.food:
        ink.oval(0.50, 0.62, 0.62, 0.22, 0.18, mix: 0.28);
        ink.oval(0.50, 0.52, 0.50, 0.28, 0.32);
        ink.circle(0.38, 0.44, 0.10, 0.28, mix: 0.16);
        ink.circle(0.60, 0.40, 0.08, 0.24, mix: 0.36);
      case LingoArtKind.drinks:
        ink.rrect(0.40, 0.48, 0.18, 0.46, 0.08, 0.32);
        ink.circle(0.66, 0.62, 0.11, 0.36);
        ink.oval(0.66, 0.50, 0.16, 0.06, 0.20, mix: 0.30);
      case LingoArtKind.home:
        ink.rrect(0.50, 0.62, 0.48, 0.32, 0.03, 0.30);
        ink.triangle(0.50, 0.28, 0.56, 0.28, 0.34);
        ink.rrect(0.50, 0.64, 0.14, 0.16, 0.02, 0.22, mix: 0.35);
      case LingoArtKind.clothing:
        ink.rrect(0.50, 0.46, 0.42, 0.34, 0.06, 0.32);
        ink.oval(0.50, 0.26, 0.22, 0.10, 0.26, mix: 0.18);
        ink.rrect(0.38, 0.72, 0.16, 0.12, 0.04, 0.24);
        ink.rrect(0.62, 0.72, 0.16, 0.12, 0.04, 0.24);
      case LingoArtKind.animals:
        ink.oval(0.54, 0.58, 0.52, 0.32, 0.34);
        ink.circle(0.32, 0.44, 0.14, 0.32);
        ink.triangle(0.26, 0.26, 0.12, 0.16, 0.28);
        ink.triangle(0.38, 0.24, 0.12, 0.16, 0.28);
        ink.circle(0.72, 0.70, 0.07, 0.26, mix: 0.22);
      case LingoArtKind.nature:
        ink.circle(0.72, 0.24, 0.10, 0.28, mix: 0.20);
        ink.oval(0.50, 0.72, 0.86, 0.28, 0.22);
        ink.triangle(0.34, 0.34, 0.28, 0.40, 0.34);
        ink.rrect(0.34, 0.62, 0.06, 0.16, 0.02, 0.28);
      case LingoArtKind.weather:
        ink.circle(0.68, 0.30, 0.12, 0.26, mix: 0.18);
        ink.oval(0.44, 0.42, 0.46, 0.22, 0.34);
        ink.oval(0.56, 0.38, 0.32, 0.18, 0.26, mix: 0.16);
        ink.rrect(0.38, 0.62, 0.03, 0.16, 0.02, 0.20);
        ink.rrect(0.48, 0.66, 0.03, 0.18, 0.02, 0.18);
        ink.rrect(0.58, 0.62, 0.03, 0.16, 0.02, 0.20);
      case LingoArtKind.school:
        ink.rrect(0.38, 0.54, 0.36, 0.28, 0.03, 0.28, mix: 0.20);
        ink.rrect(0.62, 0.54, 0.36, 0.28, 0.03, 0.34);
        ink.rrect(0.72, 0.70, 0.06, 0.36, 0.03, 0.26, mix: 0.12);
      case LingoArtKind.work:
        ink.rrect(0.50, 0.70, 0.62, 0.16, 0.03, 0.18, mix: 0.30);
        ink.rrect(0.38, 0.58, 0.32, 0.22, 0.03, 0.32);
        ink.rrect(0.64, 0.42, 0.08, 0.28, 0.04, 0.28);
        ink.oval(0.64, 0.24, 0.22, 0.14, 0.24, mix: 0.16);
      case LingoArtKind.sports:
        ink.oval(0.38, 0.48, 0.22, 0.46, 0.22, mix: 0.24);
        ink.rrect(0.38, 0.72, 0.06, 0.22, 0.03, 0.30);
        ink.circle(0.66, 0.58, 0.14, 0.36);
      case LingoArtKind.shopping:
      case LingoArtKind.shoppingPhrases:
        ink.rrect(0.50, 0.58, 0.42, 0.36, 0.04, 0.32);
        ink.rrect(0.50, 0.36, 0.18, 0.10, 0.03, 0.26);
        ink.circle(0.30, 0.68, 0.08, 0.24, mix: 0.22);
        ink.circle(0.70, 0.70, 0.07, 0.22, mix: 0.36);
      case LingoArtKind.travel:
        ink.rrect(0.50, 0.58, 0.50, 0.32, 0.05, 0.34);
        ink.rrect(0.50, 0.40, 0.22, 0.08, 0.03, 0.26);
        ink.rrect(0.68, 0.70, 0.18, 0.12, 0.02, 0.22, mix: 0.28);
      case LingoArtKind.transportation:
        ink.rrect(0.42, 0.48, 0.50, 0.22, 0.06, 0.34);
        ink.rrect(0.28, 0.42, 0.16, 0.16, 0.04, 0.28);
        ink.circle(0.30, 0.66, 0.08, 0.30);
        ink.circle(0.54, 0.66, 0.08, 0.30);
        ink.rrect(0.78, 0.58, 0.22, 0.08, 0.04, 0.24, mix: 0.20);
        ink.circle(0.72, 0.66, 0.05, 0.22);
        ink.circle(0.84, 0.66, 0.05, 0.22);
      case LingoArtKind.health:
        ink.rrect(0.38, 0.50, 0.16, 0.36, 0.06, 0.34);
        ink.rrect(0.38, 0.30, 0.10, 0.08, 0.03, 0.26);
        ink.oval(0.66, 0.62, 0.28, 0.16, 0.24, mix: 0.22);
        ink.rrect(0.66, 0.46, 0.22, 0.10, 0.02, 0.18, mix: 0.40);
      case LingoArtKind.time:
        ink.circle(0.50, 0.50, 0.22, 0.30);
        ink.circle(0.50, 0.50, 0.16, 0.16, mix: 0.40);
        ink.rrect(0.50, 0.40, 0.03, 0.12, 0.02, 0.36);
        ink.rrect(0.58, 0.50, 0.10, 0.03, 0.02, 0.30);
        ink.circle(0.76, 0.28, 0.07, 0.22, mix: 0.18);
        ink.oval(0.24, 0.28, 0.12, 0.08, 0.20, mix: 0.28);
      case LingoArtKind.places:
        ink.rrect(0.42, 0.58, 0.36, 0.32, 0.03, 0.32);
        ink.triangle(0.42, 0.30, 0.42, 0.22, 0.30);
        ink.triangle(0.72, 0.46, 0.18, 0.28, 0.28, mix: 0.18);
        ink.rrect(0.72, 0.66, 0.05, 0.16, 0.02, 0.24);
      case LingoArtKind.greetings:
        ink.rrect(0.48, 0.52, 0.40, 0.56, 0.04, 0.22, mix: 0.20);
        ink.rrect(0.48, 0.54, 0.22, 0.46, 0.03, 0.34);
        ink.oval(0.72, 0.62, 0.16, 0.28, 0.26, mix: 0.16);
      case LingoArtKind.introductions:
        ink.oval(0.50, 0.64, 0.42, 0.12, 0.18, mix: 0.30);
        ink.circle(0.40, 0.50, 0.11, 0.34);
        ink.circle(0.60, 0.50, 0.11, 0.28, mix: 0.22);
        ink.oval(0.40, 0.40, 0.16, 0.06, 0.20, mix: 0.36);
        ink.oval(0.60, 0.40, 0.16, 0.06, 0.18, mix: 0.36);
      case LingoArtKind.restaurant:
        ink.circle(0.50, 0.54, 0.24, 0.22, mix: 0.28);
        ink.circle(0.50, 0.54, 0.16, 0.30);
        ink.rrect(0.78, 0.48, 0.04, 0.36, 0.02, 0.24);
        ink.rrect(0.22, 0.48, 0.04, 0.36, 0.02, 0.24, mix: 0.20);
      case LingoArtKind.hotel:
        ink.rrect(0.58, 0.60, 0.40, 0.26, 0.04, 0.30);
        ink.rrect(0.58, 0.44, 0.16, 0.08, 0.03, 0.24);
        ink.rrect(0.30, 0.44, 0.06, 0.22, 0.03, 0.32);
        ink.circle(0.30, 0.30, 0.07, 0.26, mix: 0.18);
      case LingoArtKind.airport:
        ink.rrect(0.42, 0.64, 0.36, 0.20, 0.04, 0.30);
        ink.oval(0.62, 0.34, 0.46, 0.10, 0.26);
        ink.rrect(0.62, 0.34, 0.08, 0.22, 0.03, 0.22, mix: 0.16);
        ink.rrect(0.28, 0.52, 0.18, 0.10, 0.02, 0.20, mix: 0.34);
      case LingoArtKind.directions:
      case LingoArtKind.questions:
        ink.rrect(0.48, 0.52, 0.50, 0.38, 0.04, 0.26, mix: 0.22);
        ink.rrect(0.54, 0.48, 0.36, 0.28, 0.03, 0.20);
        ink.circle(0.62, 0.40, 0.05, 0.40);
        ink.rrect(0.62, 0.48, 0.03, 0.10, 0.02, 0.32);
      case LingoArtKind.doctor:
        ink.circle(0.34, 0.36, 0.08, 0.28);
        ink.circle(0.62, 0.36, 0.08, 0.28);
        ink.arc(0.48, 0.48, 0.28, 0.26);
        ink.rrect(0.50, 0.68, 0.14, 0.22, 0.05, 0.30, mix: 0.16);
      case LingoArtKind.emergency:
        ink.rrect(0.50, 0.56, 0.22, 0.32, 0.05, 0.34);
        ink.rrect(0.50, 0.36, 0.10, 0.10, 0.03, 0.26);
        ink.circle(0.50, 0.28, 0.05, 0.22, mix: 0.18);
        ink.oval(0.72, 0.68, 0.18, 0.16, 0.22, mix: 0.28);
      case LingoArtKind.dailyConversation:
        ink.rrect(0.50, 0.58, 0.42, 0.12, 0.04, 0.30);
        ink.rrect(0.50, 0.70, 0.08, 0.18, 0.03, 0.24);
        ink.rrect(0.28, 0.52, 0.12, 0.28, 0.04, 0.26, mix: 0.16);
        ink.rrect(0.72, 0.52, 0.12, 0.28, 0.04, 0.26, mix: 0.22);
        ink.circle(0.42, 0.50, 0.06, 0.28);
        ink.circle(0.58, 0.50, 0.06, 0.28);
      case LingoArtKind.cafe:
        ink.oval(0.50, 0.66, 0.36, 0.10, 0.20, mix: 0.30);
        ink.circle(0.50, 0.50, 0.13, 0.34);
        ink.oval(0.50, 0.38, 0.18, 0.06, 0.22, mix: 0.36);
        ink.oval(0.72, 0.58, 0.16, 0.10, 0.24, mix: 0.12);
      case LingoArtKind.pharmacy:
        ink.rrect(0.38, 0.52, 0.16, 0.36, 0.06, 0.34);
        ink.rrect(0.38, 0.32, 0.10, 0.08, 0.03, 0.26);
        ink.rrect(0.62, 0.56, 0.14, 0.30, 0.06, 0.28, mix: 0.18);
        ink.rrect(0.62, 0.38, 0.09, 0.07, 0.03, 0.22, mix: 0.18);
        ink.rrect(0.50, 0.74, 0.22, 0.08, 0.02, 0.18, mix: 0.40);
      case LingoArtKind.socialSituations:
        ink.rrect(0.42, 0.52, 0.28, 0.24, 0.04, 0.30);
        ink.rrect(0.42, 0.38, 0.32, 0.08, 0.03, 0.36);
        ink.circle(0.66, 0.62, 0.08, 0.26, mix: 0.16);
        ink.circle(0.78, 0.64, 0.07, 0.24, mix: 0.28);
    }
  }

  @override
  bool shouldRepaint(_CategoryStillLifePainter oldDelegate) {
    return oldDelegate.art != art || oldDelegate.tint != tint;
  }
}

class _Ink {
  _Ink(this.canvas, this.size, this.tint);

  final Canvas canvas;
  final Size size;
  final Color tint;

  double get _s => size.shortestSide;

  Offset _p(double x, double y) => Offset(size.width * x, size.height * y);

  Paint _fill(double alpha, {double mix = 0}) {
    final Color color = mix <= 0
        ? tint
        : Color.lerp(tint, const Color(0xFFFFFFFF), mix) ?? tint;
    return Paint()
      ..color = color.withValues(alpha: alpha)
      ..isAntiAlias = true;
  }

  void circle(double x, double y, double r, double alpha, {double mix = 0}) {
    canvas.drawCircle(_p(x, y), _s * r, _fill(alpha, mix: mix));
  }

  void oval(
    double x,
    double y,
    double w,
    double h,
    double alpha, {
    double mix = 0,
  }) {
    canvas.drawOval(
      Rect.fromCenter(
        center: _p(x, y),
        width: size.width * w,
        height: size.height * h,
      ),
      _fill(alpha, mix: mix),
    );
  }

  void rrect(
    double x,
    double y,
    double w,
    double h,
    double radius,
    double alpha, {
    double mix = 0,
  }) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: _p(x, y),
          width: size.width * w,
          height: size.height * h,
        ),
        Radius.circular(_s * radius),
      ),
      _fill(alpha, mix: mix),
    );
  }

  void triangle(
    double x,
    double y,
    double w,
    double h,
    double alpha, {
    double mix = 0,
  }) {
    final Offset center = _p(x, y);
    final double hw = size.width * w * 0.5;
    final double hh = size.height * h * 0.5;
    final Path path = Path()
      ..moveTo(center.dx, center.dy - hh)
      ..lineTo(center.dx + hw, center.dy + hh)
      ..lineTo(center.dx - hw, center.dy + hh)
      ..close();
    canvas.drawPath(path, _fill(alpha, mix: mix));
  }

  void figure(
    double x,
    double y,
    double w,
    double h,
    double alpha, {
    double mix = 0,
  }) {
    rrect(x, y + h * 0.12, w, h * 0.72, 0.06, alpha, mix: mix);
    circle(x, y - h * 0.28, w * 0.38, alpha, mix: mix);
  }

  void arc(double x, double y, double w, double h) {
    final Rect rect = Rect.fromCenter(
      center: _p(x, y),
      width: size.width * w,
      height: size.height * h,
    );
    canvas.drawArc(rect, math.pi * 0.05, math.pi * 0.9, false, _stroke(0.28));
  }

  Paint _stroke(double alpha) {
    return Paint()
      ..color = tint.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _s * 0.045
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
  }
}
