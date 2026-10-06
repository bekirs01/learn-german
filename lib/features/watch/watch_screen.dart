import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lingo_core/app/content_scope.dart';
import 'package:lingo_core/app/lingo_navigation.dart';
import 'package:lingo_core/core/feedback/feedback_service.dart';
import 'package:lingo_core/core/l10n/ui_strings.dart';
import 'package:lingo_core/core/theme/app_theme.dart';
import 'package:lingo_core/core/theme/lingo_tokens.dart';
import 'package:lingo_core/core/widgets/lingo_widgets.dart';
import 'package:lingo_core/data/user_preferences.dart';
import 'package:lingo_core/domain/content_repository.dart';
import 'package:lingo_core/domain/watch_companion_draft.dart';
import 'package:lingo_core/domain/watch_learning_plan.dart';
import 'package:lingo_core/features/watch/watch_catalog.dart';
import 'package:lingo_core/features/watch/watch_companion_service.dart';
import 'package:lingo_core/features/watch/watch_picker_screen.dart';
import 'package:lingo_core/features/watch/watch_widgets.dart';

/// iPhone-side Apple Watch companion management.
class WatchScreen extends StatefulWidget {
  const WatchScreen({super.key});

  static const ValueKey<String> screenKey = ValueKey<String>('watch-screen');
  static const ValueKey<String> statusKey = ValueKey<String>('watch-status');
  static const ValueKey<String> previewKey = ValueKey<String>('watch-preview');
  static const ValueKey<String> wordsKey = ValueKey<String>('watch-words');
  static const ValueKey<String> phrasesKey = ValueKey<String>('watch-phrases');
  static const ValueKey<String> bothKey = ValueKey<String>('watch-both');
  static const ValueKey<String> sendKey = ValueKey<String>('watch-send');
  static const ValueKey<String> chooseKey = ValueKey<String>('watch-choose');
  static const ValueKey<String> clearKey = ValueKey<String>('watch-clear');
  static const ValueKey<String> summaryKey = ValueKey<String>(
    'watch-selection-summary',
  );
  static const ValueKey<String> scheduleEnabledKey = ValueKey<String>(
    'watch-schedule-enabled',
  );
  static const ValueKey<String> frequencyDecreaseKey = ValueKey<String>(
    'watch-frequency-decrease',
  );
  static const ValueKey<String> frequencyIncreaseKey = ValueKey<String>(
    'watch-frequency-increase',
  );
  static const ValueKey<String> windowStartDecreaseKey = ValueKey<String>(
    'watch-window-start-decrease',
  );
  static const ValueKey<String> windowStartIncreaseKey = ValueKey<String>(
    'watch-window-start-increase',
  );
  static const ValueKey<String> windowEndDecreaseKey = ValueKey<String>(
    'watch-window-end-decrease',
  );
  static const ValueKey<String> windowEndIncreaseKey = ValueKey<String>(
    'watch-window-end-increase',
  );

  static ValueKey<String> itemKey(String id) =>
      ValueKey<String>('watch-item-$id');

  @override
  State<WatchScreen> createState() => _WatchScreenState();
}

class _WatchScreenState extends State<WatchScreen> {
  WatchCompanionStatus _status = WatchCompanionStatus.unavailable;
  bool _sending = false;
  LingoStatus _sendStatus = LingoStatus.idle;
  String? _sendMessage;
  Timer? _statusReset;

  @override
  void initState() {
    super.initState();
    unawaited(_refreshStatus());
  }

  @override
  void dispose() {
    _statusReset?.cancel();
    super.dispose();
  }

  Future<void> _refreshStatus() async {
    final WatchCompanionStatus status = await WatchCompanionService.instance
        .getStatus();
    if (!mounted) {
      return;
    }
    setState(() => _status = status);
  }

  Future<void> _save(WatchCompanionDraft draft) {
    return UserPreferences.instance.setWatchDraft(draft);
  }

  void _queueStatusReset() {
    _statusReset?.cancel();
    _statusReset = Timer(const Duration(milliseconds: 1600), () {
      if (!mounted) {
        return;
      }
      if (_sendStatus == LingoStatus.success) {
        setState(() => _sendStatus = LingoStatus.idle);
      }
    });
  }

