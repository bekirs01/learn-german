import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lingo_core/core/l10n/ui_strings.dart';
import 'package:lingo_core/core/theme/app_theme.dart';
import 'package:lingo_core/core/theme/lingo_feedback.dart';
import 'package:lingo_core/core/theme/lingo_tokens.dart';
import 'package:lingo_core/core/widgets/lingo_artwork.dart';
import 'package:lingo_core/core/widgets/lingo_motion.dart';
import 'package:lingo_core/core/widgets/lingo_nav_glyphs.dart';

export 'package:lingo_core/core/widgets/lingo_nav_glyphs.dart';

/// One destination in [LingoFloatingBottomNav].
final class LingoNavDestination {
  const LingoNavDestination({
    required this.label,
    this.glyph,
    this.icon,
    this.selectedIcon,
  }) : assert(
         glyph != null || icon != null,
         'A nav destination needs a glyph or an icon.',
       );

  final String label;
  final LingoNavGlyph? glyph;
  final IconData? icon;
  final IconData? selectedIcon;
}

/// Floating glass capsule used as the app's primary tab bar.
class LingoFloatingBottomNav extends StatefulWidget {
  const LingoFloatingBottomNav({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    this.includeSafeArea = true,
    this.visible = true,
  });

  static const Key selectionBubbleKey = ValueKey<String>(
    'nav-selection-bubble',
  );

  static const Duration selectionTravel = Duration(milliseconds: 260);

  final List<LingoNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool includeSafeArea;
  final bool visible;

  @override
  State<LingoFloatingBottomNav> createState() => _LingoFloatingBottomNavState();
}

