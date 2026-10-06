import 'package:flutter/material.dart';
import 'package:lingo_core/core/feedback/feedback_service.dart';
import 'package:lingo_core/core/theme/app_theme.dart';
import 'package:lingo_core/core/theme/lingo_tokens.dart';
import 'package:lingo_core/core/widgets/lingo_widgets.dart';
import 'package:lingo_core/domain/content_models.dart';

TextDirection quizTextDirection(ContentTextDirection direction) {
  return direction == ContentTextDirection.rtl
      ? TextDirection.rtl
      : TextDirection.ltr;
}

/// Compact back control plus optional progress. Avoids a repeated Quiz title.
class QuizTopBar extends StatelessWidget {
  const QuizTopBar({super.key, this.current, this.total});

  static const ValueKey<String> backKey = ValueKey<String>('quiz-back');

  final int? current;
  final int? total;

  @override
  Widget build(BuildContext context) {
    final LingoMetrics metrics = LingoMetrics.of(context);
    final int? current = this.current;
    final int? total = this.total;
    final double top = MediaQuery.paddingOf(context).top;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        LingoSpacing.sm,
        top,
        metrics.horizontalGutter,
        LingoSpacing.xs,
      ),
      child: SizedBox(
        height: LingoSpacing.minTapTarget,
        child: Row(
          children: <Widget>[
            const _QuizBackButton(key: backKey),
            if (current != null && total != null)
              Expanded(
                child: QuizProgressBar(current: current, total: total),
              )
            else
              const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _QuizBackButton extends StatelessWidget {
  const _QuizBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);
    final String tooltip = MaterialLocalizations.of(context).backButtonTooltip;
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: LingoTapScale(
          onPressed: () => Navigator.of(context).maybePop(),
          child: SizedBox(
            width: LingoSpacing.minTapTarget,
            height: LingoSpacing.minTapTarget,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Transform.scale(
                scaleX: Directionality.of(context) == TextDirection.rtl
                    ? -1
                    : 1,
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 17,
                  color: theme.colors.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class QuizProgressBar extends StatelessWidget {
  const QuizProgressBar({
    super.key,
    required this.current,
    required this.total,
  });

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final String label = '$current / $total';
    return Semantics(
      label: label,
      child: Row(
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: LingoTheme.of(context).colors.onSurfaceMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: LingoSpacing.sm),
          Expanded(
            child: LingoProgressIndicator(
              value: total <= 0 ? 0 : current / total,
            ),
          ),
        ],
      ),
    );
  }
}

/// Token chip that uses the shared selection SFX and haptic.
class QuizTokenChip extends StatelessWidget {
  const QuizTokenChip({
    super.key,
    required this.label,
    required this.onPressed,
    this.selected = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);
    final Color face = selected
        ? theme.colors.primaryContainer
        : theme.colors.surfaceRaised;
    final Color foreground = selected
        ? theme.colors.onPrimaryContainer
        : theme.colors.onSurface;
    final double maxChipWidth = MediaQuery.sizeOf(context).width * 0.72;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxChipWidth),
      child: LingoPressable(
        onPressed: onPressed == null
            ? null
            : () {
                onPressed?.call();
                FeedbackService.play(FeedbackEvent.selection);
              },
        enableHaptics: false,
        color: face,
        depth: selected ? LingoElevation.flat : LingoElevation.rest,
        borderRadius: LingoRadii.chip,
        padding: const EdgeInsets.symmetric(
          horizontal: LingoSpacing.md,
          vertical: LingoSpacing.sm,
        ),
        minHeight: LingoSpacing.minTapTarget,
        border: Border.all(
          color: selected ? theme.colors.primary : theme.colors.hairline,
          width: selected ? 1.6 : 1,
        ),
        semanticLabel: label,
        semanticButton: onPressed != null,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: foreground,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          ),
          softWrap: true,
        ),
      ),
    );
  }
}

/// Premium, restrained correct/wrong surface.
class QuizOutcomePanel extends StatelessWidget {
  const QuizOutcomePanel({
    super.key,
    required this.isCorrect,
    required this.title,
    required this.animation,
    required this.reduceMotion,
    this.detail,
    this.detailDirection = ContentTextDirection.ltr,
  });

