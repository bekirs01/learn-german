import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lingo_core/core/feedback/feedback_service.dart';
import 'package:lingo_core/core/l10n/ui_strings.dart';
import 'package:lingo_core/core/theme/app_theme.dart';
import 'package:lingo_core/core/theme/lingo_feedback.dart';
import 'package:lingo_core/core/theme/lingo_tokens.dart';
import 'package:lingo_core/core/widgets/lingo_widgets.dart';
import 'package:lingo_core/domain/watch_companion_draft.dart';
import 'package:lingo_core/domain/watch_learning_plan.dart';
import 'package:lingo_core/features/watch/watch_companion_service.dart';

BoxDecoration watchPaperCard(LingoTheme theme) {
  return BoxDecoration(
    color: theme.colors.paperFill,
    borderRadius: LingoRadii.card,
    border: Border.all(color: theme.colors.paperRim, width: 0.7),
    boxShadow: theme.shadows.paper,
  );
}

String watchIssueMessage(BuildContext context, WatchPlanIssue issue) {
  switch (issue) {
    case WatchPlanIssue.noContent:
      return UiStrings.of(context, UiKeys.watchEmptySelection);
    case WatchPlanIssue.invalidWindow:
      return UiStrings.of(context, UiKeys.watchInvalidWindow);
    case WatchPlanIssue.zeroDeliveries:
      return UiStrings.of(context, UiKeys.watchZeroDeliveries);
    case WatchPlanIssue.unreasonableFrequency:
      return UiStrings.of(context, UiKeys.watchUnreasonableFrequency);
    case WatchPlanIssue.overLimit:
      return UiStrings.of(
        context,
        UiKeys.watchSelectionLimit,
        params: <String, String>{
          'count': '${WatchCompanionDraft.maxSelectedItems}',
        },
      );
  }
}

String watchOutcomeMessage(BuildContext context, WatchSyncOutcome outcome) {
  switch (outcome) {
    case WatchSyncOutcome.sent:
      return UiStrings.of(context, UiKeys.watchSyncSuccess);
    case WatchSyncOutcome.updated:
      return UiStrings.of(context, UiKeys.watchSyncUpdated);
    case WatchSyncOutcome.saved:
      return UiStrings.of(context, UiKeys.watchSyncSaved);
    case WatchSyncOutcome.unavailable:
      return UiStrings.of(context, UiKeys.watchStatusUnavailable);
    case WatchSyncOutcome.appNotInstalled:
      return UiStrings.of(context, UiKeys.watchStatusAppNotInstalled);
  }
}

String watchStatusTitle(BuildContext context, WatchCompanionStatus status) {
  switch (status.presence) {
    case WatchCompanionPresence.connected:
      return UiStrings.of(context, UiKeys.watchStatusConnected);
    case WatchCompanionPresence.ready:
      return UiStrings.of(context, UiKeys.watchStatusReady);
    case WatchCompanionPresence.appNotInstalled:
      return UiStrings.of(context, UiKeys.watchStatusAppNotInstalled);
    case WatchCompanionPresence.unsupported:
    case WatchCompanionPresence.unpaired:
      return UiStrings.of(context, UiKeys.watchStatusUnavailable);
  }
}

String watchFilterLabel(BuildContext context, WatchContentFilter filter) {
  final String words = UiStrings.of(context, UiKeys.navWords);
  final String phrases = UiStrings.of(context, UiKeys.navPhrases);
  switch (filter) {
    case WatchContentFilter.words:
      return words;
    case WatchContentFilter.phrases:
      return phrases;
    case WatchContentFilter.both:
      return '$words + $phrases';
  }
}

class WatchPaperCard extends StatelessWidget {
  const WatchPaperCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return LingoPaperSurface(
      padding:
          padding ??
          const EdgeInsets.fromLTRB(
            LingoSpacing.lg,
            LingoSpacing.md,
            LingoSpacing.lg,
            LingoSpacing.md,
          ),
      child: child,
    );
  }
}

