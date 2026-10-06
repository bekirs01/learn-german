import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_core/app/app.dart';
import 'package:lingo_core/core/feedback/feedback_service.dart';
import 'package:lingo_core/core/l10n/learner_languages.dart';
import 'package:lingo_core/core/l10n/ui_strings.dart';
import 'package:lingo_core/data/local_content_repository.dart';
import 'package:lingo_core/data/user_preferences.dart';
import 'package:lingo_core/domain/content_models.dart';
import 'package:lingo_core/domain/validation.dart';

import 'support/shell_nav.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    UiCatalog.resetForTest();
    UserPreferences.resetForTest();
    FeedbackService.resetInstance();
  });

  test(
    'all 15 learner languages load complete UI and content tables',
    () async {
      expect(LearnerLanguages.all, hasLength(15));
      expect(LearnerLanguages.rtlCodes, unorderedEquals(<String>['ar', 'fa']));

      final LocalContentRepository repo = await LocalContentRepository.load();
      expect(repo.pack.translationLanguageCodes, LearnerLanguages.orderedCodes);
      expect(repo.translationBundles, hasLength(15));
      expect(repo.validation.whereCode(ValidationCodes.missingUiKey), isEmpty);
      expect(
        repo.validation.whereCode(ValidationCodes.missingTranslation),
        isEmpty,
      );
      expect(
        repo.validation.whereCode(ValidationCodes.blankTranslation),
        isEmpty,
      );
      expect(
        repo.validation.whereCode(ValidationCodes.staleTranslation),
        isEmpty,
      );
      expect(
        repo.validation.whereCode(ValidationCodes.unsupportedLanguageCode),
        isEmpty,
      );

      final Set<String> contentIds = <String>{
        for (final ContentCategory category in repo.wordCategories) category.id,
        for (final ContentCategory category in repo.phraseCategories)
          category.id,
        for (final ContentCategory category in repo.wordCategories)
          for (final WordEntry word in repo.wordsForCategory(category.id))
            word.id,
        for (final ContentCategory category in repo.phraseCategories)
          for (final PhraseEntry phrase in repo.phrasesForCategory(category.id))
            phrase.id,
        for (final AlphabetUnit unit in repo.alphabet)
          if (unit.example != null && unit.example!.trim().isNotEmpty) unit.id,
      };

      for (final String code in LearnerLanguages.orderedCodes) {
        expect(UiCatalog.hasTable(code), isTrue, reason: code);
        expect(UiCatalog.missingChromeKeys(code), isEmpty, reason: code);
        TranslationBundle? bundle;
        for (final TranslationBundle item in repo.translationBundles) {
          if (item.languageCode == code) {
            bundle = item;
            break;
          }
        }
        expect(bundle, isNotNull, reason: code);
        for (final String id in contentIds) {
          final String? value = bundle!.strings[id];
          expect(value, isNotNull, reason: '$code $id');
          expect(value!.trim(), isNotEmpty, reason: '$code $id');
        }
      }
    },
  );

  test('missing UI strings fall back to English then a readable label', () {
    expect(
      UiStrings.resolve(UiKeys.navSettings, languageCode: 'xx'),
      'Settings',
    );
    expect(
      UiStrings.resolve('does.not_exist', languageCode: 'ar'),
      'Not exist',
    );
    expect(
      UiStrings.resolve(UiKeys.quizContinue, languageCode: '  '),
      'Continue',
    );
  });

  testWidgets('language picker lists native names for all 15 languages', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await tester.tap(shellTab(ShellTabIndex.settings));
    await _pumpUi(tester);
    await tester.tap(find.text('Translation language'));
    await _pumpUi(tester);

    for (final LearnerLanguage language in LearnerLanguages.all) {
      final Finder option = find.byKey(
        ValueKey<String>('learner-language-${language.code}'),
      );
      await tester.ensureVisible(option);
      expect(option, findsOneWidget, reason: language.code);
      expect(
        find.text(language.nativeName),
        findsWidgets,
        reason: language.code,
      );
      expect(
        find.descendant(of: option, matching: find.text(language.flagEmoji)),
        findsOneWidget,
        reason: language.code,
      );
    }
  });

  testWidgets('Arabic learner UI is RTL and keeps German targets', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    final LocalContentRepository pack = _pack();
    final WordEntry mother = pack.wordById('word.family.mother')!;
    expect(mother.text, 'die Mutter');
    final String? arabicMeaning = pack.translation(
      mother.id,
      languageCode: 'ar',
    );

    await _selectLearnerLanguage(tester, 'العربية');
    expect(shellTabLabels(tester), contains('الإعدادات'));
    expect(find.text('لغة الترجمة'), findsOneWidget);
    expect(
      Directionality.of(tester.element(shellTab(ShellTabIndex.settings))),
      TextDirection.rtl,
    );

    await tester.tap(shellTab(ShellTabIndex.words));
    await _pumpUi(tester);
    final String arabicFamily = pack.labelFor(
      'word_category.family',
      'Family',
      languageCode: 'ar',
    );
    expect(find.text(arabicFamily), findsWidgets);
    await tester.tap(find.text(arabicFamily).first);
    await _pumpUi(tester);
    expect(find.text('die Mutter'), findsWidgets);
    if (arabicMeaning != null) {
      expect(find.text(arabicMeaning), findsWidgets);
    }
    expect(shellTabLabels(tester), isNot(contains('Words')));
  });

  testWidgets('Persian learner UI is RTL and keeps German targets', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    final LocalContentRepository pack = _pack();
    final PhraseEntry hello = pack.phraseById('phrase.greetings.hello')!;
    expect(hello.text, 'Hallo.');
    final String? persianMeaning = pack.translation(
      hello.id,
      languageCode: 'fa',
    );

    await _selectLearnerLanguage(tester, 'فارسی');
    expect(shellTabLabels(tester), contains('تنظیمات'));
    expect(
      Directionality.of(tester.element(shellTab(ShellTabIndex.settings))),
      TextDirection.rtl,
    );

    await tester.tap(shellTab(ShellTabIndex.phrases));
    await _pumpUi(tester);
    final String persianGreetings = pack.labelFor(
      'phrase_category.greetings',
      'Greetings',
      languageCode: 'fa',
    );
    expect(find.text(persianGreetings), findsWidgets);
    await tester.tap(find.text(persianGreetings).first);
    await _pumpUi(tester);
    expect(find.text('Hallo.'), findsWidgets);
    if (persianMeaning != null) {
      expect(find.text(persianMeaning), findsWidgets);
    }
  });

  testWidgets('privacy copy is localized and matches the local-only product', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await tester.tap(shellTab(ShellTabIndex.settings));
    await _pumpUi(tester);
    await tester.tap(find.text('Privacy'));
    await _pumpUi(tester);
    expect(
      find.text('Learning content is stored locally on this device.'),
      findsOneWidget,
    );
    expect(find.text('No account is required.'), findsOneWidget);
    expect(find.text('There is no advertising.'), findsOneWidget);
    expect(find.text('There is no analytics or tracking.'), findsOneWidget);
    expect(
      find.text('Your preferences and favorites stay on this device.'),
      findsOneWidget,
    );

    await tester.pageBack();
    await _pumpUi(tester);
    await _selectLearnerLanguage(tester, 'Türkçe', alreadyOnSettings: true);
    await tester.tap(find.text('Gizlilik'));
    await _pumpUi(tester);
    expect(find.text('Hesap gerekmez.'), findsOneWidget);
    expect(find.text('Reklam yoktur.'), findsOneWidget);
  });

  testWidgets('Arabic quiz chrome follows the learner language', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await _selectLearnerLanguage(tester, 'العربية');
    await tester.tap(shellTab(ShellTabIndex.words));
    await _pumpUi(tester);
    final LocalContentRepository pack = _pack();
    final String arabicFamily = pack.labelFor(
      pack.wordCategories.first.id,
      pack.wordCategories.first.title,
      languageCode: 'ar',
    );
    await tester.tap(find.text(arabicFamily).first);
    await _pumpUi(tester);
    await tester.tap(find.byTooltip('اختبار'));
    await _pumpUi(tester);
    expect(find.text('اختر اختبارًا'), findsOneWidget);
    expect(find.text('Choose quiz'), findsNothing);
  });
}

