import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_core/app/content_scope.dart';
import 'package:lingo_core/core/audio/pronunciation_service.dart';
import 'package:lingo_core/core/feedback/feedback_service.dart';
import 'package:lingo_core/core/theme/app_theme.dart';
import 'package:lingo_core/core/widgets/lingo_controls.dart';
import 'package:lingo_core/core/widgets/lingo_layout.dart';
import 'package:lingo_core/core/widgets/pronunciation_control.dart';
import 'package:lingo_core/data/local_content_repository.dart';
import 'package:lingo_core/data/user_preferences.dart';
import 'package:lingo_core/domain/content_models.dart';
import 'package:lingo_core/domain/content_repository.dart';
import 'package:lingo_core/domain/product_config.dart';
import 'package:lingo_core/features/learn/alphabet_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    LocalContentRepository.clearCache();
    UserPreferences.resetForTest();
    ProductConfig.reset();
    FeedbackService.instance = FeedbackService(
      haptics: HapticService(driver: _RecordingHapticDriver()),
      soundEnabled: false,
    );
    _installFakePronunciation();
  });

  tearDown(() {
    LocalContentRepository.clearCache();
    UserPreferences.resetForTest();
    ProductConfig.reset();
  });

  group('bundled German alphabet illustrations', () {
    test('every current Alphabet item has a real 1024×1024 image', () async {
      final LocalContentRepository repo = await LocalContentRepository.load();
      expect(repo.alphabet, hasLength(30));
      expect(repo.alphabetUnitById('letter.auml')?.glyph, 'Ä');
      expect(repo.alphabetUnitById('letter.ouml')?.glyph, 'Ö');
      expect(repo.alphabetUnitById('letter.uuml')?.glyph, 'Ü');
      expect(repo.alphabetUnitById('letter.eszett')?.glyph, 'ß');

      final String screenSource = File(
        'lib/features/learn/alphabet_screen.dart',
      ).readAsStringSync();
      expect(screenSource.contains('.png'), isFalse);
      expect(screenSource.contains('apple.png'), isFalse);

      expect(repo.pronunciationEnabled, isTrue);

      final Set<String> ids = <String>{};
      final Set<String> referencedFiles = <String>{};
      for (final AlphabetUnit unit in repo.alphabet) {
        expect(ids.add(unit.id), isTrue, reason: 'duplicate ${unit.id}');
        expect(unit.glyph.trim(), isNotEmpty, reason: unit.id);
        expect(unit.pronunciation, isNotNull, reason: unit.id);
        expect(unit.pronunciation!.trim(), isNotEmpty, reason: unit.id);
        expect(unit.example, isNotNull, reason: unit.id);
        expect(unit.example!.trim(), isNotEmpty, reason: unit.id);
        expect(
          repo.translation(unit.id, languageCode: 'en'),
          isNotNull,
          reason: unit.id,
        );
        expect(
          repo.translation(unit.id, languageCode: 'tr'),
          isNotNull,
          reason: unit.id,
        );
        expect(
          repo.translation(unit.id, languageCode: 'en')!.trim(),
          isNotEmpty,
          reason: unit.id,
        );
        expect(
          repo.translation(unit.id, languageCode: 'tr')!.trim(),
          isNotEmpty,
          reason: unit.id,
        );

        final String? path = unit.imageAsset;
        expect(path, isNotNull, reason: unit.id);
        expect(path, isNotEmpty, reason: unit.id);
        expect(unit.audioAsset, isNull, reason: unit.id);
        expect(
          repo.pronunciationAssetFor(unit.id),
          'assets/audio/de/alphabet/${unit.id}.wav',
          reason: unit.id,
        );
        final File file = File(path!);
        expect(file.existsSync(), isTrue, reason: path);
        expect(file.lengthSync(), greaterThan(8 * 1024), reason: path);
        final (int, int) size = _imageSize(file.readAsBytesSync());
        expect(size.$1, 1024, reason: path);
        expect(size.$2, 1024, reason: path);
        referencedFiles.add(file.uri.pathSegments.last);
      }

      final Set<String> onDisk = Directory('assets/images/alphabet')
          .listSync()
          .whereType<File>()
          .map((File file) => file.uri.pathSegments.last)
          .where((String name) => name.endsWith('.png'))
          .toSet();
      expect(onDisk.containsAll(referencedFiles), isTrue);
    });
  });

  group('selected character card', () {
    testWidgets('root screen has no redundant Alphabet heading', (
      WidgetTester tester,
    ) async {
      await _pumpAlphabet(
        tester,
        _repo(
          alphabet: const <AlphabetUnit>[
            AlphabetUnit(
              id: 'letter.a',
              glyph: 'A',
              sortOrder: 0,
              quizEnabled: true,
              pronunciation: 'ay',
              example: 'apple',
            ),
          ],
        ),
      );

      expect(find.byType(LingoLargeTitle), findsNothing);
      expect(find.text('Alphabet'), findsNothing);
      expect(find.text('Alfabe'), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('alphabet-glyph')),
        findsOneWidget,
      );
    });

    testWidgets('selecting a character updates the study card', (
      WidgetTester tester,
    ) async {
      final LocalContentRepository repo = _repo(
        alphabet: const <AlphabetUnit>[
          AlphabetUnit(
            id: 'letter.a',
            glyph: 'A',
            sortOrder: 0,
            quizEnabled: true,
            pronunciation: 'ay',
            romanization: '/eɪ/',
            example: 'apple',
            imageAsset: 'assets/images/alphabet/apple.png',
          ),
          AlphabetUnit(
            id: 'letter.b',
            glyph: 'B',
            sortOrder: 1,
            quizEnabled: true,
            pronunciation: 'bee',
            romanization: '/biː/',
            example: 'book',
            imageAsset: 'assets/images/alphabet/book.png',
          ),
        ],
        strings: const <String, Map<String, String>>{
          'en': <String, String>{'letter.a': 'apple', 'letter.b': 'book'},
          'tr': <String, String>{'letter.a': 'elma', 'letter.b': 'kitap'},
        },
        translationLanguageCodes: const <String>['en', 'tr'],
      );
      await _pumpAlphabet(tester, repo);

      expect(
        find.byKey(const ValueKey<String>('alphabet-glyph')),
        findsOneWidget,
      );
      expect(find.text('ay'), findsOneWidget);
      expect(find.text('/eɪ/'), findsNothing);
      expect(find.text('apple'), findsWidgets);
      expect(
        find.byKey(const ValueKey<String>('alphabet-example')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('alphabet-illustration')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('alphabet-study')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('plate-letter.a')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('alphabet-tile-letter.b')),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('alphabet-study')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('plate-letter.b')),
        findsOneWidget,
      );
      expect(find.text('bee'), findsOneWidget);
      expect(find.text('/biː/'), findsNothing);
      expect(find.text('book'), findsWidgets);
      expect(find.text('ay'), findsNothing);
      expect(find.text('apple'), findsNothing);
      expect(find.text('/eɪ/'), findsNothing);
      expect(find.text('elma'), findsNothing);

      UserPreferences.instance.setSelectedTranslationLanguage('tr');
      await tester.pump();
      expect(find.text('book'), findsOneWidget);
      expect(find.text('kitap'), findsOneWidget);
      expect(find.text('elma'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('IPA pronunciation falls back to a subtle romanization cue', (
      WidgetTester tester,
    ) async {
      await _pumpAlphabet(
        tester,
        _repo(
          alphabet: const <AlphabetUnit>[
            AlphabetUnit(
              id: 'kana.ki',
              glyph: 'き',
              sortOrder: 0,
              quizEnabled: false,
              pronunciation: '/ki/',
              romanization: 'ki',
              example: 'きく',
            ),
          ],
          scriptFamily: ScriptFamily.japanese,
        ),
      );

      expect(find.text('き'), findsWidgets);
      expect(find.text('ki'), findsOneWidget);
      expect(find.text('/ki/'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('target example and learner translation stay separate', (
      WidgetTester tester,
    ) async {
      final LocalContentRepository repo = _repo(
        alphabet: const <AlphabetUnit>[
          AlphabetUnit(
            id: 'letter.a',
            glyph: 'A',
            sortOrder: 0,
            quizEnabled: true,
            pronunciation: 'ay',
            romanization: '/eɪ/',
            example: 'apple',
          ),
        ],
        translationLanguageCodes: const <String>['tr'],
        strings: const <String, Map<String, String>>{
          'tr': <String, String>{'letter.a': 'elma'},
        },
      );
      await _pumpAlphabet(tester, repo);

      expect(
        find.byKey(const ValueKey<String>('alphabet-example')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('alphabet-meaning')),
        findsOneWidget,
      );
      expect(find.text('apple'), findsOneWidget);
      expect(find.text('elma'), findsOneWidget);
    });
  });

  group('optional data fallbacks', () {
    testWidgets('missing optional fields do not crash or leave blank copy', (
      WidgetTester tester,
    ) async {
      final LocalContentRepository repo = _repo(
        alphabet: const <AlphabetUnit>[
          AlphabetUnit(
            id: 'letter.bare',
            glyph: 'あ',
            sortOrder: 0,
            quizEnabled: false,
          ),
        ],
      );
      await _pumpAlphabet(tester, repo);

      expect(find.text('あ'), findsWidgets);
      expect(find.text('Example'), findsNothing);
      expect(find.text('Meaning'), findsNothing);
      expect(find.byType(PronunciationControl), findsOneWidget);
      expect(find.byIcon(Icons.volume_up_outlined), findsOneWidget);
      expect(find.byIcon(Icons.volume_up_rounded), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('alphabet-illustration')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('bundled illustration assets can paint in the study plate', (
      WidgetTester tester,
    ) async {
      final LocalContentRepository repo = _repo(
        alphabet: const <AlphabetUnit>[
          AlphabetUnit(
            id: 'letter.a',
            glyph: 'A',
            sortOrder: 0,
            quizEnabled: false,
            example: 'apple',
            imageAsset: 'assets/images/alphabet/apple.png',
          ),
        ],
      );
      await _pumpAlphabet(tester, repo);
      expect(
        find.byKey(const ValueKey<String>('alphabet-illustration')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('missing image path still keeps a stable plate', (
      WidgetTester tester,
    ) async {
      final LocalContentRepository repo = _repo(
        alphabet: const <AlphabetUnit>[
          AlphabetUnit(
            id: 'letter.ghost',
            glyph: 'Q',
            sortOrder: 0,
            quizEnabled: false,
            example: 'queen',
            imageAsset: 'assets/images/alphabet/missing-queen.png',
          ),
        ],
        strings: const <String, Map<String, String>>{
          'en': <String, String>{'letter.ghost': 'queen'},
        },
      );
      await _pumpAlphabet(tester, repo);
      await tester.pump();
      expect(find.text('queen'), findsWidgets);
      expect(
        find.byKey(const ValueKey<String>('alphabet-illustration')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('non-Latin layout safety', () {
    testWidgets('kana, Hangul, Arabic, and Cyrillic glyphs render', (
      WidgetTester tester,
    ) async {
      final LocalContentRepository repo = _repo(
        alphabet: const <AlphabetUnit>[
          AlphabetUnit(
            id: 'kana.ki',
            glyph: 'き',
            sortOrder: 0,
            quizEnabled: false,
            pronunciation: 'ki',
            romanization: 'ki',
          ),
          AlphabetUnit(
            id: 'kana.kya',
            glyph: 'きゃ',
            sortOrder: 1,
            quizEnabled: false,
            pronunciation: 'kya',
          ),
          AlphabetUnit(
            id: 'hangul.ga',
            glyph: '가',
            sortOrder: 2,
            quizEnabled: false,
            pronunciation: 'ga',
          ),
          AlphabetUnit(
            id: 'arabic.ba',
            glyph: 'ب',
            sortOrder: 3,
            quizEnabled: false,
            pronunciation: 'ba',
          ),
          AlphabetUnit(
            id: 'cyrillic.ya',
            glyph: 'Я',
            sortOrder: 4,
            quizEnabled: false,
            pronunciation: 'ya',
          ),
        ],
        scriptFamily: ScriptFamily.japanese,
      );
      await _pumpAlphabet(tester, repo, size: const Size(320, 568));

      expect(find.text('き'), findsWidgets);
      expect(find.text('きゃ'), findsOneWidget);
      expect(find.text('가'), findsOneWidget);
      expect(find.text('ب'), findsOneWidget);
      expect(find.text('Я'), findsWidgets);
      expect(tester.takeException(), isNull);

      await tester.tap(
        find.byKey(const ValueKey<String>('alphabet-tile-hangul.ga')),
      );
      await tester.pump();
      expect(find.text('ga'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a 3-character inventory stays fully selectable', (
      WidgetTester tester,
    ) async {
      await _pumpAlphabet(
        tester,
        _repo(
          alphabet: const <AlphabetUnit>[
            AlphabetUnit(
              id: 'item.one',
              glyph: 'あ',
              sortOrder: 0,
              quizEnabled: false,
              pronunciation: 'a',
              example: 'あめ',
            ),
            AlphabetUnit(
              id: 'item.two',
              glyph: 'い',
              sortOrder: 1,
              quizEnabled: false,
              pronunciation: 'i',
              example: 'いす',
            ),
            AlphabetUnit(
              id: 'item.three',
              glyph: 'う',
              sortOrder: 2,
              quizEnabled: false,
              pronunciation: 'u',
              example: 'うみ',
            ),
          ],
          scriptFamily: ScriptFamily.japanese,
          strings: const <String, Map<String, String>>{
            'en': <String, String>{
              'item.one': 'candy',
              'item.two': 'chair',
              'item.three': 'sea',
            },
          },
        ),
        size: const Size(320, 568),
      );

      expect(
        find.byKey(const ValueKey<String>('alphabet-grid')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('alphabet-tile-item.three')),
      );
      await tester.pump();
      expect(find.text('u'), findsOneWidget);
      expect(find.text('うみ'), findsOneWidget);
      expect(find.text('sea'), findsOneWidget);
      expect(find.text('あめ'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('RTL packs keep the study card inside compact bounds', (
      WidgetTester tester,
    ) async {
      final LocalContentRepository repo = _repo(
        alphabet: const <AlphabetUnit>[
          AlphabetUnit(
            id: 'arabic.alif',
            glyph: 'ا',
            sortOrder: 0,
            quizEnabled: false,
            pronunciation: 'alif',
            example: 'أسد',
          ),
          AlphabetUnit(
            id: 'arabic.ba',
            glyph: 'ب',
            sortOrder: 1,
            quizEnabled: false,
            pronunciation: 'ba',
            example: 'بيت',
          ),
        ],
        scriptFamily: ScriptFamily.arabic,
        textDirection: ContentTextDirection.rtl,
        strings: const <String, Map<String, String>>{
          'en': <String, String>{'arabic.alif': 'lion', 'arabic.ba': 'house'},
        },
      );
      await _pumpAlphabet(
        tester,
        repo,
        size: const Size(320, 568),
        textDirection: TextDirection.rtl,
      );

      expect(find.text('ا'), findsWidgets);
      expect(find.text('أسد'), findsOneWidget);
      expect(find.text('lion'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('standard iPhone uses five balanced glyph columns', (
      WidgetTester tester,
    ) async {
      await _pumpAlphabet(
        tester,
        _repo(
          alphabet: <AlphabetUnit>[
            for (int index = 0; index < 26; index++)
              AlphabetUnit(
                id: 'letter.$index',
                glyph: String.fromCharCode(0x41 + index),
                sortOrder: index,
                quizEnabled: false,
                pronunciation: 'p$index',
              ),
          ],
        ),
        size: const Size(390, 844),
      );

      final Offset first = tester.getTopLeft(
        find.byKey(const ValueKey<String>('alphabet-tile-letter.0')),
      );
      final Offset fifth = tester.getTopLeft(
        find.byKey(const ValueKey<String>('alphabet-tile-letter.4')),
      );
      final Offset sixth = tester.getTopLeft(
        find.byKey(const ValueKey<String>('alphabet-tile-letter.5')),
      );
      expect(first.dy, closeTo(fifth.dy, 0.5));
      expect(sixth.dy, greaterThan(first.dy + 24));
      expect(tester.takeException(), isNull);
    });

    testWidgets('narrow layout falls back to four glyph columns', (
      WidgetTester tester,
    ) async {
      await _pumpAlphabet(
        tester,
        _repo(
          alphabet: <AlphabetUnit>[
            for (int index = 0; index < 26; index++)
              AlphabetUnit(
                id: 'letter.$index',
                glyph: String.fromCharCode(0x41 + index),
                sortOrder: index,
                quizEnabled: false,
                pronunciation: 'p$index',
              ),
          ],
        ),
        size: const Size(320, 568),
      );

      final Offset first = tester.getTopLeft(
        find.byKey(const ValueKey<String>('alphabet-tile-letter.0')),
      );
      final Offset fourth = tester.getTopLeft(
        find.byKey(const ValueKey<String>('alphabet-tile-letter.3')),
      );
      final Offset fifth = tester.getTopLeft(
        find.byKey(const ValueKey<String>('alphabet-tile-letter.4')),
      );
      expect(first.dy, closeTo(fourth.dy, 0.5));
      expect(fifth.dy, greaterThan(first.dy + 24));
      expect(tester.takeException(), isNull);
    });

    testWidgets('large iPhone layout stays overflow-free', (
      WidgetTester tester,
    ) async {
      final LocalContentRepository repo = _repo(
        alphabet: <AlphabetUnit>[
          for (int index = 0; index < 26; index++)
            AlphabetUnit(
              id: 'letter.$index',
              glyph: String.fromCharCode(0x41 + index),
              sortOrder: index,
              quizEnabled: false,
              pronunciation: 'p$index',
            ),
        ],
      );
      await _pumpAlphabet(tester, repo, size: const Size(430, 932));
      expect(
        find.byKey(const ValueKey<String>('alphabet-grid')),
        findsOneWidget,
      );
      expect(find.text('Z'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('small iPhone wraps a long learner translation', (
      WidgetTester tester,
    ) async {
      await _pumpAlphabet(
        tester,
        _repo(
          alphabet: const <AlphabetUnit>[
            AlphabetUnit(
              id: 'letter.z',
              glyph: 'Z',
              sortOrder: 0,
              quizEnabled: false,
              pronunciation: 'zee',
              example: 'zoo',
              imageAsset: 'assets/images/alphabet/zoo.png',
            ),
          ],
          translationLanguageCodes: const <String>['tr'],
          strings: const <String, Map<String, String>>{
            'tr': <String, String>{'letter.z': 'hayvanat bahçesi'},
          },
        ),
        size: const Size(320, 568),
      );

      expect(find.text('zoo'), findsOneWidget);
      expect(find.text('hayvanat bahçesi'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('alphabet-illustration')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('standard iPhone layout stays overflow-free', (
      WidgetTester tester,
    ) async {
      await _pumpAlphabet(
        tester,
        _repo(
          alphabet: <AlphabetUnit>[
            for (int index = 0; index < 26; index++)
              AlphabetUnit(
                id: 'letter.$index',
                glyph: String.fromCharCode(0x41 + index),
                sortOrder: index,
                quizEnabled: false,
                pronunciation: 'p$index',
                example: 'word $index',
              ),
          ],
        ),
        size: const Size(390, 844),
      );
      expect(
        find.byKey(const ValueKey<String>('alphabet-grid')),
        findsOneWidget,
      );
      expect(find.text('Z'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('large accessibility text stays overflow-free', (
      WidgetTester tester,
    ) async {
      await _pumpAlphabet(
        tester,
        _repo(
          alphabet: const <AlphabetUnit>[
            AlphabetUnit(
              id: 'letter.z',
              glyph: 'Z',
              sortOrder: 0,
              quizEnabled: false,
              pronunciation: 'zee',
              romanization: '/ziː/',
              example: 'zoo',
              imageAsset: 'assets/images/alphabet/zoo.png',
            ),
            AlphabetUnit(
              id: 'letter.a',
              glyph: 'A',
              sortOrder: 1,
              quizEnabled: false,
              pronunciation: 'ay',
              example: 'apple',
            ),
          ],
          translationLanguageCodes: const <String>['tr'],
          strings: const <String, Map<String, String>>{
            'tr': <String, String>{
              'letter.z': 'hayvanat bahçesi ve çevresindeki uzun açıklama',
            },
          },
        ),
        size: const Size(320, 568),
        textScaler: const TextScaler.linear(1.4),
      );

      expect(find.text('zee'), findsOneWidget);
      expect(
        find.text('hayvanat bahçesi ve çevresindeki uzun açıklama'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('alphabet-grid')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('bundled English pack renders the selected-character card', (
    WidgetTester tester,
  ) async {
    await _pumpAlphabet(
      tester,
      _repo(
        alphabet: <AlphabetUnit>[
          for (int index = 0; index < 26; index++)
            AlphabetUnit(
              id: 'letter.${String.fromCharCode(0x61 + index)}',
              glyph: String.fromCharCode(0x41 + index),
              sortOrder: index,
              quizEnabled: true,
              pronunciation: 'sound $index',
              romanization: '/ipa/',
              example: 'word $index',
            ),
        ],
        strings: <String, Map<String, String>>{
          'en': <String, String>{
            for (int index = 0; index < 26; index++)
              'letter.${String.fromCharCode(0x61 + index)}': 'meaning $index',
          },
        },
      ),
    );

    expect(find.byType(AlphabetScreen), findsOneWidget);
    expect(find.text('A'), findsWidgets);
    expect(find.text('sound 0'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('alphabet-example')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('alphabet-illustration')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey<String>('alphabet-grid')), findsOneWidget);
    expect(find.text('meaning 0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('selection and translation', () {
    testWidgets('every character can be selected and updates the card', (
      WidgetTester tester,
    ) async {
      await _pumpAlphabet(
        tester,
        _repo(
          alphabet: <AlphabetUnit>[
            for (int index = 0; index < 26; index++)
              AlphabetUnit(
                id: 'letter.${String.fromCharCode(0x61 + index)}',
                glyph: String.fromCharCode(0x41 + index),
                sortOrder: index,
                quizEnabled: true,
                pronunciation: 'sound $index',
                example: 'word $index',
              ),
          ],
        ),
        size: const Size(430, 932),
      );

      for (int index = 0; index < 26; index++) {
        final String id = 'letter.${String.fromCharCode(0x61 + index)}';
        final Finder tile = find.byKey(ValueKey<String>('alphabet-tile-$id'));
        await tester.tap(tile);
        await tester.pump();
        expect(find.text('sound $index'), findsOneWidget);
        expect(find.text('word $index'), findsWidgets);
      }
      expect(tester.takeException(), isNull);
    });

    test('switching translation language keeps the target example', () async {
      final LocalContentRepository repo = _repo(
        alphabet: const <AlphabetUnit>[
          AlphabetUnit(
            id: 'letter.a',
            glyph: 'A',
            sortOrder: 0,
            quizEnabled: true,
            example: 'apple',
          ),
        ],
        translationLanguageCodes: const <String>['en', 'tr'],
        strings: const <String, Map<String, String>>{
          'en': <String, String>{'letter.a': 'apple'},
          'tr': <String, String>{'letter.a': 'elma'},
        },
      );
      const List<String> codes = <String>['en', 'tr'];
      expect(repo.alphabet.single.example, 'apple');
      expect(
        repo.translation(
          'letter.a',
          languageCode: UserPreferences.instance.resolvedTranslationLanguage(
            codes,
          ),
        ),
        'apple',
      );

      await UserPreferences.instance.setSelectedTranslationLanguage('tr');

      expect(repo.alphabet.single.example, 'apple');
      expect(
        repo.translation(
          'letter.a',
          languageCode: UserPreferences.instance.resolvedTranslationLanguage(
            codes,
          ),
        ),
        'elma',
      );
    });

    testWidgets('learner translation updates without changing the example', (
      WidgetTester tester,
    ) async {
      final LocalContentRepository repo = _repo(
        alphabet: const <AlphabetUnit>[
          AlphabetUnit(
            id: 'letter.a',
            glyph: 'A',
            sortOrder: 0,
            quizEnabled: true,
            pronunciation: 'ay',
            example: 'apple',
          ),
        ],
        translationLanguageCodes: const <String>['en', 'tr'],
        strings: const <String, Map<String, String>>{
          'en': <String, String>{'letter.a': 'apple'},
          'tr': <String, String>{'letter.a': 'elma'},
        },
      );
      await _pumpAlphabet(tester, repo);

      expect(
        find.byKey(const ValueKey<String>('alphabet-example')),
        findsOneWidget,
      );
      expect(find.text('apple'), findsOneWidget);
      expect(find.text('elma'), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('alphabet-meaning')),
        findsNothing,
      );

      UserPreferences.instance.setSelectedTranslationLanguage('tr');
      await tester.pump();

      expect(find.text('apple'), findsOneWidget);
      expect(find.text('elma'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('alphabet-meaning')),
        findsOneWidget,
      );
      expect(find.text('ay'), findsOneWidget);
    });
  });

  group('pronunciation playback', () {
    testWidgets('play uses the pronunciation service when audio exists', (
      WidgetTester tester,
    ) async {
      final _RecordingPronunciationPlayer player =
          _RecordingPronunciationPlayer();
      PronunciationService.instance = PronunciationService(
        audioEnabled: true,
        player: player,
        probe: const AlwaysPresentSoundAssetProbe(),
        onStarted: () {},
      );
      await _pumpAlphabet(
        tester,
        _repo(
          alphabet: const <AlphabetUnit>[
            AlphabetUnit(
              id: 'letter.a',
              glyph: 'A',
              sortOrder: 0,
              quizEnabled: true,
              pronunciation: 'ay',
              example: 'apple',
              audioAsset: 'assets/audio/alphabet/a.wav',
            ),
            AlphabetUnit(
              id: 'letter.b',
              glyph: 'B',
              sortOrder: 1,
              quizEnabled: true,
              pronunciation: 'bee',
              audioAsset: 'assets/audio/alphabet/b.wav',
            ),
          ],
        ),
      );

      expect(find.byType(LingoGlyphButton), findsOneWidget);
      expect(
        tester
            .getSemantics(find.byType(LingoGlyphButton))
            .getSemanticsData()
            .tooltip,
        'Play pronunciation',
      );
      expect(
        tester
            .getSemantics(find.byType(LingoGlyphButton))
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );

      await tester.tap(find.byType(LingoGlyphButton));
      await tester.pump();
      await tester.tap(find.byType(LingoGlyphButton));
      await tester.pump();
      expect(player.paths, <String>['assets/audio/alphabet/a.wav']);

      await tester.tap(
        find.byKey(const ValueKey<String>('alphabet-tile-letter.b')),
      );
      await tester.pump();
      expect(player.stopCount, greaterThan(0));
      expect(find.text('bee'), findsOneWidget);
    });

    testWidgets('play does not fire quiz SFX', (WidgetTester tester) async {
      final _RecordingSoundPlayer sfx = _RecordingSoundPlayer();
      final _RecordingPronunciationPlayer player =
          _RecordingPronunciationPlayer();
      FeedbackService.instance = FeedbackService(
        hapticsEnabled: false,
        sound: SoundService(
          enabled: true,
          player: sfx,
          probe: const AlwaysPresentSoundAssetProbe(),
        ),
      );
      PronunciationService.instance = PronunciationService(
        audioEnabled: true,
        player: player,
        probe: const AlwaysPresentSoundAssetProbe(),
      );
      await _pumpAlphabet(
        tester,
        _repo(
          alphabet: const <AlphabetUnit>[
            AlphabetUnit(
              id: 'letter.a',
              glyph: 'A',
              sortOrder: 0,
              quizEnabled: true,
              pronunciation: 'ay',
              audioAsset: 'assets/audio/alphabet/a.wav',
            ),
          ],
        ),
      );

      await tester.tap(find.byType(LingoGlyphButton));
      await tester.pump();
      expect(player.paths, <String>['assets/audio/alphabet/a.wav']);
      expect(sfx.cues, isEmpty);
      expect(sfx.paths, isEmpty);
    });

    testWidgets('a missing pronunciation file stays safe to tap', (
      WidgetTester tester,
    ) async {
      final _RecordingPronunciationPlayer player =
          _RecordingPronunciationPlayer();
      PronunciationService.instance = PronunciationService(
        audioEnabled: true,
        player: player,
        probe: const _AbsentSoundAssetProbe(),
        onStarted: () {},
      );
      await _pumpAlphabet(
        tester,
        _repo(
          alphabet: const <AlphabetUnit>[
            AlphabetUnit(
              id: 'letter.a',
              glyph: 'A',
              sortOrder: 0,
              quizEnabled: true,
              pronunciation: 'ay',
              audioAsset: 'assets/audio/alphabet/missing-a.wav',
            ),
          ],
        ),
      );

      expect(find.byType(LingoGlyphButton), findsOneWidget);
      await tester.tap(find.byType(LingoGlyphButton));
      await tester.pump();
      expect(player.paths, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('missing bundled audio still offers TTS playback', (
      WidgetTester tester,
    ) async {
      final _RecordingPronunciationPlayer player =
          _RecordingPronunciationPlayer();
      PronunciationService.instance = PronunciationService(
        audioEnabled: true,
        player: player,
        speech: const SilentSpeechEngine(),
        probe: const _AbsentSoundAssetProbe(),
        onStarted: () {},
      );
      await _pumpAlphabet(
        tester,
        _repo(
          alphabet: const <AlphabetUnit>[
            AlphabetUnit(
              id: 'letter.a',
              glyph: 'A',
              sortOrder: 0,
              quizEnabled: true,
              pronunciation: 'ay',
              example: 'apple',
            ),
          ],
        ),
      );

      expect(find.byType(LingoGlyphButton), findsOneWidget);
      expect(find.byType(PronunciationControl), findsOneWidget);
      await tester.tap(find.byType(LingoGlyphButton));
      await tester.pump();
      expect(player.paths, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('opening Alphabet does not auto-pronounce the first letter', (
      WidgetTester tester,
    ) async {
      final _RecordingSpeechEngine speech = _RecordingSpeechEngine();
      final _RecordingPronunciationPlayer player =
          _RecordingPronunciationPlayer();
      PronunciationService.instance.dispose();
      PronunciationService.instance = PronunciationService(
        audioEnabled: true,
        player: player,
        speech: speech,
        probe: const AlwaysPresentSoundAssetProbe(),
        onStarted: () {},
      );
      await _pumpAlphabet(
        tester,
        _repo(
          alphabet: const <AlphabetUnit>[
            AlphabetUnit(
              id: 'letter.a',
              glyph: 'A',
              sortOrder: 0,
              quizEnabled: true,
              pronunciation: 'ay',
              example: 'apple',
            ),
            AlphabetUnit(
              id: 'letter.b',
              glyph: 'B',
              sortOrder: 1,
              quizEnabled: true,
              pronunciation: 'bee',
              example: 'book',
            ),
          ],
        ),
      );

      await tester.pump();
      expect(speech.utterances, isEmpty);
      expect(player.paths, isEmpty);

      await tester.tap(
        find.byKey(const ValueKey<String>('alphabet-tile-letter.a')),
      );
      await tester.pump();
      expect(speech.utterances, isEmpty);
      expect(player.paths, isEmpty);
    });

    testWidgets('selecting a new letter pronounces it with the speaker clip', (
      WidgetTester tester,
    ) async {
      final _RecordingSpeechEngine speech = _RecordingSpeechEngine();
      PronunciationService.instance.dispose();
      PronunciationService.instance = PronunciationService(
        audioEnabled: true,
        player: const SilentPronunciationPlayer(),
        speech: speech,
        probe: const _AbsentSoundAssetProbe(),
        speechLocale: 'en',
        onStarted: () {},
      );
      const AlphabetUnit letterA = AlphabetUnit(
        id: 'letter.a',
        glyph: 'A',
        sortOrder: 0,
        quizEnabled: true,
        pronunciation: 'ay',
        speechText: 'A',
        example: 'apple',
      );
      const AlphabetUnit letterB = AlphabetUnit(
        id: 'letter.b',
        glyph: 'B',
        sortOrder: 1,
        quizEnabled: true,
        pronunciation: 'bee',
        speechText: 'B',
        example: 'book',
      );
      await _pumpAlphabet(
        tester,
        _repo(alphabet: const <AlphabetUnit>[letterA, letterB]),
      );

      expect(speech.utterances, isEmpty);
      await tester.tap(
        find.byKey(const ValueKey<String>('alphabet-tile-letter.b')),
      );
      await tester.pump();

      expect(find.text('bee'), findsOneWidget);
      expect(speech.utterances, <(String, String)>[
        (PronunciationClip.fromAlphabet(letterB).speechText!, 'en-US'),
      ]);
      expect(speech.utterances.single.$1, 'B');
      expect(
        speech.utterances.single.$1.toLowerCase(),
        isNot(contains('capital')),
      );
      expect(
        speech.utterances.single.$1.toLowerCase(),
        isNot(contains('uppercase')),
      );
      expect(
        speech.utterances.single.$1.toLowerCase(),
        isNot(contains('lowercase')),
      );
      expect(speech.utterances.single.$1, isNot('book'));
      expect(speech.utterances.single.$1, isNot('bee'));
    });

    testWidgets('selecting another letter replaces in-flight pronunciation', (
      WidgetTester tester,
    ) async {
      final _GateSpeechEngine speech = _GateSpeechEngine();
      PronunciationService.instance.dispose();
      PronunciationService.instance = PronunciationService(
        audioEnabled: true,
        player: const SilentPronunciationPlayer(),
        speech: speech,
        probe: const _AbsentSoundAssetProbe(),
        speechLocale: 'en',
        onStarted: () {},
      );
      await _pumpAlphabet(
        tester,
        _repo(
          alphabet: const <AlphabetUnit>[
            AlphabetUnit(
              id: 'letter.a',
              glyph: 'A',
              sortOrder: 0,
              quizEnabled: true,
              speechText: 'A',
              example: 'apple',
            ),
            AlphabetUnit(
              id: 'letter.b',
              glyph: 'B',
              sortOrder: 1,
              quizEnabled: true,
              speechText: 'B',
              example: 'book',
            ),
            AlphabetUnit(
              id: 'letter.c',
              glyph: 'C',
              sortOrder: 2,
              quizEnabled: true,
              speechText: 'C',
              example: 'cat',
            ),
          ],
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('alphabet-tile-letter.b')),
      );
      await tester.pump();
      expect(speech.utterances, <String>['B']);

      await tester.tap(
        find.byKey(const ValueKey<String>('alphabet-tile-letter.c')),
      );
      await tester.pump();
      expect(speech.stopCount, greaterThan(0));
      expect(speech.utterances.last, 'C');
      expect(speech.overlapping, isFalse);
      expect(speech.utterances, isNot(contains('apple')));
      expect(speech.utterances, isNot(contains('cat')));
    });

    testWidgets('speaker still replays after auto pronunciation', (
      WidgetTester tester,
    ) async {
      final _RecordingSpeechEngine speech = _RecordingSpeechEngine();
      PronunciationService.instance.dispose();
      PronunciationService.instance = PronunciationService(
        audioEnabled: true,
        player: const SilentPronunciationPlayer(),
        speech: speech,
        probe: const _AbsentSoundAssetProbe(),
        speechLocale: 'en',
        onStarted: () {},
      );
      await _pumpAlphabet(
        tester,
        _repo(
          alphabet: const <AlphabetUnit>[
            AlphabetUnit(
              id: 'letter.a',
              glyph: 'A',
              sortOrder: 0,
              quizEnabled: true,
              speechText: 'A',
              example: 'apple',
            ),
            AlphabetUnit(
              id: 'letter.b',
              glyph: 'B',
              sortOrder: 1,
              quizEnabled: true,
              speechText: 'B',
              example: 'book',
            ),
          ],
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('alphabet-tile-letter.b')),
      );
      await tester.pump();
      expect(speech.utterances, <(String, String)>[('B', 'en-US')]);

      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 80));
      });
      await tester.tap(find.byType(LingoGlyphButton));
      await tester.pump();
      expect(speech.utterances, <(String, String)>[
        ('B', 'en-US'),
        ('B', 'en-US'),
      ]);
      for (final (String spoken, String _) in speech.utterances) {
        expect(spoken, 'B');
        expect(spoken.toLowerCase(), isNot(contains('capital')));
        expect(spoken.toLowerCase(), isNot(contains('uppercase')));
        expect(spoken.toLowerCase(), isNot(contains('lowercase')));
      }
      expect(find.byType(PronunciationControl), findsOneWidget);
    });

    testWidgets('disabled audio capability hides playback', (
      WidgetTester tester,
    ) async {
      PronunciationService.instance = PronunciationService(
        audioEnabled: false,
        player: _RecordingPronunciationPlayer(),
        probe: const AlwaysPresentSoundAssetProbe(),
        onStarted: () {},
      );
      await _pumpAlphabet(
        tester,
        _repo(
          alphabet: const <AlphabetUnit>[
            AlphabetUnit(
              id: 'letter.a',
              glyph: 'A',
              sortOrder: 0,
              quizEnabled: true,
              pronunciation: 'ay',
              audioAsset: 'assets/audio/alphabet/a.wav',
            ),
          ],
        ),
      );

      expect(find.byType(LingoGlyphButton), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('haptics and semantics', () {
    testWidgets('selecting a character uses letter haptics once', (
      WidgetTester tester,
    ) async {
      final _RecordingHapticDriver haptics = _RecordingHapticDriver();
      FeedbackService.instance = FeedbackService(
        haptics: HapticService(driver: haptics),
        soundEnabled: false,
      );
      await _pumpAlphabet(
        tester,
        _repo(
          alphabet: const <AlphabetUnit>[
            AlphabetUnit(
              id: 'letter.a',
              glyph: 'A',
              sortOrder: 0,
              quizEnabled: true,
              pronunciation: 'ay',
            ),
            AlphabetUnit(
              id: 'letter.b',
              glyph: 'B',
              sortOrder: 1,
              quizEnabled: true,
              pronunciation: 'bee',
            ),
          ],
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('alphabet-tile-letter.a')),
      );
      await tester.pump();
      expect(haptics.played, isEmpty);

      await tester.tap(
        find.byKey(const ValueKey<String>('alphabet-tile-letter.b')),
      );
      await tester.pump();
      expect(haptics.played, <HapticLevel>[HapticLevel.selection]);
      final SemanticsData tile = tester
          .getSemantics(
            find.byKey(const ValueKey<String>('alphabet-tile-letter.b')),
          )
          .getSemanticsData();
      expect(tile.label, 'B, bee');
      expect(
        tile.flagsCollection.isButton.toString().toLowerCase(),
        contains('true'),
      );
      expect(
        tile.flagsCollection.isSelected.toString().toLowerCase(),
        contains('true'),
      );
    });
  });

  group('writing-system fixtures', () {
    testWidgets('Latin glyphs can show a case companion', (
      WidgetTester tester,
    ) async {
      await _pumpAlphabet(
        tester,
        _repo(
          alphabet: const <AlphabetUnit>[
            AlphabetUnit(
              id: 'letter.a',
              glyph: 'A',
              sortOrder: 0,
              quizEnabled: false,
              pronunciation: 'ay',
            ),
          ],
        ),
      );

      expect(find.text('A'), findsWidgets);
      expect(find.text('a'), findsOneWidget);
    });

    testWidgets('German ß is taught without an SS companion', (
      WidgetTester tester,
    ) async {
      await _pumpAlphabet(
        tester,
        _repo(
          alphabet: const <AlphabetUnit>[
            AlphabetUnit(
              id: 'letter.eszett',
              glyph: 'ß',
              sortOrder: 0,
              quizEnabled: false,
              pronunciation: 'eszett',
              example: 'Straße',
              speechText: 'ß',
            ),
          ],
        ),
      );

      expect(find.text('ß'), findsWidgets);
      expect(find.text('SS'), findsNothing);
      expect(find.text('ẞ'), findsNothing);
      expect(find.text('Straße'), findsOneWidget);
    });

    testWidgets('German umlauts keep an ä/ö/ü companion', (
      WidgetTester tester,
    ) async {
      await _pumpAlphabet(
        tester,
        _repo(
          alphabet: const <AlphabetUnit>[
            AlphabetUnit(
              id: 'letter.auml',
              glyph: 'Ä',
              sortOrder: 0,
              quizEnabled: false,
              pronunciation: 'a-umlaut',
              example: 'Äpfel',
            ),
          ],
        ),
      );

      expect(find.text('Ä'), findsWidgets);
      expect(find.text('ä'), findsOneWidget);
      expect(find.text('Äpfel'), findsOneWidget);
    });

    testWidgets('uncased scripts do not invent a case companion', (
      WidgetTester tester,
    ) async {
      await _pumpAlphabet(
        tester,
        _repo(
          alphabet: const <AlphabetUnit>[
            AlphabetUnit(
              id: 'hangul.ga',
              glyph: '가',
              sortOrder: 0,
              quizEnabled: false,
              pronunciation: 'ga',
            ),
          ],
          scriptFamily: ScriptFamily.korean,
        ),
      );

      expect(find.text('가'), findsNWidgets(2));
      expect(find.text('A'), findsNothing);
      expect(find.text('a'), findsNothing);
    });

    testWidgets('a larger inventory stays selectable', (
      WidgetTester tester,
    ) async {
      await _pumpAlphabet(
        tester,
        _repo(
          alphabet: <AlphabetUnit>[
            for (int index = 0; index < 48; index++)
              AlphabetUnit(
                id: 'item.$index',
                glyph: 'n$index',
                sortOrder: index,
                quizEnabled: false,
                pronunciation: 'p$index',
              ),
          ],
        ),
        size: const Size(430, 932),
      );

      final Finder last = find.byKey(
        const ValueKey<String>('alphabet-tile-item.47'),
      );
      final ScrollableState scrollable = tester.state<ScrollableState>(
        find.descendant(
          of: find.byKey(const ValueKey<String>('alphabet-scroll')),
          matching: find.byType(Scrollable),
        ),
      );
      scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
      await tester.pump();
      await tester.tap(last);
      await tester.pump();
      expect(find.text('p47'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

LocalContentRepository _repo({
  required List<AlphabetUnit> alphabet,
  ScriptFamily scriptFamily = ScriptFamily.latin,
  ContentTextDirection textDirection = ContentTextDirection.ltr,
  List<String> translationLanguageCodes = const <String>['en'],
  Map<String, Map<String, String>> strings =
      const <String, Map<String, String>>{'en': <String, String>{}},
}) {
  return LocalContentRepository(
    product: ProductConfig.fallback,
    pack: LanguagePack(
      id: 'alphabet-test',
      name: 'Alphabet Test',
      version: '1',
      targetLanguageCode: 'und',
      targetLanguageName: 'Sample',
      scriptFamily: scriptFamily,
      textDirection: textDirection,
      hasAlphabet: true,
      defaultTranslationLanguageCode: translationLanguageCodes.first,
      translationLanguageCodes: translationLanguageCodes,
      assetIndex: const <String, String>{},
    ),
    alphabet: alphabet,
    wordCategories: const <ContentCategory>[],
    phraseCategories: const <ContentCategory>[],
    words: const <WordEntry>[],
    phrases: const <PhraseEntry>[],
    translationBundles: <TranslationBundle>[
      for (final String code in translationLanguageCodes)
        TranslationBundle(
          languageCode: code,
          languageName: code,
          strings: strings[code] ?? const <String, String>{},
        ),
    ],
  );
}

Future<void> _pumpAlphabet(
  WidgetTester tester,
  ContentRepository repo, {
  Size size = const Size(390, 844),
  TextDirection textDirection = TextDirection.ltr,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  tester.view.physicalSize = Size(size.width * 3, size.height * 3);
  tester.view.devicePixelRatio = 3;
  tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: Directionality(
        textDirection: textDirection,
        child: ContentScope(repository: repo, child: const AlphabetScreen()),
      ),
    ),
  );
  await tester.pump();
}

(int, int) _imageSize(Uint8List bytes) {
  if (bytes.length >= 24 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47) {
    final int width =
        (bytes[16] << 24) | (bytes[17] << 16) | (bytes[18] << 8) | bytes[19];
    final int height =
        (bytes[20] << 24) | (bytes[21] << 16) | (bytes[22] << 8) | bytes[23];
    return (width, height);
  }
  if (bytes.length > 4 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
    int offset = 2;
    while (offset + 8 < bytes.length) {
      if (bytes[offset] != 0xFF) {
        offset++;
        continue;
      }
      final int marker = bytes[offset + 1];
      if (marker == 0xD8 || marker == 0x01) {
        offset += 2;
        continue;
      }
      if (marker == 0xD9 || marker == 0xDA) {
        break;
      }
      final int length = (bytes[offset + 2] << 8) | bytes[offset + 3];
      final bool startOfFrame =
          marker == 0xC0 || marker == 0xC1 || marker == 0xC2;
      if (startOfFrame && offset + 8 < bytes.length) {
        final int height = (bytes[offset + 5] << 8) | bytes[offset + 6];
        final int width = (bytes[offset + 7] << 8) | bytes[offset + 8];
        return (width, height);
      }
      if (length < 2) {
        break;
      }
      offset += 2 + length;
    }
  }
  return (0, 0);
}

void _installFakePronunciation() {
  PronunciationService.instance.dispose();
  PronunciationService.instance = PronunciationService(
    audioEnabled: true,
    player: _RecordingPronunciationPlayer(),
    probe: const AlwaysPresentSoundAssetProbe(),
    onStarted: () {},
  );
}

final class _RecordingPronunciationPlayer implements PronunciationPlayer {
  final List<String> paths = <String>[];
  int stopCount = 0;

  @override
  Future<void> play(String assetPath) async {
    paths.add(assetPath);
  }

  @override
  Future<void> stop() async {
    stopCount++;
  }

  @override
  Future<void> warmUp() async {}

  @override
  void dispose() {}
}

final class _AbsentSoundAssetProbe implements SoundAssetProbe {
  const _AbsentSoundAssetProbe();

  @override
  Future<bool> exists(String path) async => false;
}

final class _RecordingSpeechEngine implements SpeechEngine {
  final List<(String, String)> utterances = <(String, String)>[];
  int stopCount = 0;

  @override
  Future<void> speak({
    required String text,
    required String locale,
    TargetSpeechProfile? profile,
  }) async {
    utterances.add((text, locale));
  }

  @override
  Future<void> stop() async {
    stopCount++;
  }

  @override
  Future<void> warmUp() async {}

  @override
  void dispose() {}
}

final class _GateSpeechEngine implements SpeechEngine {
  final List<String> utterances = <String>[];
  int stopCount = 0;
  int _active = 0;
  bool overlapping = false;
  Completer<void>? _hold;

  @override
  Future<void> speak({
    required String text,
    required String locale,
    TargetSpeechProfile? profile,
  }) async {
    _active++;
    if (_active > 1) {
      overlapping = true;
    }
    utterances.add(text);
    if (utterances.length == 1) {
      _hold = Completer<void>();
      await _hold!.future;
    }
    _active--;
  }

  @override
  Future<void> stop() async {
    stopCount++;
    final Completer<void>? hold = _hold;
    _hold = null;
    if (hold != null && !hold.isCompleted) {
      hold.complete();
    }
  }

  @override
  Future<void> warmUp() async {}

  @override
  void dispose() {}
}

final class _RecordingHapticDriver implements HapticDriver {
  final List<HapticLevel> played = <HapticLevel>[];

  @override
  Future<void> play(HapticLevel level) async {
    played.add(level);
  }
}

final class _RecordingSoundPlayer implements SoundPlayer {
  final List<SoundCue> cues = <SoundCue>[];
  final List<String> paths = <String>[];

  @override
  Future<void> play(SoundCue cue, String assetPath) async {
    cues.add(cue);
    paths.add(assetPath);
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> warmUp() async {}

  @override
  void dispose() {}
}
