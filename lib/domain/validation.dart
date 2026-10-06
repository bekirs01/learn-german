enum ValidationSeverity { error, warning }

abstract final class ValidationCodes {
  static const String duplicateId = 'duplicate_id';
  static const String missingTranslation = 'missing_translation';
  static const String missingCategories = 'missing_categories';
  static const String invalidCategoryReference = 'invalid_category_reference';
  static const String missingAssetReference = 'missing_asset_reference';
  static const String malformedEntry = 'malformed_entry';
  static const String emptyRequiredField = 'empty_required_field';
  static const String unsupportedLanguageCode = 'unsupported_language_code';
  static const String emptyCategory = 'empty_category';
  static const String invalidPronunciation = 'invalid_pronunciation';
  static const String quizNotReady = 'quiz_not_ready';
  static const String missingUiBundle = 'missing_ui_bundle';
  static const String missingUiKey = 'missing_ui_key';
  static const String blankTranslation = 'blank_translation';
  static const String staleTranslation = 'stale_translation';
  static const String languageMismatch = 'language_mismatch';
}

final class ValidationIssue {
  const ValidationIssue({
    required this.code,
    required this.message,
    this.severity = ValidationSeverity.error,
    this.id,
  });

  final String code;
  final String message;
  final ValidationSeverity severity;
  final String? id;
}

final class ValidationReport {
  const ValidationReport(this.issues);

  static const ValidationReport empty = ValidationReport(<ValidationIssue>[]);

  final List<ValidationIssue> issues;

  bool get hasErrors => issues.any(
    (ValidationIssue issue) => issue.severity == ValidationSeverity.error,
  );

  bool get isClean => issues.isEmpty;

  List<ValidationIssue> whereCode(String code) {
    return issues
        .where((ValidationIssue issue) => issue.code == code)
        .toList(growable: false);
  }
}
