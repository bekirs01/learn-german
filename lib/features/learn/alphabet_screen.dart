import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lingo_core/app/content_scope.dart';
import 'package:lingo_core/core/audio/pronunciation_service.dart';
import 'package:lingo_core/core/feedback/feedback_service.dart';
import 'package:lingo_core/core/l10n/ui_strings.dart';
import 'package:lingo_core/core/theme/app_theme.dart';
import 'package:lingo_core/core/theme/lingo_feedback.dart';
import 'package:lingo_core/core/theme/lingo_tokens.dart';
import 'package:lingo_core/core/widgets/lingo_widgets.dart';
import 'package:lingo_core/data/user_preferences.dart';
import 'package:lingo_core/domain/content_models.dart';
import 'package:lingo_core/domain/content_repository.dart';

class AlphabetScreen extends StatefulWidget {
  const AlphabetScreen({super.key});

  @override
  State<AlphabetScreen> createState() => _AlphabetScreenState();
}

class _AlphabetScreenState extends State<AlphabetScreen> {
  final ScrollController _scrollController = ScrollController();
  int _selectedIndex = 0;

  @override
  void dispose() {
    unawaited(PronunciationService.instance.stop());
    _scrollController.dispose();
    super.dispose();
  }

  void _select(int index) {
    if (index == _selectedIndex) {
      return;
    }
    final List<AlphabetUnit> letters = ContentScope.of(context).alphabet;
    if (index < 0 || index >= letters.length) {
      return;
    }
    final AlphabetUnit unit = letters[index];
    setState(() => _selectedIndex = index);
    FeedbackService.play(FeedbackEvent.letterSelected);
    PronunciationService.play(PronunciationClip.fromAlphabet(unit));
  }

