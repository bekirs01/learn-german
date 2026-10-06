import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lingo_core/app/content_scope.dart';
import 'package:lingo_core/app/lingo_navigation.dart';
import 'package:lingo_core/core/l10n/learner_languages.dart';
import 'package:lingo_core/core/l10n/ui_strings.dart';
import 'package:lingo_core/core/theme/app_theme.dart';
import 'package:lingo_core/core/theme/lingo_tokens.dart';
import 'package:lingo_core/core/widgets/lingo_widgets.dart';
import 'package:lingo_core/data/user_preferences.dart';
import 'package:lingo_core/domain/content_models.dart';
import 'package:lingo_core/domain/content_repository.dart';
import 'package:lingo_core/features/watch/watch_learner_language_sync.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: UserPreferences.instance,
      builder: (BuildContext context, Widget? _) {
        final UserPreferences prefs = UserPreferences.instance;
        final ContentRepository content = ContentScope.of(context);
        final String languageCode = prefs.resolvedTranslationLanguage(
          ContentScope.translationLanguageCodesOf(content),
        );

        return LingoPage(
          showAppBar: false,
          body: LingoContent(
            storageKey: 'settings',
            topSafeArea: true,
            children: <Widget>[
              _SettingsGroup(
                key: const ValueKey<String>('settings-surface'),
                children: <Widget>[
                  LingoSettingsRow(
                    title: UiStrings.of(
                      context,
                      UiKeys.settingsTranslationLanguage,
                    ),
                    value: LearnerLanguages.labelFor(
                      languageCode,
                      fallback: _bundleName(content, languageCode),
                    ),
                    onPressed: () =>
                        _pickTranslationLanguage(context, languageCode),
                  ),
                  LingoSettingsRow(
                    title: UiStrings.of(context, UiKeys.settingsSoundEffects),
                    trailing: LingoToggle(
                      value: prefs.getSoundEnabled(),
                      onChanged: (bool value) {
                        unawaited(prefs.setSoundEnabled(value));
                      },
                    ),
                  ),
                  LingoSettingsRow(
                    title: UiStrings.of(context, UiKeys.settingsHaptics),
                    trailing: LingoToggle(
                      value: prefs.getHapticsEnabled(),
                      onChanged: (bool value) {
                        unawaited(prefs.setHapticsEnabled(value));
                      },
                    ),
                  ),
                  LingoSettingsRow(
                    title: UiStrings.of(context, UiKeys.settingsPrivacy),
                    onPressed: () {
                      LingoNavigation.push(context, const _PrivacyScreen());
                    },
                    showDivider: false,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

Future<void> _pickTranslationLanguage(
  BuildContext context,
  String selectedCode,
) async {
  final ContentRepository content = ContentScope.of(context);
  final List<(String, String)> languages = _translationOptions(content);
  if (languages.isEmpty) {
    return;
  }
  final String? next = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    barrierColor: LingoTheme.of(context).colors.scrim,
    builder: (BuildContext context) {
      return _TranslationLanguageSheet(
        languages: languages,
        selectedCode: selectedCode,
      );
    },
  );
  if (next == null) {
    return;
  }
  await UserPreferences.instance.setSelectedTranslationLanguage(next);
  final String learner = UserPreferences.instance.resolvedTranslationLanguage(
    ContentScope.translationLanguageCodesOf(content),
  );
  unawaited(
    WatchLearnerLanguageSync.refresh(
      content: content,
      learnerLanguageCode: learner,
    ),
  );
}

String? _bundleName(ContentRepository content, String code) {
  for (final TranslationBundle bundle in content.translationBundles) {
    if (bundle.languageCode == code) {
      return bundle.languageName;
    }
  }
  return null;
}

List<(String, String)> _translationOptions(ContentRepository content) {
  final Map<String, String> available = <String, String>{};
  if (content.translationBundles.isNotEmpty) {
    for (final TranslationBundle bundle in content.translationBundles) {
      available[bundle.languageCode] = bundle.languageName;
    }
  } else {
    for (final String code in content.product.supportedTranslationLanguages) {
      available[code] = code;
    }
  }

  final List<(String, String)> options = <(String, String)>[];
  final Set<String> seen = <String>{};
  for (final LearnerLanguage language in LearnerLanguages.all) {
    if (!available.containsKey(language.code) || !seen.add(language.code)) {
      continue;
    }
    options.add((language.code, language.nativeName));
  }
  for (final MapEntry<String, String> entry in available.entries) {
    if (!seen.add(entry.key)) {
      continue;
    }
    options.add((
      entry.key,
      LearnerLanguages.labelFor(entry.key, fallback: entry.value),
    ));
  }
  return options;
}

class _TranslationLanguageSheet extends StatelessWidget {
  const _TranslationLanguageSheet({
    required this.languages,
    required this.selectedCode,
  });

  final List<(String, String)> languages;
  final String selectedCode;

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final MediaQueryData media = MediaQuery.of(context);
    final double maxHeight = media.size.height * 0.78;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color.lerp(
                  theme.colors.canvas,
                  theme.colors.surfaceRaised,
                  theme.colors.isDark ? 0.18 : 0.28,
                )?.withValues(alpha: 0.94),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(LingoRadii.xxl),
                ),
                border: Border.all(color: theme.colors.paperRim, width: 0.7),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  LingoSpacing.lg,
                  LingoSpacing.sm,
                  LingoSpacing.lg,
                  LingoSpacing.md,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: theme.colors.onSurface.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(LingoRadii.pill),
                        ),
                        child: const SizedBox(width: 36, height: 4),
                      ),
                    ),
                    const SizedBox(height: LingoSpacing.md),
                    Text(
                      UiStrings.of(context, UiKeys.settingsTranslationLanguage),
                      style: textTheme.titleMedium,
                      textAlign: TextAlign.start,
                    ),
                    const SizedBox(height: LingoSpacing.md),
                    Flexible(
                      child: LingoPaperSurface(
                        child: ListView.builder(
                          key: const PageStorageKey<String>(
                            'learner-language-list',
                          ),
                          shrinkWrap: true,
                          itemCount: languages.length,
                          itemBuilder: (BuildContext context, int index) {
                            final (String code, String name) = languages[index];
                            final bool selected = code == selectedCode;
                            return LingoSettingsRow(
                              key: ValueKey<String>('learner-language-$code'),
                              title: name,
                              compact: true,
                              selected: selected,
                              leading: _LearnerLanguageFlag(languageCode: code),
                              trailing: selected
                                  ? Icon(
                                      Icons.check_rounded,
                                      color: theme.colors.primary,
                                      size: LingoIconSize.md,
                                    )
                                  : const SizedBox(
                                      width: LingoIconSize.md,
                                      height: LingoIconSize.md,
                                    ),
                              onPressed: () => Navigator.of(context).pop(code),
                              showDivider: index != languages.length - 1,
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LearnerLanguageFlag extends StatelessWidget {
  const _LearnerLanguageFlag({required this.languageCode});

  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final String? emoji = LearnerLanguages.flagEmojiFor(languageCode);
    return ExcludeSemantics(
      child: SizedBox(
        width: LingoIconSize.md,
        height: LingoIconSize.md,
        child: emoji == null
            ? null
            : Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      emoji,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: LingoIconSize.sm,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LingoPaperSurface(child: Column(children: children));
  }
}

class _PrivacyScreen extends StatelessWidget {
  const _PrivacyScreen();

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final LingoTheme theme = LingoTheme.of(context);
    final String appName = ContentScope.of(context).product.displayName;

    return LingoPage(
      title: UiStrings.of(context, UiKeys.settingsPrivacy),
      body: LingoContent(
        topInset: LingoSpacing.md,
        children: <Widget>[
          Align(
            alignment: AlignmentDirectional.topStart,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    UiStrings.of(
                      context,
                      UiKeys.settingsPrivacyBody,
                      params: <String, String>{'appName': appName},
                    ),
                    style: textTheme.bodyLarge?.copyWith(
                      color: theme.colors.onSurface,
                      height: 1.48,
                      letterSpacing: -0.12,
                    ),
                  ),
                  const SizedBox(height: LingoSpacing.xl),
                  LingoPaperSurface(
                    padding: const EdgeInsets.fromLTRB(
                      LingoSpacing.lg,
                      LingoSpacing.md,
                      LingoSpacing.lg,
                      LingoSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _PrivacyPoint(
                          text: UiStrings.of(
                            context,
                            UiKeys.settingsPrivacyLocalContent,
                          ),
                        ),
                        _PrivacyPoint(
                          text: UiStrings.of(
                            context,
                            UiKeys.settingsPrivacyNoAccount,
                          ),
                        ),
                        _PrivacyPoint(
                          text: UiStrings.of(
                            context,
                            UiKeys.settingsPrivacyNoAds,
                          ),
                        ),
                        _PrivacyPoint(
                          text: UiStrings.of(
                            context,
                            UiKeys.settingsPrivacyNoTracking,
                          ),
                        ),
                        _PrivacyPoint(
                          text: UiStrings.of(
                            context,
                            UiKeys.settingsPrivacyOnDevice,
                          ),
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyPoint extends StatelessWidget {
  const _PrivacyPoint({required this.text, this.showDivider = true});

  final String text;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: LingoSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colors.primary.withValues(alpha: 0.72),
                    shape: BoxShape.circle,
                  ),
                  child: const SizedBox(width: 6, height: 6),
                ),
              ),
              const SizedBox(width: LingoSpacing.md),
              Expanded(
                child: Text(
                  text,
                  style: textTheme.bodyLarge?.copyWith(
                    height: 1.4,
                    letterSpacing: -0.08,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 0.5,
            color: theme.colors.hairline.withValues(alpha: 0.5),
          ),
      ],
    );
  }
}