class _LingoFloatingBottomNavState extends State<LingoFloatingBottomNav>
    with TickerProviderStateMixin {
  late final AnimationController _visibility;
  late final AnimationController _selection;

  TextDirection _direction = TextDirection.ltr;
  bool _layoutReady = false;
  double _fromSlot = 0;
  double _toSlot = 0;

  @override
  void initState() {
    super.initState();
    _visibility = AnimationController(
      vsync: this,
      value: widget.visible ? 1 : 0,
      duration: LingoMotion.chromeShow,
    );
    _selection = AnimationController(
      vsync: this,
      value: 1,
      duration: LingoFloatingBottomNav.selectionTravel,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final TextDirection next = Directionality.of(context);
    if (!_layoutReady) {
      _direction = next;
      _fromSlot = _visualSlot(widget.selectedIndex);
      _toSlot = _fromSlot;
      _layoutReady = true;
      return;
    }
    if (_direction == next) {
      return;
    }
    _direction = next;
    _fromSlot = _visualSlot(widget.selectedIndex);
    _toSlot = _fromSlot;
    _selection.value = 1;
  }

  @override
  void didUpdateWidget(LingoFloatingBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible != widget.visible) {
      _updateVisibility();
    }
    if (oldWidget.selectedIndex == widget.selectedIndex &&
        oldWidget.destinations.length == widget.destinations.length) {
      return;
    }
    _retargetSelection(oldWidget.selectedIndex);
  }

  void _updateVisibility() {
    final bool reduceMotion = LingoMetrics.of(context).reduceMotion;
    if (reduceMotion) {
      _visibility.value = widget.visible ? 1 : 0;
      return;
    }
    if (widget.visible) {
      _visibility
        ..duration = LingoMotion.chromeShow
        ..animateTo(1, curve: LingoMotion.chromeShowCurve);
    } else {
      _visibility
        ..duration = LingoMotion.chromeHide
        ..animateTo(0, curve: LingoMotion.chromeHideCurve);
    }
  }

  void _retargetSelection(int previousIndex) {
    final bool reduceMotion = LingoMetrics.of(context).reduceMotion;
    final double current = _slotNow();
    _fromSlot = current;
    _toSlot = _visualSlot(widget.selectedIndex);
    if (reduceMotion || previousIndex == widget.selectedIndex) {
      _fromSlot = _toSlot;
      _selection.value = 1;
      return;
    }
    _selection
      ..duration = LingoFloatingBottomNav.selectionTravel
      ..forward(from: 0);
  }

  double _visualSlot(int index) {
    final int count = widget.destinations.length;
    if (count <= 1) {
      return 0;
    }
    final int clamped = index.clamp(0, count - 1);
    if (_direction == TextDirection.rtl) {
      return (count - 1 - clamped).toDouble();
    }
    return clamped.toDouble();
  }

  double _slotNow() {
    return lerpDouble(_fromSlot, _toSlot, _glassPosition(_selection.value)) ??
        _toSlot;
  }

  @override
  void dispose() {
    _visibility.dispose();
    _selection.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);
    final LingoMetrics metrics = LingoMetrics.of(context);
    final MediaQueryData media = MediaQuery.of(context);
    final bool compact = metrics.isNarrow;
    final double sideInset = compact ? LingoSpacing.lg : LingoSpacing.xl;
    final double bottomInset =
        (widget.includeSafeArea ? media.padding.bottom : 0) + LingoSpacing.md;
    final double maxBarWidth = metrics.isExpanded ? 430 : double.infinity;

    return UnconstrainedBox(
      constrainedAxis: Axis.horizontal,
      alignment: Alignment.bottomCenter,
      child: Material(
        type: MaterialType.transparency,
        child: MediaQuery(
          data: media.copyWith(
            textScaler: media.textScaler.clamp(maxScaleFactor: 1.15),
          ),
          child: AnimatedBuilder(
            animation: _visibility,
            builder: (BuildContext context, Widget? child) {
              final double t = _visibility.value;
              return IgnorePointer(
                ignoring: t < 0.18,
                child: Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, (1 - t) * 36),
                    child: child,
                  ),
                ),
              );
            },
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                sideInset,
                LingoSpacing.sm,
                sideInset,
                bottomInset,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Flexible(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxBarWidth),
                      child: Semantics(
                        container: true,
                        explicitChildNodes: true,
                        label: UiStrings.of(
                          context,
                          UiKeys.navBottomNavigation,
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              LingoRadii.pill,
                            ),
                            boxShadow: lingoSkipDecodedPhotos
                                ? const <BoxShadow>[]
                                : _floatingShadows(theme.colors),
                          ),
                          child: _GlassCapsule(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(6, 5, 6, 5),
                              child: LayoutBuilder(
                                builder:
                                    (
                                      BuildContext context,
                                      BoxConstraints constraints,
                                    ) {
                                      return AnimatedBuilder(
                                        animation: _selection,
                                        builder:
                                            (
                                              BuildContext context,
                                              Widget? child,
                                            ) {
                                              return Stack(
                                                alignment: Alignment.center,
                                                children: <Widget>[
                                                  if (widget
                                                      .destinations
                                                      .isNotEmpty)
                                                    _selectionBubble(
                                                      constraints,
                                                    ),
                                                  child ??
                                                      const SizedBox.shrink(),
                                                ],
                                              );
                                            },
                                        child: Row(
                                          children: <Widget>[
                                            for (
                                              int index = 0;
                                              index <
                                                  widget.destinations.length;
                                              index++
                                            )
                                              Expanded(
                                                child: LingoBottomNavItem(
                                                  key: ValueKey<String>(
                                                    'nav-item-$index',
                                                  ),
                                                  glyph: widget
                                                      .destinations[index]
                                                      .glyph,
                                                  icon: widget
                                                      .destinations[index]
                                                      .icon,
                                                  selectedIcon: widget
                                                      .destinations[index]
                                                      .selectedIcon,
                                                  label: widget
                                                      .destinations[index]
                                                      .label,
                                                  selected:
                                                      index ==
                                                      widget.selectedIndex,
                                                  dense: compact,
                                                  onPressed: () =>
                                                      widget.onSelected(index),
                                                ),
                                              ),
                                          ],
                                        ),
                                      );
                                    },
                              ),
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
        ),
      ),
    );
  }

  Widget _selectionBubble(BoxConstraints constraints) {
    final int count = math.max(widget.destinations.length, 1);
    final double slotWidth = constraints.maxWidth / count;
    final double travel = (_toSlot - _fromSlot).abs();
    final double t = _selection.value;
    final double widthFactor = _glassWidth(t, travel);
    final double slot = _slotNow();
    double width = (slotWidth - 8) * 0.84 * widthFactor;
    width = width.clamp(slotWidth * 0.50, constraints.maxWidth - 8);
    double left = slot * slotWidth + (slotWidth - width) / 2;
    final double minLeft = 1;
    final double maxRight = constraints.maxWidth - 1;
    if (left < minLeft) {
      left = minLeft;
    }
    if (left + width > maxRight) {
      width = math.max(slotWidth * 0.50, maxRight - left);
    }
    return Positioned(
      key: LingoFloatingBottomNav.selectionBubbleKey,
      left: left,
      top: 2,
      bottom: 2,
      width: width,
      child: const IgnorePointer(
        child: ExcludeSemantics(child: LingoNavSelectionBubble()),
      ),
    );
  }

  static List<BoxShadow> _floatingShadows(LingoColors colors) {
    return <BoxShadow>[
      BoxShadow(
        color: colors.shadow.withValues(alpha: colors.isDark ? 0.40 : 0.14),
        offset: const Offset(0, 16),
        blurRadius: 34,
        spreadRadius: -14,
      ),
      BoxShadow(
        color: colors.shadow.withValues(alpha: colors.isDark ? 0.18 : 0.05),
        offset: const Offset(0, 2),
        blurRadius: 8,
      ),
    ];
  }
}

