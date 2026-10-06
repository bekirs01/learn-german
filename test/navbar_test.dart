import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_core/app/app.dart';
import 'package:lingo_core/core/feedback/feedback_service.dart';
import 'package:lingo_core/core/theme/app_theme.dart';
import 'package:lingo_core/core/widgets/lingo_bottom_nav.dart';
import 'package:lingo_core/data/local_content_repository.dart';
import 'package:lingo_core/data/user_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    UserPreferences.resetForTest();
    FeedbackService.resetInstance();
  });

  testWidgets('custom glyphs render and selected state follows the tab', (
    WidgetTester tester,
  ) async {
    final ValueNotifier<int> selected = ValueNotifier<int>(2);
    addTearDown(selected.dispose);
    await tester.pumpWidget(_harness(selected));

    expect(find.byType(LingoNavGlyphIcon), findsNWidgets(5));
    expect(find.byIcon(Icons.home_rounded), findsNothing);
    expect(find.byIcon(Icons.menu_book_rounded), findsNothing);
    expect(find.byIcon(Icons.chat_bubble_rounded), findsNothing);
    expect(find.byIcon(Icons.favorite_rounded), findsNothing);
    expect(find.byIcon(Icons.settings_rounded), findsNothing);
    expect(find.byType(LingoNavSelectionBubble), findsOneWidget);

    List<LingoBottomNavItem> items = tester
        .widgetList<LingoBottomNavItem>(find.byType(LingoBottomNavItem))
        .toList(growable: false);
    List<LingoNavGlyphIcon> glyphs = tester
        .widgetList<LingoNavGlyphIcon>(find.byType(LingoNavGlyphIcon))
        .toList(growable: false);
    expect(items[2].selected, isTrue);
    expect(glyphs[2].selected, isTrue);
    expect(glyphs[2].glyph, LingoNavGlyph.phrases);
    expect(glyphs[2].size, greaterThan(glyphs[0].size));
    expect(
      items.where((LingoBottomNavItem item) => item.selected),
      hasLength(1),
    );
    expect(
      glyphs.where((LingoNavGlyphIcon icon) => icon.selected),
      hasLength(1),
    );

    await tester.tap(_navItem(3));
    await tester.pump();
    items = tester
        .widgetList<LingoBottomNavItem>(find.byType(LingoBottomNavItem))
        .toList(growable: false);
    glyphs = tester
        .widgetList<LingoNavGlyphIcon>(find.byType(LingoNavGlyphIcon))
        .toList(growable: false);
    expect(items[3].selected, isTrue);
    expect(items[2].selected, isFalse);
    expect(glyphs[3].selected, isTrue);
    expect(glyphs[3].glyph, LingoNavGlyph.favorites);
    expect(glyphs[2].selected, isFalse);
  });

  testWidgets('visible labels stay out of the capsule and semantics remain', (
    WidgetTester tester,
  ) async {
    final ValueNotifier<int> selected = ValueNotifier<int>(0);
    addTearDown(selected.dispose);
    await tester.pumpWidget(_harness(selected));

    final Finder nav = find.byType(LingoFloatingBottomNav);
    expect(find.descendant(of: nav, matching: find.text('Home')), findsNothing);
    expect(
      find.descendant(of: nav, matching: find.text('Words')),
      findsNothing,
    );
    expect(
      find.descendant(of: nav, matching: find.text('Phrases')),
      findsNothing,
    );
    expect(
      find.descendant(of: nav, matching: find.text('Favorites')),
      findsNothing,
    );
    expect(
      find.descendant(of: nav, matching: find.text('Settings')),
      findsNothing,
    );

    expect(tester.getSemantics(_navItem(0)).label, 'Home');
    expect(tester.getSemantics(_navItem(1)).label, 'Words');
    expect(tester.getSemantics(_navItem(2)).label, 'Phrases');
    expect(tester.getSemantics(_navItem(3)).label, 'Favorites');
    expect(tester.getSemantics(_navItem(4)).label, 'Settings');
    expect(
      tester
          .getSemantics(_navItem(0))
          .flagsCollection
          .isSelected
          .toString()
          .toLowerCase(),
      contains('istrue'),
    );
  });

  testWidgets('selection bubble travels, overshoots, then settles on the tab', (
    WidgetTester tester,
  ) async {
    final ValueNotifier<int> selected = ValueNotifier<int>(0);
    addTearDown(selected.dispose);
    await tester.pumpWidget(_harness(selected));

    final Finder nav = find.byType(LingoFloatingBottomNav);
    final Finder bubble = find.byKey(LingoFloatingBottomNav.selectionBubbleKey);
    final Rect start = tester.getRect(bubble);
    final Rect first = tester.getRect(_navItem(0));
    expect(start.center.dx, closeTo(first.center.dx, 10));

    await tester.tap(_navItem(4));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 90));
    final Rect traveling = tester.getRect(bubble);
    expect(traveling.center.dx, greaterThan(start.center.dx + 12));

    await tester.pump(const Duration(milliseconds: 260));
    final Rect settled = tester.getRect(bubble);
    final Rect last = tester.getRect(_navItem(4));
    expect(settled.center.dx, closeTo(last.center.dx, 10));
    expect(settled.left, greaterThanOrEqualTo(tester.getRect(nav).left));
    expect(settled.right, lessThanOrEqualTo(tester.getRect(nav).right));

    final List<LingoNavGlyphIcon> glyphs = tester
        .widgetList<LingoNavGlyphIcon>(find.byType(LingoNavGlyphIcon))
        .toList(growable: false);
    expect(glyphs[4].selected, isTrue);
    expect(glyphs[0].selected, isFalse);
  });

  testWidgets('RTL keeps Home on the trailing edge and bubble with it', (
    WidgetTester tester,
  ) async {
    final ValueNotifier<int> selected = ValueNotifier<int>(0);
    addTearDown(selected.dispose);
    await tester.pumpWidget(
      _harness(selected, textDirection: TextDirection.rtl),
    );

    final Rect home = tester.getRect(_navItem(0));
    final Rect settings = tester.getRect(_navItem(4));
    expect(home.center.dx, greaterThan(settings.center.dx));

    final Rect bubble = tester.getRect(
      find.byKey(LingoFloatingBottomNav.selectionBubbleKey),
    );
    expect(bubble.center.dx, closeTo(home.center.dx, 10));
    expect(tester.getSemantics(_navItem(0)).label, 'Home');
  });

  testWidgets('compact and Pro Max capsules keep tap targets and safe area', (
    WidgetTester tester,
  ) async {
    Future<void> pumpAt(Size size) async {
      tester.view.physicalSize = Size(size.width * 2, size.height * 2);
      tester.view.devicePixelRatio = 2;
      tester.view.padding = const FakeViewPadding(bottom: 34);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              padding: const EdgeInsets.only(bottom: 34),
            ),
            child: const Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: LingoFloatingBottomNav(
                  selectedIndex: 0,
                  onSelected: _noopIndex,
                  destinations: _destinations,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);

    await pumpAt(const Size(320, 568));
    expect(tester.takeException(), isNull);
    expect(find.byType(LingoNavGlyphIcon), findsNWidgets(5));
    final Rect firstSmall = tester.getRect(_navItem(0));
    expect(firstSmall.left, greaterThan(8));
    expect(firstSmall.height, greaterThanOrEqualTo(44));

    await pumpAt(const Size(430, 932));
    expect(tester.takeException(), isNull);
    final Rect bar = tester.getRect(find.byType(LingoFloatingBottomNav));
    expect(bar.bottom, closeTo(932, 0.5));
    final Rect firstLarge = tester.getRect(_navItem(0));
    final Rect lastLarge = tester.getRect(_navItem(4));
    expect(firstLarge.left, greaterThan(12));
    expect(lastLarge.right, lessThan(430 - 12));
    expect(firstLarge.height, greaterThanOrEqualTo(44));
    expect(bar.height, lessThan(140));
    expect(tester.getSemantics(_navItem(3)).label, 'Favorites');
  });

  testWidgets('production tabs keep localized semantics and custom marks', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester, const Size(390, 844));

    final Finder nav = find.byType(LingoFloatingBottomNav);
    expect(
      find.descendant(of: nav, matching: find.byType(LingoNavGlyphIcon)),
      findsNWidgets(5),
    );
    expect(find.descendant(of: nav, matching: find.text('Home')), findsNothing);
    expect(
      find.descendant(of: nav, matching: find.text('Alphabet')),
      findsNothing,
    );

    List<LingoBottomNavItem> items = tester
        .widgetList<LingoBottomNavItem>(find.byType(LingoBottomNavItem))
        .toList(growable: false);
    List<LingoNavGlyphIcon> glyphs = tester
        .widgetList<LingoNavGlyphIcon>(find.byType(LingoNavGlyphIcon))
        .toList(growable: false);
    expect(items[0].selected, isTrue);
    expect(items[0].label, 'Home');
    expect(glyphs[0].selected, isTrue);
    expect(tester.getSemantics(_navItem(0)).label, 'Home');
    expect(tester.getSemantics(_navItem(4)).label, 'Settings');

    await tester.tap(_navItem(4));
    await tester.pump();
    items = tester
        .widgetList<LingoBottomNavItem>(find.byType(LingoBottomNavItem))
        .toList(growable: false);
    glyphs = tester
        .widgetList<LingoNavGlyphIcon>(find.byType(LingoNavGlyphIcon))
        .toList(growable: false);
    expect(items[4].selected, isTrue);
    expect(glyphs[4].selected, isTrue);
    expect(find.text('Privacy'), findsOneWidget);

    await tester.tap(_navItem(1));
    await tester.pump();
    items = tester
        .widgetList<LingoBottomNavItem>(find.byType(LingoBottomNavItem))
        .toList(growable: false);
    expect(items[1].selected, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('nav hides after idle and returns on tab interaction', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester, const Size(390, 844));
    final Finder nav = find.byType(LingoFloatingBottomNav);
    expect(tester.widget<LingoFloatingBottomNav>(nav).visible, isTrue);

    await tester.pump(const Duration(milliseconds: 2800));
    await tester.pump();
    expect(tester.widget<LingoFloatingBottomNav>(nav).visible, isFalse);

    await tester.tapAt(const Offset(195, 320));
    await tester.pump();
    expect(tester.widget<LingoFloatingBottomNav>(nav).visible, isTrue);

    await tester.tap(_navItem(2));
    await tester.pump();
    expect(tester.widget<LingoFloatingBottomNav>(nav).visible, isTrue);
    final List<LingoBottomNavItem> items = tester
        .widgetList<LingoBottomNavItem>(find.byType(LingoBottomNavItem))
        .toList(growable: false);
    expect(items[2].selected, isTrue);
  });

  testWidgets('Arabic production chrome keeps RTL tab order', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester, const Size(390, 844), languageCode: 'ar');

    final List<LingoBottomNavItem> items = tester
        .widgetList<LingoBottomNavItem>(find.byType(LingoBottomNavItem))
        .toList(growable: false);
    expect(items.map((LingoBottomNavItem item) => item.label), <String>[
      'الرئيسية',
      'الكلمات',
      'العبارات',
      'المفضلة',
      'الإعدادات',
    ]);
    expect(tester.getSemantics(_navItem(0)).label, 'الرئيسية');
    final Rect home = tester.getRect(_navItem(0));
    final Rect settings = tester.getRect(_navItem(4));
    expect(home.center.dx, greaterThan(settings.center.dx));
    final Rect bubble = tester.getRect(
      find.byKey(LingoFloatingBottomNav.selectionBubbleKey),
    );
    expect(bubble.center.dx, closeTo(home.center.dx, 12));
  });
}

