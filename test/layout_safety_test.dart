import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_core/core/assets/lingo_assets.dart';
import 'package:lingo_core/core/theme/app_theme.dart';
import 'package:lingo_core/core/theme/lingo_tokens.dart';
import 'package:lingo_core/core/widgets/lingo_cards.dart';
import 'package:lingo_core/core/widgets/lingo_controls.dart';
import 'package:lingo_core/core/widgets/lingo_layout.dart';

void main() {
  testWidgets('empty meanings do not reserve blank copy', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: LingoWordCard(word: 'Hello', meaning: ''),
        ),
      ),
    );

    expect(find.text('Hello'), findsOneWidget);
    expect(find.text(''), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('matching meanings do not repeat the headword', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: Column(
            children: <Widget>[
              LingoWordCard(word: 'Hello', meaning: 'hello.'),
              LingoPhraseCard(phrase: 'Good morning.', meaning: 'Good morning'),
              LingoWordCard(word: 'Hello', meaning: 'Merhaba'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Hello'), findsWidgets);
    expect(find.text('hello.'), findsNothing);
    expect(find.text('Good morning'), findsNothing);
    expect(find.text('Merhaba'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('phrase cards stay inside RTL and compact bounds', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        builder: (BuildContext context, Widget? child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const Scaffold(
          body: SizedBox(
            width: 320,
            child: LingoPhraseCard(
              phrase: 'Good morning, how are you today?',
              meaning: 'Sabahlar hayırlı olsun, nasılsın?',
              action: LingoFavoriteButton(saved: true, onPressed: _noop),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Good morning, how are you today?'), findsOneWidget);
  });

  testWidgets('missing category images fall back without breaking layout', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Wrap(
              children: <Widget>[
                for (final LingoArtKind art in LingoArtKind.values)
                  SizedBox(
                    width: 180,
                    child: LingoCategoryCard(label: art.name, art: art),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('basics'), findsOneWidget);
    expect(find.text('questions'), findsOneWidget);
  });

  testWidgets('settings chevron mirrors in RTL', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        builder: (BuildContext context, Widget? child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const Scaffold(
          body: LingoSettingsRow(title: 'Privacy', onPressed: _noop),
        ),
      ),
    );

    expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long category labels wrap inside a reserved two-line block', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 168,
              child: LingoCategoryCard(
                label: 'Sehenswürdigkeiten und Reiseziele',
                art: LingoArtKind.travel,
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Sehenswürdigkeiten und Reiseziele'), findsOneWidget);
    final Size card = tester.getSize(find.byType(LingoCategoryCard));
    expect(card.height - card.width, lessThan(52));
  });

  testWidgets('word cards stay compact with pronunciation and meaning', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: LingoWordCard(
              word: 'Hallo',
              pronunciation: '/hˈaloː/',
              meaning: 'A greeting used when meeting someone.',
              action: LingoFavoriteButton(saved: false, onPressed: _noop),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Hallo'), findsOneWidget);
    expect(find.text('A greeting used when meeting someone.'), findsOneWidget);
    expect(
      tester
              .getRect(find.text('A greeting used when meeting someone.'))
              .bottom -
          tester.getRect(find.text('Hallo')).top,
      lessThan(112),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('phrase cards wrap long copy and show pronunciation', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: SizedBox(
            width: 320,
            child: LingoPhraseCard(
              phrase: 'Could you please tell me how to get to the station?',
              pronunciation: '/kʊd ju pliːz/',
              meaning:
                  'İstasyona nasıl gideceğimi lütfen söyler misiniz, çok teşekkür ederim.',
              action: LingoFavoriteButton(saved: true, onPressed: _noop),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('/kʊd ju pliːz/'), findsNothing);
    expect(
      find.text('Could you please tell me how to get to the station?'),
      findsOneWidget,
    );
  });

  testWidgets('pair grids keep leftover cards at half width', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: LingoPairGrid(
              spacing: LingoSpacing.lg,
              stack: false,
              children: const <Widget>[
                SizedBox(
                  key: Key('grid-a'),
                  height: 48,
                  width: double.infinity,
                ),
                SizedBox(
                  key: Key('grid-b'),
                  height: 48,
                  width: double.infinity,
                ),
                SizedBox(
                  key: Key('grid-c'),
                  height: 48,
                  width: double.infinity,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final double full = tester.getSize(find.byType(LingoPairGrid)).width;
    final double leftover = tester
        .getSize(find.byKey(const Key('grid-c')))
        .width;
    expect(leftover, closeTo((full - LingoSpacing.lg) / 2, 0.5));
    expect(leftover, lessThan(full * 0.6));
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings rows wrap long localized titles', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: SizedBox(
            width: 320,
            child: LingoSettingsRow(
              title: 'Dokunsal geri bildirim',
              subtitle: 'Translation language for the learner',
              onPressed: _noop,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Dokunsal geri bildirim'), findsOneWidget);
  });

  testWidgets('German compound nouns wrap on a compact iPhone', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: SizedBox(
            width: 320,
            child: LingoWordCard(
              word: 'das Vorstellungsgespräch',
              meaning: 'job interview',
              action: LingoFavoriteButton(saved: false, onPressed: _noop),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('das Vorstellungsgespräch'), findsOneWidget);
    expect(tester.getSize(find.byType(LingoWordCard)).width, lessThan(321));
  });

  testWidgets('German umlauts and ß stay visible in cards and phrases', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: SizedBox(
            width: 320,
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  LingoWordCard(word: 'die Straße', meaning: 'street'),
                  LingoWordCard(word: 'die Äpfel', meaning: 'apples'),
                  LingoPhraseCard(
                    phrase: 'Könnte ich einen weiteren Zimmerschlüssel haben?',
                    meaning: 'Could I have another room key?',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('die Straße'), findsOneWidget);
    expect(find.text('die Äpfel'), findsOneWidget);
    expect(
      find.text('Könnte ich einen weiteren Zimmerschlüssel haben?'),
      findsOneWidget,
    );
    expect(find.textContaining('ß'), findsWidgets);
    expect(find.textContaining('Ä'), findsOneWidget);
    expect(find.textContaining('ö'), findsOneWidget);
  });
}

void _noop() {}
