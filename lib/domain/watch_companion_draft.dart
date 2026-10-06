import 'package:lingo_core/domain/content_models.dart';

/// Which curriculum lists the learner is currently curating for Watch.
enum WatchContentFilter { words, phrases, both }

/// Stable content kind used in the shared Watch payload `type` field.
enum WatchItemType { word, phrase }

/// Last user-facing sync result persisted on iPhone.
enum WatchSyncOutcome { sent, updated, saved, unavailable, appNotInstalled }

/// Local, unpublished Watch companion plan.
final class WatchCompanionDraft {
  const WatchCompanionDraft({
    required this.filter,
    required this.wordIds,
    required this.phraseIds,
    required this.scheduleEnabled,
    required this.windowStartMinutes,
    required this.windowEndMinutes,
    required this.deliveriesPerDay,
    this.lastSyncOutcome,
    this.lastSyncAtEpochMs,
    this.lastSyncedLearnerLanguage,
  });

  static const int defaultStartMinutes = 9 * 60;
  static const int defaultEndMinutes = 21 * 60;
  static const int defaultDeliveriesPerDay = 5;
  static const int minDeliveriesPerDay = 1;
  static const int maxRemindersPerDensityWindow = 10;
  static const int reminderDensityWindowMinutes = 30;
  static const int maxDeliveriesPerDay =
      maxRemindersPerDensityWindow *
      ((24 * 60) ~/ reminderDensityWindowMinutes);
  static const int timeStepMinutes = 30;
  static const int maxSelectedItems = 24;
  static const int starterSetSize = 12;
  static const String scheduleMode = 'window_frequency';
  static const int schemaVersion = 1;

  static const WatchCompanionDraft initial = WatchCompanionDraft(
    filter: WatchContentFilter.words,
    wordIds: <String>{},
    phraseIds: <String>{},
    scheduleEnabled: true,
    windowStartMinutes: defaultStartMinutes,
    windowEndMinutes: defaultEndMinutes,
    deliveriesPerDay: defaultDeliveriesPerDay,
  );

  final WatchContentFilter filter;
  final Set<String> wordIds;
  final Set<String> phraseIds;
  final bool scheduleEnabled;
  final int windowStartMinutes;
  final int windowEndMinutes;
  final int deliveriesPerDay;
  final WatchSyncOutcome? lastSyncOutcome;
  final int? lastSyncAtEpochMs;
  final String? lastSyncedLearnerLanguage;

  /// Back-compat for callers that still branch on quiz kind.
  QuizContentKind get kind {
    return filter == WatchContentFilter.phrases
        ? QuizContentKind.phrase
        : QuizContentKind.word;
  }

  /// IDs currently shown for the active content filter.
  Set<String> get selectedIds {
    switch (filter) {
      case WatchContentFilter.words:
        return wordIds;
      case WatchContentFilter.phrases:
        return phraseIds;
      case WatchContentFilter.both:
        return Set<String>.unmodifiable(<String>{...wordIds, ...phraseIds});
    }
  }

  /// Total Watch items across words and phrases. The send limit is global.
  int get selectedCount => wordIds.length + phraseIds.length;

  bool get isAtSelectionLimit => selectedCount >= maxSelectedItems;

  /// Highest reminder count that stays at or under 10 per 30 minutes.
  static int maxDeliveriesForWindow(int startMinutes, int endMinutes) {
    final int span = endMinutes - startMinutes;
    if (span <= 0) {
      return minDeliveriesPerDay;
    }
    final int windows =
        (span + reminderDensityWindowMinutes - 1) ~/
        reminderDensityWindowMinutes;
    final int capacity = windows * maxRemindersPerDensityWindow;
    if (capacity < minDeliveriesPerDay) {
      return minDeliveriesPerDay;
    }
    return capacity.clamp(minDeliveriesPerDay, maxDeliveriesPerDay);
  }

  int get maxDeliveriesForSelectedWindow {
    return maxDeliveriesForWindow(windowStartMinutes, windowEndMinutes);
  }

  int get clampedDeliveriesPerDay {
    if (deliveriesPerDay < minDeliveriesPerDay) {
      return deliveriesPerDay;
    }
    return deliveriesPerDay.clamp(
      minDeliveriesPerDay,
      maxDeliveriesForSelectedWindow,
    );
  }

  /// Drops the reminder count when the active window can no longer hold it.
  WatchCompanionDraft clampedToWindow() {
    final int next = clampedDeliveriesPerDay;
    if (next == deliveriesPerDay) {
      return this;
    }
    return copyWith(deliveriesPerDay: next);
  }

  bool includes(WatchItemType type) {
    switch (filter) {
      case WatchContentFilter.words:
        return type == WatchItemType.word;
      case WatchContentFilter.phrases:
        return type == WatchItemType.phrase;
      case WatchContentFilter.both:
        return true;
    }
  }

  bool isSelected(String id, WatchItemType type) {
    return type == WatchItemType.phrase
        ? phraseIds.contains(id)
        : wordIds.contains(id);
  }

