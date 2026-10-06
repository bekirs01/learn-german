import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_core/core/audio/expected_audio.dart';
import 'package:lingo_core/core/audio/pronunciation_service.dart';
import 'package:lingo_core/core/feedback/sound_service.dart';
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

  test('pubspec registers the three German pronunciation folders', () {
    final String pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec.contains('- assets/audio/de/alphabet/'), isTrue);
    expect(pubspec.contains('- assets/audio/de/words/'), isTrue);
    expect(pubspec.contains('- assets/audio/de/phrases/'), isTrue);
  });

  test('UI sound effects stay separate from German pronunciation files', () {
    for (final String path in SoundAssets.allPaths) {
      expect(path.startsWith('assets/sounds/sfx_'), isTrue, reason: path);
      expect(path.contains('/audio/de/'), isFalse, reason: path);
    }
  });

  test('curriculum, manifest, files, and runtime lookup are 1:1', () {
    expect(inventory.count, 1798);
    expect(inventory.issues.isEmpty, isTrue);
    expect(inventory.locale, 'de-DE');

    final Map<String, Object?> decoded =
        jsonDecode(File('docs/expected_audio_manifest.json').readAsStringSync())
            as Map<String, Object?>;
    expect(decoded['count'], 1798);
    expect(decoded['locale'], 'de-DE');
    expect(decoded['provider'], 'native_tts');
    final List<Object?> rows = decoded['items']! as List<Object?>;
    expect(rows, hasLength(1798));

    final Set<String> paths = <String>{};
    final Set<String> keys = <String>{};
    int generated = 0;
    int failed = 0;
    for (final Object? raw in rows) {
      final Map<String, Object?> row = Map<String, Object?>.from(raw! as Map);
      final String contentId = row['contentId']! as String;
      final String assetPath = row['assetPath']! as String;
      final String audioKey = row['audioKey']! as String;
      expect(audioKey, contentId);
      expect(keys.add(audioKey), isTrue, reason: 'duplicate key $audioKey');
      expect(paths.add(assetPath), isTrue, reason: 'collision $assetPath');
      expect(row['locale'], 'de-DE');
      expect(row['voice'], 'Anna');
      expect(row['speechText'], isNotEmpty);
      if (row['generationStatus'] == 'generated') {
        generated += 1;
      }
      if (row['generationStatus'] == 'failed') {
        failed += 1;
      }
    }
    expect(generated, 1798);
    expect(failed, 0);

    expect(
      inventory.items.map((ExpectedAudioItem item) => item.contentId).toSet(),
      keys,
    );

    for (final ExpectedAudioItem item in inventory.items) {
      expect(repo.pronunciationAssetFor(item.contentId), item.assetPath);
      expect(
        PronunciationClip.fromContent(repo, item.contentId).assetPath,
        item.assetPath,
      );
    }
  });

  test('every German clip is a non-silent 24 kHz mono PCM WAV', () {
    final Set<String> hashes = <String>{};
    int alphabet = 0;
    int words = 0;
    int phrases = 0;
    for (final ExpectedAudioItem item in inventory.items) {
      final File file = File(item.assetPath);
      expect(file.existsSync(), isTrue, reason: item.assetPath);
      expect(file.lengthSync(), greaterThan(1500), reason: item.assetPath);
      final RandomAccessFile handle = file.openSync();
      final Uint8List header;
      try {
        header = Uint8List.fromList(handle.readSync(12288));
      } finally {
        handle.closeSync();
      }
      final _WavInfo info = _WavInfo.parse(header);
      expect(info.riff, isTrue, reason: item.assetPath);
      expect(info.audioFormat, 1, reason: item.assetPath);
      expect(info.channels, 1, reason: item.assetPath);
      expect(info.sampleRate, 24000, reason: item.assetPath);
      expect(info.bitsPerSample, 16, reason: item.assetPath);
      expect(info.durationSeconds, greaterThan(0.12), reason: item.assetPath);
      expect(info.durationSeconds, lessThan(12), reason: item.assetPath);
      expect(info.dataBytes, greaterThan(4000), reason: item.assetPath);
      hashes.add('${info.sampleRate}:${info.dataBytes}:${item.speechText}');
      switch (item.kind) {
        case ExpectedAudioKind.alphabet:
          alphabet += 1;
        case ExpectedAudioKind.words:
          words += 1;
        case ExpectedAudioKind.phrases:
          phrases += 1;
      }
    }
    expect(alphabet, 30);
    expect(words, 1156);
    expect(phrases, 612);
    expect(hashes.length, greaterThan(1700));
  });

  test('quiz and review listening reuse the same German audio keys', () {
    expect(repo.quizItems, hasLength(1798));
    for (final QuizReadyItem item in repo.quizItems) {
      expect(
        item.audioAsset,
        ExpectedAudio.pathForId(item.id, languageCode: 'de'),
        reason: item.id,
      );
      expect(File(item.audioAsset!).existsSync(), isTrue, reason: item.id);
    }
  });

  test('Watch keeps pronunciation IDs but does not bundle lesson audio', () {
    final Directory watch = Directory('ios/LingoWatch');
    expect(watch.existsSync(), isTrue);
    final List<File> watchWavs = watch
        .listSync(recursive: true)
        .whereType<File>()
        .where((File file) => file.path.toLowerCase().endsWith('.wav'))
        .toList();
    expect(watchWavs, isNotEmpty);
    for (final File file in watchWavs) {
      expect(
        file.uri.pathSegments.last.startsWith('sfx_'),
        isTrue,
        reason: file.path,
      );
    }
  });
}

