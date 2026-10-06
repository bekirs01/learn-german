import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:lingo_core/core/theme/app_theme.dart';
import 'package:lingo_core/core/theme/lingo_tokens.dart';

/// Pointer-down press tracking that does not wait for the tap gesture arena.
mixin LingoImmediatePressState<T extends StatefulWidget>
    on State<T>, TickerProvider {
  late final AnimationController pressAnimation;

  bool get pressInteractive;

  Offset? _pressOrigin;
  int? _pressPointer;

  @override
  void initState() {
    super.initState();
    pressAnimation = AnimationController(
      vsync: this,
      duration: LingoMotion.pressDown,
      reverseDuration: LingoMotion.pressUp,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final LingoMetrics metrics = LingoMetrics.of(context);
    pressAnimation.duration = metrics.motion(LingoMotion.pressDown);
    pressAnimation.reverseDuration = metrics.motion(LingoMotion.pressUp);
  }

  @override
  void dispose() {
    pressAnimation.dispose();
    super.dispose();
  }

  @visibleForTesting
  bool get debugPressed => pressAnimation.value > 0;

  void syncPressAvailability() {
    if (pressInteractive || pressAnimation.value == 0) {
      return;
    }
    _clearPressPointer();
    pressAnimation.value = 0;
  }

  void handlePressPointerDown(PointerDownEvent event) {
    if (!pressInteractive) {
      return;
    }
    _pressPointer = event.pointer;
    _pressOrigin = event.position;
    _snapOrForward();
  }

  void handlePressPointerMove(PointerMoveEvent event) {
    if (!pressInteractive ||
        event.pointer != _pressPointer ||
        _pressOrigin == null) {
      return;
    }
    if ((event.position - _pressOrigin!).distance <= kTouchSlop) {
      return;
    }
    _clearPressPointer();
    _snapOrReverse();
  }

  void handlePressPointerUp(PointerUpEvent event) {
    if (event.pointer != _pressPointer) {
      return;
    }
    _clearPressPointer();
    _snapOrReverse();
  }

  void handlePressPointerCancel(PointerCancelEvent event) {
    if (event.pointer != _pressPointer) {
      return;
    }
    _clearPressPointer();
    _snapOrReverse();
  }

  void _clearPressPointer() {
    _pressPointer = null;
    _pressOrigin = null;
  }

  void _snapOrForward() {
    if (pressAnimation.duration == Duration.zero) {
      pressAnimation.value = 1;
      return;
    }
    if (pressAnimation.value < 0.45) {
      pressAnimation.value = 0.45;
    }
    pressAnimation.forward();
  }

  void _snapOrReverse() {
    if (pressAnimation.reverseDuration == Duration.zero ||
        pressAnimation.duration == Duration.zero) {
      pressAnimation.value = 0;
      return;
    }
    pressAnimation.reverse();
  }

  Widget wrapImmediatePress({required Widget child, VoidCallback? onTap}) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: pressInteractive ? handlePressPointerDown : null,
      onPointerMove: pressInteractive ? handlePressPointerMove : null,
      onPointerUp: pressInteractive ? handlePressPointerUp : null,
      onPointerCancel: pressInteractive ? handlePressPointerCancel : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: pressInteractive ? onTap : null,
        child: child,
      ),
    );
  }
}

/// Scale-only press used by rows that should not have a 3D lip.
class LingoTapScale extends StatefulWidget {
  const LingoTapScale({
    super.key,
    required this.child,
    this.onPressed,
    this.enabled = true,
    this.pressedScale,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final bool enabled;
  final double? pressedScale;

  @override
  State<LingoTapScale> createState() => LingoTapScaleState();
}

class LingoTapScaleState extends State<LingoTapScale>
    with SingleTickerProviderStateMixin, LingoImmediatePressState {
  @override
  bool get pressInteractive => widget.enabled && widget.onPressed != null;

  @override
  void didUpdateWidget(LingoTapScale oldWidget) {
    super.didUpdateWidget(oldWidget);
    syncPressAvailability();
  }

  @override
  Widget build(BuildContext context) {
    final double pressScale =
        widget.pressedScale ?? LingoTheme.of(context).identity.pressScale;

    return wrapImmediatePress(
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: pressAnimation,
        child: widget.child,
        builder: (BuildContext context, Widget? child) {
          final double t = pressInteractive ? pressAnimation.value : 0;
          final double scale = 1 + (pressScale - 1) * t;
          return Transform.scale(
            key: const ValueKey<String>('lingo-tap-scale-transform'),
            scale: scale,
            child: child,
          );
        },
      ),
    );
  }
}
