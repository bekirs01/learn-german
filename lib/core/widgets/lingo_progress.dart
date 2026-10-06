import 'package:flutter/material.dart';
import 'package:lingo_core/core/theme/app_theme.dart';
import 'package:lingo_core/core/theme/lingo_tokens.dart';

enum LingoProgressKind { linear, circular }

class LingoProgressIndicator extends StatefulWidget {
  const LingoProgressIndicator({
    super.key,
    required this.value,
    this.kind = LingoProgressKind.linear,
    this.size = 28,
  });

  /// Progress from 0.0 to 1.0.
  final double value;
  final LingoProgressKind kind;
  final double size;

  @override
  State<LingoProgressIndicator> createState() => _LingoProgressIndicatorState();
}

class _LingoProgressIndicatorState extends State<LingoProgressIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: LingoMotion.progress,
    );
    _animation = const AlwaysStoppedAnimation<double>(0.0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _animateTo(widget.value);
    }
  }

  @override
  void didUpdateWidget(covariant LingoProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animateTo(widget.value);
    }
  }

  void _animateTo(double next) {
    final double target = next.clamp(0.0, 1.0);
    final LingoMetrics metrics = LingoMetrics.of(context);
    final double begin = _animation.value;
    _controller.duration = metrics.motion(LingoMotion.progress);
    _animation = Tween<double>(begin: begin, end: target).animate(
      CurvedAnimation(parent: _controller, curve: LingoMotion.standardCurve),
    );
    if (metrics.reduceMotion) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double animated = _animation.value.clamp(0.0, 1.0);
        if (widget.kind == LingoProgressKind.circular) {
          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: CircularProgressIndicator(
              value: animated,
              strokeWidth: 3.2,
              color: theme.colors.primary,
              backgroundColor: theme.colors.surfaceSunken,
              strokeCap: StrokeCap.round,
            ),
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(LingoRadii.pill),
          child: SizedBox(
            height: LingoSpacing.sm,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    ColoredBox(color: theme.colors.surfaceSunken),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: SizedBox(
                        width: constraints.maxWidth * animated,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: theme.gradients.progress,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// Thin trailing-edge reading progress for long learning lists.
///
/// Not a desktop scrollbar: it only shows how far the list has been revealed
/// and stays out of the way when the content already fits.
class LingoEdgeScrollProgress extends StatefulWidget {
  const LingoEdgeScrollProgress({
    super.key,
    required this.child,
    this.enabled = true,
    this.minOverflow = 72,
  });

  final Widget child;
  final bool enabled;
  final double minOverflow;

  @override
  State<LingoEdgeScrollProgress> createState() =>
      _LingoEdgeScrollProgressState();
}

class _LingoEdgeScrollProgressState extends State<LingoEdgeScrollProgress> {
  final _EdgeScrollTick _tick = _EdgeScrollTick();

  @override
  void dispose() {
    _tick.dispose();
    super.dispose();
  }

  bool _onNotification(Notification notification) {
    if (!widget.enabled) {
      return false;
    }
    if (notification is ScrollMetricsNotification) {
      if (notification.depth == 0) {
        _sync(notification.metrics);
      }
      return false;
    }
    if (notification is ScrollNotification && notification.depth == 0) {
      _sync(notification.metrics);
    }
    return false;
  }

  void _sync(ScrollMetrics metrics) {
    if (metrics.axis != Axis.vertical) {
      return;
    }
    final double overflow = metrics.maxScrollExtent;
    final bool visible = overflow >= widget.minOverflow;
    final double total = overflow + metrics.viewportDimension;
    final double revealed = (metrics.pixels + metrics.viewportDimension).clamp(
      0.0,
      total,
    );
    final double progress = total <= 0 ? 0 : (revealed / total).clamp(0.0, 1.0);
    _tick.set(progress: progress, visible: visible);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return NotificationListener<Notification>(
      onNotification: _onNotification,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          widget.child,
          PositionedDirectional(
            top: LingoSpacing.lg,
            bottom: LingoSpacing.lg,
            end: 1,
            width: 2,
            child: ListenableBuilder(
              listenable: _tick,
              builder: (BuildContext context, Widget? _) {
                return _EdgeProgressRail(
                  progress: _tick.progress,
                  visible: _tick.visible,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EdgeScrollTick extends ChangeNotifier {
  double progress = 0;
  bool visible = false;

  void set({required double progress, required bool visible}) {
    if (this.visible == visible && (this.progress - progress).abs() < 0.004) {
      return;
    }
    this.progress = progress;
    this.visible = visible;
    notifyListeners();
  }
}

class _EdgeProgressRail extends StatelessWidget {
  const _EdgeProgressRail({required this.progress, required this.visible});

  final double progress;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox.shrink();
    }
    final LingoTheme theme = LingoTheme.of(context);
    return IgnorePointer(
      child: DecoratedBox(
        key: const ValueKey<String>('list-scroll-progress'),
        decoration: BoxDecoration(
          color: theme.colors.onSurface.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(LingoRadii.pill),
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: FractionallySizedBox(
            heightFactor: progress.clamp(0.1, 1.0),
            widthFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colors.primary.withValues(alpha: 0.38),
                borderRadius: BorderRadius.circular(LingoRadii.pill),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