  final bool isCorrect;
  final String title;
  final String? detail;
  final ContentTextDirection detailDirection;
  final Animation<double> animation;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);
    final String? detail = this.detail;
    final Animation<double> curved = CurvedAnimation(
      parent: animation,
      curve: LingoMotion.entranceCurve,
    );

    Widget panel = DecoratedBox(
      decoration: BoxDecoration(
        color: isCorrect
            ? theme.colors.successContainer
            : theme.colors.dangerContainer.withValues(alpha: 0.86),
        borderRadius: LingoRadii.card,
        border: Border.all(
          color: isCorrect
              ? theme.colors.success.withValues(alpha: 0.48)
              : theme.colors.danger.withValues(alpha: 0.34),
          width: 1.1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: LingoSpacing.lg,
          vertical: LingoSpacing.md,
        ),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                QuizAnswerMark(
                  isCorrect: isCorrect,
                  animation: curved,
                  burst: isCorrect,
                ),
                const SizedBox(width: LingoSpacing.md),
                Flexible(
                  child: Text(
                    title,
                    key: Key(
                      isCorrect ? 'quiz-outcome-correct' : 'quiz-outcome-wrong',
                    ),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isCorrect
                          ? theme.colors.success
                          : theme.colors.danger,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            if (!isCorrect && detail != null && detail.isNotEmpty) ...<Widget>[
              const SizedBox(height: LingoSpacing.sm),
              Directionality(
                textDirection: quizTextDirection(detailDirection),
                child: Text(
                  detail,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                  softWrap: true,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (reduceMotion) {
      return Semantics(container: true, liveRegion: true, child: panel);
    }

    return Semantics(
      container: true,
      liveRegion: true,
      child: AnimatedBuilder(
        animation: curved,
        builder: (BuildContext context, Widget? child) {
          final double t = curved.value;
          final Color glowColor = isCorrect
              ? theme.colors.success
              : theme.colors.danger;
          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: LingoRadii.card,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: glowColor.withValues(
                    alpha: (isCorrect ? 0.20 : 0.08) * t,
                  ),
                  blurRadius: (isCorrect ? 20 : 10) * t,
                  spreadRadius: isCorrect ? 0.6 : 0.15,
                ),
              ],
            ),
            child: child,
          );
        },
        child: panel,
      ),
    );
  }
}

class QuizAnswerMark extends StatelessWidget {
  const QuizAnswerMark({
    super.key,
    required this.isCorrect,
    required this.animation,
    this.tagged = true,
    this.burst = false,
  });

  final bool isCorrect;
  final Animation<double> animation;
  final bool tagged;
  final bool burst;

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);
    final Color color = isCorrect ? theme.colors.success : theme.colors.danger;
    final Color onColor = isCorrect
        ? theme.colors.onSuccess
        : theme.colors.onDanger;
    final double size = burst ? 36 : 28;
    final Widget mark = AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final double t = animation.value.clamp(0.0, 1.0);
        final double scale = 0.78 + 0.22 * Curves.easeOutBack.transform(t);
        return Transform.scale(scale: scale, child: child);
      },
      child: SizedBox(
        key: tagged
            ? Key(isCorrect ? 'quiz-success-mark' : 'quiz-wrong-mark')
            : null,
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: color.withValues(alpha: 0.28),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: CustomPaint(
            painter: _QuizMarkPainter(isCorrect: isCorrect, color: onColor),
          ),
        ),
      ),
    );

    if (!burst) {
      return mark;
    }

    return SizedBox(
      key: tagged ? const Key('quiz-success-burst') : null,
      width: size + 18,
      height: size + 18,
      child: AnimatedBuilder(
        animation: animation,
        builder: (BuildContext context, Widget? child) {
          return CustomPaint(
            painter: _QuizBurstPainter(progress: animation.value, color: color),
            child: Center(child: child),
          );
        },
        child: mark,
      ),
    );
  }
}

class _QuizBurstPainter extends CustomPainter {
  const _QuizBurstPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) {
      return;
    }
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double maxRadius = size.shortestSide / 2;
    final Paint ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..isAntiAlias = true;
    for (final double delay in <double>[0, 0.22]) {
      final double local = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (local <= 0) {
        continue;
      }
      ring.color = color.withValues(alpha: 0.28 * (1 - local));
      canvas.drawCircle(center, 10 + (maxRadius - 10) * local, ring);
    }
  }

  @override
  bool shouldRepaint(covariant _QuizBurstPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _QuizMarkPainter extends CustomPainter {
  const _QuizMarkPainter({required this.isCorrect, required this.color});

  final bool isCorrect;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    final double w = size.width;
    final Path path = Path();
    if (isCorrect) {
      path
        ..moveTo(w * 0.28, w * 0.52)
        ..lineTo(w * 0.44, w * 0.68)
        ..lineTo(w * 0.74, w * 0.34);
    } else {
      path
        ..moveTo(w * 0.34, w * 0.34)
        ..lineTo(w * 0.66, w * 0.66)
        ..moveTo(w * 0.66, w * 0.34)
        ..lineTo(w * 0.34, w * 0.66);
    }
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _QuizMarkPainter oldDelegate) {
    return oldDelegate.isCorrect != isCorrect || oldDelegate.color != color;
  }
}

/// Trailing mark for Quiz source and mode cards.
class QuizPickerChevron extends StatelessWidget {
  const QuizPickerChevron({super.key});

  @override
  Widget build(BuildContext context) {
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: LingoSpacing.sm),
      child: Icon(
        rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
        color: LingoTheme.of(context).colors.onSurfaceFaint,
        size: LingoIconSize.md,
      ),
    );
  }
}
