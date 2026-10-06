import 'package:characters/characters.dart';
import 'package:lingo_core/domain/content_models.dart';

/// Language-agnostic string helpers for quiz prompts, options, and answers.
abstract final class QuizText {
  static const Set<String> _rtlLanguageCodes = <String>{
    'ar',
    'fa',
    'he',
    'ps',
    'ur',
    'yi',
  };

  static const Set<int> _ignoredCodePoints = <int>{
    0x200B, // zero-width space
    0x200C, // zero-width non-joiner
    0x200D, // zero-width joiner
    0x200E, // LTR mark
    0x200F, // RTL mark
    0x202A,
    0x202B,
    0x202C,
    0x202D,
    0x202E,
    0x2066,
    0x2067,
    0x2068,
    0x2069,
    0xFEFF, // BOM
    0xFE0E, // variation selector
    0xFE0F,
  };

  static final RegExp _whitespace = RegExp(r'\s');
  static final RegExp _unicodePunctuation = RegExp(r'\p{P}', unicode: true);
  static const Set<int> _softTerminalPunctuation = <int>{
    0x002E, // .
    0x003F, // ?
    0x0021, // !
    0x00A1, // ¡
    0x00BF, // ¿
    0x2026, // …
    0x3002, // 。
    0xFF01, // ！
    0xFF1F, // ？
  };

  static const int _hangulSBase = 0xAC00;
  static const int _hangulLBase = 0x1100;
  static const int _hangulVBase = 0x1161;
  static const int _hangulTBase = 0x11A7;
  static const int _hangulLCount = 19;
  static const int _hangulVCount = 21;
  static const int _hangulTCount = 28;
  static const int _hangulNCount = _hangulVCount * _hangulTCount;
  static const int _hangulSCount = _hangulLCount * _hangulNCount;

  static final Map<int, String> _latinDecompositions = _latinDecompositionMap();

  /// Trim, Unicode-decompose, strip bidi/zero-width marks, collapse whitespace,
  /// drop wrapping punctuation, and optionally casefold.
  static String normalize(String input, {required bool caseSensitive}) {
    final String decomposed = _canonicalDecompose(input);
    final String collapsed = _collapseIgnoredAndWhitespace(decomposed);
    final String stripped = _stripEdgePunctuation(collapsed);
    final String compact = _collapseIgnoredAndWhitespace(stripped);
    if (!caseSensitive) {
      return compact.toLowerCase();
    }
    return compact;
  }

  static bool equals(String left, String right, {required bool caseSensitive}) {
    return normalize(left, caseSensitive: caseSensitive) ==
        normalize(right, caseSensitive: caseSensitive);
  }

  static String uniquenessKey(String input) {
    return normalize(input, caseSensitive: false);
  }

  /// Search-only fold. Visible stored spelling is never rewritten.
  ///
  /// Umlauts match their base letters and ß/ẞ match ss, so queries like
  /// "apfel" and "strasse" can find Äpfel and Straße. Quiz equality still
  /// uses [normalize] and keeps ä/ö/ü/ß distinct from a/o/u/ss.
  static String searchKey(String input) {
    final String folded = input.replaceAll('ß', 'ss').replaceAll('ẞ', 'ss');
    final String normalized = normalize(folded, caseSensitive: false);
    final StringBuffer buffer = StringBuffer();
    for (final int code in normalized.runes) {
      if (code >= 0x0300 && code <= 0x036F) {
        continue;
      }
      buffer.writeCharCode(code);
    }
    return buffer.toString();
  }

  static bool matchesQuery(String haystack, String needle) {
    final String query = searchKey(needle);
    if (query.isEmpty) {
      return true;
    }
    return searchKey(haystack).contains(query);
  }

  static bool isBlank(String? input) {
    if (input == null) {
      return true;
    }
    return _collapseIgnoredAndWhitespace(input).isEmpty;
  }

  /// Grapheme clusters with whitespace and ignored marks removed. Safe for
  /// Hangul, kana, combining marks, and accented Latin letters.
  static List<String> graphemes(String input) {
    final List<String> units = <String>[];
    for (final String cluster in input.characters) {
      if (_collapseIgnoredAndWhitespace(cluster).isEmpty) {
        continue;
      }
      units.add(cluster);
    }
    return units;
  }

