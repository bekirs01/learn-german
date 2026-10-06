import 'package:flutter/material.dart';
import 'package:lingo_core/core/assets/lingo_assets.dart';
import 'package:lingo_core/core/theme/app_theme.dart';
import 'package:lingo_core/core/theme/lingo_feedback.dart';
import 'package:lingo_core/core/theme/lingo_tokens.dart';
import 'package:lingo_core/core/widgets/lingo_artwork.dart';
import 'package:lingo_core/core/widgets/lingo_pressable.dart';
import 'package:lingo_core/core/widgets/lingo_progress.dart';

class LingoLearningCard extends StatelessWidget {
  const LingoLearningCard({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.progress,
    this.onPressed,
    this.status = LingoStatus.idle,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final double? progress;
  final VoidCallback? onPressed;
  final LingoStatus status;

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Widget? leading = this.leading;
    final Widget? trailing = this.trailing;
    final String? subtitle = this.subtitle;
    final double? progress = this.progress;

    return LingoPressable(
      onPressed: onPressed,
      enableHaptics: false,
      color: theme.colors.cardFill,
      depth: LingoElevation.raised,
      borderRadius: LingoRadii.card,
      border: _statusBorder(theme, status),
      padding: const EdgeInsets.fromLTRB(
        LingoSpacing.lg,
        LingoSpacing.lg,
        LingoSpacing.lg,
        LingoSpacing.md,
      ),
      semanticLabel: title,
      semanticButton: onPressed != null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (leading != null) ...<Widget>[
                leading,
                const SizedBox(width: LingoSpacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null && subtitle.isNotEmpty) ...<Widget>[
                      const SizedBox(height: LingoSpacing.xxs),
                      Text(
                        subtitle,
                        style: textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          if (progress != null) ...<Widget>[
            const SizedBox(height: LingoSpacing.md),
            LingoProgressIndicator(value: progress),
          ],
        ],
      ),
    );
  }
}

class LingoCategoryCard extends StatelessWidget {
  const LingoCategoryCard({
    super.key,
    required this.label,
    required this.art,
    this.imageAsset,
    this.onPressed,
    this.selected = false,
  });

  final String label;
  final LingoArtKind art;
  final String? imageAsset;
  final VoidCallback? onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);
    final LingoMetrics metrics = LingoMetrics.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color tint = lingoArtTint(art, theme.colors);
    const double labelHeight = 1.08;
    final TextStyle labelStyle = (textTheme.labelLarge ?? const TextStyle())
        .copyWith(
          fontSize: 13,
          height: labelHeight,
          letterSpacing: -0.16,
          fontWeight: FontWeight.w600,
          color: theme.colors.onSurface,
        );
    final double labelBlockHeight = metrics.textScaler.scale(
      (labelStyle.fontSize ?? 13) * labelHeight * 2,
    );
    final Color wellColor =
        Color.lerp(theme.colors.cardFill, tint, 0.12) ?? theme.colors.cardFill;
    final Color captionColor =
        Color.lerp(wellColor, theme.colors.cardFill, 0.22) ?? wellColor;

    return LingoPressable(
      onPressed: onPressed,
      feedbackKind: LingoFeedbackKind.select,
      color: captionColor,
      depth: LingoElevation.raised,
      borderRadius: LingoRadii.poster,
      padding: EdgeInsets.zero,
      minHeight: 0,
      border: selected
          ? Border.all(color: theme.colors.primary.withValues(alpha: 0.45))
          : null,
      semanticLabel: label,
      semanticButton: onPressed != null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AspectRatio(
            aspectRatio: 1,
            child: ColoredBox(
              color: wellColor,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  LingoArtwork(
                    art: art,
                    assetPath: imageAsset,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: IgnorePointer(
                      child: SizedBox(
                        height: 16,
                        width: double.infinity,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: <Color>[
                                captionColor.withValues(alpha: 0),
                                captionColor.withValues(alpha: 0.94),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 5, 10, 8),
            child: SizedBox(
              height: labelBlockHeight,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  label,
                  style: labelStyle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LingoCategoryHero extends StatelessWidget {
  const LingoCategoryHero({super.key, required this.art, this.imageAsset});

  final LingoArtKind art;
  final String? imageAsset;

  /// Landscape frame that keeps 1:1 category art large and readable.
  static const double frameAspectRatio = 1.24;

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);
    const BorderRadius radius = LingoRadii.poster;

    final Color wellColor =
        Color.lerp(
          theme.colors.cardFill,
          lingoArtTint(art, theme.colors),
          0.10,
        ) ??
        theme.colors.cardFill;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: theme.colors.paperRim, width: 0.7),
        boxShadow: theme.shadows.paper,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: ColoredBox(
          color: wellColor,
          child: AspectRatio(
            aspectRatio: frameAspectRatio,
            child: LingoArtwork(
              art: art,
              assetPath: imageAsset,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
        ),
      ),
    );
  }
}

class LingoWordCard extends StatelessWidget {
  const LingoWordCard({
    super.key,
    required this.word,
    this.pronunciation,
    this.meaning,
    this.detail,
    this.onPressed,
    this.play,
    this.action,
    this.learnedAction,
    this.learned = false,
    this.index,
    this.total,
    this.titleDirection,
    this.status = LingoStatus.idle,
  });

  final String word;
  final String? pronunciation;
  final String? meaning;
  final String? detail;
  final VoidCallback? onPressed;
  final Widget? play;
  final Widget? action;
  final Widget? learnedAction;
  final bool learned;
  final int? index;
  final int? total;
  final TextDirection? titleDirection;
  final LingoStatus status;

  @override
  Widget build(BuildContext context) {
    return _LearningEntryCard(
      title: word,
      pronunciation: pronunciation,
      meaning: meaning,
      detail: detail,
      onPressed: onPressed,
      play: play,
      action: action,
      learnedAction: learnedAction,
      learned: learned,
      index: index,
      total: total,
      titleDirection: titleDirection,
      status: status,
      titleMaxLines: 3,
      meaningMaxLines: 3,
    );
  }
}

class LingoPhraseCard extends StatelessWidget {
  const LingoPhraseCard({
    super.key,
    required this.phrase,
    this.pronunciation,
    this.meaning,
    this.onPressed,
    this.play,
    this.action,
    this.learnedAction,
    this.learned = false,
    this.index,
    this.total,
    this.titleDirection,
    this.status = LingoStatus.idle,
  });

  final String phrase;
  final String? pronunciation;
  final String? meaning;
  final VoidCallback? onPressed;
  final Widget? play;
  final Widget? action;
  final Widget? learnedAction;
  final bool learned;
  final int? index;
  final int? total;
  final TextDirection? titleDirection;
  final LingoStatus status;

  @override
  Widget build(BuildContext context) {
    return _LearningEntryCard(
      title: phrase,
      pronunciation: pronunciation,
      meaning: meaning,
      onPressed: onPressed,
      play: play,
      action: action,
      learnedAction: learnedAction,
      learned: learned,
      index: index,
      total: total,
      titleDirection: titleDirection,
      status: status,
      titleMaxLines: 5,
      meaningMaxLines: 4,
    );
  }
}

Border? _statusBorder(LingoTheme theme, LingoStatus status) {
  return switch (status) {
    LingoStatus.idle => Border.all(color: theme.colors.paperRim, width: 0.7),
    LingoStatus.success => Border.all(color: theme.colors.success, width: 1.2),
    LingoStatus.error => Border.all(color: theme.colors.danger, width: 1.2),
  };
}

Color _entryFill(LingoTheme theme, {required bool learned}) {
  if (!learned) {
    return theme.colors.cardFill;
  }
  return Color.lerp(
        theme.colors.cardFill,
        theme.colors.accentContainer,
        theme.colors.isDark ? 0.42 : 0.34,
      ) ??
      theme.colors.cardFill;
}

Border? _entryBorder(
  LingoTheme theme,
  LingoStatus status, {
  required bool learned,
}) {
  if (status != LingoStatus.idle) {
    return _statusBorder(theme, status);
  }
  if (!learned) {
    return _statusBorder(theme, status);
  }
  final Color rim =
      Color.lerp(
        theme.colors.paperRim,
        theme.colors.accent,
        theme.colors.isDark ? 0.28 : 0.18,
      ) ??
      theme.colors.paperRim;
  return Border.all(color: rim, width: 0.8);
}

class _LearningEntryCard extends StatelessWidget {
  const _LearningEntryCard({
    required this.title,
    required this.titleMaxLines,
    required this.meaningMaxLines,
    this.pronunciation,
    this.meaning,
    this.detail,
    this.onPressed,
    this.play,
    this.action,
    this.learnedAction,
    this.learned = false,
    this.index,
    this.total,
    this.titleDirection,
    this.status = LingoStatus.idle,
  });

  final String title;
  final String? pronunciation;
  final String? meaning;
  final String? detail;
  final VoidCallback? onPressed;
  final Widget? play;
  final Widget? action;
  final Widget? learnedAction;
  final bool learned;
  final int? index;
  final int? total;
  final TextDirection? titleDirection;
  final LingoStatus status;
  final int titleMaxLines;
  final int meaningMaxLines;

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Widget? play = this.play;
    final Widget? action = this.action;
    final Widget? learnedAction = this.learnedAction;
    final int? index = this.index;
    final String? meaning = this.meaning;
    final String? detail = this.detail?.trim();
    final TextDirection? titleDirection = this.titleDirection;
    final String? cue = _subtlePronunciationCue(
      pronunciation,
      title: title,
      meaning: meaning,
    );
    final bool showMeaning =
        meaning != null &&
        meaning.isNotEmpty &&
        !_sameVisibleCopy(title, meaning);
    final String semanticLabel = <String?>[
      index == null ? null : '$index',
      title,
      meaning,
      if (detail != null &&
          detail.isNotEmpty &&
          !_sameVisibleCopy(title, detail))
        detail,
    ].whereType<String>().join(', ');

    final TextStyle titleStyle =
        textTheme.titleMedium?.copyWith(
          height: 1.28,
          letterSpacing: -0.22,
          fontWeight: FontWeight.w600,
        ) ??
        const TextStyle(
          fontSize: 17,
          height: 1.28,
          letterSpacing: -0.22,
          fontWeight: FontWeight.w600,
        );
    final double firstLineHeight = LingoMetrics.of(context).textScaler.scale(
      (titleStyle.fontSize ?? 17) * (titleStyle.height ?? 1.25),
    );
    final double firstLineInset =
        ((LingoSpacing.minTapTarget - firstLineHeight) / 2).clamp(0.0, 16.0);
    final List<Widget> actions = <Widget>[?play, ?action, ?learnedAction];

    final Widget titleText = Text(
      title,
      style: titleStyle,
      maxLines: titleMaxLines,
      overflow: TextOverflow.ellipsis,
    );

    final Widget body = Padding(
      padding: const EdgeInsets.fromLTRB(
        LingoSpacing.lg,
        LingoSpacing.lg,
        LingoSpacing.sm,
        LingoSpacing.lg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (index != null)
            _LearningIndex(
              index: index,
              total: total ?? index,
              lineHeight: firstLineHeight,
              lineInset: firstLineInset,
            ),
          Expanded(
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                start: index == null ? 0 : LingoSpacing.lg,
                end: LingoSpacing.sm,
                top: firstLineInset,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  titleDirection == null
                      ? titleText
                      : Directionality(
                          textDirection: titleDirection,
                          child: titleText,
                        ),
                  if (showMeaning) ...<Widget>[
                    const SizedBox(height: LingoSpacing.sm),
                    Text(
                      meaning,
                      style: textTheme.bodyMedium?.copyWith(
                        color: theme.colors.onSurfaceMuted,
                        height: 1.38,
                        letterSpacing: 0,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: meaningMaxLines,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (detail != null &&
                      detail.isNotEmpty &&
                      !_sameVisibleCopy(title, detail)) ...<Widget>[
                    const SizedBox(height: LingoSpacing.xxs),
                    Text(
                      detail,
                      style: textTheme.labelSmall?.copyWith(
                        color: theme.colors.onSurfaceFaint,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (cue != null) ...<Widget>[
                    const SizedBox(height: LingoSpacing.xxs),
                    Text(
                      cue,
                      style: textTheme.labelSmall?.copyWith(
                        color: theme.colors.onSurfaceFaint,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (actions.isNotEmpty) _LearningActions(children: actions),
        ],
      ),
    );

    final Color fill = _entryFill(theme, learned: learned);
    final Border? border = _entryBorder(theme, status, learned: learned);

    final Widget card = onPressed == null
        ? Semantics(
            container: true,
            label: semanticLabel,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: fill,
                borderRadius: LingoRadii.card,
                boxShadow: theme.shadows.rest,
                border: border,
              ),
              child: body,
            ),
          )
        : LingoPressable(
            onPressed: onPressed,
            enableHaptics: true,
            color: fill,
            depth: LingoElevation.rest,
            borderRadius: LingoRadii.card,
            border: border,
            padding: EdgeInsets.zero,
            semanticLabel: semanticLabel,
            semanticButton: true,
            child: body,
          );

    return RepaintBoundary(child: card);
  }
}

class _LearningActions extends StatelessWidget {
  const _LearningActions({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: LingoSpacing.minTapTarget,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
      ),
    );
  }
}

class _LearningIndex extends StatelessWidget {
  const _LearningIndex({
    required this.index,
    required this.total,
    required this.lineHeight,
    required this.lineInset,
  });

  final int index;
  final int total;
  final double lineHeight;
  final double lineInset;

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final int width = total >= 100 ? 3 : (total >= 10 ? 2 : 1);
    final String label = index.toString().padLeft(width, '0');

    return Padding(
      padding: EdgeInsets.only(top: lineInset),
      child: SizedBox(
        width: width >= 3 ? 34 : (width >= 2 ? 28 : 22),
        height: lineHeight,
        child: Align(
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: textTheme.labelSmall?.copyWith(
              color: theme.colors.onSurfaceFaint,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              fontWeight: FontWeight.w600,
              height: 1,
              letterSpacing: 0,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

String? _subtlePronunciationCue(
  String? pronunciation, {
  required String title,
  String? meaning,
}) {
  final String? value = pronunciation?.trim();
  if (value == null || value.isEmpty) {
    return null;
  }
  if (_looksLikePhoneticCue(value)) {
    return null;
  }
  if (_sameVisibleCopy(title, value)) {
    return null;
  }
  if (meaning != null && _sameVisibleCopy(meaning, value)) {
    return null;
  }
  return value;
}

bool _looksLikePhoneticCue(String value) {
  if (value.contains('/') ||
      value.contains('[') ||
      value.contains(']') ||
      value.contains('ˈ') ||
      value.contains('ˌ')) {
    return true;
  }
  return RegExp(r'[ɑɒæəɚɛɜɪɨɔʊʌθðʃʒŋːˑ]').hasMatch(value);
}

bool _sameVisibleCopy(String primary, String secondary) {
  final String left = _foldVisibleCopy(primary);
  final String right = _foldVisibleCopy(secondary);
  return left.isNotEmpty && left == right;
}

String _foldVisibleCopy(String value) {
  return value.trim().toLowerCase().replaceAll(
    RegExp(r'[\s\p{P}\p{S}]+', unicode: true),
    '',
  );
}
