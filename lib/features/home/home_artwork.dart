import 'package:flutter/material.dart';
import 'package:lingo_core/core/assets/lingo_assets.dart';
import 'package:lingo_core/core/theme/app_theme.dart';
import 'package:lingo_core/core/theme/lingo_tokens.dart';
import 'package:lingo_core/core/widgets/lingo_artwork.dart';

enum HomeDestinationArt {
  alphabet,
  words,
  phrases,
  quiz,
  wrongAnswers,
  appleWatch,
}

String homeArtAssetPath(HomeDestinationArt art) {
  return switch (art) {
    HomeDestinationArt.alphabet => LingoAssets.homeAlphabet,
    HomeDestinationArt.words => LingoAssets.homeWords,
    HomeDestinationArt.phrases => LingoAssets.homePhrases,
    HomeDestinationArt.quiz => LingoAssets.homeQuiz,
    HomeDestinationArt.wrongAnswers => LingoAssets.homeWrongAnswers,
    HomeDestinationArt.appleWatch => LingoAssets.homeAppleWatch,
  };
}

Color homeArtTint(HomeDestinationArt art, LingoColors colors) {
  return switch (art) {
    HomeDestinationArt.alphabet => colors.primary,
    HomeDestinationArt.words => colors.accent,
    HomeDestinationArt.phrases => colors.success,
    HomeDestinationArt.quiz => colors.accent,
    HomeDestinationArt.wrongAnswers => colors.tertiary,
    HomeDestinationArt.appleWatch => colors.success,
  };
}

Alignment homeArtAlignment(HomeDestinationArt art) {
  return switch (art) {
    HomeDestinationArt.alphabet => const Alignment(0, -0.06),
    HomeDestinationArt.words => const Alignment(0, -0.08),
    HomeDestinationArt.phrases => const Alignment(0, -0.08),
    HomeDestinationArt.quiz => const Alignment(0, -0.10),
    HomeDestinationArt.wrongAnswers => const Alignment(0, -0.04),
    HomeDestinationArt.appleWatch => const Alignment(0.02, -0.08),
  };
}

/// Bundled Home still-life with a painted fallback for tests and missing files.
class HomeArtwork extends StatelessWidget {
  const HomeArtwork({
    super.key,
    required this.art,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
  });

  final HomeDestinationArt art;
  final BoxFit fit;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    if (lingoSkipDecodedPhotos) {
      return HomeFallbackArt(art: art);
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        return Image.asset(
          homeArtAssetPath(art),
          fit: fit,
          alignment: alignment,
          cacheWidth: lingoCacheWidth(context, width),
          filterQuality: FilterQuality.medium,
          gaplessPlayback: true,
          errorBuilder:
              (BuildContext context, Object error, StackTrace? stackTrace) {
                return HomeFallbackArt(art: art);
              },
        );
      },
    );
  }
}

class HomeFallbackArt extends StatelessWidget {
  const HomeFallbackArt({super.key, required this.art});

  final HomeDestinationArt art;