/// Moving glass token that marks the selected tab.
class LingoNavSelectionBubble extends StatelessWidget {
  const LingoNavSelectionBubble({super.key});

  @override
  Widget build(BuildContext context) {
    final LingoColors colors = LingoTheme.of(context).colors;
    final bool isDark = colors.isDark;
    final Color frost =
        Color.lerp(
          colors.surfaceRaised,
          colors.primary,
          isDark ? 0.22 : 0.10,
        ) ??
        colors.surfaceRaised;
    final Color fill = frost.withValues(alpha: isDark ? 0.42 : 0.52);
    final Color rim = const Color(
      0xFFFFFFFF,
    ).withValues(alpha: isDark ? 0.50 : 0.92);
    final Color inner = const Color(
      0xFFFFFFFF,
    ).withValues(alpha: isDark ? 0.28 : 0.70);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(LingoRadii.xl),
        border: Border.all(color: rim, width: 0.8),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            const Color(0xFFFFFFFF).withValues(alpha: isDark ? 0.42 : 0.82),
            fill,
            Color.lerp(fill, colors.primary, isDark ? 0.22 : 0.10) ?? fill,
          ],
          stops: const <double>[0, 0.42, 1],
        ),
        boxShadow: lingoSkipDecodedPhotos
            ? const <BoxShadow>[]
            : <BoxShadow>[
                BoxShadow(
                  color: colors.primary.withValues(alpha: isDark ? 0.28 : 0.14),
                  blurRadius: 14,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(LingoRadii.xl),
          border: Border.all(color: inner, width: 0.55),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              const Color(0xFFFFFFFF).withValues(alpha: isDark ? 0.22 : 0.36),
              const Color(0xFFFFFFFF).withValues(alpha: 0),
            ],
            stops: const <double>[0, 0.55],
          ),
        ),
      ),
    );
  }
}

class _GlassCapsule extends StatelessWidget {
  const _GlassCapsule({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final LingoColors colors = LingoTheme.of(context).colors;
    final bool isDark = colors.isDark;
    final Color frost =
        Color.lerp(
          colors.surfaceRaised,
          isDark ? const Color(0xFF10161A) : const Color(0xFFFFFFFF),
          isDark ? 0.18 : 0.58,
        ) ??
        colors.surfaceRaised;
    final Color fill = frost.withValues(alpha: isDark ? 0.34 : 0.30);
    final Color rim = Color.lerp(
      const Color(0xFFFFFFFF).withValues(alpha: isDark ? 0.48 : 0.94),
      colors.hairline,
      isDark ? 0.08 : 0.04,
    )!;
    final Color innerLight = const Color(
      0xFFFFFFFF,
    ).withValues(alpha: isDark ? 0.30 : 0.72);

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(LingoRadii.pill),
        clipBehavior: Clip.antiAlias,
        child: _glassFill(
          fill: fill,
          rim: rim,
          innerLight: innerLight,
          isDark: isDark,
          child: child,
        ),
      ),
    );
  }

  Widget _glassFill({
    required Color fill,
    required Color rim,
    required Color innerLight,
    required bool isDark,
    required Widget child,
  }) {
    final Widget pane = DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(LingoRadii.pill),
        border: Border.all(color: rim, width: 0.95),
      ),
      child: Stack(
        fit: StackFit.passthrough,
        children: <Widget>[
          if (!lingoSkipDecodedPhotos)
            Positioned.fill(
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: _GlassSheen(isDark: isDark, innerLight: innerLight),
                ),
              ),
            ),
          child,
        ],
      ),
    );
    if (lingoSkipDecodedPhotos) {
      return pane;
    }
    return BackdropFilter(
      filter: ImageFilter.blur(
        sigmaX: 22,
        sigmaY: 22,
        tileMode: TileMode.clamp,
      ),
      child: pane,
    );
  }
}