LocalContentRepository _pack() {
  final LocalContentRepository? pack = LocalContentRepository.cached;
  if (pack == null) {
    fail('content pack was not loaded');
  }
  return pack;
}

String? _codeForNativeName(String nativeName) {
  for (final LearnerLanguage language in LearnerLanguages.all) {
    if (language.nativeName == nativeName) {
      return language.code;
    }
  }
  return null;
}

Future<void> _selectLearnerLanguage(
  WidgetTester tester,
  String nativeName, {
  bool alreadyOnSettings = false,
}) async {
  if (!alreadyOnSettings) {
    await tester.tap(shellTab(ShellTabIndex.settings));
    await _pumpUi(tester);
  }
  await tester.tap(
    find.text(UiStrings.resolve(UiKeys.settingsTranslationLanguage)),
  );
  await _pumpUi(tester);
  final String? code = _codeForNativeName(nativeName);
  final Finder option = code == null
      ? find.text(nativeName)
      : find.byKey(ValueKey<String>('learner-language-$code'));
  await tester.scrollUntilVisible(
    option,
    72,
    scrollable: find.descendant(
      of: find.byKey(const PageStorageKey<String>('learner-language-list')),
      matching: find.byType(Scrollable),
    ),
  );
  await tester.pump();
  await tester.tap(option);
  await _pumpUi(tester);
}

Future<void> _pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1290, 3600);
  tester.view.devicePixelRatio = 3;
  tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);

  FeedbackService.instance = FeedbackService(
    hapticsEnabled: false,
    soundEnabled: false,
  );
  UserPreferences.resetForTest();
  final LocalContentRepository? repo = await tester.runAsync(
    LocalContentRepository.load,
  );
  if (repo == null) {
    fail('content pack was not loaded');
  }
  await tester.pumpWidget(LingoCoreApp(contentRepository: repo));
  await _pumpUi(tester);
}

Future<void> _pumpUi(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}
