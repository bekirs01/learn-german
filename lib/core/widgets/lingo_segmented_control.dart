import 'package:flutter/material.dart';
import 'package:lingo_core/core/theme/app_theme.dart';
import 'package:lingo_core/core/theme/lingo_feedback.dart';
import 'package:lingo_core/core/theme/lingo_tokens.dart';
import 'package:lingo_core/core/widgets/lingo_motion.dart';

class LingoSegmentedControl extends StatelessWidget {
  const LingoSegmentedControl({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);
    final LingoMetrics metrics = LingoMetrics.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colors.paperFill,
        borderRadius: BorderRadius.circular(LingoRadii.xl),
        border: Border.all(color: theme.colors.paperRim, width: 0.7),
      ),
      child: Padding(
        padding: const EdgeInsets.all(LingoSpacing.xs),
        child: Row(
          children: <Widget>[
            for (int index = 0; index < labels.length; index++)
              Expanded(
                child: _Segment(
                  label: labels[index],
                  selected: index == selectedIndex,
                  minHeight: metrics.tapHeight(LingoSpacing.settingsRowCompact),
                  onPressed: () {
                    if (index == selectedIndex) {
                      return;
                    }
                    onChanged(index);
                    LingoFeedback.play(
                      LingoFeedbackKind.select,
                      identity: theme.identity,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.minHeight,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final double minHeight;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: LingoTapScale(
        onPressed: onPressed,
        child: AnimatedContainer(
          duration: LingoMetrics.of(context).motion(LingoMotion.quick),
          curve: LingoMotion.standardCurve,
          constraints: BoxConstraints(minHeight: minHeight),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? theme.colors.cardFill : Colors.transparent,
            borderRadius: BorderRadius.circular(LingoRadii.md),
            boxShadow: selected ? theme.shadows.paper : theme.shadows.none,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: LingoSpacing.md,
              vertical: LingoSpacing.sm,
            ),
            child: Text(
              label,
              style: textTheme.labelLarge?.copyWith(
                fontSize: 14,
                height: 1.2,
                letterSpacing: -0.08,
                color: selected
                    ? theme.colors.onSurface
                    : theme.colors.onSurfaceMuted,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