class _GlassSheen extends StatelessWidget {
  const _GlassSheen({required this.isDark, required this.innerLight});

  final bool isDark;
  final Color innerLight;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(LingoRadii.pill),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            const Color(0xFFFFFFFF).withValues(alpha: isDark ? 0.34 : 0.58),
            const Color(0xFFFFFFFF).withValues(alpha: isDark ? 0.10 : 0.18),
            const Color(0xFFFFFFFF).withValues(alpha: 0),
          ],
          stops: const <double>[0, 0.28, 0.76],
        ),
        border: Border.all(color: innerLight, width: 0.55),
      ),
    );
  }
}

/// Icon-only tab control used inside [LingoFloatingBottomNav].
class LingoBottomNavItem extends StatelessWidget {
  const LingoBottomNavItem({
    super.key,
    required this.label,
    this.glyph,
    this.icon,
    this.selectedIcon,
    this.selected = false,
    this.dense = false,
    this.onPressed,
  });

  final String label;
  final LingoNavGlyph? glyph;
  final IconData? icon;
  final IconData? selectedIcon;
  final bool selected;
  final bool dense;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);
    final LingoMetrics metrics = LingoMetrics.of(context);
    final Duration duration = metrics.motion(LingoMotion.quick);
    final Color active = theme.colors.primary;
    final Color idle = Color.lerp(
      theme.colors.onSurface,
      theme.colors.onSurfaceMuted,
      0.48,
    )!;
    final Color color = selected ? active : idle;
    final VoidCallback? onPressed = this.onPressed;
    final double iconSize = dense
        ? (selected ? 24 : 22)
        : (selected ? 26.5 : 23.5);
    final double well = dense ? 40 : 44;
    final LingoNavGlyph? glyph = this.glyph;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: LingoTapScale(
        pressedScale: 0.97,
        onPressed: onPressed == null
            ? null
            : () {
                onPressed();
                LingoFeedback.play(
                  LingoFeedbackKind.select,
                  identity: theme.identity,
                );
              },
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: metrics.tapHeight(LingoSpacing.minTapTarget),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: Center(
              child: TweenAnimationBuilder<Color?>(
                tween: ColorTween(end: color),
                duration: duration,
                curve: LingoMotion.standardCurve,
                builder: (BuildContext context, Color? animatedColor, _) {
                  final Color resolved = animatedColor ?? color;
                  final IconData? materialIcon = selected
                      ? (selectedIcon ?? icon)
                      : icon;
                  return AnimatedScale(
                    scale: selected ? 1.05 : 1,
                    duration: duration,
                    curve: LingoMotion.standardCurve,
                    child: SizedBox(
                      width: well,
                      height: well,
                      child: Center(
                        child: glyph == null
                            ? Icon(
                                materialIcon ?? Icons.circle_outlined,
                                size: iconSize,
                                color: resolved,
                              )
                            : LingoNavGlyphIcon(
                                glyph: glyph,
                                color: resolved,
                                highlight: theme.colors.surfaceRaised,
                                selected: selected,
                                size: iconSize,
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

double _glassPosition(double t) {
  if (t <= 0) {
    return 0;
  }
  if (t >= 1) {
    return 1;
  }
  const double peakAt = 0.52;
  const double overshoot = 1.032;
  if (t < peakAt) {
    return Curves.easeOutCubic.transform(t / peakAt) * overshoot;
  }
  final double u = (t - peakAt) / (1 - peakAt);
  return overshoot + (1 - overshoot) * Curves.easeInOutCubic.transform(u);
}

double _glassWidth(double t, double travel) {
  final double stretch = (0.09 + travel * 0.06).clamp(0.09, 0.18);
  if (t <= 0 || t >= 1) {
    return 1;
  }
  if (t < 0.20) {
    return 1 + stretch * Curves.easeOut.transform(t / 0.20);
  }
  if (t < 0.52) {
    return 1 + stretch;
  }
  if (t < 0.76) {
    final double u = (t - 0.52) / 0.24;
    return (1 + stretch) +
        (0.96 - (1 + stretch)) * Curves.easeInOut.transform(u);
  }
  final double u = (t - 0.76) / 0.24;
  return 0.96 + 0.04 * Curves.easeOut.transform(u);
}
