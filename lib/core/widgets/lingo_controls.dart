import 'package:flutter/material.dart';
import 'package:lingo_core/core/l10n/ui_strings.dart';
import 'package:lingo_core/core/theme/app_theme.dart';
import 'package:lingo_core/core/theme/lingo_feedback.dart';
import 'package:lingo_core/core/theme/lingo_tokens.dart';
import 'package:lingo_core/core/widgets/lingo_motion.dart';
import 'package:lingo_core/core/widgets/lingo_pressable.dart';

class LingoChip extends StatelessWidget {
  const LingoChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onPressed,
    this.icon,
    this.enabled = true,
  });

  final String label;
  final bool selected;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color face = selected
        ? theme.colors.primaryContainer
        : theme.colors.surfaceRaised;
    final Color foreground = selected
        ? theme.colors.onPrimaryContainer
        : theme.colors.onSurface;
    final IconData? icon = this.icon;

    return LingoPressable(
      onPressed: enabled ? onPressed : null,
      enabled: enabled,
      feedbackKind: LingoFeedbackKind.select,
      color: face,
      depth: LingoElevation.rest,
      borderRadius: LingoRadii.chip,
      padding: const EdgeInsets.symmetric(
        horizontal: LingoSpacing.md,
        vertical: LingoSpacing.sm,
      ),
      minHeight: LingoSpacing.minTapTarget,
      border: Border.all(
        color: selected ? theme.colors.primary : theme.colors.hairline,
      ),
      semanticLabel: label,
      semanticButton: onPressed != null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: LingoIconSize.sm, color: foreground),
            const SizedBox(width: LingoSpacing.xs),
          ],
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(color: foreground),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Compact circular glyph used by learning play and favorite actions.
class LingoGlyphButton extends StatelessWidget {
  const LingoGlyphButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.selected = false,
    this.child,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final bool selected;
  final Widget? child;

  static const double extent = LingoSpacing.minTapTarget;
  static const double glyphSize = LingoIconSize.md;

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);
    final Color color = selected
        ? theme.colors.primary
        : theme.colors.onSurfaceMuted;
    final Widget? child = this.child;

    final Widget glyph = DecoratedBox(
      decoration: BoxDecoration(
        color: selected
            ? theme.colors.primaryContainer.withValues(alpha: 0.70)
            : theme.colors.cardFill.withValues(
                alpha: theme.colors.isDark ? 0.72 : 0.90,
              ),
        shape: BoxShape.circle,
      ),
      child: SizedBox(
        width: 34,
        height: 34,
        child: child ?? Icon(icon, size: glyphSize, color: color),
      ),
    );

    return Semantics(
      button: true,
      enabled: true,
      label: tooltip,
      tooltip: tooltip,
      onTap: onPressed,
      child: SizedBox(
        width: extent,
        height: extent,
        child: Tooltip(
          message: tooltip ?? '',
          excludeFromSemantics: true,
          child: LingoTapScale(onPressed: onPressed, child: glyph),
        ),
      ),
    );
  }
}

class LingoFavoriteButton extends StatelessWidget {
  const LingoFavoriteButton({
    super.key,
    required this.saved,
    required this.onPressed,
  });

  final bool saved;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return LingoGlyphButton(
      tooltip: saved
          ? UiStrings.of(context, UiKeys.favoritesRemove)
          : UiStrings.of(context, UiKeys.favoritesAdd),
      onPressed: onPressed,
      selected: saved,
      icon: saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
    );
  }
}

class LingoLearnedButton extends StatelessWidget {
  const LingoLearnedButton({
    super.key,
    required this.learned,
    required this.onPressed,
  });

  final bool learned;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return LingoGlyphButton(
      tooltip: learned
          ? UiStrings.of(context, UiKeys.learnedUnmark)
          : UiStrings.of(context, UiKeys.learnedMark),
      onPressed: onPressed,
      selected: learned,
      icon: learned
          ? Icons.check_rounded
          : Icons.check_box_outline_blank_rounded,
    );
  }
}

class LingoToggle extends StatelessWidget {
  const LingoToggle({
    super.key,
    required this.value,
    this.onChanged,
    this.enabled = true,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);

    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Switch.adaptive(
        value: value,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        onChanged: enabled
            ? (bool next) {
                onChanged?.call(next);
                LingoFeedback.play(
                  LingoFeedbackKind.select,
                  identity: theme.identity,
                );
              }
            : null,
      ),
    );
  }
}

class LingoSettingsRow extends StatelessWidget {
  const LingoSettingsRow({
    super.key,
    required this.title,
    this.subtitle,
    this.value,
    this.leading,
    this.trailing,
    this.onPressed,
    this.showDivider = true,
    this.selected = false,
    this.compact = false,
  });

  final String title;
  final String? subtitle;
  final String? value;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onPressed;
  final bool showDivider;
  final bool selected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final LingoMetrics metrics = LingoMetrics.of(context);
    final Widget? leading = this.leading;
    final String? subtitle = this.subtitle;
    final String? value = this.value;
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    final Color foreground = selected
        ? theme.colors.primary
        : theme.colors.onSurface;
    final Widget trailing =
        this.trailing ??
        Icon(
          rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
          color: theme.colors.onSurfaceFaint,
          size: LingoIconSize.md,
        );

    final Widget row = ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: metrics.tapHeight(
          compact ? LingoSpacing.settingsRowCompact : LingoSpacing.settingsRow,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: LingoSpacing.lg,
          vertical: compact ? LingoSpacing.sm : LingoSpacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            if (leading != null) ...<Widget>[
              leading,
              const SizedBox(width: LingoSpacing.md),
            ],
            Expanded(
              flex: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: textTheme.bodyLarge?.copyWith(
                      color: foreground,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null && subtitle.isNotEmpty) ...<Widget>[
                    const SizedBox(height: LingoSpacing.xxs),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: theme.colors.onSurfaceMuted,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (value != null && value.isNotEmpty) ...<Widget>[
              const SizedBox(width: LingoSpacing.sm),
              Flexible(
                flex: 1,
                fit: FlexFit.loose,
                child: Text(
                  value,
                  style: textTheme.bodyLarge?.copyWith(
                    color: theme.colors.onSurfaceMuted,
                    height: 1.25,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
            const SizedBox(width: LingoSpacing.sm),
            trailing,
          ],
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ColoredBox(
          color: selected
              ? theme.colors.primary.withValues(alpha: 0.07)
              : const Color(0x00000000),
          child: LingoTapScale(onPressed: onPressed, child: row),
        ),
        if (showDivider)
          Divider(
            height: 0.5,
            indent: leading == null
                ? LingoSpacing.lg
                : LingoSpacing.settingsLeadingInset,
            endIndent: LingoSpacing.lg,
            color: theme.colors.hairline.withValues(alpha: 0.55),
          ),
      ],
    );
  }
}
