import 'package:lingo_core/domain/content_models.dart';
import 'package:lingo_core/domain/product_config.dart';
import 'package:lingo_core/domain/validation.dart';

Map<String, Object?> jsonObject(Object? value, String label) {
  if (value is Map) {
    return <String, Object?>{
      for (final Object key in value.keys) '$key': value[key],
    };
  }
  throw FormatException('Expected a JSON object for $label.');
}

Map<String, Object?>? jsonObjectOrNull(Object? value) {
  if (value is Map) {
    return <String, Object?>{
      for (final Object key in value.keys) '$key': value[key],
    };
  }
  return null;
}

List<Object?> jsonList(Object? value, String label) {
  if (value is List<Object?>) {
    return value;
  }
  if (value is List) {
    return List<Object?>.from(value);
  }
  throw FormatException('Expected a JSON array for $label.');
}

List<Object?> jsonListOrEmpty(Object? value) {
  if (value is List<Object?>) {
    return value;
  }
  if (value is List) {
    return List<Object?>.from(value);
  }
  return const <Object?>[];
}

String jsonString(Map<String, Object?> json, String key) {
  final Object? value = json[key];
  if (value is String && value.isNotEmpty) {
    return value;
  }
  throw FormatException('Missing non-empty string "$key".');
}

String jsonStringOrFallback(
  Map<String, Object?> json,
  String key,
  String fallback,
  List<ValidationIssue> issues,
) {
  final Object? value = json[key];
  if (value is String && value.isNotEmpty) {
    return value;
  }
  issues.add(
    ValidationIssue(
      code: ValidationCodes.emptyRequiredField,
      message: 'Missing non-empty "$key".',
      id: key,
      severity: ValidationSeverity.warning,
    ),
  );
  return fallback;
}

String? jsonOptionalString(Map<String, Object?> json, String key) {
  final Object? value = json[key];
  if (value is String && value.isNotEmpty) {
    return value;
  }
  return null;
}

double? jsonOptionalDouble(Map<String, Object?> json, String key) {
  final Object? value = json[key];
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value.trim());
  }
  return null;
}

int jsonInt(Map<String, Object?> json, String key, {int fallback = 0}) {
  final Object? value = json[key];
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return fallback;
}

bool jsonBool(Map<String, Object?> json, String key, {bool fallback = false}) {
  final Object? value = json[key];
  if (value is bool) {
    return value;
  }
  return fallback;
}

List<String> jsonStringList(Map<String, Object?> json, String key) {
  final Object? value = json[key];
  if (value is! List) {
    return const <String>[];
  }
  return value
      .whereType<String>()
      .where((String item) => item.isNotEmpty)
      .toList(growable: false);
}

Map<String, String> jsonStringMap(Object? value, String label) {
  final Map<String, Object?>? object = jsonObjectOrNull(value);
  if (object == null) {
    return const <String, String>{};
  }
  final Map<String, String> result = <String, String>{};
  for (final MapEntry<String, Object?> entry in object.entries) {
    final Object? item = entry.value;
    if (item is String && item.isNotEmpty) {
      result[entry.key] = item;
    }
  }
  return result;
}

String? resolveAsset({
  required LanguagePack pack,
  required List<ValidationIssue> issues,
  String? assetPath,
  String? assetId,
  String? ownerId,
}) {
  if (assetPath != null && assetPath.isNotEmpty) {
    return assetPath;
  }
  if (assetId == null) {
    return null;
  }
  final String? resolved = pack.assetPathFor(assetId);
  if (resolved == null || resolved.isEmpty) {
    issues.add(
      ValidationIssue(
        code: ValidationCodes.missingAssetReference,
        message: 'No asset path for ID "$assetId".',
        id: ownerId ?? assetId,
        severity: ValidationSeverity.warning,
      ),
    );
    return null;
  }
  return resolved;
}

ScriptFamily parseScriptFamily(String? value) {
  return switch (value) {
    'latin' => ScriptFamily.latin,
    'cyrillic' => ScriptFamily.cyrillic,
    'arabic' => ScriptFamily.arabic,
    'han' => ScriptFamily.han,
    'japanese' => ScriptFamily.japanese,
    'korean' => ScriptFamily.korean,
    'none' => ScriptFamily.none,
    'other' => ScriptFamily.other,
    _ => ScriptFamily.other,
  };
}

ContentTextDirection parseTextDirection(String? value) {
  return value == 'rtl' ? ContentTextDirection.rtl : ContentTextDirection.ltr;
}

