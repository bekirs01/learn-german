import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_core/core/audio/expected_audio.dart';
import 'package:lingo_core/core/audio/target_speech_locale.dart';
import 'package:lingo_core/data/local_content_repository.dart';
import 'package:lingo_core/data/user_preferences.dart';
import 'package:lingo_core/domain/content_models.dart';
import 'package:lingo_core/domain/product_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalContentRepository repo;
  late ExpectedAudioInventory inventory;

  setUp(() async {
    LocalContentRepository.clearCache();
    UserPreferences.resetForTest();
    ProductConfig.reset();
    repo = await LocalContentRepository.load();
    inventory = ExpectedAudio.buildFrom(repo);
  });

  tearDown(() {
    LocalContentRepository.clearCache();
    UserPreferences.resetForTest();
    ProductConfig.reset();
  });

  test('product speech is native German de-DE / Anna', () {
    expect(repo.product.targetLanguageCode, 'de');
    expect(repo.product.speechLocale, 'de-DE');
    expect(repo.product.speechProfile.locale, 'de-DE');
    expect(repo.product.speechProfile.preferredVoiceName, 'Anna');
    expect(TargetSpeechLocale.resolve(product: repo.product), 'de-DE');
    expect(inventory.locale, 'de-DE');
    expect(inventory.languageCode, 'de');
  });

  test('every curriculum item has exactly one expected audio mapping', () {
    expect(inventory.isStructurallyValid, isTrue);
    expect(inventory.issues.duplicateAudioKeys, isEmpty);
    expect(inventory.issues.filenameCollisions, isEmpty);
    expect(inventory.issues.invalidCharacters, isEmpty);
    expect(inventory.issues.missingMappings, isEmpty);
    expect(inventory.issues.orphanDeclaredAssets, isEmpty);

    final Set<String> ids = <String>{
      for (final AlphabetUnit unit in repo.alphabet) unit.id,
      for (final ContentCategory category in repo.wordCategories)
        for (final WordEntry word in repo.wordsForCategory(category.id))
          word.id,
      for (final ContentCategory category in repo.phraseCategories)
        for (final PhraseEntry phrase in repo.phrasesForCategory(category.id))
          phrase.id,
    };
    expect(inventory.count, ids.length);
    expect(
      inventory.items.map((ExpectedAudioItem item) => item.contentId).toSet(),
      ids,
    );
  });

  test('filenames stay ASCII and preserve German speech text', () {
    for (final ExpectedAudioItem item in inventory.items) {
      expect(item.filename, isNot(contains(RegExp(r'[^a-zA-Z0-9._-]'))));
      expect(item.assetPath, startsWith('assets/audio/de/'));
      expect(item.assetPath, endsWith('.wav'));
      expect(item.audioKey, item.contentId);
      expect(item.filename, '${item.contentId}.wav');
    }
    expect(ExpectedAudio.filenameFor('letter.auml'), 'letter.auml.wav');
    expect(ExpectedAudio.filenameFor('word.food.apfel'), 'word.food.apfel.wav');
  });

  test('committed manifest matches the live German inventory', () {
    final String raw = File(
      'docs/expected_audio_manifest.json',
    ).readAsStringSync();
    final Map<String, Object?> decoded =
        jsonDecode(raw) as Map<String, Object?>;
    expect(decoded['locale'], 'de-DE');
    expect(decoded['languageCode'], 'de');
    expect(decoded['count'], inventory.count);
    expect(decoded['extension'], 'wav');
    expect(decoded['provider'], 'native_tts');
    final Object? items = decoded['items'];
    expect(items, isA<List<Object?>>());
    final List<Object?> rows = items! as List<Object?>;
    expect(rows, hasLength(inventory.count));
    expect((rows.first as Map)['contentId'], inventory.items.first.contentId);
    expect(
      (rows.map((Object? row) => (row as Map)['contentId']).toSet()),
      inventory.items.map((ExpectedAudioItem item) => item.contentId).toSet(),
    );
  });

  test('physical recordings reconcile with the expected German inventory', () {
    expect(Directory('assets/audio/de').existsSync(), isTrue);
    expect(Directory('assets/audio/en').existsSync(), isFalse);
    expect(Directory('assets/audio/fr').existsSync(), isFalse);
    expect(Directory('assets/audio/es').existsSync(), isFalse);

    final Set<String> expectedPaths = <String>{
      for (final ExpectedAudioItem item in inventory.items) item.assetPath,
    };
    final List<String> present = <String>[];
    final List<String> missing = <String>[];
    final List<String> invalid = <String>[];
    for (final ExpectedAudioItem item in inventory.items) {
      final File file = File(item.assetPath);
      if (!file.existsSync()) {
        missing.add(item.assetPath);
        continue;
      }
      present.add(item.assetPath);
      if (file.lengthSync() <= 0 || !_looksLikeWav(file)) {
        invalid.add(item.assetPath);
      }
    }
    expect(present.length + missing.length, inventory.count);
    expect(missing, isEmpty, reason: '${missing.length} clips missing');
    expect(present, hasLength(inventory.count));
    expect(invalid, isEmpty);

    final List<String> orphans = <String>[];
    final List<String> wrongExtension = <String>[];
    for (final FileSystemEntity entity in Directory(
      'assets/audio',
    ).listSync(recursive: true)) {
      if (entity is! File) {
        continue;
      }
      final String relative = _assetRelativePath(entity.path);
      if (relative.endsWith('.gitkeep')) {
        continue;
      }
      if (!relative.endsWith('.wav')) {
        wrongExtension.add(relative);
        continue;
      }
      if (!expectedPaths.contains(relative)) {
        orphans.add(relative);
      }
    }
    expect(wrongExtension, isEmpty);
    expect(orphans, isEmpty);
    expect(
      repo.pronunciationAssetFor('word.basics.hello'),
      'assets/audio/de/words/word.basics.hello.wav',
    );
  });

  test('quiz listening items reuse the same expected audio keys', () {
    for (final QuizReadyItem item in repo.quizItems) {
      expect(item.audioAsset, isNotNull);
      expect(
        item.audioAsset,
        ExpectedAudio.pathForId(item.id, languageCode: 'de'),
      );
    }
  });
}

String _assetRelativePath(String path) {
  final String normalized = path.replaceAll('\\', '/');
  final int index = normalized.indexOf('assets/audio/');
  if (index < 0) {
    return normalized;
  }
  return normalized.substring(index);
}

bool _looksLikeWav(File file) {
  final RandomAccessFile handle = file.openSync();
  try {
    final List<int> header = handle.readSync(4);
    return header.length == 4 &&
        header[0] == 0x52 &&
        header[1] == 0x49 &&
        header[2] == 0x46 &&
        header[3] == 0x46;
  } finally {
    handle.closeSync();
  }
}
