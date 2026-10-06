import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:lingo_core/app/app_shell.dart';
import 'package:lingo_core/app/content_scope.dart';
import 'package:lingo_core/core/audio/pronunciation_service.dart';
import 'package:lingo_core/core/constants/app_constants.dart';
import 'package:lingo_core/core/feedback/feedback_service.dart';
import 'package:lingo_core/core/l10n/learner_languages.dart';
import 'package:lingo_core/core/l10n/ui_strings.dart';
import 'package:lingo_core/core/theme/app_theme.dart';
import 'package:lingo_core/core/theme/hex_color.dart';
import 'package:lingo_core/core/theme/lingo_identity.dart';
import 'package:lingo_core/data/local_content_repository.dart';
import 'package:lingo_core/data/user_preferences.dart';
import 'package:lingo_core/domain/content_models.dart';
import 'package:lingo_core/domain/content_repository.dart';
import 'package:lingo_core/domain/product_config.dart';

class LingoCoreApp extends StatefulWidget {
  const LingoCoreApp({super.key, this.contentRepository});

  final ContentRepository? contentRepository;

  @override
  State<LingoCoreApp> createState() => _LingoCoreAppState();
}

class _LingoCoreAppState extends State<LingoCoreApp> {
  late final Future<ContentRepository> _contentFuture = _loadContent();
  final UserPreferences _preferences = UserPreferences.instance;

  Future<ContentRepository> _loadContent() {
    final ContentRepository? injected = widget.contentRepository;
    if (injected != null) {
      ProductConfig.bind(injected.product);
      unawaited(PronunciationService.instance.warmUp());
      return Future<ContentRepository>.value(injected);
    }
    return LocalContentRepository.load().then((ContentRepository repository) {
      unawaited(PronunciationService.instance.warmUp());
      return repository;
    });
  }

  @override
  void initState() {
    super.initState();
    _preferences.addListener(_syncFeedback);
    _syncFeedback();
  }

  @override
  void dispose() {
    _preferences.removeListener(_syncFeedback);
    super.dispose();
  }

  void _syncFeedback() {
    FeedbackService.instance.soundEnabled = _preferences.getSoundEnabled();
    FeedbackService.instance.hapticsEnabled = _preferences.getHapticsEnabled();
  }

  @override
  Widget build(BuildContext context) {
    final ContentRepository? ready =
        widget.contentRepository ?? LocalContentRepository.cached;
    final ProductConfig product = ready?.product ?? ProductConfig.current;
    final Color? accent = parseHexColor(product.primaryAccentColor);
    final LingoIdentity identity = LingoIdentity.lingoCore.copyWith(
      name: product.displayName,
      accent: accent,
    );

    return ListenableBuilder(
      listenable: _preferences,
      builder: (BuildContext context, Widget? _) {
        final String language = _uiLanguage(ready);
        return MaterialApp(
          title: AppConstants.appDisplayName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(identity: identity),
          themeMode: ThemeMode.light,
          locale: Locale(LearnerLanguages.baseCode(language)),
          supportedLocales: <Locale>[
            for (final String code in LearnerLanguages.orderedCodes)
              Locale(code),
          ],
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (BuildContext context, Widget? child) {
            return UiScope(
              languageCode: language,
              overlay: _uiOverlay(ready, language),
              child: Localizations.override(
                context: context,
                locale: Locale(LearnerLanguages.baseCode(language)),
                child: Directionality(
                  textDirection: LearnerLanguages.textDirectionFor(language),
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            );
          },
          home: ready != null
              ? ContentScope(repository: ready, child: const AppShell())
              : FutureBuilder<ContentRepository>(
                  future: _contentFuture,
                  builder:
                      (
                        BuildContext context,
                        AsyncSnapshot<ContentRepository> snapshot,
                      ) {
                        if (snapshot.hasError) {
                          return Scaffold(
                            body: Center(
                              child: Text(
                                UiStrings.of(context, UiKeys.appLoadError),
                              ),
                            ),
                          );
                        }
                        final ContentRepository? repository = snapshot.data;
                        if (repository == null) {
                          return const Scaffold(
                            body: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return ContentScope(
                          repository: repository,
                          child: const AppShell(),
                        );
                      },
                ),
        );
      },
    );
  }

  String _uiLanguage(ContentRepository? content) {
    if (content == null) {
      return _preferences.getSelectedTranslationLanguage();
    }
    return _preferences.resolvedTranslationLanguage(
      ContentScope.translationLanguageCodesOf(content),
    );
  }

  static Map<String, String> _uiOverlay(
    ContentRepository? content,
    String language,
  ) {
    if (content == null) {
      return const <String, String>{};
    }
    for (final TranslationBundle bundle in content.translationBundles) {
      if (bundle.languageCode != language) {
        continue;
      }
      final Map<String, String> overlay = <String, String>{};
      for (final String key in UiKeys.chrome) {
        final String? value = bundle.strings[key];
        if (value == null) {
          continue;
        }
        final String trimmed = value.trim();
        if (trimmed.isNotEmpty) {
          overlay[key] = trimmed;
        }
      }
      return overlay;
    }
    return const <String, String>{};
  }
}