WritingSystem parseWritingSystem(String? value) {
  return switch (value) {
    'alphabet' => WritingSystem.alphabet,
    'syllabary' => WritingSystem.syllabary,
    'characters' => WritingSystem.characters,
    'other' => WritingSystem.other,
    _ => WritingSystem.other,
  };
}

void _recordMalformed(List<ValidationIssue> issues, String label) {
  issues.add(
    ValidationIssue(
      code: ValidationCodes.malformedEntry,
      message: 'Skipped a malformed $label.',
      severity: ValidationSeverity.warning,
    ),
  );
}

LanguagePack parseLanguagePack(
  Object? decoded,
  ProductConfig product, [
  List<ValidationIssue>? issues,
]) {
  final List<ValidationIssue> collected = issues ?? <ValidationIssue>[];
  final Map<String, Object?> json = jsonObject(decoded, 'language_pack');
  final List<String> translationCodes = jsonStringList(
    json,
    'translationLanguageCodes',
  );
  return LanguagePack(
    id: jsonStringOrFallback(json, 'id', product.id, collected),
    name: jsonStringOrFallback(json, 'name', product.displayName, collected),
    version: jsonStringOrFallback(json, 'version', '0.1.0', collected),
    targetLanguageCode:
        jsonOptionalString(json, 'targetLanguageCode') ??
        product.targetLanguageCode,
    targetLanguageName:
        jsonOptionalString(json, 'targetLanguageName') ??
        product.targetLanguageName,
    scriptFamily: parseScriptFamily(jsonOptionalString(json, 'scriptFamily')),
    textDirection: parseTextDirection(
      jsonOptionalString(json, 'textDirection') ??
          (product.textDirection == ContentTextDirection.rtl ? 'rtl' : 'ltr'),
    ),
    hasAlphabet: json.containsKey('hasAlphabet')
        ? jsonBool(
            json,
            'hasAlphabet',
            fallback: product.showsCharacterInventory,
          )
        : product.showsCharacterInventory,
    defaultTranslationLanguageCode:
        jsonOptionalString(json, 'defaultTranslationLanguageCode') ??
        product.defaultTranslationLanguage,
    translationLanguageCodes: translationCodes.isEmpty
        ? product.supportedTranslationLanguages
        : translationCodes,
    assetIndex: jsonStringMap(json['assetIndex'], 'assetIndex'),
  );
}

List<AlphabetUnit> parseAlphabet(
  Object? decoded,
  LanguagePack pack,
  List<ValidationIssue> issues,
) {
  final Map<String, Object?>? json = jsonObjectOrNull(decoded);
  if (json == null) {
    _recordMalformed(issues, 'alphabet file');
    return const <AlphabetUnit>[];
  }
  final List<AlphabetUnit> units = <AlphabetUnit>[];
  final Set<String> ids = <String>{};
  for (final Object? item in jsonListOrEmpty(json['units'])) {
    final Map<String, Object?>? unit = jsonObjectOrNull(item);
    if (unit == null) {
      _recordMalformed(issues, 'alphabet unit');
      continue;
    }
    final String? id = jsonOptionalString(unit, 'id');
    final String? glyph = jsonOptionalString(unit, 'glyph');
    if (id == null || glyph == null) {
      issues.add(
        const ValidationIssue(
          code: ValidationCodes.emptyRequiredField,
          message: 'Alphabet unit is missing id or glyph.',
          severity: ValidationSeverity.warning,
        ),
      );
      continue;
    }
    if (!ids.add(id)) {
      issues.add(
        ValidationIssue(
          code: ValidationCodes.duplicateId,
          message: 'Duplicate alphabet ID "$id".',
          id: id,
        ),
      );
      continue;
    }
    units.add(
      AlphabetUnit(
        id: id,
        glyph: glyph,
        pronunciation: jsonOptionalString(unit, 'pronunciation'),
        speechText:
            jsonOptionalString(unit, 'pronunciationSpeechText') ??
            jsonOptionalString(unit, 'speechText'),
        romanization: jsonOptionalString(unit, 'romanization'),
        example: jsonOptionalString(unit, 'example'),
        imageAsset: resolveAsset(
          pack: pack,
          issues: issues,
          assetPath: jsonOptionalString(unit, 'imageAsset'),
          assetId: jsonOptionalString(unit, 'imageAssetId'),
          ownerId: id,
        ),
        audioAsset: resolveAsset(
          pack: pack,
          issues: issues,
          assetPath: jsonOptionalString(unit, 'audioAsset'),
          assetId: jsonOptionalString(unit, 'audioAssetId'),
          ownerId: id,
        ),
        sortOrder: jsonInt(unit, 'sortOrder'),
        quizEnabled: jsonBool(unit, 'quizEnabled', fallback: true),
      ),
    );
  }
  units.sort(
    (AlphabetUnit a, AlphabetUnit b) => a.sortOrder.compareTo(b.sortOrder),
  );
  return List<AlphabetUnit>.unmodifiable(units);
}

