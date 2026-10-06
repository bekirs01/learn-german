import 'package:lingo_core/core/l10n/learner_languages.dart';
import 'package:lingo_core/data/user_preferences.dart';
import 'package:lingo_core/domain/content_repository.dart';
import 'package:lingo_core/domain/watch_companion_draft.dart';
import 'package:lingo_core/features/watch/watch_catalog.dart';
import 'package:lingo_core/features/watch/watch_companion_service.dart';

/// Rebuilds the current Watch plan when Translation Language changes.
///
/// Selected IDs and target text stay in place. Only learner language,
/// meanings, and Watch chrome language are refreshed.
abstract final class WatchLearnerLanguageSync {
  static bool wasDelivered(WatchCompanionDraft draft) {
    switch (draft.lastSyncOutcome) {
      case WatchSyncOutcome.sent:
      case WatchSyncOutcome.updated:
      case WatchSyncOutcome.saved:
        return true;
      case WatchSyncOutcome.unavailable:
      case WatchSyncOutcome.appNotInstalled:
      case null:
        return false;
    }
  }

  static Future<WatchSyncResult?> refresh({
    required ContentRepository content,
    required String learnerLanguageCode,
    int? updatedAtEpochMs,
    bool force = false,
  }) async {
    final String learner = LearnerLanguages.baseCode(learnerLanguageCode);
    final WatchCompanionDraft raw = UserPreferences.instance.getWatchDraft();
    final WatchCompanionDraft draft = raw.pruned(
      wordIds: WatchCatalog.wordIds(content),
      phraseIds: WatchCatalog.phraseIds(content),
    );
    if (!wasDelivered(draft)) {
      return null;
    }
    final String? previous = draft.lastSyncedLearnerLanguage;
    if (!force &&
        previous != null &&
        LearnerLanguages.baseCode(previous) == learner) {
      return null;
    }
    final int now = updatedAtEpochMs ?? DateTime.now().millisecondsSinceEpoch;
    final Map<String, Object> payload = WatchCatalog.syncPayload(
      content: content,
      draft: draft,
      learnerLanguageCode: learner,
      updatedAtEpochMs: now,
    );
    final WatchSyncResult result = await WatchCompanionService.instance
        .syncLearningPlan(payload, previous: draft.lastSyncOutcome);
    if (result.succeeded) {
      await UserPreferences.instance.setWatchDraft(
        draft.withSync(result.outcome, now, learnerLanguageCode: learner),
      );
    }
    return result;
  }
}