  WatchCompanionDraft copyWith({
    WatchContentFilter? filter,
    Set<String>? wordIds,
    Set<String>? phraseIds,
    bool? scheduleEnabled,
    int? windowStartMinutes,
    int? windowEndMinutes,
    int? deliveriesPerDay,
    WatchSyncOutcome? lastSyncOutcome,
    int? lastSyncAtEpochMs,
    String? lastSyncedLearnerLanguage,
    bool clearLastSync = false,
  }) {
    return WatchCompanionDraft(
      filter: filter ?? this.filter,
      wordIds: wordIds ?? this.wordIds,
      phraseIds: phraseIds ?? this.phraseIds,
      scheduleEnabled: scheduleEnabled ?? this.scheduleEnabled,
      windowStartMinutes: windowStartMinutes ?? this.windowStartMinutes,
      windowEndMinutes: windowEndMinutes ?? this.windowEndMinutes,
      deliveriesPerDay: deliveriesPerDay ?? this.deliveriesPerDay,
      lastSyncOutcome: clearLastSync
          ? lastSyncOutcome
          : (lastSyncOutcome ?? this.lastSyncOutcome),
      lastSyncAtEpochMs: clearLastSync
          ? lastSyncAtEpochMs
          : (lastSyncAtEpochMs ?? this.lastSyncAtEpochMs),
      lastSyncedLearnerLanguage: clearLastSync
          ? lastSyncedLearnerLanguage
          : (lastSyncedLearnerLanguage ?? this.lastSyncedLearnerLanguage),
    );
  }

  WatchToggleResult toggled(String id, WatchItemType type) {
    final String trimmed = id.trim();
    if (trimmed.isEmpty) {
      return WatchToggleResult(draft: this);
    }
    final Set<String> current = Set<String>.of(
      type == WatchItemType.phrase ? phraseIds : wordIds,
    );
    if (current.contains(trimmed)) {
      current.remove(trimmed);
      return WatchToggleResult(
        draft: type == WatchItemType.phrase
            ? copyWith(phraseIds: Set<String>.unmodifiable(current))
            : copyWith(wordIds: Set<String>.unmodifiable(current)),
      );
    }
    if (selectedCount >= maxSelectedItems) {
      return WatchToggleResult(draft: this, atLimit: true);
    }
    current.add(trimmed);
    return WatchToggleResult(
      draft: type == WatchItemType.phrase
          ? copyWith(phraseIds: Set<String>.unmodifiable(current))
          : copyWith(wordIds: Set<String>.unmodifiable(current)),
    );
  }

  WatchCompanionDraft clearedSelection() {
    switch (filter) {
      case WatchContentFilter.words:
        return copyWith(wordIds: const <String>{});
      case WatchContentFilter.phrases:
        return copyWith(phraseIds: const <String>{});
      case WatchContentFilter.both:
        return copyWith(wordIds: const <String>{}, phraseIds: const <String>{});
    }
  }

  WatchCompanionDraft addingStarter(Iterable<WatchPlanItem> catalog) {
    if (isAtSelectionLimit) {
      return this;
    }
    final Set<String> nextWords = Set<String>.of(wordIds);
    final Set<String> nextPhrases = Set<String>.of(phraseIds);
    int remaining = maxSelectedItems - selectedCount;
    int added = 0;
    for (final WatchPlanItem item in catalog) {
      if (remaining <= 0 || added >= starterSetSize) {
        break;
      }
      if (!includes(item.type)) {
        continue;
      }
      final Set<String> bucket = item.type == WatchItemType.phrase
          ? nextPhrases
          : nextWords;
      if (!bucket.add(item.id)) {
        continue;
      }
      remaining -= 1;
      added += 1;
    }
    if (added == 0) {
      return this;
    }
    return copyWith(
      wordIds: Set<String>.unmodifiable(nextWords),
      phraseIds: Set<String>.unmodifiable(nextPhrases),
    );
  }

  WatchCompanionDraft pruned({
    required Set<String> wordIds,
    required Set<String> phraseIds,
  }) {
    final Set<String> words = Set<String>.unmodifiable(
      this.wordIds.where(wordIds.contains),
    );
    final Set<String> phrases = Set<String>.unmodifiable(
      this.phraseIds.where(phraseIds.contains),
    );
    if (words.length == this.wordIds.length &&
        phrases.length == this.phraseIds.length) {
      return this;
    }
    return copyWith(wordIds: words, phraseIds: phrases);
  }

  WatchCompanionDraft withSync(
    WatchSyncOutcome outcome,
    int epochMs, {
    String? learnerLanguageCode,
  }) {
    return copyWith(
      lastSyncOutcome: outcome,
      lastSyncAtEpochMs: epochMs,
      lastSyncedLearnerLanguage: learnerLanguageCode,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'filter': filter.name,
      'kind': kind.name,
      'wordIds': List<String>.unmodifiable(wordIds),
      'phraseIds': List<String>.unmodifiable(phraseIds),
      'scheduleEnabled': scheduleEnabled,
      'windowStartMinutes': windowStartMinutes,
      'windowEndMinutes': windowEndMinutes,
      'deliveriesPerDay': deliveriesPerDay,
      'lastSyncOutcome': lastSyncOutcome?.name,
      'lastSyncAtEpochMs': lastSyncAtEpochMs,
      'lastSyncedLearnerLanguage': lastSyncedLearnerLanguage,
    };
  }