List<ContentCategory> parseCategories(
  Object? decoded,
  LanguagePack pack,
  String label,
  List<ValidationIssue> issues,
) {
  final Map<String, Object?>? json = jsonObjectOrNull(decoded);
  if (json == null) {
    _recordMalformed(issues, label);
    return const <ContentCategory>[];
  }
  final List<ContentCategory> items = <ContentCategory>[];
  final Set<String> ids = <String>{};
  for (final Object? item in jsonListOrEmpty(json['items'])) {
    final Map<String, Object?>? category = jsonObjectOrNull(item);
    if (category == null) {
      _recordMalformed(issues, label);
      continue;
    }
    final String? id = jsonOptionalString(category, 'id');
    final String? title = jsonOptionalString(category, 'title');
    if (id == null || title == null) {
      issues.add(
        ValidationIssue(
          code: ValidationCodes.emptyRequiredField,
          message: 'A $label entry is missing id or title.',
          severity: ValidationSeverity.warning,
        ),
      );
      continue;
    }
    if (!ids.add(id)) {
      issues.add(
        ValidationIssue(
          code: ValidationCodes.duplicateId,
          message: 'Duplicate $label ID "$id".',
          id: id,
        ),
      );
      continue;
    }
    items.add(
      ContentCategory(
        id: id,
        title: title,
        imageAsset: resolveAsset(
          pack: pack,
          issues: issues,
          assetPath: jsonOptionalString(category, 'imageAsset'),
          assetId: jsonOptionalString(category, 'imageAssetId'),
          ownerId: id,
        ),
        audioAsset: resolveAsset(
          pack: pack,
          issues: issues,
          assetPath: jsonOptionalString(category, 'audioAsset'),
          assetId: jsonOptionalString(category, 'audioAssetId'),
          ownerId: id,
        ),
        artKind: jsonOptionalString(category, 'artKind'),
        sortOrder: jsonInt(category, 'sortOrder'),
      ),
    );
  }
  items.sort(
    (ContentCategory a, ContentCategory b) =>
        a.sortOrder.compareTo(b.sortOrder),
  );
  return List<ContentCategory>.unmodifiable(items);
}

List<WordEntry> parseWords(
  Object? decoded,
  LanguagePack pack,
  Set<String> categoryIds,
  List<ValidationIssue> issues,
) {
  final Map<String, Object?>? json = jsonObjectOrNull(decoded);
  if (json == null) {
    _recordMalformed(issues, 'words');
    return const <WordEntry>[];
  }
  final List<WordEntry> items = <WordEntry>[];
  final Set<String> ids = <String>{};
  for (final Object? item in jsonListOrEmpty(json['items'])) {
    final Map<String, Object?>? word = jsonObjectOrNull(item);
    if (word == null) {
      _recordMalformed(issues, 'word');
      continue;
    }
    final String? id = jsonOptionalString(word, 'id');
    final String? categoryId = jsonOptionalString(word, 'categoryId');
    final String? text = jsonOptionalString(word, 'text');
    if (id == null || categoryId == null || text == null) {
      issues.add(
        const ValidationIssue(
          code: ValidationCodes.emptyRequiredField,
          message: 'A word is missing id, categoryId, or text.',
          severity: ValidationSeverity.warning,
        ),
      );
      continue;
    }
    if (!ids.add(id)) {
      issues.add(
        ValidationIssue(
          code: ValidationCodes.duplicateId,
          message: 'Duplicate word ID "$id".',
          id: id,
        ),
      );
      continue;
    }
    if (!categoryIds.contains(categoryId)) {
      issues.add(
        ValidationIssue(
          code: ValidationCodes.invalidCategoryReference,
          message: 'Word "$id" references missing category "$categoryId".',
          id: id,
        ),
      );
      continue;
    }
    items.add(
      WordEntry(
        id: id,
        categoryId: categoryId,
        text: text,
        pronunciation: jsonOptionalString(word, 'pronunciation'),
        romanization: jsonOptionalString(word, 'romanization'),
        imageAsset: resolveAsset(
          pack: pack,
          issues: issues,
          assetPath: jsonOptionalString(word, 'imageAsset'),
          assetId: jsonOptionalString(word, 'imageAssetId'),
          ownerId: id,
        ),
        audioAsset: resolveAsset(
          pack: pack,
          issues: issues,
          assetPath: jsonOptionalString(word, 'audioAsset'),
          assetId: jsonOptionalString(word, 'audioAssetId'),
          ownerId: id,
        ),
        grammaticalGender: jsonOptionalString(word, 'grammaticalGender'),
        plural: jsonOptionalString(word, 'plural'),
        sortOrder: jsonInt(word, 'sortOrder'),
        quizEnabled: jsonBool(word, 'quizEnabled', fallback: true),
      ),
    );
  }
  items.sort((WordEntry a, WordEntry b) => a.sortOrder.compareTo(b.sortOrder));
  return List<WordEntry>.unmodifiable(items);
}

