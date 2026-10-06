import 'package:flutter/foundation.dart';
import 'package:lingo_core/core/l10n/learner_languages.dart';
import 'package:lingo_core/domain/content_models.dart';
import 'package:lingo_core/domain/content_repository.dart';
import 'package:lingo_core/domain/quiz_text.dart';
import 'package:lingo_core/domain/watch_companion_draft.dart';
import 'package:lingo_core/domain/watch_learning_plan.dart';

/// Curriculum rows for Watch selection. Reads existing repositories only.
abstract final class WatchCatalog {
  static Set<String> wordIds(ContentRepository content) {
    return <String>{
      for (final ContentCategory category in content.wordCategories)
        for (final WordEntry word in content.wordsForCategory(category.id))
          word.id,
    };
  }

  static Set<String> phraseIds(ContentRepository content) {
    return <String>{
      for (final ContentCategory category in content.phraseCategories)
        for (final PhraseEntry phrase in content.phrasesForCategory(
          category.id,
        ))
          phrase.id,
    };
  }

  static List<WatchPlanItem> items({
    required ContentRepository content,
    required String learnerLanguageCode,
    WatchContentFilter filter = WatchContentFilter.both,
  }) {
    final List<WatchPlanItem> rows = <WatchPlanItem>[];
    if (filter != WatchContentFilter.phrases) {
      for (final ContentCategory category in content.wordCategories) {
        for (final WordEntry word in content.wordsForCategory(category.id)) {
          rows.add(_word(content, word, learnerLanguageCode));
        }
      }
    }
    if (filter != WatchContentFilter.words) {
      for (final ContentCategory category in content.phraseCategories) {
        for (final PhraseEntry phrase in content.phrasesForCategory(
          category.id,
        )) {
          rows.add(_phrase(content, phrase, learnerLanguageCode));
        }
      }
    }
    return rows;
  }

  static List<WatchPickerRow> pickerRows({
    required ContentRepository content,
    required String learnerLanguageCode,
    required WatchContentFilter filter,
    String query = '',
  }) {
    final String needle = query.trim().toLowerCase();
    final List<WatchPickerRow> rows = <WatchPickerRow>[];
    if (filter != WatchContentFilter.phrases) {
      _appendSection(
        rows: rows,
        section: filter == WatchContentFilter.both ? WatchItemType.word : null,
        categories: content.wordCategories,
        learnerLanguageCode: learnerLanguageCode,
        content: content,
        needle: needle,
        words: true,
      );
    }
    if (filter != WatchContentFilter.words) {
      _appendSection(
        rows: rows,
        section: filter == WatchContentFilter.both
            ? WatchItemType.phrase
            : null,
        categories: content.phraseCategories,
        learnerLanguageCode: learnerLanguageCode,
        content: content,
        needle: needle,
        words: false,
      );
    }
    return rows;
  }

  static WatchPlanItem? resolve(
    ContentRepository content,
    String id, {
    required String learnerLanguageCode,
  }) {
    final WordEntry? word = content.wordById(id);
    if (word != null) {
      return _word(content, word, learnerLanguageCode);
    }
    final PhraseEntry? phrase = content.phraseById(id);
    if (phrase != null) {
      return _phrase(content, phrase, learnerLanguageCode);
    }
    return null;
  }

  static List<WatchPlanItem> selectedItems({
    required ContentRepository content,
    required WatchCompanionDraft draft,
    required String learnerLanguageCode,
  }) {
    final List<WatchPlanItem> rows = <WatchPlanItem>[];
    for (final String id in draft.wordIds) {
      final WatchPlanItem? item = resolve(
        content,
        id,
        learnerLanguageCode: learnerLanguageCode,
      );
      if (item != null && item.type == WatchItemType.word) {
        rows.add(item);
      }
    }
    for (final String id in draft.phraseIds) {
      final WatchPlanItem? item = resolve(
        content,
        id,
        learnerLanguageCode: learnerLanguageCode,
      );
      if (item != null && item.type == WatchItemType.phrase) {
        rows.add(item);
      }
    }
    return rows;
  }

  /// Rebuilds Watch rows from stable IDs and the current learner language.
  /// Call this immediately before the iPhone → Watch sync so translations
  /// never stay bound to a previous Translation Language.
  static Map<String, Object> syncPayload({
    required ContentRepository content,
    required WatchCompanionDraft draft,
    required String learnerLanguageCode,
    required int updatedAtEpochMs,
  }) {
    return WatchLearningPlan.payload(
      draft: draft,
      items: selectedItems(
        content: content,
        draft: draft,
        learnerLanguageCode: learnerLanguageCode,
      ),
      targetLanguageCode: content.product.targetLanguageCode,
      learnerLanguageCode: learnerLanguageCode,
      updatedAtEpochMs: updatedAtEpochMs,
    );
  }

