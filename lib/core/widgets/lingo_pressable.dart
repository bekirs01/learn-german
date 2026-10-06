import 'package:flutter/material.dart';
import 'package:lingo_core/core/theme/app_theme.dart';
import 'package:lingo_core/core/theme/lingo_feedback.dart';
import 'package:lingo_core/core/theme/lingo_identity.dart';
import 'package:lingo_core/core/theme/lingo_tokens.dart';
import 'package:lingo_core/core/widgets/lingo_motion.dart';

/// Shared physical-depth press interaction used by buttons and cards.
class LingoPressable extends StatefulWidget {
  const LingoPressable({
    super.key,
    required this.child,
    this.onPressed,
    this.depth = LingoElevation.raised,
    this.color,
    this.depthColor,
    this.gradient,
    this.borderRadius = LingoRadii.button,
    this.padding,
    this.border,
    this.enabled = true,
    this.enableHaptics = true,
    this.feedbackKind = LingoFeedbackKind.tap,
    this.width,
    this.height,
    this.minHeight = LingoSpacing.minTapTarget,
    this.semanticLabel,
    this.semanticButton = true,
  });

  static const Key pressTransformKey = ValueKey<String>(
    'lingo-press-transform',
  );

  final Widget child;
  final VoidCallback? onPressed;
  final double depth;
  final Color? color;
  final Color? depthColor;
  final Gradient? gradient;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final Border? border;
  final bool enabled;
  final bool enableHaptics;
  final LingoFeedbackKind feedbackKind;
  final double? width;
  final double? height;
  final double minHeight;
  final String? semanticLabel;
  final bool semanticButton;

  @override
  State<LingoPressable> createState() => LingoPressableState();
}

class LingoPressableState extends State<LingoPressable>
    with SingleTickerProviderStateMixin, LingoImmediatePressState {
  bool _focused = false;

  @override
  bool get pressInteractive => widget.enabled && widget.onPressed != null;

  @override
  void didUpdateWidget(LingoPressable oldWidget) {
    super.didUpdateWidget(oldWidget);
    syncPressAvailability();
  }

  void _handleTap() {
    if (!pressInteractive) {
      return;
    }
    final VoidCallback? onPressed = widget.onPressed;
    final bool playHaptics = widget.enableHaptics;
    final LingoFeedbackKind kind = widget.feedbackKind;
    final LingoIdentity identity = LingoTheme.of(context).identity;
    onPressed?.call();
    if (playHaptics) {
      LingoFeedback.play(kind, identity: identity);
    }
  }

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);
    final double depth = widget.enabled ? widget.depth : LingoElevation.flat;
    final double pressScale = theme.identity.pressScale;
    final Color faceColor = widget.color ?? theme.colors.surfaceRaised;
    final Color lipColor =
        widget.depthColor ?? _fallbackDepth(faceColor, theme.colors);

    final Widget face = AnimatedBuilder(
      animation: pressAnimation,
      child: widget.child,
      builder: (BuildContext context, Widget? child) {
        final double t = pressInteractive ? pressAnimation.value : 0;
        final double offset = depth * t;
        final double scale = 1 + (pressScale - 1) * t;
        final List<BoxShadow> shadows = _shadowsFor(
          theme: theme,
          depth: depth,
          compressed: t > 0 || !pressInteractive,
        );

        return Transform.translate(
          offset: Offset(0, offset),
          child: Transform.scale(
            key: LingoPressable.pressTransformKey,
            alignment: Alignment.topCenter,
            scale: scale,
            child: Container(
              width: widget.width,
              height: widget.height,
              margin: EdgeInsets.only(bottom: depth),
              padding: widget.padding,
              constraints: BoxConstraints(minHeight: widget.minHeight),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: widget.gradient == null ? faceColor : null,
                gradient: widget.gradient,
                borderRadius: widget.borderRadius,
                border: widget.border,
                boxShadow: shadows,
              ),
              child: child,
            ),
          ),
        );
      },
    );

    final Widget body = Opacity(
      opacity: widget.enabled ? 1 : 0.48,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: lipColor,
                borderRadius: widget.borderRadius,
              ),
            ),
          ),
          face,
        ],
      ),
    );

    return Semantics(
      button: widget.semanticButton,
      enabled: pressInteractive,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        enabled: pressInteractive,
        mouseCursor: pressInteractive
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowFocusHighlight: (bool focused) {
          setState(() => _focused = focused);
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (ActivateIntent intent) {
              _handleTap();
              return null;
            },
          ),
        },
        child: wrapImmediatePress(
          onTap: _handleTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              border: Border.all(
                color: _focused ? theme.colors.focusRing : Colors.transparent,
                width: 2,
              ),
            ),
            child: body,
          ),
        ),
      ),
    );
  }

  List<BoxShadow> _shadowsFor({
    required LingoTheme theme,
    required double depth,
    required bool compressed,
  }) {
    if (compressed || depth <= LingoElevation.flat) {
      return theme.shadows.none;
    }
    if (depth >= LingoElevation.overlay) {
      return theme.shadows.overlay;
    }
    if (depth >= LingoElevation.raised) {
      return theme.shadows.raised;
    }
    return theme.shadows.rest;
  }

  Color _fallbackDepth(Color face, LingoColors colors) {
    if (face == colors.primary) {
      return colors.primaryDepth;
    }
    if (face == colors.accent) {
      return colors.accentDepth;
    }
    if (face == colors.success) {
      return colors.successDepth;
    }
    if (face == colors.danger) {
      return colors.dangerDepth;
    }
    if (face == colors.tertiary) {
      return colors.tertiaryDepth;
    }
    return colors.surfaceDepth;
  }
}