  static WatchCompanionDraft tryParse(Object? raw) {
    if (raw is! Map) {
      return initial;
    }
    final Map<Object?, Object?> map = raw;
    final int startMinutes = _minutes(
      map['windowStartMinutes'],
      defaultStartMinutes,
    );
    final int endMinutes = _minutes(map['windowEndMinutes'], defaultEndMinutes);
    return WatchCompanionDraft(
      filter: _filter(map),
      wordIds: _ids(map['wordIds']),
      phraseIds: _ids(map['phraseIds']),
      scheduleEnabled: _bool(map['scheduleEnabled'], true),
      windowStartMinutes: startMinutes,
      windowEndMinutes: endMinutes,
      deliveriesPerDay: _deliveries(
        map['deliveriesPerDay'],
        startMinutes: startMinutes,
        endMinutes: endMinutes,
      ),
      lastSyncOutcome: _outcome(map['lastSyncOutcome']),
      lastSyncAtEpochMs: _epoch(map['lastSyncAtEpochMs']),
      lastSyncedLearnerLanguage: _language(map['lastSyncedLearnerLanguage']),
    );
  }

  static WatchContentFilter _filter(Map<Object?, Object?> map) {
    final String? named = map['filter'] is String
        ? map['filter'] as String
        : null;
    switch (named) {
      case 'phrases':
        return WatchContentFilter.phrases;
      case 'both':
        return WatchContentFilter.both;
      case 'words':
        return WatchContentFilter.words;
    }
    return map['kind'] == QuizContentKind.phrase.name
        ? WatchContentFilter.phrases
        : WatchContentFilter.words;
  }

  static Set<String> _ids(Object? raw) {
    if (raw is! List) {
      return const <String>{};
    }
    return Set<String>.unmodifiable(<String>[
      for (final Object? item in raw)
        if (item is String && item.trim().isNotEmpty) item.trim(),
    ]);
  }

  static int _minutes(Object? raw, int fallback) {
    final int? value = raw is int ? raw : int.tryParse('$raw');
    if (value == null) {
      return fallback;
    }
    return value.clamp(0, 24 * 60 - timeStepMinutes);
  }

  static int _deliveries(
    Object? raw, {
    required int startMinutes,
    required int endMinutes,
  }) {
    final int max = maxDeliveriesForWindow(startMinutes, endMinutes);
    final int? value = raw is int ? raw : int.tryParse('$raw');
    if (value == null) {
      return defaultDeliveriesPerDay.clamp(minDeliveriesPerDay, max);
    }
    return value.clamp(minDeliveriesPerDay, max);
  }

  static bool _bool(Object? raw, bool fallback) {
    if (raw is bool) {
      return raw;
    }
    return fallback;
  }

  static WatchSyncOutcome? _outcome(Object? raw) {
    if (raw is! String) {
      return null;
    }
    for (final WatchSyncOutcome value in WatchSyncOutcome.values) {
      if (value.name == raw) {
        return value;
      }
    }
    return null;
  }

  static int? _epoch(Object? raw) {
    if (raw is int) {
      return raw;
    }
    return int.tryParse('$raw');
  }

  static String? _language(Object? raw) {
    if (raw is! String) {
      return null;
    }
    final String trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

final class WatchToggleResult {
  const WatchToggleResult({required this.draft, this.atLimit = false});

  final WatchCompanionDraft draft;
  final bool atLimit;
}

/// One curriculum row that can be sent to Watch.
final class WatchPlanItem {
  const WatchPlanItem({
    required this.id,
    required this.type,
    required this.targetText,
    required this.translation,
    this.pronunciationId,
    this.translationMissing = false,
  });

  final String id;
  final WatchItemType type;

  /// Target-language content from the curriculum row. Never a translation.
  final String targetText;

  /// Meaning in the current learner / Translation Language.
  final String translation;

  /// Audio key for this row. Matches the content ID / expected-audio key.
  final String? pronunciationId;

  /// True when the learner-language bundle had no usable string for [id].
  final bool translationMissing;

  String get typeName => type.name;

  String get audioKey => pronunciationId ?? id;

  Map<String, Object> toPayload() {
    return <String, Object>{
      'id': id,
      'type': typeName,
      'targetText': targetText,
      'translation': translation,
      'pronunciationId': audioKey,
    };
  }
}

/// Formats minutes from midnight as a compact 24-hour clock.
String formatWatchClock(int minutes) {
  final int wrapped = minutes.clamp(0, 24 * 60 - 1);
  final int hour = wrapped ~/ 60;
  final int minute = wrapped % 60;
  return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