  /// Learner-language meaning only. Never uses [ProductConfig.targetLanguageCode]
  /// and never copies the target text into the translation field.
  static WatchResolvedMeaning meaningFor(
    ContentRepository content,
    String id, {
    required String learnerLanguageCode,
  }) {
    final String learner = LearnerLanguages.baseCode(learnerLanguageCode);
    final String? direct = _bundleValue(content, id, learner);
    if (direct != null) {
      return WatchResolvedMeaning(text: direct, missing: false);
    }
    final String? fallback = content.translation(id);
    debugPrint('Watch missing learner translation for "$id" in "$learner".');
    return WatchResolvedMeaning(text: fallback ?? '', missing: true);
  }

  static void _appendSection({
    required List<WatchPickerRow> rows,
    required WatchItemType? section,
    required List<ContentCategory> categories,
    required ContentRepository content,
    required String learnerLanguageCode,
    required String needle,
    required bool words,
  }) {
    final int marked = rows.length;
    if (section != null) {
      rows.add(WatchPickerRow.section(section));
    }
    _appendCategory(
      rows: rows,
      categories: categories,
      learnerLanguageCode: learnerLanguageCode,
      content: content,
      needle: needle,
      words: words,
    );
    if (section != null && rows.length == marked + 1) {
      rows.removeLast();
    }
  }

  static void _appendCategory({
    required List<WatchPickerRow> rows,
    required List<ContentCategory> categories,
    required ContentRepository content,
    required String learnerLanguageCode,
    required String needle,
    required bool words,
  }) {
    for (final ContentCategory category in categories) {
      final List<WatchPlanItem> items = <WatchPlanItem>[
        if (words)
          for (final WordEntry word in content.wordsForCategory(category.id))
            _word(content, word, learnerLanguageCode)
        else
          for (final PhraseEntry phrase in content.phrasesForCategory(
            category.id,
          ))
            _phrase(content, phrase, learnerLanguageCode),
      ];
      final List<WatchPlanItem> visible = needle.isEmpty
          ? items
          : <WatchPlanItem>[
              for (final WatchPlanItem item in items)
                if (_matches(item, needle)) item,
            ];
      if (visible.isEmpty) {
        continue;
      }
      rows.add(
        WatchPickerRow.header(
          content.labelFor(
            category.id,
            category.title,
            languageCode: learnerLanguageCode,
          ),
        ),
      );
      for (final WatchPlanItem item in visible) {
        rows.add(WatchPickerRow.item(item));
      }
    }
  }

  static bool _matches(WatchPlanItem item, String needle) {
    return QuizText.matchesQuery(item.targetText, needle) ||
        QuizText.matchesQuery(item.translation, needle);
  }

  static WatchPlanItem _word(
    ContentRepository content,
    WordEntry word,
    String learnerLanguageCode,
  ) {
    final WatchResolvedMeaning meaning = meaningFor(
      content,
      word.id,
      learnerLanguageCode: learnerLanguageCode,
    );
    return WatchPlanItem(
      id: word.id,
      type: WatchItemType.word,
      targetText: word.text,
      translation: meaning.text,
      pronunciationId: word.id,
      translationMissing: meaning.missing,
    );
  }

  static WatchPlanItem _phrase(
    ContentRepository content,
    PhraseEntry phrase,
    String learnerLanguageCode,
  ) {
    final WatchResolvedMeaning meaning = meaningFor(
      content,
      phrase.id,
      learnerLanguageCode: learnerLanguageCode,
    );
    return WatchPlanItem(
      id: phrase.id,
      type: WatchItemType.phrase,
      targetText: phrase.text,
      translation: meaning.text,
      pronunciationId: phrase.id,
      translationMissing: meaning.missing,
    );
  }

  static String? _bundleValue(
    ContentRepository content,
    String id,
    String learnerLanguageCode,
  ) {
    for (final TranslationBundle bundle in content.translationBundles) {
      if (LearnerLanguages.baseCode(bundle.languageCode) !=
          learnerLanguageCode) {
        continue;
      }
      final String? value = bundle.strings[id];
      if (value == null) {
        return null;
      }
      final String trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    return null;
  }
}

/// Watch secondary line: current Translation Language, not the target pack.
final class WatchResolvedMeaning {
  const WatchResolvedMeaning({required this.text, required this.missing});

  final String text;
  final bool missing;
}

final class WatchPickerRow {
  const WatchPickerRow.header(this.title) : item = null, section = null;

  const WatchPickerRow.section(this.section) : title = null, item = null;

  const WatchPickerRow.item(this.item) : title = null, section = null;

  final String? title;
  final WatchPlanItem? item;
  final WatchItemType? section;

  bool get isHeader => title != null;
  bool get isSection => section != null;
}