  @override
  Widget build(BuildContext context) {
    final LingoMetrics metrics = LingoMetrics.of(context);
    final ContentRepository content = ContentScope.of(context);
    final List<AlphabetUnit> letters = content.alphabet;

    final bool nested = ModalRoute.of(context)?.canPop ?? false;
    final String? nestedTitle = nested
        ? UiStrings.of(context, UiKeys.navAlphabet)
        : null;

    if (letters.isEmpty) {
      return LingoPage(
        showAppBar: nested,
        title: nestedTitle,
        body: LingoContent(
          storageKey: 'alphabet',
          controller: _scrollController,
          topSafeArea: !nested,
          children: <Widget>[
            LingoEmptyState(
              icon: Icons.grid_view_rounded,
              title: UiStrings.of(context, UiKeys.alphabetEmptyTitle),
              message: UiStrings.of(context, UiKeys.alphabetEmptyMessage),
            ),
          ],
        ),
      );
    }

    final int selectedIndex = _selectedIndex.clamp(0, letters.length - 1);
    final AlphabetUnit selected = letters[selectedIndex];
    final MediaQueryData media = MediaQuery.of(context);
    final double sectionGap = metrics.stackTightCards
        ? LingoSpacing.md
        : LingoSpacing.lg;
    final double reservedBelow =
        sectionGap +
        metrics.floatingChromeClearance +
        media.padding.bottom +
        LingoSpacing.minTapTarget * 3;
    final double studyMaxHeight =
        (media.size.height -
                media.padding.top -
                metrics.rootTopGap -
                reservedBelow)
            .clamp(LingoSpacing.minTapTarget * 4, media.size.height);

    return LingoPage(
      showAppBar: nested,
      title: nestedTitle,
      body: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(
              top: nested
                  ? metrics.rootTopGap
                  : media.padding.top + metrics.rootTopGap,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: metrics.maxContentWidth,
                  maxHeight: studyMaxHeight,
                ),
                child: SingleChildScrollView(
                  primary: false,
                  padding: EdgeInsets.symmetric(
                    horizontal: metrics.horizontalGutter,
                  ),
                  child: ListenableBuilder(
                    listenable: UserPreferences.instance,
                    builder: (BuildContext context, Widget? _) {
                      return _AlphabetStudyPanel(
                        key: const ValueKey<String>('alphabet-study'),
                        unit: selected,
                        exampleMeaning: content.translation(
                          selected.id,
                          languageCode: ContentScope.translationLanguageOf(
                            context,
                          ),
                        ),
                        textDirection: _contentTextDirection(content.pack),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: sectionGap),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: metrics.maxContentWidth),
                child: ListView(
                  key: const ValueKey<String>('alphabet-scroll'),
                  controller: _scrollController,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    metrics.horizontalGutter,
                    0,
                    metrics.horizontalGutter,
                    metrics.floatingChromeClearance + media.padding.bottom,
                  ),
                  children: <Widget>[
                    _AlphabetCharacterGrid(
                      letters: letters,
                      selectedIndex: selectedIndex,
                      onSelected: _select,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlphabetStudyPanel extends StatelessWidget {
  const _AlphabetStudyPanel({
    super.key,
    required this.unit,
    required this.textDirection,
    this.exampleMeaning,
  });

  final AlphabetUnit unit;
  final String? exampleMeaning;
  final TextDirection textDirection;

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);
    final LingoMetrics metrics = LingoMetrics.of(context);
    final bool compact = metrics.stackTightCards;
    final _AlphabetLesson lesson = _AlphabetLesson.from(
      unit,
      exampleMeaning: exampleMeaning,
    );
    final bool stackPlate = compact && metrics.size.width < 360;
    final double plateSize = lingoSkipDecodedPhotos
        ? 48
        : compact
        ? 108
        : metrics.isExpanded
        ? 148
        : 128;

    final bool showPlate = lesson.imageAsset != null;
    final Widget copy = _LessonCopy(
      lesson: lesson,
      clip: PronunciationClip.fromAlphabet(unit),
      compact: compact,
      textDirection: textDirection,
    );
    final Widget? plate = showPlate
        ? _LessonPlate(lesson: lesson, size: plateSize)
        : null;

    final Widget body = Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? LingoSpacing.md : LingoSpacing.lg,
        compact ? LingoSpacing.md : LingoSpacing.lg,
        compact ? LingoSpacing.md : LingoSpacing.lg,
        compact ? LingoSpacing.sm : LingoSpacing.md,
      ),
      child: stackPlate || plate == null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                copy,
                if (plate != null) ...<Widget>[
                  const SizedBox(height: LingoSpacing.md),
                  Center(child: plate),
                ],
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: copy),
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: LingoSpacing.md,
                  ),
                  child: plate,
                ),
              ],
            ),
    );

    return RepaintBoundary(
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        liveRegion: true,
        selected: true,
        label: lesson.semanticLabel,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colors.surfaceRaised,
            borderRadius: LingoRadii.poster,
            boxShadow: lingoSkipDecodedPhotos
                ? const <BoxShadow>[]
                : theme.shadows.raised,
          ),
          child: lingoSkipDecodedPhotos
              ? body
              : ClipRRect(
                  borderRadius: LingoRadii.poster,
                  child: CustomPaint(
                    painter: _StudyWashPainter(
                      primary: theme.colors.primary,
                      accent: theme.colors.accent,
                      tertiary: theme.colors.tertiary,
                    ),
                    child: body,
                  ),
                ),
        ),
      ),
    );
  }
}

class _LessonCopy extends StatelessWidget {
  const _LessonCopy({
    required this.lesson,
    required this.clip,
    required this.compact,
    required this.textDirection,
  });