  /// Tokens for Build mode. Whitespace-separated scripts keep word groups.
  /// Soft terminal punctuation is not a standalone chip. Scripts without
  /// spaces use grapheme clusters, dropping trailing soft punctuation.
  static List<String> tokensFor(String input) {
    final String trimmed = input.trim();
    if (trimmed.isEmpty) {
      return const <String>[];
    }
    if (_whitespace.hasMatch(trimmed)) {
      final List<String> tokens = <String>[];
      for (final String part in trimmed.split(RegExp(r'\s+'))) {
        if (part.isEmpty || _isPunctuationToken(part)) {
          continue;
        }
        final String cleaned = _stripSoftTerminalPunctuation(part);
        if (cleaned.isEmpty || _isPunctuationToken(cleaned)) {
          continue;
        }
        tokens.add(cleaned);
      }
      return List<String>.unmodifiable(tokens);
    }
    final List<String> units = graphemes(trimmed);
    int end = units.length;
    while (end > 1 && _isPunctuationToken(units[end - 1])) {
      end -= 1;
    }
    if (end <= 0) {
      return const <String>[];
    }
    return List<String>.unmodifiable(units.sublist(0, end));
  }

  /// True when prompt and cue would make a trivial identical question.
  static bool isTrivialPair(String left, String right) {
    final String leftKey = uniquenessKey(left);
    final String rightKey = uniquenessKey(right);
    if (leftKey.isEmpty || rightKey.isEmpty) {
      return true;
    }
    return leftKey == rightKey;
  }

  static String joinTokens(List<String> tokens, String separator) {
    if (tokens.isEmpty) {
      return '';
    }
    if (separator.isEmpty) {
      return tokens.join();
    }
    final StringBuffer buffer = StringBuffer();
    for (int index = 0; index < tokens.length; index += 1) {
      final String token = tokens[index];
      if (index == 0) {
        buffer.write(token);
        continue;
      }
      final String previous = tokens[index - 1];
      if (_isPunctuationToken(token) && !_isOpeningPunctuation(token)) {
        buffer.write(token);
      } else if (_isOpeningPunctuation(previous)) {
        buffer.write(token);
      } else {
        buffer.write(separator);
        buffer.write(token);
      }
    }
    return buffer.toString();
  }

  static bool usesCaseSensitiveAnswers({
    required QuizContentKind kind,
    required ScriptFamily scriptFamily,
  }) {
    if (kind == QuizContentKind.alphabet) {
      return true;
    }
    switch (scriptFamily) {
      case ScriptFamily.latin:
      case ScriptFamily.cyrillic:
        return false;
      case ScriptFamily.arabic:
      case ScriptFamily.han:
      case ScriptFamily.japanese:
      case ScriptFamily.korean:
      case ScriptFamily.other:
      case ScriptFamily.none:
        return true;
    }
  }

  static ContentTextDirection directionForLanguage(
    String? languageCode, {
    required ContentTextDirection fallback,
  }) {
    if (languageCode == null || languageCode.isEmpty) {
      return fallback;
    }
    final String base = languageCode.split('-').first.toLowerCase();
    if (_rtlLanguageCodes.contains(base)) {
      return ContentTextDirection.rtl;
    }
    return ContentTextDirection.ltr;
  }

  static String _canonicalDecompose(String input) {
    final StringBuffer buffer = StringBuffer();
    for (final int code in input.runes) {
      if (code >= _hangulSBase && code < _hangulSBase + _hangulSCount) {
        buffer.write(_decomposeHangul(code));
        continue;
      }
      final String? latin = _latinDecompositions[code];
      if (latin != null) {
        buffer.write(latin);
        continue;
      }
      buffer.writeCharCode(code);
    }
    return buffer.toString();
  }

  static String _decomposeHangul(int syllable) {
    final int sIndex = syllable - _hangulSBase;
    final int l = _hangulLBase + sIndex ~/ _hangulNCount;
    final int v = _hangulVBase + (sIndex % _hangulNCount) ~/ _hangulTCount;
    final int t = _hangulTBase + sIndex % _hangulTCount;
    if (t == _hangulTBase) {
      return String.fromCharCodes(<int>[l, v]);
    }
    return String.fromCharCodes(<int>[l, v, t]);
  }

