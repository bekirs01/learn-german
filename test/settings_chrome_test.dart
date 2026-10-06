import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_core/app/content_scope.dart';
import 'package:lingo_core/core/assets/lingo_assets.dart';
import 'package:lingo_core/core/feedback/feedback_service.dart';
import 'package:lingo_core/core/l10n/learner_languages.dart';
import 'package:lingo_core/core/l10n/ui_strings.dart';
import 'package:lingo_core/core/theme/app_theme.dart';
import 'package:lingo_core/core/theme/lingo_tokens.dart';
import 'package:lingo_core/core/widgets/lingo_cards.dart';
import 'package:lingo_core/core/widgets/lingo_controls.dart';
import 'package:lingo_core/core/widgets/lingo_layout.dart';
import 'package:lingo_core/core/widgets/lingo_paper.dart';
import 'package:lingo_core/data/local_content_repository.dart';
import 'package:lingo_core/data/user_preferences.dart';
import 'package:lingo_core/domain/content_models.dart';
import 'package:lingo_core/domain/product_config.dart';
import 'package:lingo_core/features/settings/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    UserPreferences.resetForTest();
    FeedbackService.instance = FeedbackService(
      hapticsEnabled: false,
      soundEnabled: false,
    );
  });

  tearDown(() {
    UserPreferences.resetForTest();
    FeedbackService.resetInstance();
    ProductConfig.reset();
  });

  testWidgets('Settings uses a translucent paper group, not a white slab', (
    WidgetTester tester,
  ) async {
    await _pumpSettings(tester);

    expect(find.text('Translation language'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Sound effects'), findsOneWidget);
    expect(find.text('Haptics'), findsOneWidget);
    expect(find.text('Privacy'), findsOneWidget);
    expect(find.text('About'), findsNothing);
    expect(find.byType(LingoPaperSurface), findsOneWidget);

    final DecoratedBox box = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byKey(const ValueKey<String>('settings-surface')),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final BoxDecoration decoration = box.decoration as BoxDecoration;
    expect(decoration.color, isNotNull);
    expect(decoration.color!.a, lessThan(0.9));
    expect(decoration.color!.a, greaterThan(0.4));
    expect(decoration.border, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Settings rows share height and align switches on the trailing edge',
    (WidgetTester tester) async {
      await _pumpSettings(tester);

      final List<LingoSettingsRow> rows = tester
          .widgetList<LingoSettingsRow>(find.byType(LingoSettingsRow))
          .toList(growable: false);
      expect(rows, hasLength(4));
      expect(rows[0].value, 'English');
      expect(find.byType(LingoToggle), findsNWidgets(2));

      final double languageH = tester
          .getSize(find.byType(LingoSettingsRow).at(0))
          .height;
      final double soundH = tester
          .getSize(find.byType(LingoSettingsRow).at(1))
          .height;
      final double hapticsH = tester
          .getSize(find.byType(LingoSettingsRow).at(2))
          .height;
      expect(languageH, greaterThanOrEqualTo(LingoSpacing.minTapTarget));
      expect(soundH, closeTo(hapticsH, 1));
      expect((languageH - soundH).abs(), lessThan(24));

      final Rect title = tester.getRect(find.text('Sound effects'));
      final Rect toggle = tester.getRect(find.byType(LingoToggle).first);
      final Rect row = tester.getRect(find.byType(LingoSettingsRow).at(1));
      expect(toggle.center.dy, closeTo(title.center.dy, 8));
      expect(row.right - toggle.right, closeTo(LingoSpacing.lg, 10));
      expect(toggle.left, greaterThan(title.right));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('language picker is compact, selected, and shows flags', (
    WidgetTester tester,
  ) async {
    await _pumpSettings(tester);
    await tester.tap(find.text('Translation language'));
    await _pumpUi(tester);

    expect(
      find.byKey(const ValueKey<String>('learner-language-en')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('English'), findsWidgets);

    final Finder languageList = find.byKey(
      const PageStorageKey<String>('learner-language-list'),
    );
    final ListView list = tester.widget<ListView>(languageList);
    final SliverChildBuilderDelegate delegate =
        list.childrenDelegate as SliverChildBuilderDelegate;
    expect(delegate.estimatedChildCount, LearnerLanguages.all.length);
    expect(LearnerLanguages.all, hasLength(15));
    expect(LearnerLanguages.flagEmojiFor('en'), '🇺🇸');
    expect(LearnerLanguages.flagEmojiFor('tr'), '🇹🇷');
    expect(LearnerLanguages.flagEmojiFor('es'), '🇪🇸');
    expect(LearnerLanguages.flagEmojiFor('ar'), '🇸🇦');
    expect(LearnerLanguages.flagEmojiFor('fr'), '🇫🇷');
    expect(LearnerLanguages.flagEmojiFor('de'), '🇩🇪');
    expect(LearnerLanguages.flagEmojiFor('ru'), '🇷🇺');
    expect(LearnerLanguages.flagEmojiFor('pt'), '🇵🇹');
    expect(LearnerLanguages.flagEmojiFor('it'), '🇮🇹');
    expect(LearnerLanguages.flagEmojiFor('ja'), '🇯🇵');
    expect(LearnerLanguages.flagEmojiFor('ko'), '🇰🇷');
    expect(LearnerLanguages.flagEmojiFor('zh'), '🇨🇳');
    expect(LearnerLanguages.flagEmojiFor('hi'), '🇮🇳');
    expect(LearnerLanguages.flagEmojiFor('id'), '🇮🇩');
    expect(LearnerLanguages.flagEmojiFor('fa'), '🇮🇷');

    final Finder englishRow = find.byKey(
      const ValueKey<String>('learner-language-en'),
    );
    final Rect englishFlag = tester.getRect(
      find.descendant(of: englishRow, matching: find.text('🇺🇸')),
    );
    final Rect englishName = tester.getRect(
      find.descendant(of: englishRow, matching: find.text('English')),
    );
    expect(englishFlag.center.dx, lessThan(englishName.center.dx));
    expect(
      find.descendant(
        of: englishRow,
        matching: find.byIcon(Icons.check_rounded),
      ),
      findsOneWidget,
    );

    final Finder languageScroll = find.descendant(
      of: languageList,
      matching: find.byType(Scrollable),
    );
    for (final LearnerLanguage language in LearnerLanguages.all) {
      final Finder option = find.byKey(
        ValueKey<String>('learner-language-${language.code}'),
      );
      await tester.scrollUntilVisible(option, 240, scrollable: languageScroll);
      await tester.pump();
      expect(option, findsOneWidget, reason: language.code);
      expect(
        find.descendant(of: option, matching: find.text(language.nativeName)),
        findsOneWidget,
        reason: language.code,
      );
      expect(
        find.descendant(of: option, matching: find.text(language.flagEmoji)),
        findsOneWidget,
        reason: language.code,
      );
      expect(
        tester.getSize(option).height,
        lessThan(64),
        reason: language.code,
      );
      expect(
        tester.getSize(option).height,
        greaterThanOrEqualTo(LingoSpacing.minTapTarget),
        reason: language.code,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('language picker keeps flags on the start edge in RTL', (
    WidgetTester tester,
  ) async {
    await _pumpSettings(
      tester,
      languageCode: 'ar',
      textDirection: TextDirection.rtl,
    );
    await tester.tap(
      find.text(
        UiStrings.resolve(
          UiKeys.settingsTranslationLanguage,
          languageCode: 'ar',
        ),
      ),
    );
    await _pumpUi(tester);

    final Finder languageList = find.byKey(
      const PageStorageKey<String>('learner-language-list'),
    );
    final Finder languageScroll = find.descendant(
      of: languageList,
      matching: find.byType(Scrollable),
    );
    final Finder arabicRow = find.byKey(
      const ValueKey<String>('learner-language-ar'),
    );
    await tester.scrollUntilVisible(arabicRow, 240, scrollable: languageScroll);
    await tester.pump();

    final Rect flag = tester.getRect(
      find.descendant(of: arabicRow, matching: find.text('🇸🇦')),
    );
    final Rect name = tester.getRect(
      find.descendant(of: arabicRow, matching: find.text('العربية')),
    );
    expect(flag.center.dx, greaterThan(name.center.dx));
    expect(
      find.descendant(
        of: arabicRow,
        matching: find.byIcon(Icons.check_rounded),
      ),
      findsOneWidget,
    );

    final Finder persianRow = find.byKey(
      const ValueKey<String>('learner-language-fa'),
    );
    await tester.scrollUntilVisible(
      persianRow,
      240,
      scrollable: languageScroll,
    );
    await tester.pump();
    final Rect persianFlag = tester.getRect(
      find.descendant(of: persianRow, matching: find.text('🇮🇷')),
    );
    final Rect persianName = tester.getRect(
      find.descendant(of: persianRow, matching: find.text('فارسی')),
    );
    expect(persianFlag.center.dx, greaterThan(persianName.center.dx));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Privacy uses the compact header and readable paper copy', (
    WidgetTester tester,
  ) async {
    await _pumpSettings(tester, size: const Size(390, 844), islandTop: 59);
    await tester.tap(find.text('Privacy'));
    await _pumpUi(tester);

    expect(find.byType(LingoBackButton), findsOneWidget);
    expect(find.text('Privacy'), findsWidgets);
    expect(
      find.text(
        'Learn German for Beginners keeps learning on this device. Content is stored locally, no account is required, and this build has no ads or tracking. Preferences and favorites stay on the device.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Learning content is stored locally on this device.'),
      findsOneWidget,
    );
    expect(find.text('No account is required.'), findsOneWidget);

    final AppBar bar = tester.widget<AppBar>(find.byType(AppBar));
    expect(bar.toolbarHeight, LingoSpacing.toolbar);
    final Rect back = tester.getRect(find.byType(LingoBackButton));
    final double viewTop =
        tester.view.padding.top / tester.view.devicePixelRatio;
    expect(back.top, closeTo(viewTop, 8));
    expect(back.height, greaterThanOrEqualTo(LingoSpacing.minTapTarget - 1));
    expect(back.width, lessThanOrEqualTo(52));
    expect(find.byType(LingoPaperSurface), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'shared header and hero framing stay compact on a standard phone',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (BuildContext context) {
              return TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) {
                        return LingoPage(
                          title: 'Privacy',
                          body: LingoContent(
                            topInset: LingoSpacing.md,
                            children: const <Widget>[
                              LingoCategoryHero(art: LingoArtKind.basics),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await _pumpUi(tester);

      expect(find.byType(LingoBackButton), findsOneWidget);
      expect(find.text('Privacy'), findsOneWidget);
      final Size hero = tester.getSize(find.byType(LingoCategoryHero));
      expect(
        hero.width / hero.height,
        closeTo(LingoCategoryHero.frameAspectRatio, 0.08),
      );
      expect(hero.height, greaterThan(160));
      expect(hero.height, lessThan(280));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Settings chrome stays inside small iPhone and Pro Max bounds', (
    WidgetTester tester,
  ) async {
    await _pumpSettings(tester, size: const Size(320, 568));
    expect(find.text('Privacy'), findsOneWidget);
    expect(tester.takeException(), isNull);
    final Size smallRow = tester.getSize(find.byType(LingoSettingsRow).first);
    expect(smallRow.width, lessThanOrEqualTo(320));

    await _pumpSettings(tester, size: const Size(430, 932), islandTop: 59);
    expect(find.text('Translation language'), findsOneWidget);
    expect(find.text('Privacy'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Settings and headers follow RTL and localized labels',
    (WidgetTester tester) async {
      const List<String> codes = <String>['tr', 'de', 'ru', 'ja', 'fa', 'ar'];
      for (final String code in codes) {
        await _pumpSettings(
          tester,
          languageCode: code,
          textDirection: LearnerLanguages.textDirectionFor(code),
        );
        expect(
          find.text(
            UiStrings.resolve(
              UiKeys.settingsTranslationLanguage,
              languageCode: code,
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            UiStrings.resolve(UiKeys.settingsSoundEffects, languageCode: code),
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            UiStrings.resolve(UiKeys.settingsHaptics, languageCode: code),
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            UiStrings.resolve(UiKeys.settingsPrivacy, languageCode: code),
          ),
          findsOneWidget,
        );
        expect(find.text(LearnerLanguages.labelFor(code)), findsOneWidget);
        expect(tester.takeException(), isNull);
      }

      expect(find.byIcon(Icons.chevron_left_rounded), findsWidgets);
      expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);

      final Rect title = tester.getRect(
        find.text(
          UiStrings.resolve(UiKeys.settingsSoundEffects, languageCode: 'ar'),
        ),
      );
      final Rect toggle = tester.getRect(find.byType(LingoToggle).first);
      expect(toggle.right, lessThan(title.left));

      await tester.tap(
        find.text(
          UiStrings.resolve(UiKeys.settingsPrivacy, languageCode: 'ar'),
        ),
      );
      await _pumpUi(tester);
      expect(find.byType(LingoBackButton), findsOneWidget);
      final Transform arrow = tester.widget<Transform>(
        find
            .ancestor(
              of: find.byIcon(Icons.arrow_back_ios_new_rounded),
              matching: find.byType(Transform),
            )
            .first,
      );
      expect(arrow.transform.entry(0, 0), -1);
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(seconds: 45)),
  );
}

Future<void> _pumpSettings(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double islandTop = 47,
  String languageCode = 'en',
  TextDirection textDirection = TextDirection.ltr,
}) async {
  tester.view.physicalSize = Size(size.width * 3, size.height * 3);
  tester.view.devicePixelRatio = 3;
  tester.view.padding = FakeViewPadding(top: islandTop, bottom: 34);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);

  unawaited(
    UserPreferences.instance.setSelectedTranslationLanguage(languageCode),
  );
  final LocalContentRepository repo = _settingsRepo();

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      locale: Locale(languageCode),
      supportedLocales: <Locale>[
        for (final String code in LearnerLanguages.orderedCodes) Locale(code),
      ],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (BuildContext context, Widget? child) {
        return UiScope(
          languageCode: languageCode,
          child: ContentScope(
            repository: repo,
            child: Directionality(
              textDirection: textDirection,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
      home: const SettingsScreen(),
    ),
  );
  await tester.pump();
}

Future<void> _pumpUi(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

LocalContentRepository _settingsRepo() {
  return LocalContentRepository(
    product: ProductConfig.fallback,
    pack: LanguagePack(
      id: 'settings-chrome',
      name: 'Settings Chrome',
      version: '1',
      targetLanguageCode: 'und',
      targetLanguageName: 'Sample',
      scriptFamily: ScriptFamily.latin,
      textDirection: ContentTextDirection.ltr,
      hasAlphabet: false,
      defaultTranslationLanguageCode: 'en',
      translationLanguageCodes: LearnerLanguages.orderedCodes,
      assetIndex: const <String, String>{},
    ),
    alphabet: const <AlphabetUnit>[],
    wordCategories: const <ContentCategory>[],
    phraseCategories: const <ContentCategory>[],
    words: const <WordEntry>[],
    phrases: const <PhraseEntry>[],
    translationBundles: <TranslationBundle>[
      for (final LearnerLanguage language in LearnerLanguages.all)
        TranslationBundle(
          languageCode: language.code,
          languageName: language.nativeName,
          strings: const <String, String>{},
        ),
    ],
  );
}