Finder _navItem(int index) {
  return find.byKey(ValueKey<String>('nav-item-$index'));
}

Widget _harness(
  ValueNotifier<int> selected, {
  TextDirection textDirection = TextDirection.ltr,
}) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Directionality(
      textDirection: textDirection,
      child: Scaffold(
        body: ValueListenableBuilder<int>(
          valueListenable: selected,
          builder: (BuildContext context, int index, Widget? child) {
            return Align(
              alignment: Alignment.bottomCenter,
              child: LingoFloatingBottomNav(
                includeSafeArea: false,
                selectedIndex: index,
                onSelected: (int next) => selected.value = next,
                destinations: _destinations,
              ),
            );
          },
        ),
      ),
    ),
  );
}

const List<LingoNavDestination> _destinations = <LingoNavDestination>[
  LingoNavDestination(label: 'Home', glyph: LingoNavGlyph.home),
  LingoNavDestination(label: 'Words', glyph: LingoNavGlyph.words),
  LingoNavDestination(label: 'Phrases', glyph: LingoNavGlyph.phrases),
  LingoNavDestination(label: 'Favorites', glyph: LingoNavGlyph.favorites),
  LingoNavDestination(label: 'Settings', glyph: LingoNavGlyph.settings),
];

void _noopIndex(int index) {}

Future<void> _pumpApp(
  WidgetTester tester,
  Size size, {
  String languageCode = 'en',
}) async {
  tester.view.physicalSize = Size(size.width * 3, size.height * 3);
  tester.view.devicePixelRatio = 3;
  tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);

  UserPreferences.resetForTest();
  await UserPreferences.instance.setSelectedTranslationLanguage(languageCode);
  FeedbackService.instance = FeedbackService(
    hapticsEnabled: false,
    soundEnabled: false,
  );
  final LocalContentRepository? repo = await tester.runAsync(
    LocalContentRepository.load,
  );
  if (repo == null) {
    fail('content pack was not loaded');
  }
  await tester.pumpWidget(LingoCoreApp(contentRepository: repo));
  await tester.pump();
}