  static String _collapseIgnoredAndWhitespace(String input) {
    final StringBuffer buffer = StringBuffer();
    bool pendingSpace = false;
    bool wrote = false;

    for (final int code in input.runes) {
      if (_ignoredCodePoints.contains(code)) {
        continue;
      }
      final String unit = String.fromCharCode(code);
      if (_whitespace.hasMatch(unit)) {
        if (wrote) {
          pendingSpace = true;
        }
        continue;
      }
      if (pendingSpace) {
        buffer.write(' ');
        pendingSpace = false;
      }
      buffer.write(unit);
      wrote = true;
    }
    return buffer.toString();
  }

  static String _stripEdgePunctuation(String input) {
    if (input.isEmpty) {
      return input;
    }
    final List<int> codes = input.runes.toList(growable: false);
    int start = 0;
    int end = codes.length;
    while (start < end && _isPunctuationCode(codes[start])) {
      start += 1;
    }
    while (end > start && _isPunctuationCode(codes[end - 1])) {
      end -= 1;
    }
    if (start == 0 && end == codes.length) {
      return input;
    }
    if (start == end) {
      return input;
    }
    return String.fromCharCodes(codes.sublist(start, end));
  }

  static String _stripSoftTerminalPunctuation(String token) {
    if (token.isEmpty) {
      return token;
    }
    final List<int> codes = token.runes.toList(growable: false);
    int start = 0;
    int end = codes.length;
    while (start < end && _softTerminalPunctuation.contains(codes[start])) {
      start += 1;
    }
    while (end > start && _softTerminalPunctuation.contains(codes[end - 1])) {
      end -= 1;
    }
    if (start == 0 && end == codes.length) {
      return token;
    }
    if (start == end) {
      return '';
    }
    return String.fromCharCodes(codes.sublist(start, end));
  }

  static bool _isPunctuationToken(String token) {
    if (token.isEmpty) {
      return false;
    }
    for (final int code in token.runes) {
      if (_ignoredCodePoints.contains(code) ||
          _whitespace.hasMatch(String.fromCharCode(code))) {
        continue;
      }
      if (!_isPunctuationCode(code)) {
        return false;
      }
    }
    return _collapseIgnoredAndWhitespace(token).isNotEmpty;
  }

  static bool _isOpeningPunctuation(String token) {
    if (token.isEmpty) {
      return false;
    }
    const Set<String> opening = <String>{
      '(',
      '[',
      '{',
      '<',
      '«',
      '‹',
      '"',
      "'",
      '¡',
      '¿',
      '“',
      '‘',
      '（',
      '【',
      '《',
      '「',
      '『',
    };
    return opening.contains(token.characters.first);
  }

  static bool _isPunctuationCode(int code) {
    if (_ignoredCodePoints.contains(code)) {
      return false;
    }
    return _unicodePunctuation.hasMatch(String.fromCharCode(code));
  }

