import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Lightweight illustrated tab marks. One stationery family, no icon font.
enum LingoNavGlyph { home, words, phrases, favorites, settings }

class LingoNavGlyphIcon extends StatelessWidget {
  const LingoNavGlyphIcon({
    super.key,
    required this.glyph,
    required this.color,
    this.highlight = const Color(0xFFFFFBF6),
    this.selected = false,
    this.size = 22,
  });

  final LingoNavGlyph glyph;
  final Color color;
  final Color highlight;
  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _NavGlyphPainter(
            glyph: glyph,
            color: color,
            highlight: highlight,
            selected: selected,
          ),
        ),
      ),
    );
  }
}

class _NavGlyphPainter extends CustomPainter {
  const _NavGlyphPainter({
    required this.glyph,
    required this.color,
    required this.highlight,
    required this.selected,
  });

  final LingoNavGlyph glyph;
  final Color color;
  final Color highlight;
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final Paint stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = selected
          ? (w * 0.072).clamp(1.35, 1.7)
          : (w * 0.082).clamp(1.5, 1.9)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    final Paint fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    switch (glyph) {
      case LingoNavGlyph.home:
        _paintHome(canvas, size, stroke, fill);
      case LingoNavGlyph.words:
        _paintWords(canvas, size, stroke, fill);
      case LingoNavGlyph.phrases:
        _paintPhrases(canvas, size, stroke, fill);
      case LingoNavGlyph.favorites:
        _paintFavorites(canvas, size, stroke, fill);
      case LingoNavGlyph.settings:
        _paintSettings(canvas, size, stroke, fill);
    }
  }

  Paint get _highlight {
    return Paint()
      ..color = highlight
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
  }

  void _paintHome(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final double w = size.width;
    final Path roof = Path()
      ..moveTo(w * 0.08, w * 0.46)
      ..lineTo(w * 0.50, w * 0.10)
      ..lineTo(w * 0.92, w * 0.46);
    final Path house = Path()
      ..moveTo(w * 0.08, w * 0.46)
      ..lineTo(w * 0.50, w * 0.10)
      ..lineTo(w * 0.92, w * 0.46)
      ..lineTo(w * 0.78, w * 0.46)
      ..lineTo(w * 0.78, w * 0.88)
      ..lineTo(w * 0.22, w * 0.88)
      ..lineTo(w * 0.22, w * 0.46)
      ..close();
    final RRect chimney = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.66, w * 0.16, w * 0.78, w * 0.34),
      Radius.circular(w * 0.035),
    );
    final RRect door = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.42, w * 0.62, w * 0.58, w * 0.88),
      Radius.circular(w * 0.05),
    );
    final RRect leftWindow = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.30, w * 0.54, w * 0.40, w * 0.66),
      Radius.circular(w * 0.03),
    );
    final RRect rightWindow = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.60, w * 0.54, w * 0.70, w * 0.66),
      Radius.circular(w * 0.03),
    );

    if (selected) {
      fill.color = color;
      canvas.drawRRect(chimney, fill);
      canvas.drawPath(house, fill);
      canvas.drawRRect(door, _highlight);
      canvas.drawRRect(leftWindow, _highlight);
      canvas.drawRRect(rightWindow, _highlight);
    }
    canvas.drawRRect(chimney, stroke);
    canvas.drawPath(roof, stroke);
    canvas.drawLine(
      Offset(w * 0.22, w * 0.46),
      Offset(w * 0.22, w * 0.88),
      stroke,
    );
    canvas.drawLine(
      Offset(w * 0.78, w * 0.46),
      Offset(w * 0.78, w * 0.88),
      stroke,
    );
    canvas.drawLine(
      Offset(w * 0.22, w * 0.88),
      Offset(w * 0.78, w * 0.88),
      stroke,
    );
    canvas.drawRRect(door, stroke);
    canvas.drawRRect(leftWindow, stroke);
    canvas.drawRRect(rightWindow, stroke);
  }

  void _paintWords(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final double w = size.width;
    final Path left = Path()
      ..moveTo(w * 0.50, w * 0.18)
      ..lineTo(w * 0.16, w * 0.26)
      ..quadraticBezierTo(w * 0.08, w * 0.28, w * 0.08, w * 0.38)
      ..lineTo(w * 0.08, w * 0.78)
      ..quadraticBezierTo(w * 0.08, w * 0.88, w * 0.20, w * 0.86)
      ..lineTo(w * 0.50, w * 0.76)
      ..close();
    final Path right = Path()
      ..moveTo(w * 0.50, w * 0.18)
      ..lineTo(w * 0.84, w * 0.26)
      ..quadraticBezierTo(w * 0.92, w * 0.28, w * 0.92, w * 0.38)
      ..lineTo(w * 0.92, w * 0.78)
      ..quadraticBezierTo(w * 0.92, w * 0.88, w * 0.80, w * 0.86)
      ..lineTo(w * 0.50, w * 0.76)
      ..close();

    if (selected) {
      fill.color = color.withValues(alpha: 0.20);
      canvas.drawPath(left, fill);
      fill.color = color.withValues(alpha: 0.34);
      canvas.drawPath(right, fill);
    }
    canvas.drawPath(left, stroke);
    canvas.drawPath(right, stroke);
    canvas.drawLine(
      Offset(w * 0.50, w * 0.20),
      Offset(w * 0.50, w * 0.76),
      stroke,
    );
    final Paint line = Paint()
      ..color = selected ? highlight : color
      ..style = PaintingStyle.stroke
      ..strokeWidth = (stroke.strokeWidth * 0.85).clamp(1.1, 1.5)
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    canvas.drawLine(
      Offset(w * 0.22, w * 0.46),
      Offset(w * 0.40, w * 0.44),
      line,
    );
    canvas.drawLine(
      Offset(w * 0.22, w * 0.58),
      Offset(w * 0.38, w * 0.56),
      line,
    );
    canvas.drawLine(
      Offset(w * 0.60, w * 0.44),
      Offset(w * 0.78, w * 0.46),
      line,
    );
    if (selected) {
      canvas.drawLine(
        Offset(w * 0.60, w * 0.56),
        Offset(w * 0.76, w * 0.58),
        line,
      );
    }
  }

  void _paintPhrases(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final double w = size.width;
    final RRect rear = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.34, w * 0.10, w * 0.54, w * 0.40),
      Radius.circular(w * 0.18),
    );
    final RRect front = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.10, w * 0.36, w * 0.58, w * 0.44),
      Radius.circular(w * 0.18),
    );
    final Path rearTail = Path()
      ..moveTo(w * 0.72, w * 0.44)
      ..lineTo(w * 0.86, w * 0.58)
      ..lineTo(w * 0.62, w * 0.48)
      ..close();
    final Path frontTail = Path()
      ..moveTo(w * 0.22, w * 0.74)
      ..lineTo(w * 0.14, w * 0.92)
      ..lineTo(w * 0.36, w * 0.78)
      ..close();

    if (selected) {
      fill.color = color.withValues(alpha: 0.20);
      canvas.drawRRect(rear, fill);
      canvas.drawPath(rearTail, fill);
      fill.color = color.withValues(alpha: 0.36);
      canvas.drawRRect(front, fill);
      canvas.drawPath(frontTail, fill);
    }
    canvas.drawRRect(rear, stroke);
    canvas.drawPath(rearTail, stroke);
    canvas.drawRRect(front, stroke);
    canvas.drawPath(frontTail, stroke);

    final Paint dots = Paint()
      ..color = selected ? highlight : color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final double dot = selected ? w * 0.045 : w * 0.038;
    canvas.drawCircle(Offset(w * 0.28, w * 0.58), dot, dots);
    canvas.drawCircle(Offset(w * 0.39, w * 0.58), dot, dots);
    canvas.drawCircle(Offset(w * 0.50, w * 0.58), dot, dots);
  }

  void _paintFavorites(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final Path ribbon = _bookmarkPath(size);
    final double w = size.width;
    if (selected) {
      fill.color = color.withValues(alpha: 0.94);
      canvas.drawPath(ribbon, fill);
      canvas.drawCircle(Offset(w * 0.50, w * 0.30), w * 0.08, _highlight);
      final Paint stitch = Paint()
        ..color = highlight
        ..style = PaintingStyle.stroke
        ..strokeWidth = (w * 0.065).clamp(1.15, 1.5)
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;
      canvas.drawLine(
        Offset(w * 0.50, w * 0.42),
        Offset(w * 0.50, w * 0.64),
        stitch,
      );
      return;
    }
    canvas.drawPath(ribbon, stroke);
    canvas.drawCircle(Offset(w * 0.50, w * 0.30), w * 0.07, stroke);
    canvas.drawLine(
      Offset(w * 0.50, w * 0.42),
      Offset(w * 0.50, w * 0.62),
      stroke,
    );
  }

  void _paintSettings(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final double w = size.width;
    final Offset center = Offset(w / 2, w / 2);
    final double hub = w * 0.10;
    final double ring = w * 0.24;
    if (selected) {
      canvas.drawCircle(
        center,
        ring + w * 0.08,
        Paint()..color = color.withValues(alpha: 0.16),
      );
      canvas.drawCircle(
        center,
        ring,
        fill..color = color.withValues(alpha: 0.28),
      );
      canvas.drawCircle(center, hub + w * 0.02, fill..color = color);
    }
    canvas.drawCircle(center, ring, stroke);
    if (!selected) {
      canvas.drawCircle(center, hub, stroke);
    }

    const int ticks = 8;
    for (int index = 0; index < ticks; index++) {
      final double angle = index * (2 * math.pi / ticks) - math.pi / 2;
      final Offset dir = Offset(math.cos(angle), math.sin(angle));
      final bool cardinal = index.isEven;
      final double inner = ring + w * 0.02;
      final double outer = ring + (cardinal ? w * 0.16 : w * 0.11);
      canvas.drawLine(center + dir * inner, center + dir * outer, stroke);
    }

    final Path needle = Path()
      ..moveTo(center.dx, center.dy - w * 0.18)
      ..lineTo(center.dx + w * 0.045, center.dy + w * 0.02)
      ..lineTo(center.dx, center.dy + w * 0.10)
      ..lineTo(center.dx - w * 0.045, center.dy + w * 0.02)
      ..close();
    if (selected) {
      canvas.drawPath(needle, _highlight);
    }
    canvas.drawPath(needle, stroke);
  }

  Path _bookmarkPath(Size size) {
    final double w = size.width;
    final double h = size.height;
    return Path()
      ..moveTo(w * 0.28, h * 0.10)
      ..lineTo(w * 0.72, h * 0.10)
      ..quadraticBezierTo(w * 0.78, h * 0.10, w * 0.78, h * 0.16)
      ..lineTo(w * 0.78, h * 0.90)
      ..lineTo(w * 0.50, h * 0.70)
      ..lineTo(w * 0.22, h * 0.90)
      ..lineTo(w * 0.22, h * 0.16)
      ..quadraticBezierTo(w * 0.22, h * 0.10, w * 0.28, h * 0.10)
      ..close();
  }

  @override
  bool shouldRepaint(covariant _NavGlyphPainter oldDelegate) {
    return oldDelegate.glyph != glyph ||
        oldDelegate.color != color ||
        oldDelegate.highlight != highlight ||
        oldDelegate.selected != selected;
  }
}