List<PhraseEntry> parsePhrases(
  Object? decoded,
  LanguagePack pack,
  Set<String> categoryIds,
  List<ValidationIssue> issues,
) {
  final Map<String, Object?>? json = jsonObjectOrNull(decoded);
  if (json == null) {
    _recordMalformed(issues, 'phrases');
    return const <PhraseEntry>[];
  }
  final List<PhraseEntry> items = <PhraseEntry>[];
  final Set<String> ids = <String>{};
  for (final Object? item in jsonListOrEmpty(json['items'])) {
    final Map<String, Object?>? phrase = jsonObjectOrNull(item);
    if (phrase == null) {
      _recordMalformed(issues, 'phrase');
      continue;
    }
    final String? id = jsonOptionalString(phrase, 'id');
    final String? categoryId = jsonOptionalString(phrase, 'categoryId');
    final String? text = jsonOptionalString(phrase, 'text');
    if (id == null || categoryId == null || text == null) {
      issues.add(
        const ValidationIssue(
          code: ValidationCodes.emptyRequiredField,
          message: 'A phrase is missing id, categoryId, or text.',
          severity: ValidationSeverity.warning,
        ),
      );
      continue;
    }
    if (!ids.add(id)) {
      issues.add(
        ValidationIssue(
          code: ValidationCodes.duplicateId,
          message: 'Duplicate phrase ID "$id".',
          id: id,
        ),
      );
      continue;
    }
    if (!categoryIds.contains(categoryId)) {
      issues.add(
        ValidationIssue(
          code: ValidationCodes.invalidCategoryReference,
          message: 'Phrase "$id" references missing category "$categoryId".',
          id: id,
        ),
      );
      continue;
    }
    items.add(
      PhraseEntry(
        id: id,
        categoryId: categoryId,
        text: text,
        pronunciation: jsonOptionalString(phrase, 'pronunciation'),
        romanization: jsonOptionalString(phrase, 'romanization'),
        imageAsset: resolveAsset(
          pack: pack,
          issues: issues,
          assetPath: jsonOptionalString(phrase, 'imageAsset'),
          assetId: jsonOptionalString(phrase, 'imageAssetId'),
          ownerId: id,
        ),
        audioAsset: resolveAsset(
          pack: pack,
          issues: issues,
          assetPath: jsonOptionalString(phrase, 'audioAsset'),
          assetId: jsonOptionalString(phrase, 'audioAssetId'),
          ownerId: id,
        ),
        sortOrder: jsonInt(phrase, 'sortOrder'),
        quizEnabled: jsonBool(phrase, 'quizEnabled', fallback: true),
      ),
    );
  }
  items.sort(
    (PhraseEntry a, PhraseEntry b) => a.sortOrder.compareTo(b.sortOrder),
  );
  return List<PhraseEntry>.unmodifiable(items);
}

TranslationBundle parseTranslationBundle(
  Object? decoded,
  List<ValidationIssue> issues,
) {
  final Map<String, Object?>? json = jsonObjectOrNull(decoded);
  if (json == null) {
    _recordMalformed(issues, 'translation');
    return const TranslationBundle(
      languageCode: 'und',
      languageName: 'Unknown',
      strings: <String, String>{},
    );
  }
  final String languageCode = jsonOptionalString(json, 'languageCode') ?? 'und';
  final String languageName =
      jsonOptionalString(json, 'languageName') ?? languageCode;
  if (jsonOptionalString(json, 'languageCode') == null) {
    issues.add(
      const ValidationIssue(
        code: ValidationCodes.emptyRequiredField,
        message: 'Translation bundle is missing languageCode.',
        severity: ValidationSeverity.warning,
      ),
    );
  }
  return TranslationBundle(
    languageCode: languageCode,
    languageName: languageName,
    strings: jsonStringMap(json['strings'], 'strings'),
  );
}
