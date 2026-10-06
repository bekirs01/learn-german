import 'package:flutter/widgets.dart';
import 'package:lingo_core/core/audio/pronunciation_service.dart';
import 'package:lingo_core/core/feedback/feedback_service.dart';
import 'package:lingo_core/data/user_preferences.dart';
import 'package:lingo_core/domain/content_models.dart';
import 'package:lingo_core/domain/content_repository.dart';

final class ContentScope extends InheritedWidget {
  const ContentScope({
    super.key,
    required this.repository,
    required super.child,
  });

  final ContentRepository repository;

  static ContentRepository of(BuildContext context) {
    final ContentScope? scope = context
        .dependOnInheritedWidgetOfExactType<ContentScope>();
    if (scope == null) {
      throw StateError('ContentScope is missing from the widget tree.');
    }
    return scope.repository;
  }

  static Iterable<String> translationLanguageCodesOf(
    ContentRepository content,
  ) {
    if (content.translationBundles.isNotEmpty) {
      return content.translationBundles.map(
        (TranslationBundle bundle) => bundle.languageCode,
      );
    }
    return content.product.supportedTranslationLanguages;
  }

  static String translationLanguageOf(BuildContext context) {
    final ContentRepository content = of(context);
    return UserPreferences.instance.resolvedTranslationLanguage(
      translationLanguageCodesOf(content),
    );
  }

  static bool pronunciationEnabledOf(BuildContext context) {
    return of(context).pronunciationEnabled;
  }

  static PronunciationClip pronunciationClipFor(
    BuildContext context,
    String id,
  ) {
    return PronunciationClip.fromContent(of(context), id);
  }

  static void toggleFavorite(BuildContext context, String id) {
    final ContentRepository content = of(context);
    final bool next = !content.isFavorite(id);
    content.setFavorite(id, next);
    FeedbackService.play(
      next ? FeedbackEvent.favoriteAdded : FeedbackEvent.favoriteRemoved,
    );
  }

  static void toggleLearned(BuildContext context, String id) {
    final ContentRepository content = of(context);
    final bool next = !content.isLearned(id);
    content.setLearned(id, next);
    FeedbackService.play(
      next ? FeedbackEvent.learnedMarked : FeedbackEvent.learnedUnmarked,
    );
  }

  @override
  bool updateShouldNotify(ContentScope oldWidget) {
    return oldWidget.repository != repository;
  }
}
