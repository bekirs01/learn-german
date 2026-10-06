import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_core/core/assets/lingo_assets.dart';
import 'package:lingo_core/data/local_content_repository.dart';
import 'package:lingo_core/data/user_preferences.dart';
import 'package:lingo_core/domain/content_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalContentRepository repo;

  setUp(() async {
    LocalContentRepository.clearCache();
    UserPreferences.resetForTest();
    repo = await LocalContentRepository.load();
  });

  tearDown(() {
    LocalContentRepository.clearCache();
    UserPreferences.resetForTest();
  });

  test('language-pack image paths exist on disk', () {
    expect(repo.pack.assetIndex, isNotEmpty);
    final Set<String> seenPaths = <String>{};
    final Set<String> duplicatePaths = <String>{};
    for (final MapEntry<String, String> entry in repo.pack.assetIndex.entries) {
      expect(entry.key, isNotEmpty);
      expect(entry.value, isNotEmpty);
      expect(File(entry.value).existsSync(), isTrue, reason: entry.value);
      if (!seenPaths.add(entry.value)) {
        duplicatePaths.add(entry.value);
      }
    }
    expect(duplicatePaths, isEmpty);
  });

  test('home and paper illustrations exist', () {
    const List<String> paths = <String>[
      LingoAssets.paperCrumpled,
      LingoAssets.homeAlphabet,
      LingoAssets.homeWords,
      LingoAssets.homePhrases,
      LingoAssets.homeQuiz,
      LingoAssets.homeWrongAnswers,
      LingoAssets.homeAppleWatch,
    ];
    for (final String path in paths) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });

  test('every category illustration resolves', () {
    for (final ContentCategory category in <ContentCategory>[
      ...repo.wordCategories,
      ...repo.phraseCategories,
    ]) {
      expect(category.imageAsset, isNotNull, reason: category.id);
      expect(
        File(category.imageAsset!).existsSync(),
        isTrue,
        reason: '${category.id} → ${category.imageAsset}',
      );
    }
  });

  test('alphabet example illustrations resolve when mapped', () {
    for (final AlphabetUnit unit in repo.alphabet) {
      final String? path = unit.imageAsset;
      if (path == null || path.isEmpty) {
        continue;
      }
      expect(File(path).existsSync(), isTrue, reason: '${unit.id} → $path');
    }
  });
}