  Future<void> _send({
    required ContentRepository content,
    required String language,
    required WatchCompanionDraft draft,
  }) async {
    if (_sending) {
      return;
    }
    final WatchPlanIssue? issue = WatchLearningPlan.validate(draft);
    if (issue != null) {
      setState(() {
        _sendStatus = LingoStatus.idle;
        _sendMessage = watchIssueMessage(context, issue);
      });
      FeedbackService.play(FeedbackEvent.error);
      return;
    }
    setState(() {
      _sending = true;
      _sendStatus = LingoStatus.idle;
      _sendMessage = null;
    });
    final int now = DateTime.now().millisecondsSinceEpoch;
    final Map<String, Object> payload = WatchCatalog.syncPayload(
      content: content,
      draft: draft,
      learnerLanguageCode: language,
      updatedAtEpochMs: now,
    );
    final WatchSyncResult result = await WatchCompanionService.instance
        .syncLearningPlan(payload, previous: draft.lastSyncOutcome);
    if (!mounted) {
      return;
    }
    final WatchCompanionDraft next = draft.withSync(
      result.outcome,
      now,
      learnerLanguageCode: language,
    );
    await _save(next);
    setState(() {
      _sending = false;
      _sendStatus = result.succeeded ? LingoStatus.success : LingoStatus.idle;
      _sendMessage = watchOutcomeMessage(context, result.outcome);
    });
    FeedbackService.play(
      result.succeeded ? FeedbackEvent.success : FeedbackEvent.error,
    );
    if (result.succeeded) {
      _queueStatusReset();
    }
    unawaited(_refreshStatus());
  }

  @override
  Widget build(BuildContext context) {
    final LingoMetrics metrics = LingoMetrics.of(context);
    final double gap = metrics.isCompact ? LingoSpacing.md : LingoSpacing.lg;
    final LingoTheme theme = LingoTheme.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: UserPreferences.instance,
      builder: (BuildContext context, Widget? _) {
        final ContentRepository content = ContentScope.of(context);
        final String language = ContentScope.translationLanguageOf(context);
        final WatchCompanionDraft raw = UserPreferences.instance
            .getWatchDraft();
        final WatchCompanionDraft draft = raw.pruned(
          wordIds: WatchCatalog.wordIds(content),
          phraseIds: WatchCatalog.phraseIds(content),
        );
        if (draft.wordIds.length != raw.wordIds.length ||
            draft.phraseIds.length != raw.phraseIds.length) {
          unawaited(_save(draft));
        }
        final List<WatchPlanItem> selected = WatchCatalog.selectedItems(
          content: content,
          draft: draft,
          learnerLanguageCode: language,
        );
        WatchPlanItem? previewItem = selected.isNotEmpty
            ? selected.first
            : null;
        if (previewItem == null) {
          final List<WatchPlanItem> words = WatchCatalog.items(
            content: content,
            learnerLanguageCode: language,
            filter: WatchContentFilter.words,
          );
          if (words.isNotEmpty) {
            previewItem = words.first;
          }
        }

        return LingoPage(
          key: WatchScreen.screenKey,
          title: UiStrings.of(context, UiKeys.watchTitle),
          body: LingoContent(
            storageKey: 'watch-companion',
            children: <Widget>[
              WatchStatusCard(
                key: WatchScreen.statusKey,
                status: _status,
                onHiddenProbe: kDebugMode
                    ? () {
                        unawaited(
                          _send(
                            content: content,
                            language: language,
                            draft: draft,
                          ),
                        );
                      }
                    : null,
              ),
              SizedBox(height: gap),
              WatchPreviewCard(
                key: WatchScreen.previewKey,
                item: previewItem,
                draft: draft,
              ),
              SizedBox(height: gap),
              WatchContentSummary(
                draft: draft,
                onFilterChanged: (WatchContentFilter next) {
                  if (next == draft.filter) {
                    return;
                  }
                  unawaited(_save(draft.copyWith(filter: next)));
                },
                onChoose: () {
                  LingoNavigation.push(context, const WatchPickerScreen());
                },
                onClear: draft.selectedCount == 0
                    ? null
                    : () {
                        unawaited(_save(draft.clearedSelection()));
                        FeedbackService.play(FeedbackEvent.selection);
                      },
              ),
              SizedBox(height: gap),
              WatchScheduleCard(
                draft: draft,
                onChanged: (WatchCompanionDraft next) {
                  unawaited(_save(next));
                },
              ),
              const SizedBox(height: LingoSpacing.xxl),
              LingoPrimaryButton(
                key: WatchScreen.sendKey,
                label: UiStrings.of(context, UiKeys.watchSendPreview),
                isLoading: _sending,
                status: _sendStatus,
                onPressed: () {
                  unawaited(
                    _send(content: content, language: language, draft: draft),
                  );
                },
              ),
              if (_syncLine(draft) != null) ...<Widget>[
                const SizedBox(height: LingoSpacing.sm),
                Text(
                  _syncLine(draft) ?? '',
                  key: const ValueKey<String>('watch-send-message'),
                  style: textTheme.bodySmall?.copyWith(
                    color: theme.colors.onSurfaceMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String? _syncLine(WatchCompanionDraft draft) {
    if (_sendMessage != null) {
      return _sendMessage;
    }
    final WatchSyncOutcome? outcome = draft.lastSyncOutcome;
    if (outcome == null) {
      return null;
    }
    return watchOutcomeMessage(context, outcome);
  }
}
