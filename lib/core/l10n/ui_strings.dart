import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:lingo_core/core/l10n/learner_languages.dart';
import 'package:lingo_core/core/l10n/ui_catalog.dart';
import 'package:lingo_core/data/user_preferences.dart';

export 'package:lingo_core/core/l10n/ui_catalog.dart';
export 'package:lingo_core/core/l10n/ui_keys.dart';

/// Provides the active learner-language code to the widget tree.
final class UiScope extends InheritedWidget {
  const UiScope({
    super.key,
    required this.languageCode,
    this.overlay = const <String, String>{},
    required super.child,
  });

  final String languageCode;

  /// Optional UI strings from the current translation bundle. Clones can ship
  /// chrome keys in JSON without rewriting Dart screens.
  final Map<String, String> overlay;

  static UiScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<UiScope>();
  }

  static String languageOf(BuildContext context) {
    final UiScope? scope = maybeOf(context);
    if (scope != null && scope.languageCode.isNotEmpty) {
      return scope.languageCode;
    }
    return UserPreferences.instance.getSelectedTranslationLanguage();
  }

  @override
  bool updateShouldNotify(UiScope oldWidget) {
    return oldWidget.languageCode != languageCode ||
        !mapEquals(oldWidget.overlay, overlay);
  }
}

/// Looks up learner-facing application chrome for the active Translation
/// Language. Missing values fall back to English, then a readable label.
abstract final class UiStrings {
  static String of(
    BuildContext context,
    String key, {
    Map<String, String> params = const <String, String>{},
  }) {
    final UiScope? scope = UiScope.maybeOf(context);
    final String language = (scope != null && scope.languageCode.isNotEmpty)
        ? scope.languageCode
        : UserPreferences.instance.getSelectedTranslationLanguage();
    return UiCatalog.resolve(
      key,
      languageCode: language,
      overlay: scope?.overlay ?? const <String, String>{},
      params: params,
    );
  }

  static String resolve(
    String key, {
    String? languageCode,
    Map<String, String> overlay = const <String, String>{},
    Map<String, String> params = const <String, String>{},
  }) {
    return UiCatalog.resolve(
      key,
      languageCode: languageCode,
      overlay: overlay,
      params: params,
    );
  }

  static String languageName(
    BuildContext context,
    String code, {
    String? fallback,
  }) {
    final UiScope? scope = UiScope.maybeOf(context);
    final String language = (scope != null && scope.languageCode.isNotEmpty)
        ? scope.languageCode
        : UserPreferences.instance.getSelectedTranslationLanguage();
    return languageNameFor(
      code,
      languageCode: language,
      overlay: scope?.overlay ?? const <String, String>{},
      fallback: fallback,
    );
  }

  static String languageNameFor(
    String code, {
    String? languageCode,
    Map<String, String> overlay = const <String, String>{},
    String? fallback,
  }) {
    return LearnerLanguages.labelFor(code, fallback: fallback);
  }
}
