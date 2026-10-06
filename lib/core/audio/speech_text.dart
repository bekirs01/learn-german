/// Safe TTS preprocessing. Strips presentation metadata without damaging
/// legitimate target-language words and phrases.
abstract final class SpeechTextNormalizer {
  static final RegExp _ipaOnly = RegExp(r'^/.+/$');
  static final RegExp _isolatedLetter = RegExp(r'^\p{L}$', unicode: true);
  static const String _eszett = 'ß';
  static const String _capitalEszett = 'ẞ';
  static final RegExp _casePrefix = RegExp(
    r'^(?:uppercase|lowercase|upper[\s-]?case|lower[\s-]?case|capital(?:\s+letter)?|small(?:\s+letter)?)\s+',
    caseSensitive: false,
  );
  static final RegExp _caseSuffix = RegExp(
    r'\s*[\(\[]\s*(?:uppercase|lowercase|upper[\s-]?case|lower[\s-]?case|capital|small letter)\s*[\)\]]\s*$',
    caseSensitive: false,
  );
  static final RegExp _letterPrefix = RegExp(
    r'^(?:letter|glyph|character)\s+',
    caseSensitive: false,
  );
  static final RegExp _whitespace = RegExp(r'\s+');
  static final RegExp _hasLetterOrNumber = RegExp(
    r'\p{L}|\p{N}',
    unicode: true,
  );

  static const Set<String> _metadataLabels = <String>{
    'punctuation',
    'ipa',
    'romanization',
    'pronunciation',
    'uppercase',
    'lowercase',
    'glyph',
    'translation',
  };

  /// Educational spoken form for clips and tests.
  ///
  /// Returns null when [raw] is empty, IPA-only, punctuation-only, or a
  /// technical label. Terminal punctuation inside real phrases is kept.
  static String? clean(String? raw) {
    String? value = raw?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    value = value.replaceAll(_whitespace, ' ').trim();
    if (value.isEmpty || _ipaOnly.hasMatch(value)) {
      return null;
    }

    value = value.replaceFirst(_casePrefix, '').trim();
    value = value.replaceFirst(_caseSuffix, '').trim();
    if (_isIsolatedLetter(value) == false && _letterPrefix.hasMatch(value)) {
      final String stripped = value.replaceFirst(_letterPrefix, '').trim();
      if (_isIsolatedLetter(stripped)) {
        value = stripped;
      }
    }
    if (value.isEmpty || _ipaOnly.hasMatch(value)) {
      return null;
    }

    final String label = value.toLowerCase();
    if (_metadataLabels.contains(label)) {
      return null;
    }
    if (!_hasLetterOrNumber.hasMatch(value)) {
      return null;
    }
    if (_isIsolatedLetter(value)) {
      return _educationalLetter(value);
    }
    return value;
  }

  /// Native-engine string. Isolated letters stay a single letter.
  ///
  /// Apple voices announce "capital A" / "uppercase A" when the utterance is
  /// one uppercase letter. Lowercase keeps the letter name without case labels.
  /// Educational [speechText] remains "A" / "Ä"; this shaping is engine-only.
  /// German ß stays ß so it is never expanded to SS.
  static String utterance(String cleaned) {
    if (_isIsolatedLetter(cleaned)) {
      return _engineLetter(cleaned);
    }
    return cleaned;
  }

  static bool _isIsolatedLetter(String value) {
    return _isolatedLetter.hasMatch(value);
  }

  static String _educationalLetter(String value) {
    if (value == _eszett || value == _capitalEszett) {
      return _eszett;
    }
    return value.toUpperCase();
  }

  static String _engineLetter(String value) {
    if (value == _eszett || value == _capitalEszett) {
      return _eszett;
    }
    return value.toLowerCase();
  }
}
