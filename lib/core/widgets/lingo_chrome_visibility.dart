import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:lingo_core/core/theme/lingo_tokens.dart';

/// Idle / interaction policy for floating chrome such as the bottom nav.
///
/// 2.8s is long enough to finish reading a just-opened card, and short enough
/// that the bar does not linger over content. VoiceOver / TalkBack locks the
/// chrome visible so destinations are never lost.
final class LingoChromeVisibilityController extends ChangeNotifier {
  LingoChromeVisibilityController({
    this.hideAfter = LingoMotion.chromeIdleHide,
  });

  final Duration hideAfter;

  bool _visible = true;
  bool _locked = false;
  bool _scrollConsumedPointer = false;
  Timer? _hideTimer;

  bool get visible => _visible;

  /// When true, auto-hide is disabled and the chrome stays on screen.
  void setLocked(bool locked) {
    if (_locked == locked) {
      return;
    }
    _locked = locked;
    if (locked) {
      reveal(restartIdle: false);
      return;
    }
    _scheduleHide();
  }

  void startIdleClock() {
    if (_visible) {
      _scheduleHide();
    }
  }

  void reveal({bool restartIdle = true}) {
    _hideTimer?.cancel();
    _hideTimer = null;
    if (!_visible) {
      _visible = true;
      notifyListeners();
    }
    if (restartIdle) {
      _scheduleHide();
    }
  }

  void conceal() {
    if (_locked || !_visible) {
      _hideTimer?.cancel();
      _hideTimer = null;
      return;
    }
    _hideTimer?.cancel();
    _hideTimer = null;
    _visible = false;
    notifyListeners();
  }

  void onTabSelected() {
    _scrollConsumedPointer = false;
    reveal();
  }

  void handlePointerDown() {
    _scrollConsumedPointer = false;
    if (_locked) {
      return;
    }
    if (_visible) {
      _hideTimer?.cancel();
      _hideTimer = null;
    }
  }

  void handlePointerUp({required bool isTap}) {
    if (_locked) {
      return;
    }
    if (_scrollConsumedPointer) {
      _scrollConsumedPointer = false;
      if (_visible) {
        _scheduleHide();
      }
      return;
    }
    if (isTap || !_visible) {
      reveal();
      return;
    }
    _scheduleHide();
  }

  void handlePointerCancel() {
    _scrollConsumedPointer = false;
    if (_visible) {
      _scheduleHide();
    }
  }

  void handleScrollNotification(ScrollNotification notification) {
    if (_locked || notification.metrics.axis != Axis.vertical) {
      return;
    }

    if (notification is UserScrollNotification) {
      switch (notification.direction) {
        case ScrollDirection.reverse:
          _scrollConsumedPointer = true;
          conceal();
        case ScrollDirection.forward:
          _scrollConsumedPointer = true;
          reveal();
        case ScrollDirection.idle:
          break;
      }
      return;
    }

    if (notification is ScrollEndNotification) {
      final ScrollMetrics metrics = notification.metrics;
      final bool reachedEnd =
          metrics.maxScrollExtent > 0 &&
          metrics.pixels >= metrics.maxScrollExtent - 24;
      if (reachedEnd) {
        reveal();
        return;
      }
      if (_visible) {
        _scheduleHide();
      }
    }
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    if (_locked || !_visible) {
      _hideTimer = null;
      return;
    }
    _hideTimer = Timer(hideAfter, conceal);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }
}

/// Routes pointer and scroll activity from nested pages to [controller].
class LingoChromeInteractionListener extends StatefulWidget {
  const LingoChromeInteractionListener({
    super.key,
    required this.controller,
    required this.child,
  });

  final LingoChromeVisibilityController controller;
  final Widget child;

  @override
  State<LingoChromeInteractionListener> createState() =>
      _LingoChromeInteractionListenerState();
}

class _LingoChromeInteractionListenerState
    extends State<LingoChromeInteractionListener> {
  static const double _tapSlop = 12;

  Offset? _downPosition;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (PointerDownEvent event) {
        _downPosition = event.position;
        final Size size = MediaQuery.sizeOf(context);
        final double bottomEdge =
            size.height - MediaQuery.paddingOf(context).bottom - 88;
        if (event.position.dy >= bottomEdge && !widget.controller.visible) {
          widget.controller.reveal();
        } else {
          widget.controller.handlePointerDown();
        }
      },
      onPointerUp: (PointerUpEvent event) {
        final Offset? start = _downPosition;
        _downPosition = null;
        final bool isTap =
            start == null || (event.position - start).distance <= _tapSlop;
        widget.controller.handlePointerUp(isTap: isTap);
      },
      onPointerCancel: (_) {
        _downPosition = null;
        widget.controller.handlePointerCancel();
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          widget.controller.handleScrollNotification(notification);
          return false;
        },
        child: widget.child,
      ),
    );
  }
}
