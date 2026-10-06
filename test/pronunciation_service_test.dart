import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_core/core/audio/pronunciation_service.dart';
import 'package:lingo_core/core/feedback/feedback_service.dart';
import 'package:lingo_core/core/theme/app_theme.dart';
import 'package:lingo_core/core/widgets/lingo_controls.dart';
import 'package:lingo_core/core/widgets/pronunciation_control.dart';
import 'package:lingo_core/data/product_config_json.dart';
import 'package:lingo_core/data/user_preferences.dart';
import 'package:lingo_core/domain/content_models.dart';
import 'package:lingo_core/domain/product_config.dart';

void main() {
  tearDown(() {
    PronunciationService.resetInstance();
    FeedbackService.resetInstance();
    UserPreferences.resetForTest();
    ProductConfig.reset();
  });

  const PronunciationClip letter = PronunciationClip(
    id: 'letter.a',
    assetPath: 'assets/audio/alphabet/a.wav',
    speechText: 'ay',
  );
  const PronunciationClip word = PronunciationClip(
    id: 'word.apple',
    assetPath: 'assets/audio/words/apple.wav',
    speechText: 'apple',
  );
  const PronunciationClip phrase = PronunciationClip(
    id: 'phrase.good_morning',
    assetPath: 'assets/audio/phrases/good_morning.wav',
    speechText: 'Good morning.',
  );

  group('PronunciationClip', () {
    test('reads audio from existing content models', () {
      const AlphabetUnit unit = AlphabetUnit(
        id: 'letter.ka',
        glyph: 'か',
        sortOrder: 0,
        quizEnabled: true,
        audioAsset: 'assets/audio/alphabet/ka.wav',
      );
      const WordEntry entry = WordEntry(
        id: 'word.agua',
        categoryId: 'word_category.basics',
        text: 'agua',
        sortOrder: 0,
        quizEnabled: true,
        audioAsset: 'assets/audio/words/agua.wav',
      );
      const PhraseEntry spoken = PhraseEntry(
        id: 'phrase.sabah_hayir',
        categoryId: 'phrase_category.greetings',
        text: 'Günaydın',
        sortOrder: 0,
        quizEnabled: true,
        audioAsset: 'assets/audio/phrases/sabah.wav',
      );
      const QuizReadyItem quizItem = QuizReadyItem(
        id: 'word.apple',
        kind: QuizContentKind.word,
        prompt: 'apple',
        answersByLanguage: <String, String>{'en': 'apple'},
        audioAsset: 'assets/audio/words/apple.wav',
      );

      expect(PronunciationClip.fromAlphabet(unit).assetPath, unit.audioAsset);
      expect(PronunciationClip.fromWord(entry).assetPath, entry.audioAsset);
      expect(PronunciationClip.fromPhrase(spoken).assetPath, spoken.audioAsset);
      expect(
        PronunciationClip.fromQuizItem(quizItem).assetPath,
        quizItem.audioAsset,
      );
    });

    test('fills the German expected path when no audioAsset is declared', () {
      const AlphabetUnit unit = AlphabetUnit(
        id: 'letter.a',
        glyph: 'A',
        sortOrder: 0,
        quizEnabled: true,
      );
      const WordEntry word = WordEntry(
        id: 'word.food.apfel',
        categoryId: 'word_category.food',
        text: 'Apfel',
        sortOrder: 0,
        quizEnabled: true,
      );
      const PhraseEntry phrase = PhraseEntry(
        id: 'phrase.greetings.guten_tag',
        categoryId: 'phrase_category.greetings',
        text: 'Guten Tag.',
        sortOrder: 0,
        quizEnabled: true,
      );

      expect(
        PronunciationClip.fromAlphabet(unit).assetPath,
        'assets/audio/de/alphabet/letter.a.wav',
      );
      expect(
        PronunciationClip.fromWord(word).assetPath,
        'assets/audio/de/words/word.food.apfel.wav',
      );
      expect(
        PronunciationClip.fromPhrase(phrase).assetPath,
        'assets/audio/de/phrases/phrase.greetings.guten_tag.wav',
      );
    });

    test('alphabet speaks configured speech text, never the example word', () {
      const AlphabetUnit named = AlphabetUnit(
        id: 'letter.a',
        glyph: 'A',
        sortOrder: 0,
        quizEnabled: true,
        pronunciation: 'ay',
        speechText: 'A',
        example: 'apple',
      );
      const AlphabetUnit fallback = AlphabetUnit(
        id: 'letter.b',
        glyph: 'B',
        sortOrder: 1,
        quizEnabled: true,
        pronunciation: 'bee',
        example: 'book',
      );
      const AlphabetUnit ipaOnly = AlphabetUnit(
        id: 'letter.c',
        glyph: 'C',
        sortOrder: 2,
        quizEnabled: true,
        pronunciation: '/siː/',
        example: 'cat',
      );

      expect(PronunciationClip.fromAlphabet(named).speechText, 'A');
      expect(PronunciationClip.fromAlphabet(fallback).speechText, 'B');
      expect(PronunciationClip.fromAlphabet(ipaOnly).speechText, 'C');
      expect(PronunciationSpeechText.ofAlphabet(named), isNot('ay'));
      expect(PronunciationSpeechText.ofAlphabet(named), isNot('apple'));
      expect(PronunciationSpeechText.ofAlphabet(fallback), isNot('bee'));
      expect(
        SpeechTextNormalizer.utterance(
          PronunciationClip.fromAlphabet(named).speechText!,
        ),
        'a',
      );
      expect(
        SpeechTextNormalizer.utterance(
          PronunciationClip.fromAlphabet(named).speechText!,
        ).toLowerCase(),
        isNot(contains('capital')),
      );
    });

    test('word speaks target text, not the learner translation or IPA', () {
      const WordEntry entry = WordEntry(
        id: 'word.family.mother',
        categoryId: 'word_category.family',
        text: 'Mother',
        pronunciation: '/ˈmʌðər/',
        sortOrder: 0,
        quizEnabled: true,
      );
      expect(PronunciationClip.fromWord(entry).speechText, 'Mother');
      expect(PronunciationClip.fromWord(entry).speechText, isNot('/ˈmʌðər/'));
    });

    test('phrase speaks the complete target phrase, not IPA', () {
      const PhraseEntry entry = PhraseEntry(
        id: 'phrase.greetings.hello',
        categoryId: 'phrase_category.greetings',
        text: 'Hello.',
        pronunciation: '/həˈloʊ/',
        sortOrder: 0,
        quizEnabled: true,
      );
      expect(PronunciationClip.fromPhrase(entry).speechText, 'Hello.');
      expect(PronunciationClip.fromPhrase(entry).speechText, isNot('/həˈloʊ/'));
    });

    test('favorites reuse the same word and phrase clip factories', () {
      const WordEntry favoriteWord = WordEntry(
        id: 'word.family.mother',
        categoryId: 'word_category.family',
        text: 'Mother',
        sortOrder: 0,
        quizEnabled: true,
      );
      const PhraseEntry favoritePhrase = PhraseEntry(
        id: 'phrase.greetings.hello',
        categoryId: 'phrase_category.greetings',
        text: 'How are you?',
        sortOrder: 0,
        quizEnabled: true,
      );
      expect(
        PronunciationClip.fromWord(favoriteWord).speechText,
        favoriteWord.text,
      );
      expect(
        PronunciationClip.fromPhrase(favoritePhrase).speechText,
        favoritePhrase.text,
      );
    });
  });

  group('SpeechTextNormalizer', () {
    test('strips case metadata and keeps the letter name', () {
      expect(SpeechTextNormalizer.clean('A'), 'A');
      expect(SpeechTextNormalizer.clean('a'), 'A');
      expect(SpeechTextNormalizer.clean('uppercase A'), 'A');
      expect(SpeechTextNormalizer.clean('lowercase a'), 'A');
      expect(SpeechTextNormalizer.clean('capital letter B'), 'B');
      expect(SpeechTextNormalizer.clean('letter C'), 'C');
      expect(SpeechTextNormalizer.clean('A (uppercase)'), 'A');
      expect(SpeechTextNormalizer.clean('uppercase'), isNull);
      expect(SpeechTextNormalizer.clean('lowercase'), isNull);
    });

    test('does not speak punctuation names or IPA labels', () {
      expect(SpeechTextNormalizer.clean('.'), isNull);
      expect(SpeechTextNormalizer.clean('?'), isNull);
      expect(SpeechTextNormalizer.clean('punctuation'), isNull);
      expect(SpeechTextNormalizer.clean('ipa'), isNull);
      expect(SpeechTextNormalizer.clean('/ˈmʌðər/'), isNull);
      expect(SpeechTextNormalizer.clean('/eɪ/'), isNull);
      expect(SpeechTextNormalizer.clean('period'), 'period');
    });

    test('keeps natural words and phrase punctuation', () {
      expect(SpeechTextNormalizer.clean('Mother'), 'Mother');
      expect(SpeechTextNormalizer.clean('How are you?'), 'How are you?');
      expect(SpeechTextNormalizer.clean('Hello.'), 'Hello.');
      expect(SpeechTextNormalizer.clean('Letter to Santa'), 'Letter to Santa');
      expect(SpeechTextNormalizer.clean('  Good morning.  '), 'Good morning.');
    });

    test('engine utterance never contains case labels', () {
      expect(SpeechTextNormalizer.utterance('A'), 'a');
      expect(SpeechTextNormalizer.utterance('B'), 'b');
      expect(SpeechTextNormalizer.utterance('Z'), 'z');
      expect(SpeechTextNormalizer.utterance('A'), isNot(contains('capital')));
      expect(SpeechTextNormalizer.utterance('A'), isNot(contains('uppercase')));
      expect(SpeechTextNormalizer.utterance('A'), isNot(contains('lowercase')));
      expect(SpeechTextNormalizer.utterance('Mother'), 'Mother');
      expect(SpeechTextNormalizer.utterance('How are you?'), 'How are you?');
    });

    test('treats German letters and ß as isolated glyphs', () {
      expect(SpeechTextNormalizer.clean('Ä'), 'Ä');
      expect(SpeechTextNormalizer.clean('ä'), 'Ä');
      expect(SpeechTextNormalizer.clean('Ö'), 'Ö');
      expect(SpeechTextNormalizer.clean('Ü'), 'Ü');
      expect(SpeechTextNormalizer.clean('ß'), 'ß');
      expect(SpeechTextNormalizer.clean('ẞ'), 'ß');
      expect(SpeechTextNormalizer.utterance('Ä'), 'ä');
      expect(SpeechTextNormalizer.utterance('Ö'), 'ö');
      expect(SpeechTextNormalizer.utterance('Ü'), 'ü');
      expect(SpeechTextNormalizer.utterance('ß'), 'ß');
      expect(SpeechTextNormalizer.utterance('ẞ'), 'ß');
      expect(SpeechTextNormalizer.utterance('Ä'), isNot(contains('capital')));
      expect(SpeechTextNormalizer.clean('Straße'), 'Straße');
      expect(SpeechTextNormalizer.utterance('Straße'), 'Straße');
    });
  });

  group('TargetSpeechLocale', () {
    test('resolves speech from the target product, not learner language', () {
      final ProductConfig english = ProductConfig.fallback.copyWith(
        targetLanguageCode: 'en',
      );
      expect(
        TargetSpeechLocale.resolve(product: english, learnerLanguageCode: 'tr'),
        'en-US',
      );
      expect(
        TargetSpeechLocale.resolve(product: english, learnerLanguageCode: 'ar'),
        'en-US',
      );
      expect(
        TargetSpeechLocale.resolve(product: english, learnerLanguageCode: 'es'),
        'en-US',
      );
    });

    test('cloned products pick their own target locale', () {
      expect(
        TargetSpeechLocale.resolve(
          product: ProductConfig.fallback.copyWith(targetLanguageCode: 'es'),
        ),
        'es-ES',
      );
      expect(
        TargetSpeechLocale.resolve(
          product: ProductConfig.fallback.copyWith(targetLanguageCode: 'ja'),
        ),
        'ja-JP',
      );
      expect(
        TargetSpeechLocale.resolve(
          product: ProductConfig.fallback.copyWith(targetLanguageCode: 'ko'),
        ),
        'ko-KR',
      );
      expect(
        TargetSpeechLocale.resolve(
          product: ProductConfig.fallback.copyWith(targetLanguageCode: 'ar'),
        ),
        'ar-SA',
      );
      expect(
        TargetSpeechLocale.resolve(
          product: ProductConfig.fallback.copyWith(targetLanguageCode: 'ru'),
        ),
        'ru-RU',
      );
      expect(
        TargetSpeechLocale.resolve(
          product: ProductConfig.fallback.copyWith(targetLanguageCode: 'de'),
        ),
        'de-DE',
      );
      expect(
        TargetSpeechLocale.resolve(
          product: ProductConfig.fallback.copyWith(speechLocale: 'de-DE'),
        ),
        'de-DE',
      );
    });

    test('optional speechLocale overrides an undetermined target code', () {
      final ProductConfig sample = ProductConfig.fallback.copyWith(
        speechLocale: 'en',
      );
      expect(TargetSpeechLocale.resolve(product: sample), 'en-US');
      expect(
        TargetSpeechLocale.resolve(product: sample, learnerLanguageCode: 'tr'),
        'en-US',
      );
    });

    test('parses speechLocale from product JSON', () {
      final ProductConfig product = parseProductConfig(
        jsonDecode('''
{
  "id": "learn_english",
  "displayName": "Parser Fixture EN",
  "targetLanguageName": "English",
  "targetLanguageCode": "en",
  "nativeLanguageName": "English",
  "textDirection": "ltr",
  "writingSystem": "alphabet",
  "primaryAccentColor": "#C46A3C",
  "contentPackPath": "assets/content",
  "defaultTranslationLanguage": "tr",
  "supportedTranslationLanguages": ["tr", "en"],
  "speechLocale": "en",
  "featureFlags": {"alphabet": true, "audio": true}
}
'''),
      );
      expect(product.speechLocale, 'en');
      expect(product.targetLanguageCode, 'en');
      expect(TargetSpeechLocale.resolve(product: product), 'en-US');
      expect(
        TargetSpeechLocale.resolve(product: product, learnerLanguageCode: 'tr'),
        'en-US',
      );
    });

    test('parses per-product voice preferences from speech config', () {
      final ProductConfig product = parseProductConfig(
        jsonDecode('''
{
  "id": "learn_spanish",
  "displayName": "Parser Fixture ES",
  "targetLanguageName": "Spanish",
  "targetLanguageCode": "es",
  "nativeLanguageName": "Spanish",
  "textDirection": "ltr",
  "writingSystem": "alphabet",
  "primaryAccentColor": "#C46A3C",
  "contentPackPath": "assets/content",
  "defaultTranslationLanguage": "en",
  "supportedTranslationLanguages": ["en", "tr"],
  "speechLocale": "es",
  "speech": {
    "locale": "es-MX",
    "preferredVoiceName": "Paulina",
    "preferredVoiceIdentifier": "com.apple.voice.compact.es-MX.Paulina",
    "preferredVoiceNames": ["Paulina", "Monica"],
    "preferredGender": "female",
    "rate": 0.46,
    "pitch": 1.0
  },
  "featureFlags": {"alphabet": true, "audio": true}
}
'''),
      );
      expect(product.speechLocale, 'es');
      expect(product.speechProfile.locale, 'es-MX');
      expect(product.speechProfile.preferredVoiceName, 'Paulina');
      expect(
        product.speechProfile.preferredVoiceIdentifier,
        'com.apple.voice.compact.es-MX.Paulina',
      );
      expect(product.speechProfile.preferredVoiceNames, <String>[
        'Paulina',
        'Monica',
      ]);
      expect(
        product.speechProfile.preferredGender,
        PreferredSpeechGender.female,
      );
      expect(product.speechProfile.rate, closeTo(0.46, 0.001));
      expect(product.speechProfile.pitch, 1.0);
      expect(
        TargetSpeechLocale.resolve(product: product, learnerLanguageCode: 'tr'),
        'es-MX',
      );
    });
  });

  group('SpeechVoicePicker', () {
    test('prefers an enhanced voice and stays deterministic', () {
      final Map<String, String>? first = SpeechVoicePicker.select(
        locale: 'en-US',
        voices: const <Object?>[
          <String, String>{
            'name': 'Samantha',
            'locale': 'en-US',
            'quality': 'Default',
          },
          <String, String>{
            'name': 'Samantha (Enhanced)',
            'locale': 'en-US',
            'quality': 'Enhanced',
          },
          <String, String>{
            'name': 'Zarvox',
            'locale': 'en-US',
            'quality': 'Novelty',
          },
          <String, String>{
            'name': 'Monica',
            'locale': 'es-ES',
            'quality': 'Enhanced',
          },
        ],
      );
      final Map<String, String>? second = SpeechVoicePicker.select(
        locale: 'en-US',
        voices: const <Object?>[
          <String, String>{
            'name': 'Zarvox',
            'locale': 'en-US',
            'quality': 'Novelty',
          },
          <String, String>{
            'name': 'Samantha (Enhanced)',
            'locale': 'en-US',
            'quality': 'Enhanced',
          },
          <String, String>{
            'name': 'Samantha',
            'locale': 'en-US',
            'quality': 'Default',
          },
        ],
      );
      expect(first?['name'], 'Samantha (Enhanced)');
      expect(second?['name'], 'Samantha (Enhanced)');
    });

    test('current English master prefers Nicky over other en-US voices', () {
      const TargetSpeechProfile english = TargetSpeechProfile(
        preferredVoiceName: 'Nicky',
        preferredVoiceNames: <String>['Samantha (Enhanced)', 'Samantha', 'Ava'],
        preferredGender: PreferredSpeechGender.female,
      );
      final Map<String, String>? selected = SpeechVoicePicker.select(
        locale: 'en-US',
        profile: english,
        voices: const <Object?>[
          <String, String>{
            'name': 'Alex',
            'locale': 'en-US',
            'quality': 'Enhanced',
            'gender': 'male',
          },
          <String, String>{
            'name': 'Samantha',
            'locale': 'en-US',
            'quality': 'Default',
            'gender': 'female',
          },
          <String, String>{
            'name': 'Nicky',
            'locale': 'en-US',
            'quality': 'Premium',
            'gender': 'female',
          },
          <String, String>{
            'name': 'Samantha (Enhanced)',
            'locale': 'en-US',
            'quality': 'Enhanced',
            'gender': 'female',
          },
        ],
      );
      expect(selected?['name'], 'Nicky');
    });

    test('German product prefers Anna over other de-DE voices', () {
      const TargetSpeechProfile german = TargetSpeechProfile(
        preferredVoiceName: 'Anna',
        preferredVoiceNames: <String>[
          'Anna (Premium)',
          'Anna (Enhanced)',
          'Helena (Enhanced)',
          'Helena',
          'Petra',
        ],
        preferredGender: PreferredSpeechGender.female,
      );
      final Map<String, String>? selected = SpeechVoicePicker.select(
        locale: 'de-DE',
        profile: german,
        voices: const <Object?>[
          <String, String>{
            'name': 'Martin',
            'locale': 'de-DE',
            'quality': 'Enhanced',
            'gender': 'male',
          },
          <String, String>{
            'name': 'Helena',
            'locale': 'de-DE',
            'quality': 'Default',
            'gender': 'female',
          },
          <String, String>{
            'name': 'Anna',
            'locale': 'de-DE',
            'quality': 'Premium',
            'gender': 'female',
          },
          <String, String>{
            'name': 'Anna (Enhanced)',
            'locale': 'de-DE',
            'quality': 'Enhanced',
            'gender': 'female',
          },
        ],
      );
      expect(selected?['name'], 'Anna');
      expect(selected?['locale'], 'de-DE');
    });

    test('never selects an English voice for de-DE', () {
      final Map<String, String>? selected = SpeechVoicePicker.select(
        locale: 'de-DE',
        profile: const TargetSpeechProfile(
          preferredVoiceName: 'Anna',
          preferredGender: PreferredSpeechGender.female,
        ),
        voices: const <Object?>[
          <String, String>{
            'name': 'Nicky',
            'locale': 'en-US',
            'quality': 'Premium',
            'gender': 'female',
          },
          <String, String>{
            'name': 'Samantha (Enhanced)',
            'locale': 'en-US',
            'quality': 'Enhanced',
            'gender': 'female',
          },
        ],
      );
      expect(selected, isNull);
    });

    test('prefers the configured high-quality en-US female voice', () {
      const TargetSpeechProfile english = TargetSpeechProfile(
        preferredVoiceName: 'Samantha',
        preferredVoiceNames: <String>[
          'Nicky',
          'Samantha (Enhanced)',
          'Samantha',
        ],
        preferredGender: PreferredSpeechGender.female,
      );
      final Map<String, String>? selected = SpeechVoicePicker.select(
        locale: 'en-US',
        profile: english,
        voices: const <Object?>[
          <String, String>{
            'name': 'Alex',
            'locale': 'en-US',
            'quality': 'Enhanced',
            'gender': 'male',
          },
          <String, String>{
            'name': 'Fred',
            'locale': 'en-US',
            'quality': 'Default',
            'gender': 'male',
          },
          <String, String>{
            'name': 'Samantha (Enhanced)',
            'locale': 'en-US',
            'quality': 'Enhanced',
            'gender': 'female',
          },
          <String, String>{
            'name': 'Samantha',
            'locale': 'en-US',
            'quality': 'Default',
            'gender': 'female',
          },
        ],
      );
      expect(selected?['name'], 'Samantha (Enhanced)');
    });

    test('falls back to another en-US female when Samantha is missing', () {
      const TargetSpeechProfile english = TargetSpeechProfile(
        preferredVoiceName: 'Samantha',
        preferredVoiceNames: <String>['Nicky', 'Samantha', 'Ava'],
        preferredGender: PreferredSpeechGender.female,
      );
      final Map<String, String>? selected = SpeechVoicePicker.select(
        locale: 'en-US',
        profile: english,
        voices: const <Object?>[
          <String, String>{
            'name': 'Alex',
            'locale': 'en-US',
            'quality': 'Premium',
            'gender': 'male',
          },
          <String, String>{
            'name': 'Ava',
            'locale': 'en-US',
            'quality': 'Default',
            'gender': 'female',
          },
          <String, String>{
            'name': 'Daniel',
            'locale': 'en-US',
            'quality': 'Enhanced',
            'gender': 'male',
          },
        ],
      );
      expect(selected?['name'], 'Ava');
    });

    test('falls back to the best en-US voice when no female is installed', () {
      const TargetSpeechProfile english = TargetSpeechProfile(
        preferredVoiceName: 'Samantha',
        preferredGender: PreferredSpeechGender.female,
      );
      final Map<String, String>? selected = SpeechVoicePicker.select(
        locale: 'en-US',
        profile: english,
        voices: const <Object?>[
          <String, String>{
            'name': 'Fred',
            'locale': 'en-US',
            'quality': 'Default',
            'gender': 'male',
          },
          <String, String>{
            'name': 'Alex',
            'locale': 'en-US',
            'quality': 'Enhanced',
            'gender': 'male',
          },
        ],
      );
      expect(selected?['name'], 'Alex');
    });

    test('keeps the same voice when the installed list is shuffled', () {
      const TargetSpeechProfile english = TargetSpeechProfile(
        preferredVoiceName: 'Samantha',
        preferredGender: PreferredSpeechGender.female,
      );
      const List<Object?> catalog = <Object?>[
        <String, String>{
          'name': 'Alex',
          'locale': 'en-US',
          'quality': 'Enhanced',
          'gender': 'male',
        },
        <String, String>{
          'name': 'Nicky',
          'locale': 'en-US',
          'quality': 'Premium',
          'gender': 'female',
        },
        <String, String>{
          'name': 'Samantha',
          'locale': 'en-US',
          'quality': 'Default',
          'gender': 'female',
        },
      ];
      final Map<String, String>? first = SpeechVoicePicker.select(
        locale: 'en-US',
        profile: english,
        voices: catalog,
      );
      final Map<String, String>? second = SpeechVoicePicker.select(
        locale: 'en-US',
        profile: english,
        voices: catalog.reversed,
      );
      expect(first?['name'], 'Samantha');
      expect(second?['name'], first?['name']);
    });

    test('does not take the first returned voice', () {
      final Map<String, String>? selected = SpeechVoicePicker.select(
        locale: 'en-US',
        profile: const TargetSpeechProfile(
          preferredGender: PreferredSpeechGender.female,
        ),
        voices: const <Object?>[
          <String, String>{
            'name': 'Alex',
            'locale': 'en-US',
            'quality': 'Default',
            'gender': 'male',
          },
          <String, String>{
            'name': 'Samantha',
            'locale': 'en-US',
            'quality': 'Default',
            'gender': 'female',
          },
        ],
      );
      expect(selected?['name'], 'Samantha');
    });

    test('uses slightly deliberate neutral speech defaults', () {
      const TargetSpeechProfile profile = TargetSpeechProfile();
      expect(profile.resolvedRate, closeTo(0.47, 0.001));
      expect(profile.resolvedPitch, 1.0);
      expect(profile.resolvedRate, lessThan(0.5));
      expect(profile.resolvedRate, greaterThan(0.4));
    });

    test('returns null when no matching voice is installed', () {
      expect(
        SpeechVoicePicker.select(
          locale: 'ja-JP',
          voices: const <Object?>[
            <String, String>{'name': 'Samantha', 'locale': 'en-US'},
          ],
        ),
        isNull,
      );
    });

    test('prefers an on-device female voice over a network voice', () {
      final Map<String, String>? selected = SpeechVoicePicker.select(
        locale: 'en-US',
        profile: const TargetSpeechProfile(
          preferredGender: PreferredSpeechGender.female,
        ),
        voices: const <Object?>[
          <String, String>{
            'name': 'en-us-x-sfg-network',
            'locale': 'en-US',
            'quality': '400',
          },
          <String, String>{
            'name': 'en-us-x-sfg-local',
            'locale': 'en-US',
            'quality': '400',
          },
        ],
      );
      expect(selected?['name'], 'en-us-x-sfg-local');
    });

    test('prefers enhanced quality over a compact preferred name', () {
      const TargetSpeechProfile english = TargetSpeechProfile(
        preferredVoiceName: 'Nicky',
        preferredVoiceNames: <String>['Samantha (Enhanced)', 'Samantha'],
        preferredGender: PreferredSpeechGender.female,
      );
      final Map<String, String>? selected = SpeechVoicePicker.select(
        locale: 'en-US',
        profile: english,
        voices: const <Object?>[
          <String, String>{
            'name': 'Nicky',
            'locale': 'en-US',
            'quality': 'Default',
            'identifier': 'com.apple.voice.compact.en-US.Nicky',
          },
          <String, String>{
            'name': 'Samantha (Enhanced)',
            'locale': 'en-US',
            'quality': 'Enhanced',
            'gender': 'female',
          },
        ],
      );
      expect(selected?['name'], 'Samantha (Enhanced)');
    });

    test('keeps en-US when another English region is installed', () {
      final Map<String, String>? selected = SpeechVoicePicker.select(
        locale: 'en-US',
        profile: const TargetSpeechProfile(
          preferredGender: PreferredSpeechGender.female,
        ),
        voices: const <Object?>[
          <String, String>{
            'name': 'Kate',
            'locale': 'en-GB',
            'quality': 'Enhanced',
            'gender': 'female',
          },
          <String, String>{
            'name': 'Ava',
            'locale': 'en-US',
            'quality': 'Default',
            'gender': 'female',
          },
        ],
      );
      expect(selected?['name'], 'Ava');
    });
  });

  group('PronunciationService', () {
    test('plays a valid bundled pronunciation asset', () async {
      final _RecordingPronunciationPlayer player =
          _RecordingPronunciationPlayer();
      final _RecordingSpeechEngine speech = _RecordingSpeechEngine();
      final PronunciationService service = PronunciationService(
        audioEnabled: true,
        player: player,
        speech: speech,
        probe: const AlwaysPresentSoundAssetProbe(),
        onStarted: () {},
      );

      await service.playClip(letter);
      await service.playClip(word);
      await service.playClip(phrase);

      expect(player.paths, <String>[
        'assets/audio/alphabet/a.wav',
        'assets/audio/words/apple.wav',
        'assets/audio/phrases/good_morning.wav',
      ]);
      expect(speech.utterances, isEmpty);
      expect(service.phase, PronunciationPhase.idle);
      service.dispose();
    });

    test('falls back to target-language TTS when audio is absent', () async {
      final _RecordingPronunciationPlayer player =
          _RecordingPronunciationPlayer();
      final _RecordingSpeechEngine speech = _RecordingSpeechEngine();
      ProductConfig.bind(
        ProductConfig.fallback.copyWith(targetLanguageCode: 'en'),
      );
      final PronunciationService service = PronunciationService(
        audioEnabled: true,
        player: player,
        speech: speech,
        probe: const _MissingSoundAssetProbe(),
        onStarted: () {},
      );

      await service.playClip(word);
      expect(player.paths, isEmpty);
      expect(speech.utterances, <(String, String)>[('apple', 'en-US')]);
      expect(
        await service.availabilityFor(word),
        PronunciationAvailability.ready,
      );
      service.dispose();
    });

    test('skips clips that have neither a file nor speech text', () async {
      final _RecordingPronunciationPlayer player =
          _RecordingPronunciationPlayer();
      final _RecordingSpeechEngine speech = _RecordingSpeechEngine();
      final PronunciationService service = PronunciationService(
        audioEnabled: true,
        player: player,
        speech: speech,
        probe: const _MissingSoundAssetProbe(),
        onStarted: () {},
      );
      const PronunciationClip empty = PronunciationClip(
        id: 'letter.z',
        assetPath: 'assets/audio/alphabet/missing.wav',
      );

      await service.playClip(empty);
      expect(player.paths, isEmpty);
      expect(speech.utterances, isEmpty);
      expect(
        await service.availabilityFor(empty),
        PronunciationAvailability.missing,
      );
      service.dispose();
    });

    test('does not play when product audio is disabled', () async {
      final _RecordingPronunciationPlayer player =
          _RecordingPronunciationPlayer();
      final PronunciationService service = PronunciationService(
        audioEnabled: false,
        player: player,
        probe: const AlwaysPresentSoundAssetProbe(),
        onStarted: () {},
      );

      expect(service.isOffered(letter), isFalse);
      expect(
        await service.availabilityFor(letter),
        PronunciationAvailability.disabled,
      );
      await service.playClip(letter);
      expect(player.paths, isEmpty);
      service.dispose();
    });

    test('follows ProductConfig audio capability by default', () async {
      ProductConfig.bind(
        ProductConfig.fallback.copyWith(
          featureFlags: const ProductFeatureFlags(audio: true),
        ),
      );
      final _RecordingPronunciationPlayer player =
          _RecordingPronunciationPlayer();
      final PronunciationService service = PronunciationService(
        player: player,
        probe: const AlwaysPresentSoundAssetProbe(),
        onStarted: () {},
      );

      expect(service.audioEnabled, isTrue);
      await service.playClip(word);
      expect(player.paths, <String>['assets/audio/words/apple.wav']);
      service.dispose();
    });

    test('playback requests never throw', () async {
      final PronunciationService service = PronunciationService(
        audioEnabled: true,
        player: const _ThrowingPronunciationPlayer(),
        speech: const _ThrowingSpeechEngine(),
        probe: const AlwaysPresentSoundAssetProbe(),
        onStarted: () {},
      );

      await service.playClip(letter);
      await service.playClip(
        const PronunciationClip(id: 'word.hi', speechText: 'hi'),
      );
      await service.stop();
      await service.warmUp();
      service.dispose();
      await service.playClip(letter);
    });

    test('unsupported voices fail closed', () async {
      final PronunciationService service = PronunciationService(
        audioEnabled: true,
        player: const SilentPronunciationPlayer(),
        speech: const _ThrowingSpeechEngine(),
        probe: const _MissingSoundAssetProbe(),
        speechLocale: 'xx-XX',
        onStarted: () {},
      );

      await service.playClip(
        const PronunciationClip(id: 'word.hi', speechText: 'hello'),
      );
      expect(service.phase, PronunciationPhase.idle);
      service.dispose();
    });

    test('coalesces rapid repeated taps on the same clip', () async {
      final _RecordingPronunciationPlayer player =
          _RecordingPronunciationPlayer();
      final PronunciationService service = PronunciationService(
        audioEnabled: true,
        player: player,
        probe: const AlwaysPresentSoundAssetProbe(),
        onStarted: () {},
      );

      await Future.wait(<Future<void>>[
        service.playClip(letter),
        service.playClip(letter),
        service.playClip(letter),
      ]);

      expect(player.paths, <String>['assets/audio/alphabet/a.wav']);
      service.dispose();
    });

    test('a new tap stops the previous voice before replacing it', () async {
      final _GatePronunciationPlayer player = _GatePronunciationPlayer();
      final PronunciationService service = PronunciationService(
        audioEnabled: true,
        player: player,
        speech: const SilentSpeechEngine(),
        probe: const AlwaysPresentSoundAssetProbe(),
        onStarted: () {},
      );

      final Future<void> first = service.playClip(letter);
      for (int i = 0; i < 20 && player.paths.isEmpty; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(player.paths, <String>['assets/audio/alphabet/a.wav']);
      await service.playClip(word);
      await first;
      expect(player.stopCount, greaterThan(0));
      expect(player.paths.last, 'assets/audio/words/apple.wav');
      expect(player.overlapping, isFalse);
      service.dispose();
    });

    test('sound effects stay independent from pronunciation', () async {
      final _RecordingHapticDriver haptics = _RecordingHapticDriver();
      final _RecordingSoundPlayer sounds = _RecordingSoundPlayer();
      FeedbackService.instance = FeedbackService(
        haptics: HapticService(driver: haptics),
        sound: SoundService(
          enabled: false,
          player: sounds,
          probe: const AlwaysPresentSoundAssetProbe(),
        ),
      );
      final _RecordingPronunciationPlayer player =
          _RecordingPronunciationPlayer();
      final _RecordingSpeechEngine speech = _RecordingSpeechEngine();
      final PronunciationService service = PronunciationService(
        audioEnabled: true,
        player: player,
        speech: speech,
        probe: const AlwaysPresentSoundAssetProbe(),
      );

      await service.playClip(phrase);
      expect(player.paths, <String>['assets/audio/phrases/good_morning.wav']);
      expect(sounds.cues, isEmpty);
      expect(haptics.played, <HapticLevel>[HapticLevel.lightTap]);
      service.dispose();
    });

    test('TTS still runs when UI sound effects are disabled', () async {
      FeedbackService.instance = FeedbackService(
        hapticsEnabled: false,
        soundEnabled: false,
      );
      UserPreferences.instance.setSoundEnabled(false);
      final _RecordingSpeechEngine speech = _RecordingSpeechEngine();
      final PronunciationService service = PronunciationService(
        audioEnabled: true,
        player: const SilentPronunciationPlayer(),
        speech: speech,
        probe: const _MissingSoundAssetProbe(),
        speechLocale: 'en',
        onStarted: () {},
      );

      await service.playClip(
        PronunciationClip.fromWord(
          const WordEntry(
            id: 'word.family.mother',
            categoryId: 'word_category.family',
            text: 'Mother',
            sortOrder: 0,
            quizEnabled: true,
          ),
        ),
      );
      expect(speech.utterances, <(String, String)>[('Mother', 'en-US')]);
      service.dispose();
    });

    test('learner language does not change the spoken TTS locale', () async {
      UserPreferences.instance.setSelectedTranslationLanguage('tr');
      ProductConfig.bind(
        ProductConfig.fallback.copyWith(
          targetLanguageCode: 'en',
          featureFlags: const ProductFeatureFlags(audio: true),
        ),
      );
      final _RecordingSpeechEngine speech = _RecordingSpeechEngine();
      final PronunciationService service = PronunciationService(
        audioEnabled: true,
        player: const SilentPronunciationPlayer(),
        speech: speech,
        probe: const _MissingSoundAssetProbe(),
        onStarted: () {},
      );

      await service.playClip(
        PronunciationClip.fromPhrase(
          const PhraseEntry(
            id: 'phrase.greetings.hello',
            categoryId: 'phrase_category.greetings',
            text: 'Hello.',
            sortOrder: 0,
            quizEnabled: true,
          ),
        ),
      );
      expect(service.speechLocale, 'en-US');
      expect(speech.utterances, <(String, String)>[('Hello.', 'en-US')]);
      service.dispose();
    });

    test('favorites play word and phrase clips through one service', () async {
      final _RecordingSpeechEngine speech = _RecordingSpeechEngine();
      final PronunciationService service = PronunciationService(
        audioEnabled: true,
        player: const SilentPronunciationPlayer(),
        speech: speech,
        probe: const _MissingSoundAssetProbe(),
        speechLocale: 'en',
        onStarted: () {},
      );

      await service.playClip(
        PronunciationClip.fromWord(
          const WordEntry(
            id: 'word.family.mother',
            categoryId: 'word_category.family',
            text: 'Mother',
            sortOrder: 0,
            quizEnabled: true,
          ),
        ),
      );
      await service.playClip(
        PronunciationClip.fromPhrase(
          const PhraseEntry(
            id: 'phrase.greetings.hello',
            categoryId: 'phrase_category.greetings',
            text: 'How are you?',
            sortOrder: 0,
            quizEnabled: true,
          ),
        ),
      );
      expect(speech.utterances, <(String, String)>[
        ('Mother', 'en-US'),
        ('How are you?', 'en-US'),
      ]);
      service.dispose();
    });

    test(
      'alphabet TTS speaks the letter, never case labels or examples',
      () async {
        final _RecordingSpeechEngine speech = _RecordingSpeechEngine();
        final PronunciationService service = PronunciationService(
          audioEnabled: true,
          player: const SilentPronunciationPlayer(),
          speech: speech,
          probe: const _MissingSoundAssetProbe(),
          speechLocale: 'en',
          onStarted: () {},
        );

        await service.playClip(
          PronunciationClip.fromAlphabet(
            const AlphabetUnit(
              id: 'letter.a',
              glyph: 'A',
              sortOrder: 0,
              quizEnabled: true,
              pronunciation: 'ay',
              speechText: 'A',
              example: 'apple',
            ),
          ),
        );
        await service.playClip(
          PronunciationClip.fromAlphabet(
            const AlphabetUnit(
              id: 'letter.b',
              glyph: 'B',
              sortOrder: 1,
              quizEnabled: true,
              pronunciation: 'bee',
              speechText: 'B',
              example: 'book',
            ),
          ),
        );
        await service.playClip(
          PronunciationClip.fromAlphabet(
            const AlphabetUnit(
              id: 'letter.z',
              glyph: 'Z',
              sortOrder: 25,
              quizEnabled: true,
              pronunciation: 'zee',
              speechText: 'Z',
              example: 'zoo',
            ),
          ),
        );
        expect(speech.utterances, <(String, String)>[
          ('A', 'en-US'),
          ('B', 'en-US'),
          ('Z', 'en-US'),
        ]);
        for (final (String spoken, String _) in speech.utterances) {
          expect(spoken.toLowerCase(), isNot(contains('capital')));
          expect(spoken.toLowerCase(), isNot(contains('uppercase')));
          expect(spoken.toLowerCase(), isNot(contains('lowercase')));
          expect(spoken.toLowerCase(), isNot(contains('letter')));
        }
        expect(speech.utterances.first.$1, isNot('apple'));
        expect(speech.utterances[1].$1, isNot('bee'));
        service.dispose();
      },
    );

    test('does not offer punctuation-only speech text', () async {
      final PronunciationService service = PronunciationService(
        audioEnabled: true,
        player: const SilentPronunciationPlayer(),
        speech: _RecordingSpeechEngine(),
        probe: const _MissingSoundAssetProbe(),
        onStarted: () {},
      );
      const PronunciationClip mark = PronunciationClip(
        id: 'letter.question',
        speechText: '?',
      );
      expect(service.isOffered(mark), isFalse);
      await service.playClip(mark);
      service.dispose();
    });

    test('a new TTS tap stops the previous utterance', () async {
      final _GateSpeechEngine speech = _GateSpeechEngine();
      final PronunciationService service = PronunciationService(
        audioEnabled: true,
        player: const SilentPronunciationPlayer(),
        speech: speech,
        probe: const _MissingSoundAssetProbe(),
        speechLocale: 'en',
        onStarted: () {},
      );

      const PronunciationClip firstClip = PronunciationClip(
        id: 'word.mother',
        speechText: 'Mother',
      );
      const PronunciationClip secondClip = PronunciationClip(
        id: 'word.father',
        speechText: 'Father',
      );
      final Future<void> first = service.playClip(firstClip);
      for (int i = 0; i < 20 && speech.utterances.isEmpty; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(speech.utterances, <String>['Mother']);
      await service.playClip(secondClip);
      await first;
      expect(speech.stopCount, greaterThan(0));
      expect(speech.utterances.last, 'Father');
      expect(speech.overlapping, isFalse);
      service.dispose();
    });

    test('items without an audio reference are not offered', () async {
      final PronunciationService service = PronunciationService(
        audioEnabled: true,
        player: _RecordingPronunciationPlayer(),
        probe: const AlwaysPresentSoundAssetProbe(),
        onStarted: () {},
      );
      const PronunciationClip silent = PronunciationClip(id: 'letter.b');

      expect(service.isOffered(silent), isFalse);
      expect(
        await service.availabilityFor(silent),
        PronunciationAvailability.missing,
      );
      await service.playClip(silent);
      service.dispose();
    });

    test('TTS-only clips are offered without a bundled file', () async {
      final PronunciationService service = PronunciationService(
        audioEnabled: true,
        player: _RecordingPronunciationPlayer(),
        speech: _RecordingSpeechEngine(),
        probe: const _MissingSoundAssetProbe(),
        onStarted: () {},
      );
      const PronunciationClip spoken = PronunciationClip(
        id: 'word.mother',
        speechText: 'Mother',
      );
      expect(service.isOffered(spoken), isTrue);
      expect(
        await service.availabilityFor(spoken),
        PronunciationAvailability.ready,
      );
      service.dispose();
    });
  });

  group('PronunciationControl', () {
    testWidgets('hides when pronunciation is unavailable', (
      WidgetTester tester,
    ) async {
      final PronunciationService service = PronunciationService(
        audioEnabled: false,
        player: _RecordingPronunciationPlayer(),
        probe: const AlwaysPresentSoundAssetProbe(),
        onStarted: () {},
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: PronunciationControl(clip: letter, service: service),
        ),
      );

      expect(find.byType(LingoGlyphButton), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      service.dispose();
    });

    testWidgets('plays on tap when offered', (WidgetTester tester) async {
      final _RecordingPronunciationPlayer player =
          _RecordingPronunciationPlayer();
      final PronunciationService service = PronunciationService(
        audioEnabled: true,
        player: player,
        probe: const AlwaysPresentSoundAssetProbe(),
        onStarted: () {},
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: PronunciationControl(clip: word, service: service),
          ),
        ),
      );

      expect(find.byType(LingoGlyphButton), findsOneWidget);
      await tester.tap(find.byType(LingoGlyphButton));
      await tester.pump();
      expect(player.paths, <String>['assets/audio/words/apple.wav']);
      await tester.pumpWidget(const SizedBox.shrink());
      service.dispose();
    });

    testWidgets('shows a speaker for TTS-only items', (
      WidgetTester tester,
    ) async {
      final _RecordingSpeechEngine speech = _RecordingSpeechEngine();
      final PronunciationService service = PronunciationService(
        audioEnabled: true,
        player: const SilentPronunciationPlayer(),
        speech: speech,
        probe: const _MissingSoundAssetProbe(),
        speechLocale: 'en',
        onStarted: () {},
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: PronunciationControl(
              clip: const PronunciationClip(
                id: 'word.mother',
                speechText: 'Mother',
              ),
              service: service,
            ),
          ),
        ),
      );

      expect(find.byType(LingoGlyphButton), findsOneWidget);
      await tester.tap(find.byType(LingoGlyphButton));
      await tester.pump();
      expect(speech.utterances, <(String, String)>[('Mother', 'en-US')]);
      await tester.pumpWidget(const SizedBox.shrink());
      service.dispose();
    });
  });
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