class WatchStatusCard extends StatelessWidget {
  const WatchStatusCard({super.key, required this.status, this.onHiddenProbe});

  final WatchCompanionStatus status;
  final VoidCallback? onHiddenProbe;

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final (Color tone, bool positive) = switch (status.presence) {
      WatchCompanionPresence.connected => (theme.colors.success, true),
      WatchCompanionPresence.ready => (theme.colors.primary, true),
      WatchCompanionPresence.appNotInstalled => (theme.colors.warning, false),
      WatchCompanionPresence.unsupported ||
      WatchCompanionPresence.unpaired => (theme.colors.onSurfaceMuted, false),
    };

    final Widget card = WatchPaperCard(
      child: Row(
        children: <Widget>[
          WatchPresenceMark(color: tone, positive: positive),
          const SizedBox(width: LingoSpacing.md),
          Expanded(
            child: Text(
              watchStatusTitle(context, status),
              key: ValueKey<String>('watch-presence-${status.presence.name}'),
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: -0.16,
                height: 1.25,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    final VoidCallback? probe = onHiddenProbe;
    if (probe == null) {
      return card;
    }
    return GestureDetector(onLongPress: probe, child: card);
  }
}

class WatchPresenceMark extends StatelessWidget {
  const WatchPresenceMark({
    super.key,
    required this.color,
    this.positive = false,
  });

  final Color color;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);
    final Color wash =
        Color.lerp(theme.colors.paperFill, color, positive ? 0.18 : 0.10) ??
        color;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: wash,
        borderRadius: BorderRadius.circular(LingoRadii.lg),
        border: Border.all(color: theme.colors.paperRim, width: 0.7),
        boxShadow: theme.shadows.paper,
      ),
      child: SizedBox(
        width: 52,
        height: 58,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: CustomPaint(
            painter: WatchMarkPainter(
              tint: color,
              paper: theme.colors.cardFill,
              ink: theme.colors.onSurface,
              rim: theme.colors.paperRim,
            ),
          ),
        ),
      ),
    );
  }
}

/// Minimal Apple Watch silhouette painted in the paper palette.
class WatchMarkPainter extends CustomPainter {
  const WatchMarkPainter({
    required this.tint,
    required this.paper,
    required this.ink,
    required this.rim,
  });

