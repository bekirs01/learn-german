import 'package:lingo_core/data/user_preferences.dart';
import 'package:lingo_core/domain/quiz_models.dart';

/// Maps Quiz answer events onto the local Wrong Answers store.
///
/// Quiz widgets stay unaware of persistence; launch code calls these helpers.
abstract final class WrongAnswersSync {
  static Future<void> recordWrong(QuizWrongAnswer event) {
    return UserPreferences.instance.recordWrongAnswer(
      contentId: event.contentId,
      kind: event.kind,
      quizType: event.quizType,
    );
  }

  static Future<void> recordCorrect(QuizCorrectAnswer event) {
    return UserPreferences.instance.recordCorrectAnswer(event.contentId);
  }
}
