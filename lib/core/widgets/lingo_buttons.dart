import 'package:flutter/material.dart';
import 'package:lingo_core/core/theme/app_theme.dart';
import 'package:lingo_core/core/theme/lingo_feedback.dart';
import 'package:lingo_core/core/theme/lingo_tokens.dart';
import 'package:lingo_core/core/widgets/lingo_pressable.dart';

class LingoPrimaryButton extends StatelessWidget {
  const LingoPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expanded = true,
    this.isLoading = false,
    this.status = LingoStatus.idle,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;
  final bool isLoading;
  final LingoStatus status;

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);
    final LingoMetrics metrics = LingoMetrics.of(context);
    final bool canTap = onPressed != null && !isLoading;
    final _ButtonChrome chrome = _ButtonChrome.primary(theme, status);

    return LingoPressable(
      onPressed: canTap ? onPressed : null,
      enabled: onPressed != null || isLoading,
      color: chrome.face,
      depthColor: chrome.depth,
      gradient: status == LingoStatus.idle
          ? theme.gradients.primarySheen
          : null,
      depth: LingoElevation.raised,
      width: expanded ? double.infinity : null,
      minHeight: metrics.tapHeight(52),
      padding: const EdgeInsets.symmetric(horizontal: LingoSpacing.xxl),
      semanticLabel: label,
      feedbackKind: chrome.feedback,
      child: _LingoButtonLabel(
        label: label,
        icon: icon,
        isLoading: isLoading,
        status: status,
        foreground: chrome.onFace,
        indicatorColor: chrome.onFace,
      ),
    );
  }
}

class LingoSecondaryButton extends StatelessWidget {
  const LingoSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expanded = true,
    this.isLoading = false,
    this.status = LingoStatus.idle,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;
  final bool isLoading;
  final LingoStatus status;

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);
    final LingoMetrics metrics = LingoMetrics.of(context);
    final bool canTap = onPressed != null && !isLoading;
    final _ButtonChrome chrome = _ButtonChrome.secondary(theme, status);

    return LingoPressable(
      onPressed: canTap ? onPressed : null,
      enabled: onPressed != null || isLoading,
      color: chrome.face,
      depthColor: chrome.depth,
      depth: LingoElevation.rest,
      width: expanded ? double.infinity : null,
      minHeight: metrics.tapHeight(52),
      padding: const EdgeInsets.symmetric(horizontal: LingoSpacing.xxl),
      border: Border.all(color: chrome.border),
      semanticLabel: label,
      feedbackKind: chrome.feedback,
      child: _LingoButtonLabel(
        label: label,
        icon: icon,
        isLoading: isLoading,
        status: status,
        foreground: chrome.onFace,
        indicatorColor: chrome.onFace,
      ),
    );
  }
}

/// Filled 3D button with a more pronounced physical lip. Use for key
/// learning actions such as "Check" or "Continue".
class LingoPressableButton extends StatelessWidget {
  const LingoPressableButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expanded = true,
    this.isLoading = false,
    this.tone = LingoPressableTone.accent,
    this.status = LingoStatus.idle,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;
  final bool isLoading;
  final LingoPressableTone tone;
  final LingoStatus status;

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);
    final LingoMetrics metrics = LingoMetrics.of(context);
    final bool canTap = onPressed != null && !isLoading;
    final _ButtonChrome chrome = _ButtonChrome.pressable(theme, tone, status);

    return LingoPressable(
      onPressed: canTap ? onPressed : null,
      enabled: onPressed != null || isLoading,
      color: chrome.face,
      depthColor: chrome.depth,
      depth: LingoElevation.overlay,
      borderRadius: LingoRadii.button,
      width: expanded ? double.infinity : null,
      minHeight: metrics.tapHeight(56),
      padding: const EdgeInsets.symmetric(horizontal: LingoSpacing.xxl),
      semanticLabel: label,
      feedbackKind: chrome.feedback,
      child: _LingoButtonLabel(
        label: label,
        icon: icon,
        isLoading: isLoading,
        status: status,
        foreground: chrome.onFace,
        indicatorColor: chrome.onFace,
      ),
    );
  }
}