  final Color tint;
  final Color paper;
  final Color ink;
  final Color rim;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.shortestSide;
    final Offset center = Offset(size.width * 0.48, size.height * 0.50);
    final Color body = Color.lerp(ink, tint, 0.28) ?? tint;
    final Paint band = Paint()
      ..color = body.withValues(alpha: 0.78)
      ..isAntiAlias = true;
    final Paint casePaint = Paint()
      ..color = body.withValues(alpha: 0.92)
      ..isAntiAlias = true;
    final Paint bezel = Paint()
      ..color = Color.lerp(body, paper, 0.22) ?? paper
      ..isAntiAlias = true;
    final Paint face = Paint()
      ..color = paper.withValues(alpha: 0.96)
      ..isAntiAlias = true;
    final Paint tick = Paint()
      ..color = ink.withValues(alpha: 0.42)
      ..strokeWidth = math.max(1, s * 0.028)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    final RRect upperBand = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy - s * 0.34),
        width: s * 0.38,
        height: s * 0.22,
      ),
      Radius.circular(s * 0.08),
    );
    final RRect lowerBand = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + s * 0.34),
        width: s * 0.38,
        height: s * 0.22,
      ),
      Radius.circular(s * 0.08),
    );
    canvas.drawRRect(upperBand, band);
    canvas.drawRRect(lowerBand, band);

    final RRect caseRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: s * 0.58, height: s * 0.70),
      Radius.circular(s * 0.16),
    );
    canvas.drawRRect(caseRect, casePaint);

    final RRect bezelRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: s * 0.48, height: s * 0.58),
      Radius.circular(s * 0.12),
    );
    canvas.drawRRect(bezelRect, bezel);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: s * 0.40, height: s * 0.48),
        Radius.circular(s * 0.10),
      ),
      face,
    );

    for (int index = 0; index < 12; index++) {
      if (index % 3 != 0) {
        continue;
      }
      final double angle = (index / 12) * math.pi * 2 - math.pi / 2;
      final Offset inner = Offset(
        center.dx + math.cos(angle) * s * 0.12,
        center.dy + math.sin(angle) * s * 0.14,
      );
      final Offset outer = Offset(
        center.dx + math.cos(angle) * s * 0.16,
        center.dy + math.sin(angle) * s * 0.19,
      );
      canvas.drawLine(inner, outer, tick);
    }

    final Paint hands = Paint()
      ..color = tint.withValues(alpha: 0.86)
      ..strokeWidth = math.max(1.2, s * 0.035)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;
    canvas.drawLine(center, Offset(center.dx, center.dy - s * 0.10), hands);
    canvas.drawLine(
      center,
      Offset(center.dx + s * 0.08, center.dy + s * 0.02),
      hands,
    );
    canvas.drawCircle(
      center,
      s * 0.018,
      Paint()
        ..color = tint
        ..isAntiAlias = true,
    );

    final RRect crown = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx + s * 0.32, center.dy - s * 0.06),
        width: s * 0.07,
        height: s * 0.12,
      ),
      Radius.circular(s * 0.03),
    );
    canvas.drawRRect(crown, casePaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx + s * 0.31, center.dy + s * 0.12),
          width: s * 0.045,
          height: s * 0.08,
        ),
        Radius.circular(s * 0.02),
      ),
      band,
    );

    canvas.drawRRect(
      caseRect,
      Paint()
        ..color = rim.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant WatchMarkPainter oldDelegate) {
    return oldDelegate.tint != tint ||
        oldDelegate.paper != paper ||
        oldDelegate.ink != ink ||
        oldDelegate.rim != rim;
  }
}

class WatchPreviewCard extends StatelessWidget {
  const WatchPreviewCard({super.key, required this.item, required this.draft});

  final WatchPlanItem? item;
  final WatchCompanionDraft draft;

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final WatchPlanItem? item = this.item;
    final String target = item?.targetText ?? 'Hello';
    final String meaning = item?.translation ?? 'Merhaba';
    final bool ghost = item == null;
    final bool showMeaning =
        meaning.trim().isNotEmpty &&
        meaning.trim().toLowerCase() != target.trim().toLowerCase();
    final String schedule = draft.scheduleEnabled
        ? UiStrings.of(
            context,
            UiKeys.watchPreviewSchedule,
            params: <String, String>{
              'count': '${draft.deliveriesPerDay}',
              'start': formatWatchClock(draft.windowStartMinutes),
              'end': formatWatchClock(draft.windowEndMinutes),
            },
          )
        : UiStrings.of(context, UiKeys.watchRemindersPaused);