final class _WavInfo {
  const _WavInfo({
    required this.riff,
    required this.audioFormat,
    required this.channels,
    required this.sampleRate,
    required this.bitsPerSample,
    required this.dataBytes,
  });

  final bool riff;
  final int audioFormat;
  final int channels;
  final int sampleRate;
  final int bitsPerSample;
  final int dataBytes;

  double get durationSeconds {
    if (sampleRate <= 0 || channels <= 0 || bitsPerSample <= 0) {
      return 0;
    }
    final int bytesPerSecond = sampleRate * channels * (bitsPerSample ~/ 8);
    if (bytesPerSecond <= 0) {
      return 0;
    }
    return dataBytes / bytesPerSecond;
  }

  static _WavInfo parse(Uint8List bytes) {
    if (bytes.length < 44 || !_eq(bytes, 0, 'RIFF') || !_eq(bytes, 8, 'WAVE')) {
      return const _WavInfo(
        riff: false,
        audioFormat: 0,
        channels: 0,
        sampleRate: 0,
        bitsPerSample: 0,
        dataBytes: 0,
      );
    }
    final ByteData data = ByteData.sublistView(bytes);
    int offset = 12;
    int audioFormat = 0;
    int channels = 0;
    int sampleRate = 0;
    int bitsPerSample = 0;
    int dataBytes = 0;
    while (offset + 8 <= bytes.length) {
      final String id = String.fromCharCodes(bytes.sublist(offset, offset + 4));
      final int size = data.getUint32(offset + 4, Endian.little);
      final int body = offset + 8;
      if (id == 'fmt ' && body + 16 <= bytes.length) {
        audioFormat = data.getUint16(body, Endian.little);
        channels = data.getUint16(body + 2, Endian.little);
        sampleRate = data.getUint32(body + 4, Endian.little);
        bitsPerSample = data.getUint16(body + 14, Endian.little);
      } else if (id == 'data') {
        dataBytes = size;
        break;
      }
      offset = body + size;
      if (offset.isOdd) {
        offset += 1;
      }
    }
    return _WavInfo(
      riff: true,
      audioFormat: audioFormat,
      channels: channels,
      sampleRate: sampleRate,
      bitsPerSample: bitsPerSample,
      dataBytes: dataBytes,
    );
  }

  static bool _eq(Uint8List bytes, int offset, String value) {
    if (offset + value.length > bytes.length) {
      return false;
    }
    return String.fromCharCodes(bytes.sublist(offset, offset + value.length)) ==
        value;
  }
}