  @override
  Widget build(BuildContext context) {
    final LingoColors colors = LingoTheme.of(context).colors;
    final Color tint = homeArtTint(art, colors);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color.lerp(colors.surfaceRaised, tint, 0.16) ??
                colors.surfaceRaised,
            Color.lerp(colors.canvas, tint, 0.10) ?? colors.canvas,
          ],
        ),
      ),
      child: CustomPaint(
        painter: _HomeStillLifePainter(art: art, tint: tint, colors: colors),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _HomeStillLifePainter extends CustomPainter {
  const _HomeStillLifePainter({
    required this.art,
    required this.tint,
    required this.colors,
  });

  final HomeDestinationArt art;
  final Color tint;
  final LingoColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.shortestSide;
    Offset p(double x, double y) => Offset(size.width * x, size.height * y);
    Paint fill(Color color, double alpha) {
      return Paint()
        ..color = color.withValues(alpha: alpha)
        ..isAntiAlias = true;
    }

    Paint mix(double amount, double alpha) {
      final Color color =
          Color.lerp(tint, const Color(0xFFFFFFFF), amount) ?? tint;
      return fill(color, alpha);
    }

    void oval(double x, double y, double w, double h, Paint paint) {
      canvas.drawOval(
        Rect.fromCenter(
          center: p(x, y),
          width: size.width * w,
          height: size.height * h,
        ),
        paint,
      );
    }

    void rrect(
      double x,
      double y,
      double w,
      double h,
      double radius,
      Paint paint,
    ) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: p(x, y),
            width: size.width * w,
            height: size.height * h,
          ),
          Radius.circular(s * radius),
        ),
        paint,
      );
    }

    void glyph(double x, double y, String letter, Color color, double size) {
      final TextPainter painter = TextPainter(
        text: TextSpan(
          text: letter,
          style: TextStyle(
            color: color,
            fontSize: s * size,
            fontWeight: FontWeight.w600,
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        p(x, y) - Offset(painter.width / 2, painter.height / 2),
      );
    }

    switch (art) {
      case HomeDestinationArt.alphabet:
        rrect(0.32, 0.58, 0.28, 0.28, 0.04, mix(0.78, 0.94));
        rrect(0.52, 0.42, 0.26, 0.26, 0.04, mix(0.62, 0.92));
        rrect(0.70, 0.58, 0.26, 0.26, 0.04, mix(0.72, 0.90));
        glyph(0.32, 0.58, 'A', tint, 0.14);
        glyph(0.52, 0.42, 'B', tint, 0.13);
        glyph(0.70, 0.58, 'C', tint, 0.13);
        oval(0.22, 0.32, 0.16, 0.14, mix(0.08, 0.88));
        canvas.save();
        canvas.translate(p(0.86, 0.32).dx, p(0.86, 0.32).dy);
        canvas.rotate(-0.5);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: s * 0.07,
              height: s * 0.36,
            ),
            Radius.circular(s * 0.035),
          ),
          mix(0.18, 0.90),
        );
        canvas.restore();
      case HomeDestinationArt.words:
        rrect(0.42, 0.62, 0.58, 0.38, 0.04, mix(0.22, 0.82));
        rrect(0.50, 0.54, 0.58, 0.38, 0.04, mix(0.48, 0.88));
        rrect(0.58, 0.46, 0.58, 0.38, 0.04, mix(0.78, 0.94));
        rrect(0.50, 0.40, 0.34, 0.018, 0.01, mix(0.12, 0.42));
        rrect(0.46, 0.48, 0.26, 0.016, 0.01, mix(0.12, 0.32));
        rrect(0.82, 0.68, 0.16, 0.16, 0.03, mix(0.42, 0.86));
      case HomeDestinationArt.phrases:
        oval(0.50, 0.68, 0.62, 0.18, mix(0.74, 0.55));
        rrect(0.34, 0.50, 0.38, 0.28, 0.14, mix(0.10, 0.90));
        rrect(0.66, 0.48, 0.38, 0.28, 0.14, mix(0.22, 0.88));
        rrect(0.50, 0.62, 0.18, 0.14, 0.03, mix(0.78, 0.82));
      case HomeDestinationArt.quiz:
        rrect(0.42, 0.52, 0.42, 0.54, 0.05, mix(0.76, 0.92));
        canvas.drawCircle(p(0.70, 0.62), s * 0.16, mix(0.46, 0.78));
        canvas.drawCircle(p(0.74, 0.48), s * 0.14, mix(0.22, 0.84));
        canvas.drawCircle(p(0.68, 0.36), s * 0.12, mix(0.08, 0.90));
        canvas.save();
        canvas.translate(p(0.62, 0.58).dx, p(0.62, 0.58).dy);
        canvas.rotate(-0.4);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: s * 0.06,
              height: s * 0.40,
            ),
            Radius.circular(s * 0.03),
          ),
          mix(0.18, 0.88),
        );
        canvas.restore();
      case HomeDestinationArt.wrongAnswers:
        rrect(0.38, 0.58, 0.48, 0.42, 0.05, mix(0.22, 0.86));
        rrect(0.58, 0.48, 0.50, 0.44, 0.05, mix(0.78, 0.94));
        oval(0.78, 0.36, 0.18, 0.16, mix(0.18, 0.88));
        final Paint mark = Paint()
          ..color = tint.withValues(alpha: 0.86)
          ..strokeWidth = s * 0.028
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke
          ..isAntiAlias = true;
        final Offset checkAt = p(0.72, 0.42);
        canvas.drawPath(
          Path()
            ..moveTo(checkAt.dx - s * 0.05, checkAt.dy)
            ..lineTo(checkAt.dx - s * 0.01, checkAt.dy + s * 0.045)
            ..lineTo(checkAt.dx + s * 0.07, checkAt.dy - s * 0.05),
          mark,
        );
        final Offset retryAt = p(0.32, 0.52);
        canvas.drawLine(
          retryAt + Offset(-s * 0.05, -s * 0.05),
          retryAt + Offset(s * 0.05, s * 0.05),
          mark,
        );
        canvas.drawLine(
          retryAt + Offset(s * 0.05, -s * 0.05),
          retryAt + Offset(-s * 0.05, s * 0.05),
          mark,
        );
      case HomeDestinationArt.appleWatch:
        rrect(0.40, 0.50, 0.42, 0.48, 0.12, mix(0.10, 0.90));
        rrect(0.40, 0.50, 0.28, 0.32, 0.08, mix(0.78, 0.92));
        oval(0.40, 0.28, 0.16, 0.08, mix(0.22, 0.55));
        oval(0.40, 0.72, 0.16, 0.08, mix(0.22, 0.55));
        rrect(0.72, 0.46, 0.28, 0.36, 0.04, mix(0.70, 0.90));
        oval(0.74, 0.68, 0.16, 0.12, mix(0.22, 0.50));
    }
  }

  @override
  bool shouldRepaint(covariant _HomeStillLifePainter oldDelegate) {
    return oldDelegate.art != art ||
        oldDelegate.tint != tint ||
        oldDelegate.colors != colors;
  }
}