    return WatchPaperCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          WatchPresenceMark(color: theme.colors.primary, positive: true),
          const SizedBox(width: LingoSpacing.md),
          Expanded(
            child: Opacity(
              opacity: ghost ? 0.62 : 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    target,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                      letterSpacing: -0.22,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (showMeaning) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      meaning,
                      style: textTheme.bodyMedium?.copyWith(
                        color: theme.colors.onSurfaceMuted,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: LingoSpacing.sm),
                  Text(
                    UiStrings.of(context, UiKeys.watchNextReminders),
                    style: textTheme.labelSmall?.copyWith(
                      color: theme.colors.onSurfaceFaint,
                      letterSpacing: 0.08,
                    ),
                  ),
                  Text(
                    schedule,
                    style: textTheme.labelMedium?.copyWith(
                      color: theme.colors.onSurfaceMuted,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.08,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WatchContentSummary extends StatelessWidget {
  const WatchContentSummary({
    super.key,
    required this.draft,
    required this.onFilterChanged,
    required this.onChoose,
    this.onClear,
  });

  final WatchCompanionDraft draft;
  final ValueChanged<WatchContentFilter> onFilterChanged;
  final VoidCallback onChoose;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final LingoMetrics metrics = LingoMetrics.of(context);
    final KeyedSubtree filterHost = KeyedSubtree(
      key: switch (draft.filter) {
        WatchContentFilter.words => const ValueKey<String>('watch-words'),
        WatchContentFilter.phrases => const ValueKey<String>('watch-phrases'),
        WatchContentFilter.both => const ValueKey<String>('watch-both'),
      },
      child: WatchFilterControl(
        filter: draft.filter,
        onChanged: onFilterChanged,
      ),
    );

    return WatchPaperCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            UiStrings.of(context, UiKeys.watchContentTitle),
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.16,
            ),
          ),
          const SizedBox(height: LingoSpacing.sm),
          filterHost,
          const SizedBox(height: LingoSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      UiStrings.of(
                        context,
                        UiKeys.watchSelectedCount,
                        params: <String, String>{
                          'count': '${draft.selectedCount}',
                        },
                      ),
                      key: const ValueKey<String>('watch-selection-summary'),
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      watchFilterLabel(context, draft.filter),
                      key: const ValueKey<String>('watch-filter-summary'),
                      style: textTheme.bodySmall?.copyWith(
                        color: theme.colors.onSurfaceMuted,
                      ),
                    ),
                    if (draft.selectedCount == 0) ...<Widget>[
                      const SizedBox(height: LingoSpacing.xs),
                      Text(
                        UiStrings.of(context, UiKeys.watchEmptySelection),
                        style: textTheme.bodySmall?.copyWith(
                          color: theme.colors.onSurfaceFaint,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (draft.selectedCount > 0 && onClear != null) ...<Widget>[
                const SizedBox(width: LingoSpacing.sm),
                LingoPressable(
                  key: const ValueKey<String>('watch-clear'),
                  onPressed: onClear,
                  enableHaptics: false,
                  color: theme.colors.cardFill,
                  depth: LingoElevation.rest,
                  borderRadius: LingoRadii.field,
                  minHeight: metrics.tapHeight(40),
                  padding: const EdgeInsets.symmetric(
                    horizontal: LingoSpacing.md,
                  ),
                  border: Border.all(color: theme.colors.paperRim, width: 0.7),
                  child: Center(
                    child: Text(
                      UiStrings.of(context, UiKeys.watchClearSelection),
                      style: textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: LingoSpacing.md),
          LingoPressable(
            key: const ValueKey<String>('watch-choose'),
            onPressed: onChoose,
            enableHaptics: false,
            color: theme.colors.cardFill,
            depth: LingoElevation.rest,
            borderRadius: LingoRadii.field,
            minHeight: metrics.tapHeight(48),
            padding: const EdgeInsets.symmetric(horizontal: LingoSpacing.md),
            border: Border.all(color: theme.colors.paperRim, width: 0.7),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    UiStrings.of(
                      context,
                      draft.selectedCount == 0
                          ? UiKeys.watchChooseContent
                          : UiKeys.watchChangeSelection,
                    ),
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  color: theme.colors.onSurfaceFaint,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WatchFilterControl extends StatelessWidget {
  const WatchFilterControl({
    super.key,
    required this.filter,
    required this.onChanged,
  });

  final WatchContentFilter filter;
  final ValueChanged<WatchContentFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final int selected = switch (filter) {
      WatchContentFilter.words => 0,
      WatchContentFilter.phrases => 1,
      WatchContentFilter.both => 2,
    };
    return LingoSegmentedControl(
      labels: <String>[
        UiStrings.of(context, UiKeys.navWords),
        UiStrings.of(context, UiKeys.navPhrases),
        UiStrings.of(context, UiKeys.watchContentBoth),
      ],
      selectedIndex: selected,
      onChanged: (int index) {
        onChanged(switch (index) {
          1 => WatchContentFilter.phrases,
          2 => WatchContentFilter.both,
          _ => WatchContentFilter.words,
        });
      },
    );
  }
}

class WatchItemRow extends StatelessWidget {
  const WatchItemRow({
    super.key,
    required this.item,
    required this.selected,
    required this.onPressed,
  });

  final WatchPlanItem item;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final LingoMetrics metrics = LingoMetrics.of(context);
    final String meaning = item.translation;
    final bool showMeaning =
        meaning.trim().isNotEmpty &&
        meaning.trim().toLowerCase() != item.targetText.trim().toLowerCase();
    final Color fill = selected
        ? (Color.lerp(
                theme.colors.paperFill,
                theme.colors.primaryContainer,
                theme.colors.isDark ? 0.38 : 0.28,
              ) ??
              theme.colors.paperFill)
        : theme.colors.paperFill.withValues(
            alpha: theme.colors.isDark ? 0.28 : 0.22,
          );
    final String semantic = showMeaning
        ? '${item.targetText}, $meaning'
        : item.targetText;

    return LingoPressable(
      onPressed: onPressed,
      enableHaptics: false,
      color: fill,
      depth: LingoElevation.flat,
      borderRadius: LingoRadii.field,
      minHeight: metrics.tapHeight(48),
      padding: const EdgeInsets.fromLTRB(
        LingoSpacing.md,
        LingoSpacing.sm,
        LingoSpacing.sm,
        LingoSpacing.sm,
      ),
      border: Border.all(
        color: selected
            ? theme.colors.primary.withValues(alpha: 0.28)
            : theme.colors.paperRim.withValues(alpha: 0.7),
        width: 0.7,
      ),
      semanticLabel: semantic,
      semanticButton: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.targetText,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                    letterSpacing: -0.14,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (showMeaning) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    meaning,
                    style: textTheme.bodySmall?.copyWith(
                      color: theme.colors.onSurfaceMuted,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: LingoSpacing.sm),
          WatchCheck(selected: selected),
        ],
      ),
    );
  }
}

class WatchCheck extends StatelessWidget {
  const WatchCheck({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);
    return AnimatedContainer(
      duration: LingoMetrics.of(context).motion(LingoMotion.quick),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: selected
            ? theme.colors.primary.withValues(alpha: 0.92)
            : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected
              ? theme.colors.primary.withValues(alpha: 0.0)
              : theme.colors.paperRim,
          width: 1,
        ),
      ),
      child: selected
          ? Icon(Icons.check_rounded, size: 13, color: theme.colors.onPrimary)
          : null,
    );
  }
}

class WatchScheduleCard extends StatelessWidget {
  const WatchScheduleCard({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  final WatchCompanionDraft draft;
  final ValueChanged<WatchCompanionDraft> onChanged;

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final LingoMetrics metrics = LingoMetrics.of(context);
    final bool stacked = metrics.isNarrow;
    final int maxDeliveries = draft.maxDeliveriesForSelectedWindow;
    final int deliveries = draft.clampedDeliveriesPerDay;

    return WatchPaperCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  UiStrings.of(context, UiKeys.watchScheduleEnabled),
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.16,
                  ),
                ),
              ),
              KeyedSubtree(
                key: const ValueKey<String>('watch-schedule-enabled'),
                child: LingoToggle(
                  value: draft.scheduleEnabled,
                  onChanged: (bool enabled) {
                    onChanged(draft.copyWith(scheduleEnabled: enabled));
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: LingoSpacing.lg),
          AnimatedOpacity(
            duration: metrics.motion(LingoMotion.quick),
            opacity: draft.scheduleEnabled ? 1 : 0.38,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  UiStrings.of(context, UiKeys.watchActiveHours),
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.16,
                  ),
                ),
                const SizedBox(height: LingoSpacing.sm),
                stacked
                    ? Column(
                        children: <Widget>[
                          WatchTimeWell(
                            label: UiStrings.of(
                              context,
                              UiKeys.watchWindowStart,
                            ),
                            value: formatWatchClock(draft.windowStartMinutes),
                            decreaseKey: const ValueKey<String>(
                              'watch-window-start-decrease',
                            ),
                            increaseKey: const ValueKey<String>(
                              'watch-window-start-increase',
                            ),
                            onDecrease: () => _shiftStart(-1),
                            onIncrease: () => _shiftStart(1),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: LingoSpacing.sm,
                            ),
                            child: Icon(
                              Icons.arrow_downward_rounded,
                              size: 16,
                              color: theme.colors.onSurfaceFaint,
                            ),
                          ),
                          WatchTimeWell(
                            label: UiStrings.of(context, UiKeys.watchWindowEnd),
                            value: formatWatchClock(draft.windowEndMinutes),
                            decreaseKey: const ValueKey<String>(
                              'watch-window-end-decrease',
                            ),
                            increaseKey: const ValueKey<String>(
                              'watch-window-end-increase',
                            ),
                            onDecrease: () => _shiftEnd(-1),
                            onIncrease: () => _shiftEnd(1),
                          ),
                        ],
                      )
                    : Row(
                        children: <Widget>[
                          Expanded(
                            child: WatchTimeWell(
                              label: UiStrings.of(
                                context,
                                UiKeys.watchWindowStart,
                              ),
                              value: formatWatchClock(draft.windowStartMinutes),
                              decreaseKey: const ValueKey<String>(
                                'watch-window-start-decrease',
                              ),
                              increaseKey: const ValueKey<String>(
                                'watch-window-start-increase',
                              ),
                              onDecrease: () => _shiftStart(-1),
                              onIncrease: () => _shiftStart(1),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: LingoSpacing.sm,
                            ),
                            child: Transform.scale(
                              scaleX:
                                  Directionality.of(context) ==
                                      TextDirection.rtl
                                  ? -1
                                  : 1,
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                size: 16,
                                color: theme.colors.onSurfaceFaint,
                              ),
                            ),
                          ),
                          Expanded(
                            child: WatchTimeWell(
                              label: UiStrings.of(
                                context,
                                UiKeys.watchWindowEnd,
                              ),
                              value: formatWatchClock(draft.windowEndMinutes),
                              decreaseKey: const ValueKey<String>(
                                'watch-window-end-decrease',
                              ),
                              increaseKey: const ValueKey<String>(
                                'watch-window-end-increase',
                              ),
                              onDecrease: () => _shiftEnd(-1),
                              onIncrease: () => _shiftEnd(1),
                            ),
                          ),
                        ],
                      ),
                const SizedBox(height: LingoSpacing.lg),
                Text(
                  UiStrings.of(context, UiKeys.watchReminders),
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.16,
                  ),
                ),
                const SizedBox(height: LingoSpacing.sm),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        UiStrings.of(
                          context,
                          UiKeys.watchTimesPerDay,
                          params: <String, String>{'count': '$deliveries'},
                        ),
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                          fontFeatures: const <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                    ),
                    WatchStepButton(
                      key: const ValueKey<String>('watch-frequency-decrease'),
                      icon: Icons.remove_rounded,
                      enabled:
                          deliveries > WatchCompanionDraft.minDeliveriesPerDay,
                      onPressed: () {
                        onChanged(
                          draft
                              .copyWith(deliveriesPerDay: deliveries - 1)
                              .clampedToWindow(),
                        );
                        FeedbackService.play(FeedbackEvent.selection);
                      },
                    ),
                    const SizedBox(width: LingoSpacing.xs),
                    WatchStepButton(
                      key: const ValueKey<String>('watch-frequency-increase'),
                      icon: Icons.add_rounded,
                      enabled: deliveries < maxDeliveries,
                      onPressed: () {
                        onChanged(
                          draft
                              .copyWith(deliveriesPerDay: deliveries + 1)
                              .clampedToWindow(),
                        );
                        FeedbackService.play(FeedbackEvent.selection);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _shiftStart(int steps) {
    final int next =
        draft.windowStartMinutes + steps * WatchCompanionDraft.timeStepMinutes;
    final int maxStart =
        draft.windowEndMinutes - WatchCompanionDraft.timeStepMinutes;
    onChanged(
      draft
          .copyWith(windowStartMinutes: next.clamp(0, maxStart))
          .clampedToWindow(),
    );
    FeedbackService.play(FeedbackEvent.selection);
  }

  void _shiftEnd(int steps) {
    final int next =
        draft.windowEndMinutes + steps * WatchCompanionDraft.timeStepMinutes;
    final int minEnd =
        draft.windowStartMinutes + WatchCompanionDraft.timeStepMinutes;
    onChanged(
      draft
          .copyWith(
            windowEndMinutes: next.clamp(
              minEnd,
              24 * 60 - WatchCompanionDraft.timeStepMinutes,
            ),
          )
          .clampedToWindow(),
    );
    FeedbackService.play(FeedbackEvent.selection);
  }
}

class WatchTimeWell extends StatelessWidget {
  const WatchTimeWell({
    super.key,
    required this.label,
    required this.value,
    required this.decreaseKey,
    required this.increaseKey,
    required this.onDecrease,
    required this.onIncrease,
  });

  final String label;
  final String value;
  final Key decreaseKey;
  final Key increaseKey;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colors.cardFill.withValues(
          alpha: theme.colors.isDark ? 0.55 : 0.72,
        ),
        borderRadius: LingoRadii.field,
        border: Border.all(color: theme.colors.paperRim, width: 0.7),
        boxShadow: theme.shadows.paper,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          LingoSpacing.sm,
          LingoSpacing.sm,
          LingoSpacing.xs,
          LingoSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: theme.colors.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    value,
                    style: textTheme.titleLarge?.copyWith(
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.4,
                      height: 1.1,
                    ),
                  ),
                ),
                WatchStepButton(
                  key: decreaseKey,
                  icon: Icons.remove_rounded,
                  compact: true,
                  onPressed: onDecrease,
                ),
                WatchStepButton(
                  key: increaseKey,
                  icon: Icons.add_rounded,
                  compact: true,
                  onPressed: onIncrease,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class WatchStepButton extends StatelessWidget {
  const WatchStepButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.enabled = true,
    this.compact = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool enabled;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);
    final double extent = compact ? 36 : 40;

    return LingoPressable(
      onPressed: enabled ? onPressed : null,
      enabled: enabled,
      enableHaptics: false,
      feedbackKind: LingoFeedbackKind.none,
      color: theme.colors.paperFill,
      depth: LingoElevation.rest,
      borderRadius: BorderRadius.circular(LingoRadii.sm),
      width: extent,
      height: extent,
      minHeight: extent,
      padding: EdgeInsets.zero,
      border: Border.all(color: theme.colors.paperRim, width: 0.7),
      child: Icon(
        icon,
        size: 16,
        color: enabled ? theme.colors.onSurface : theme.colors.onDisabled,
      ),
    );
  }
}

class WatchPickerSectionTitle extends StatelessWidget {
  const WatchPickerSectionTitle({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        top: LingoSpacing.sm,
        bottom: LingoSpacing.xs,
        start: LingoSpacing.xs,
      ),
      child: Text(
        label,
        style: textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.12,
        ),
      ),
    );
  }
}

class WatchPickerCategoryTitle extends StatelessWidget {
  const WatchPickerCategoryTitle({
    super.key,
    required this.label,
    this.indented = false,
  });

  final String label;
  final bool indented;

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsetsDirectional.only(
        top: LingoSpacing.sm,
        bottom: LingoSpacing.xs,
        start: indented ? LingoSpacing.md : LingoSpacing.xs,
      ),
      child: Text(
        label,
        style: textTheme.labelLarge?.copyWith(
          color: theme.colors.onSurfaceMuted,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
