import 'package:lingo_core/core/l10n/ui_keys.dart';
import 'package:lingo_core/core/widgets/lingo_nav_glyphs.dart';

enum ShellTab {
  home,
  words,
  phrases,
  favorites,
  settings;

  String get labelKey {
    return switch (this) {
      ShellTab.home => UiKeys.navHome,
      ShellTab.words => UiKeys.navWords,
      ShellTab.phrases => UiKeys.navPhrases,
      ShellTab.favorites => UiKeys.navFavorites,
      ShellTab.settings => UiKeys.navSettings,
    };
  }

  LingoNavGlyph get glyph {
    return switch (this) {
      ShellTab.home => LingoNavGlyph.home,
      ShellTab.words => LingoNavGlyph.words,
      ShellTab.phrases => LingoNavGlyph.phrases,
      ShellTab.favorites => LingoNavGlyph.favorites,
      ShellTab.settings => LingoNavGlyph.settings,
    };
  }
}
