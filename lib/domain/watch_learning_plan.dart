import 'package:lingo_core/domain/watch_companion_draft.dart';

/// Concise reasons a Watch plan cannot be sent.
enum WatchPlanIssue {
  noContent,
  invalidWindow,
  zeroDeliveries,
  unreasonableFrequency,
  overLimit,
}

/// Builds and validates the frozen iPhone → Watch learning-plan contract.
abstract final class WatchLearningPlan {
  static const String mode = WatchCompanionDraft.scheduleMode;

  static WatchPlanIssue? validate(WatchCompanionDraft draft) {
    if (draft.selectedCount <= 0) {
      return WatchPlanIssue.noContent;
    }
    if (draft.selectedCount > WatchCompanionDraft.maxSelectedItems) {
      return WatchPlanIssue.overLimit;
    }
    if (!draft.scheduleEnabled) {
      return null;
    }
    if (draft.windowEndMinutes <= draft.windowStartMinutes) {
      return WatchPlanIssue.invalidWindow;
    }
    if (draft.deliveriesPerDay < WatchCompanionDraft.minDeliveriesPerDay) {
      return WatchPlanIssue.zeroDeliveries;
    }
    return null;
  }

  static Map<String, Object> payload({
    required WatchCompanionDraft draft,
    required List<WatchPlanItem> items,
    required String targetLanguageCode,
    required String learnerLanguageCode,
    required int updatedAtEpochMs,
  }) {
    final List<WatchPlanItem> sendable = <WatchPlanItem>[
      for (final WatchPlanItem item in items)
        if (draft.isSelected(item.id, item.type)) item,
    ];
    return <String, Object>{
      'schemaVersion': WatchCompanionDraft.schemaVersion,
      'targetLanguageCode': targetLanguageCode,
      'learnerLanguageCode': learnerLanguageCode,
      'items': <Map<String, Object>>[
        for (final WatchPlanItem item in sendable) item.toPayload(),
      ],
      'schedule': <String, Object>{
        'enabled': draft.scheduleEnabled,
        'mode': mode,
        'startMinutes': draft.windowStartMinutes,
        'endMinutes': draft.windowEndMinutes,
        'timesPerDay': draft.clampedDeliveriesPerDay,
      },
      'updatedAtEpochMs': updatedAtEpochMs,
    };
  }

  static Map<String, Object> emptyPayload({
    required String targetLanguageCode,
    required String learnerLanguageCode,
    required WatchCompanionDraft draft,
    required int updatedAtEpochMs,
  }) {
    return <String, Object>{
      'schemaVersion': WatchCompanionDraft.schemaVersion,
      'targetLanguageCode': targetLanguageCode,
      'learnerLanguageCode': learnerLanguageCode,
      'items': const <Map<String, Object>>[],
      'schedule': <String, Object>{
        'enabled': false,
        'mode': mode,
        'startMinutes': draft.windowStartMinutes,
        'endMinutes': draft.windowEndMinutes,
        'timesPerDay': draft.clampedDeliveriesPerDay,
      },
      'updatedAtEpochMs': updatedAtEpochMs,
    };
  }

  /// Next reminder minute-of-day for the Watch preview card.
  static int? nextReminderMinutes({
    required WatchCompanionDraft draft,
    required DateTime now,
  }) {
    if (!draft.scheduleEnabled) {
      return null;
    }
    if (draft.windowEndMinutes <= draft.windowStartMinutes) {
      return null;
    }
    final List<int> slots = reminderSlots(draft);
    if (slots.isEmpty) {
      return null;
    }
    final int nowMinutes = now.hour * 60 + now.minute;
    for (final int slot in slots) {
      if (slot > nowMinutes) {
        return slot;
      }
    }
    return slots.first;
  }

  static List<int> reminderSlots(WatchCompanionDraft draft) {
    final int start = draft.windowStartMinutes;
    final int end = draft.windowEndMinutes;
    if (end <= start) {
      return const <int>[];
    }
    if (draft.deliveriesPerDay < WatchCompanionDraft.minDeliveriesPerDay) {
      return const <int>[];
    }
    final int times = draft.clampedDeliveriesPerDay;
    if (times <= 1) {
      return <int>[start + ((end - start) ~/ 2)];
    }
    final int span = end - start;
    final List<int> slots = <int>[];
    for (int index = 0; index < times; index++) {
      int minute = start + ((span * index) / (times - 1)).round();
      if (slots.isNotEmpty && minute <= slots.last) {
        minute = slots.last + 1;
      }
      if (minute > end) {
        break;
      }
      slots.add(minute);
    }
    return _limitDensity(slots);
  }

  static List<int> _limitDensity(List<int> slots) {
    const int window = WatchCompanionDraft.reminderDensityWindowMinutes;
    const int cap = WatchCompanionDraft.maxRemindersPerDensityWindow;
    final List<int> next = List<int>.of(slots);
    while (next.length > cap) {
      int? dropAt;
      for (int index = 0; index + cap < next.length; index++) {
        if (next[index + cap] - next[index] > window) {
          continue;
        }
        int victim = index + 1;
        int tightest = next[victim] - next[victim - 1];
        for (int cursor = index + 2; cursor <= index + cap; cursor++) {
          final int gap = next[cursor] - next[cursor - 1];
          if (gap <= tightest) {
            tightest = gap;
            victim = cursor;
          }
        }
        dropAt = victim;
        break;
      }
      if (dropAt == null) {
        break;
      }
      next.removeAt(dropAt);
    }
    return next;
  }
}
