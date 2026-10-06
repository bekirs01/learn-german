import 'package:flutter/foundation.dart';
import 'package:lingo_core/core/l10n/learner_languages.dart';
import 'package:lingo_core/features/home/home_motivation_l10n.dart';

export 'package:lingo_core/features/home/home_motivation_l10n.dart'
    show HomeQuote;

/// Local, offline Home motivation quotes.
///
/// Selection is a calendar-day index, so the same quote is stable until local
/// midnight. Display copy follows the selected Translation Language.
abstract final class HomeMotivationQuotes {
  static List<HomeQuote> get pool => HomeMotivationL10n.english;

  static List<HomeQuote> poolFor(String languageCode) {
    return HomeMotivationL10n.linesFor(languageCode);
  }

  /// Injectable clock for widget and unit tests.
  @visibleForTesting
  static DateTime Function() now = DateTime.now;

  @visibleForTesting
  static void resetForTest() {
    now = DateTime.now;
  }

  static HomeQuote get today => todayFor(LearnerLanguages.fallbackCode);

  static HomeQuote todayFor(String languageCode) =>
      forDate(now(), languageCode);

  static HomeQuote forDate(DateTime date, [String? languageCode]) {
    final List<HomeQuote> lines = poolFor(
      languageCode ?? LearnerLanguages.fallbackCode,
    );
    if (lines.isEmpty) {
      return const HomeQuote(text: '', author: '');
    }
    return lines[indexForDate(date) % lines.length];
  }

  static int indexForDate(DateTime date) {
    final int elapsed =
        DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
    final int length = HomeMotivationL10n.poolSize;
    return (elapsed % length + length) % length;
  }
}