enum LingoPressableTone { primary, accent, tertiary }

final class _ButtonChrome {
  const _ButtonChrome({
    required this.face,
    required this.depth,
    required this.onFace,
    required this.border,
    required this.feedback,
  });

  final Color face;
  final Color depth;
  final Color onFace;
  final Color border;
  final LingoFeedbackKind feedback;

  static _ButtonChrome primary(LingoTheme theme, LingoStatus status) {
    final LingoColors colors = theme.colors;
    return switch (status) {
      LingoStatus.success => _ButtonChrome(
        face: colors.success,
        depth: colors.successDepth,
        onFace: colors.onSuccess,
        border: colors.success,
        feedback: LingoFeedbackKind.success,
      ),
      LingoStatus.error => _ButtonChrome(
        face: colors.danger,
        depth: colors.dangerDepth,
        onFace: colors.onDanger,
        border: colors.danger,
        feedback: LingoFeedbackKind.error,
      ),
      LingoStatus.idle => _ButtonChrome(
        face: colors.primary,
        depth: colors.primaryDepth,
        onFace: colors.onPrimary,
        border: colors.primary,
        feedback: LingoFeedbackKind.tap,
      ),
    };
  }

  static _ButtonChrome secondary(LingoTheme theme, LingoStatus status) {
    final LingoColors colors = theme.colors;
    if (status == LingoStatus.idle) {
      return _ButtonChrome(
        face: colors.cardFill,
        depth: colors.surfaceDepth,
        onFace: colors.onSurface,
        border: colors.paperRim,
        feedback: LingoFeedbackKind.tap,
      );
    }
    return primary(theme, status);
  }

  static _ButtonChrome pressable(
    LingoTheme theme,
    LingoPressableTone tone,
    LingoStatus status,
  ) {
    if (status != LingoStatus.idle) {
      return primary(theme, status);
    }
    final LingoColors colors = theme.colors;
    return switch (tone) {
      LingoPressableTone.primary => _ButtonChrome(
        face: colors.primary,
        depth: colors.primaryDepth,
        onFace: colors.onPrimary,
        border: colors.primary,
        feedback: LingoFeedbackKind.tap,
      ),
      LingoPressableTone.accent => _ButtonChrome(
        face: colors.accent,
        depth: colors.accentDepth,
        onFace: colors.onAccent,
        border: colors.accent,
        feedback: LingoFeedbackKind.tap,
      ),
      LingoPressableTone.tertiary => _ButtonChrome(
        face: colors.tertiary,
        depth: colors.tertiaryDepth,
        onFace: colors.onTertiary,
        border: colors.tertiary,
        feedback: LingoFeedbackKind.tap,
      ),
    };
  }
}

class _LingoButtonLabel extends StatelessWidget {
  const _LingoButtonLabel({
    required this.label,
    required this.foreground,
    required this.indicatorColor,
    required this.isLoading,
    required this.status,
    this.icon,
  });

  final String label;
  final Color foreground;
  final Color indicatorColor;
  final bool isLoading;
  final LingoStatus status;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: SizedBox(
          width: LingoIconSize.md,
          height: LingoIconSize.md,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: indicatorColor,
          ),
        ),
      );
    }

    final TextStyle? style = Theme.of(
      context,
    ).textTheme.labelLarge?.copyWith(color: foreground);
    final Widget text = Text(
      label,
      style: style,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    final IconData? resolvedIcon = icon ?? _statusIcon(status);

    if (resolvedIcon == null) {
      return Center(child: text);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(resolvedIcon, size: LingoIconSize.md, color: foreground),
        const SizedBox(width: LingoSpacing.sm),
        Flexible(child: text),
      ],
    );
  }

  IconData? _statusIcon(LingoStatus status) {
    return switch (status) {
      LingoStatus.success => Icons.check_rounded,
      LingoStatus.error => Icons.close_rounded,
      LingoStatus.idle => null,
    };
  }
}