final class _GatePronunciationPlayer implements PronunciationPlayer {
  final List<String> paths = <String>[];
  int stopCount = 0;
  int _active = 0;
  bool overlapping = false;
  Completer<void>? _hold;

  @override
  Future<void> play(String assetPath) async {
    _active++;
    if (_active > 1) {
      overlapping = true;
    }
    paths.add(assetPath);
    if (paths.length == 1) {
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

final class _ThrowingPronunciationPlayer implements PronunciationPlayer {
  const _ThrowingPronunciationPlayer();

  @override
  Future<void> play(String assetPath) {
    throw FlutterError('decoder missing');
  }

  @override
  Future<void> stop() {
    throw FlutterError('stop failed');
  }

  @override
  Future<void> warmUp() {
    throw FlutterError('warm up failed');
  }

  @override
  void dispose() {}
}

final class _ThrowingSpeechEngine implements SpeechEngine {
  const _ThrowingSpeechEngine();

  @override
  Future<void> speak({
    required String text,
    required String locale,
    TargetSpeechProfile? profile,
  }) {
    throw FlutterError('voice unavailable');
  }

  @override
  Future<void> stop() {
    throw FlutterError('stop failed');
  }

  @override
  Future<void> warmUp() {
    throw FlutterError('warm up failed');
  }

  @override
  void dispose() {}
}

final class _MissingSoundAssetProbe implements SoundAssetProbe {
  const _MissingSoundAssetProbe();

  @override
  Future<bool> exists(String path) async => false;
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

  @override
  Future<void> play(SoundCue cue, String assetPath) async {
    cues.add(cue);
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> warmUp() async {}

  @override
  void dispose() {}
}