  final _AlphabetLesson lesson;
  final PronunciationClip clip;
  final bool compact;
  final TextDirection textDirection;

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String? pronunciation = lesson.spokenCue;
    final String? example = lesson.example;
    final String? exampleMeaning = lesson.exampleMeaning;
    final bool showMeaning =
        exampleMeaning != null &&
        (example == null || !_sameVisibleCopy(example, exampleMeaning));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Directionality(
                textDirection: textDirection,
                child: lingoSkipDecodedPhotos
                    ? _GlyphPair(
                        glyph: lesson.glyph,
                        companion: lesson.companionGlyph,
                        compact: compact,
                      )
                    : FittedBox(
                        key: ValueKey<String>('glyph-${lesson.id}'),
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: _GlyphPair(
                          glyph: lesson.glyph,
                          companion: lesson.companionGlyph,
                          compact: compact,
                        ),
                      ),
              ),
            ),
            PronunciationControl(
              key: const ValueKey<String>('alphabet-play'),
              clip: clip,
              semanticLabel: UiStrings.of(
                context,
                UiKeys.audioPlayPronunciation,
              ),
            ),
          ],
        ),
        if (pronunciation != null) ...<Widget>[
          const SizedBox(height: LingoSpacing.xs),
          Text(
            pronunciation,
            style: textTheme.labelMedium?.copyWith(
              color: theme.colors.onSurfaceFaint,
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (example != null || showMeaning) ...<Widget>[
          SizedBox(height: compact ? LingoSpacing.sm : LingoSpacing.md),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: theme.colors.hairline.withValues(alpha: 0.9),
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: LingoSpacing.sm),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (example != null)
                    Directionality(
                      textDirection: textDirection,
                      child: _ExampleChip(
                        key: const ValueKey<String>('alphabet-example'),
                        text: example,
                      ),
                    ),
                  if (showMeaning) ...<Widget>[
                    if (example != null)
                      const SizedBox(height: LingoSpacing.xs),
                    Text(
                      exampleMeaning,
                      key: const ValueKey<String>('alphabet-meaning'),
                      style: textTheme.bodyMedium?.copyWith(
                        color: theme.colors.onSurfaceMuted,
                        height: 1.35,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _GlyphPair extends StatelessWidget {
  const _GlyphPair({
    required this.glyph,
    required this.companion,
    required this.compact,
  });

  final String glyph;
  final String? companion;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String? companion = this.companion;
    final double primarySize = _glyphSize(compact: compact, glyph: glyph);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: <Widget>[
        Text(
          glyph,
          key: const ValueKey<String>('alphabet-glyph'),
          style: textTheme.displayLarge?.copyWith(
            fontSize: primarySize,
            height: 1,
            letterSpacing: glyph.characters.length == 1 ? -2.4 : 0,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (companion != null) ...<Widget>[
          const SizedBox(width: LingoSpacing.md),
          Text(
            companion,
            style: textTheme.displaySmall?.copyWith(
              fontSize: compact ? 28 : 34,
              height: 1,
              fontWeight: FontWeight.w500,
              color: theme.colors.onSurfaceMuted,
            ),
          ),
        ],
      ],
    );
  }
}

class _LessonPlate extends StatelessWidget {
  const _LessonPlate({required this.lesson, required this.size});

  final _AlphabetLesson lesson;
  final double size;

  @override
  Widget build(BuildContext context) {
    final String? assetPath = lesson.imageAsset;
    if (assetPath == null) {
      return const SizedBox.shrink();
    }
    return _ExampleIllustration(
      key: ValueKey<String>('plate-${lesson.id}'),
      assetPath: assetPath,
      size: size,
    );
  }
}

class _ExampleChip extends StatelessWidget {
  const _ExampleChip({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colors.accentContainer.withValues(alpha: 0.58),
          borderRadius: LingoRadii.chip,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LingoSpacing.md,
            vertical: LingoSpacing.xs,
          ),
          child: Text(
            text,
            style: textTheme.titleSmall?.copyWith(
              color: theme.colors.onAccentContainer,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

class _ExampleIllustration extends StatelessWidget {
  const _ExampleIllustration({
    super.key,
    required this.assetPath,
    required this.size,
  });

  final String assetPath;
  final double size;

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);

    final BorderRadius radius = BorderRadius.circular(LingoRadii.lg);
    if (lingoSkipDecodedPhotos) {
      return ExcludeSemantics(
        child: SizedBox(
          key: const ValueKey<String>('alphabet-illustration'),
          width: size,
          height: size,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colors.surfaceSunken,
              borderRadius: radius,
            ),
          ),
        ),
      );
    }

    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: radius,
        child: ColoredBox(
          color: theme.colors.surfaceSunken,
          child: SizedBox(
            key: const ValueKey<String>('alphabet-illustration'),
            width: size,
            height: size,
            child: Image.asset(
              assetPath,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              cacheWidth: lingoCacheWidth(context, size).clamp(1, 1024),
              filterQuality: FilterQuality.medium,
              gaplessPlayback: true,
              errorBuilder:
                  (BuildContext context, Object error, StackTrace? stackTrace) {
                    return const LingoCategoryArt(art: LingoArtKind.basics);
                  },
            ),
          ),
        ),
      ),
    );
  }
}

class _AlphabetCharacterGrid extends StatelessWidget {
  const _AlphabetCharacterGrid({
    required this.letters,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<AlphabetUnit> letters;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final LingoMetrics metrics = LingoMetrics.of(context);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int columns = _alphabetCrossAxisCount(
          unitCount: letters.length,
          maxWidth: constraints.maxWidth,
          metrics: metrics,
        );
        final double spacing = _alphabetGridSpacing(metrics);
        final double available = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : metrics.maxContentWidth;
        final double maxTile = metrics.isExpanded
            ? 68
            : metrics.stackTightCards
            ? 56
            : 62;
        final double tileSize =
            ((available - spacing * (columns - 1)) / columns).clamp(
              LingoSpacing.minTapTarget,
              maxTile,
            );
        final double gridWidth = tileSize * columns + spacing * (columns - 1);

        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: gridWidth,
            child: RepaintBoundary(
              child: Wrap(
                key: const ValueKey<String>('alphabet-grid'),
                spacing: spacing,
                runSpacing: spacing,
                children: <Widget>[
                  for (int index = 0; index < letters.length; index++)
                    SizedBox(
                      width: tileSize,
                      height: tileSize,
                      child: _AlphabetGlyphTile(
                        key: ValueKey<String>(
                          'alphabet-tile-${letters[index].id}',
                        ),
                        letter: letters[index],
                        selected: index == selectedIndex,
                        size: tileSize,
                        onPressed: () => onSelected(index),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AlphabetGlyphTile extends StatelessWidget {
  const _AlphabetGlyphTile({
    super.key,
    required this.letter,
    required this.selected,
    required this.size,
    required this.onPressed,
  });

  final AlphabetUnit letter;
  final bool selected;
  final double size;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String? pronunciation = _visibleText(letter.pronunciation);
    final String semanticLabel = pronunciation == null
        ? letter.glyph
        : '${letter.glyph}, $pronunciation';
    final Border selectedBorder = Border.all(
      color: selected
          ? theme.colors.primary
          : theme.colors.hairline.withValues(alpha: 0.42),
      width: selected ? 2 : 1,
    );
    final double fontSize = (size * 0.4).clamp(17.0, 24.0);

    final TextStyle? glyphStyle = textTheme.headlineSmall?.copyWith(
      color: selected
          ? theme.colors.onPrimaryContainer
          : theme.colors.onSurface,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
      fontSize: fontSize,
      height: 1,
      letterSpacing: letter.glyph.characters.length == 1 ? -0.4 : 0,
    );
    final Widget glyph = Center(
      child: Padding(
        padding: const EdgeInsets.all(LingoSpacing.xs),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: ExcludeSemantics(child: Text(letter.glyph, style: glyphStyle)),
        ),
      ),
    );

    if (lingoSkipDecodedPhotos) {
      return Semantics(
        button: true,
        selected: selected,
        enabled: true,
        label: semanticLabel,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPressed,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: selected
                  ? theme.colors.primaryContainer
                  : theme.colors.surfaceRaised,
              borderRadius: LingoRadii.button,
              border: selectedBorder,
            ),
            child: glyph,
          ),
        ),
      );
    }

    return Semantics(
      button: true,
      selected: selected,
      enabled: true,
      label: semanticLabel,
      child: LingoPressable(
        onPressed: onPressed,
        feedbackKind: LingoFeedbackKind.none,
        color: selected
            ? theme.colors.primaryContainer
            : theme.colors.surfaceRaised,
        depthColor: selected
            ? theme.colors.primaryDepth
            : theme.colors.surfaceDepth,
        depth: LingoElevation.rest,
        borderRadius: LingoRadii.button,
        border: selectedBorder,
        padding: EdgeInsets.zero,
        minHeight: 0,
        semanticButton: false,
        child: glyph,
      ),
    );
  }
}

class _StudyWashPainter extends CustomPainter {
  const _StudyWashPainter({
    required this.primary,
    required this.accent,
    required this.tertiary,
  });

  final Color primary;
  final Color accent;
  final Color tertiary;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      Offset(size.width * 0.18, size.height * 0.42),
      size.shortestSide * 0.42,
      Paint()..color = primary.withValues(alpha: 0.08),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.86, size.height * 0.22),
        width: size.width * 0.34,
        height: size.height * 0.48,
      ),
      Paint()..color = accent.withValues(alpha: 0.06),
    );
    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.86),
      size.shortestSide * 0.18,
      Paint()..color = tertiary.withValues(alpha: 0.05),
    );
  }

  @override
  bool shouldRepaint(_StudyWashPainter oldDelegate) {
    return oldDelegate.primary != primary ||
        oldDelegate.accent != accent ||
        oldDelegate.tertiary != tertiary;
  }
}

final class _AlphabetLesson {
  const _AlphabetLesson({
    required this.id,
    required this.glyph,
    this.companionGlyph,
    this.pronunciation,
    this.romanization,
    this.example,
    this.exampleMeaning,
    this.imageAsset,
  });

  factory _AlphabetLesson.from(AlphabetUnit unit, {String? exampleMeaning}) {
    final String? spoken = _spokenCue(unit.pronunciation);
    final String? romanized = _spokenCue(unit.romanization);
    final String? example = _visibleText(unit.example);
    return _AlphabetLesson(
      id: unit.id,
      glyph: unit.glyph,
      companionGlyph: _caseCompanion(unit.glyph),
      pronunciation: spoken,
      romanization: _distinctCue(
        _distinctCue(romanized, spoken),
        _visibleText(unit.glyph),
      ),
      example: example,
      exampleMeaning: _visibleText(exampleMeaning),
      imageAsset: _visibleText(unit.imageAsset),
    );
  }

  final String id;
  final String glyph;
  final String? companionGlyph;
  final String? pronunciation;
  final String? romanization;
  final String? example;
  final String? exampleMeaning;
  final String? imageAsset;

  String? get spokenCue => pronunciation ?? romanization;

  String get semanticLabel {
    return <String?>[
      glyph,
      companionGlyph,
      pronunciation,
      romanization,
      example,
      exampleMeaning,
    ].whereType<String>().join(', ');
  }
}

TextDirection _contentTextDirection(LanguagePack pack) {
  return pack.textDirection == ContentTextDirection.rtl
      ? TextDirection.rtl
      : TextDirection.ltr;
}

int _alphabetCrossAxisCount({
  required int unitCount,
  required double maxWidth,
  required LingoMetrics metrics,
}) {
  if (unitCount <= 1) {
    return 1;
  }

  final double spacing = _alphabetGridSpacing(metrics);
  final double minTile = metrics.stackTightCards ? 48 : 52;
  final int widthCap = ((maxWidth + spacing) / (minTile + spacing)).floor();
  final int maxColumns = widthCap.clamp(2, metrics.isExpanded ? 10 : 6);
  if (unitCount <= maxColumns) {
    return unitCount;
  }

  final int preferred = _preferredAlphabetColumns(metrics);
  return preferred.clamp(2, maxColumns);
}

int _preferredAlphabetColumns(LingoMetrics metrics) {
  if (metrics.isExpanded) {
    return 6;
  }
  if (metrics.size.width < 360) {
    return 4;
  }
  return 5;
}

double _alphabetGridSpacing(LingoMetrics metrics) {
  return metrics.stackTightCards ? LingoSpacing.sm : 10;
}

double _glyphSize({required bool compact, required String glyph}) {
  if (lingoSkipDecodedPhotos) {
    return 28;
  }
  final int clusters = glyph.characters.length;
  final double base = compact ? 58 : 72;
  if (clusters > 2) {
    return base * 0.68;
  }
  if (clusters > 1) {
    return base * 0.84;
  }
  return base;
}

String? _caseCompanion(String glyph) {
  final String value = glyph.trim();
  if (value.isEmpty || value.characters.length > 2) {
    return null;
  }
  // Beginners learn ß as one glyph. Dart maps ß → SS, which is misleading.
  if (value == 'ß' || value == 'ẞ') {
    return null;
  }
  final String lower = value.toLowerCase();
  final String upper = value.toUpperCase();
  if (lower == upper) {
    return null;
  }
  if (value == upper && lower != value && lower.characters.length <= 3) {
    return lower;
  }
  if (value == lower && upper != value && upper.characters.length <= 3) {
    return upper;
  }
  return null;
}

String? _visibleText(String? value) {
  if (value == null) {
    return null;
  }
  final String trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String? _distinctCue(String? value, String? other) {
  final String? visible = _visibleText(value);
  if (visible == null) {
    return null;
  }
  if (other != null && visible.toLowerCase() == other.toLowerCase()) {
    return null;
  }
  return visible;
}

bool _sameVisibleCopy(String left, String right) {
  return left.trim().toLowerCase() == right.trim().toLowerCase();
}

String? _spokenCue(String? value) {
  final String? visible = _visibleText(value);
  if (visible == null || _looksLikePhoneticCue(visible)) {
    return null;
  }
  return visible;
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