  static Map<int, String> _latinDecompositionMap() {
    const int grave = 0x0300;
    const int acute = 0x0301;
    const int circumflex = 0x0302;
    const int tilde = 0x0303;
    const int macron = 0x0304;
    const int breve = 0x0306;
    const int dotAbove = 0x0307;
    const int diaeresis = 0x0308;
    const int ring = 0x030A;
    const int doubleAcute = 0x030B;
    const int caron = 0x030C;
    const int cedilla = 0x0327;
    const int ogonek = 0x0328;

    final Map<int, String> map = <int, String>{};
    void pair(int precomposed, int base, int mark) {
      map[precomposed] = String.fromCharCodes(<int>[base, mark]);
    }

    pair(0x00C0, 0x41, grave);
    pair(0x00C1, 0x41, acute);
    pair(0x00C2, 0x41, circumflex);
    pair(0x00C3, 0x41, tilde);
    pair(0x00C4, 0x41, diaeresis);
    pair(0x00C5, 0x41, ring);
    pair(0x00C7, 0x43, cedilla);
    pair(0x00C8, 0x45, grave);
    pair(0x00C9, 0x45, acute);
    pair(0x00CA, 0x45, circumflex);
    pair(0x00CB, 0x45, diaeresis);
    pair(0x00CC, 0x49, grave);
    pair(0x00CD, 0x49, acute);
    pair(0x00CE, 0x49, circumflex);
    pair(0x00CF, 0x49, diaeresis);
    pair(0x00D1, 0x4E, tilde);
    pair(0x00D2, 0x4F, grave);
    pair(0x00D3, 0x4F, acute);
    pair(0x00D4, 0x4F, circumflex);
    pair(0x00D5, 0x4F, tilde);
    pair(0x00D6, 0x4F, diaeresis);
    pair(0x00D9, 0x55, grave);
    pair(0x00DA, 0x55, acute);
    pair(0x00DB, 0x55, circumflex);
    pair(0x00DC, 0x55, diaeresis);
    pair(0x00DD, 0x59, acute);
    pair(0x00E0, 0x61, grave);
    pair(0x00E1, 0x61, acute);
    pair(0x00E2, 0x61, circumflex);
    pair(0x00E3, 0x61, tilde);
    pair(0x00E4, 0x61, diaeresis);
    pair(0x00E5, 0x61, ring);
    pair(0x00E7, 0x63, cedilla);
    pair(0x00E8, 0x65, grave);
    pair(0x00E9, 0x65, acute);
    pair(0x00EA, 0x65, circumflex);
    pair(0x00EB, 0x65, diaeresis);
    pair(0x00EC, 0x69, grave);
    pair(0x00ED, 0x69, acute);
    pair(0x00EE, 0x69, circumflex);
    pair(0x00EF, 0x69, diaeresis);
    pair(0x00F1, 0x6E, tilde);
    pair(0x00F2, 0x6F, grave);
    pair(0x00F3, 0x6F, acute);
    pair(0x00F4, 0x6F, circumflex);
    pair(0x00F5, 0x6F, tilde);
    pair(0x00F6, 0x6F, diaeresis);
    pair(0x00F9, 0x75, grave);
    pair(0x00FA, 0x75, acute);
    pair(0x00FB, 0x75, circumflex);
    pair(0x00FC, 0x75, diaeresis);
    pair(0x00FD, 0x79, acute);
    pair(0x00FF, 0x79, diaeresis);

    pair(0x0100, 0x41, macron);
    pair(0x0101, 0x61, macron);
    pair(0x0102, 0x41, breve);
    pair(0x0103, 0x61, breve);
    pair(0x0104, 0x41, ogonek);
    pair(0x0105, 0x61, ogonek);
    pair(0x0106, 0x43, acute);
    pair(0x0107, 0x63, acute);
    pair(0x010C, 0x43, caron);
    pair(0x010D, 0x63, caron);
    pair(0x010E, 0x44, caron);
    pair(0x010F, 0x64, caron);
    pair(0x0112, 0x45, macron);
    pair(0x0113, 0x65, macron);
    pair(0x0118, 0x45, ogonek);
    pair(0x0119, 0x65, ogonek);
    pair(0x011A, 0x45, caron);
    pair(0x011B, 0x65, caron);
    pair(0x011E, 0x47, breve);
    pair(0x011F, 0x67, breve);
    pair(0x012A, 0x49, macron);
    pair(0x012B, 0x69, macron);
    pair(0x0130, 0x49, dotAbove);
    pair(0x014C, 0x4F, macron);
    pair(0x014D, 0x6F, macron);
    pair(0x0150, 0x4F, doubleAcute);
    pair(0x0151, 0x6F, doubleAcute);
    pair(0x0158, 0x52, caron);
    pair(0x0159, 0x72, caron);
    pair(0x015A, 0x53, acute);
    pair(0x015B, 0x73, acute);
    pair(0x015E, 0x53, cedilla);
    pair(0x015F, 0x73, cedilla);
    pair(0x0160, 0x53, caron);
    pair(0x0161, 0x73, caron);
    pair(0x0164, 0x54, caron);
    pair(0x0165, 0x74, caron);
    pair(0x016A, 0x55, macron);
    pair(0x016B, 0x75, macron);
    pair(0x0170, 0x55, doubleAcute);
    pair(0x0171, 0x75, doubleAcute);
    pair(0x0179, 0x5A, acute);
    pair(0x017A, 0x7A, acute);
    pair(0x017B, 0x5A, dotAbove);
    pair(0x017C, 0x7A, dotAbove);
    pair(0x017D, 0x5A, caron);
    pair(0x017E, 0x7A, caron);
    return map;
  }
}
