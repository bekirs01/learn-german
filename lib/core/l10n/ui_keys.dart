/// Stable, language-independent keys for learner-facing application chrome.
///
/// Learning content (target-language words, phrases, glyphs) is not keyed
/// here. Category names and item meanings live in translation bundles.
abstract final class UiKeys {
  static const String navHome = 'nav.home';
  static const String navAlphabet = 'nav.alphabet';
  static const String navWords = 'nav.words';
  static const String navPhrases = 'nav.phrases';
  static const String navFavorites = 'nav.favorites';
  static const String navSettings = 'nav.settings';
  static const String navBottomNavigation = 'nav.bottom_navigation';

  static const String wrongAnswersTitle = 'wrong_answers.title';
  static const String wrongAnswersEmptyTitle = 'wrong_answers.empty_title';
  static const String wrongAnswersEmptyMessage = 'wrong_answers.empty_message';
  static const String wrongAnswersPractice = 'wrong_answers.practice';
  static const String wrongAnswersCharacters = 'wrong_answers.characters';
  static const String wrongAnswersMissCount = 'wrong_answers.miss_count';

  static const String alphabetExample = 'alphabet.example';
  static const String alphabetMeaning = 'alphabet.meaning';
  static const String alphabetEmptyTitle = 'alphabet.empty_title';
  static const String alphabetEmptyMessage = 'alphabet.empty_message';

  static const String wordsEmptyTitle = 'words.empty_title';
  static const String wordsEmptyCategoriesTitle =
      'words.empty_categories_title';
  static const String wordsEmptyCategoriesMessage =
      'words.empty_categories_message';

  static const String phrasesEmptyTitle = 'phrases.empty_title';
  static const String phrasesEmptyCategoriesTitle =
      'phrases.empty_categories_title';
  static const String phrasesEmptyCategoriesMessage =
      'phrases.empty_categories_message';

  static const String favoritesWords = 'favorites.words';
  static const String favoritesPhrases = 'favorites.phrases';
  static const String favoritesEmptyWords = 'favorites.empty_words';
  static const String favoritesEmptyPhrases = 'favorites.empty_phrases';
  static const String favoritesAdd = 'favorites.add';
  static const String favoritesRemove = 'favorites.remove';

  static const String learnedMark = 'learned.mark';
  static const String learnedUnmark = 'learned.unmark';

  static const String settingsTitle = 'settings.title';
  static const String settingsTranslationLanguage =
      'settings.translation_language';
  static const String settingsSoundEffects = 'settings.sound_effects';
  static const String settingsHaptics = 'settings.haptics';
  static const String settingsPrivacy = 'settings.privacy';
  static const String settingsPrivacyBody = 'settings.privacy_body';
  static const String settingsPrivacyLocalContent =
      'settings.privacy_local_content';
  static const String settingsPrivacyNoAccount = 'settings.privacy_no_account';
  static const String settingsPrivacyNoAds = 'settings.privacy_no_ads';
  static const String settingsPrivacyNoTracking =
      'settings.privacy_no_tracking';
  static const String settingsPrivacyOnDevice = 'settings.privacy_on_device';

  static const String quizTitle = 'quiz.title';
  static const String quizChoose = 'quiz.choose';
  static const String quizPractice = 'quiz.practice';
  static const String quizMixed = 'quiz.mixed';
  static const String quizMixedDescription = 'quiz.mixed_description';
  static const String quizMultipleChoice = 'quiz.multiple_choice';
  static const String quizReverseMultipleChoice =
      'quiz.reverse_multiple_choice';
  static const String quizBuildWord = 'quiz.build_word';
  static const String quizBuildPhrase = 'quiz.build_phrase';
  static const String quizBuildAnswer = 'quiz.build_answer';
  static const String quizTypeAnswer = 'quiz.type_answer';
  static const String quizMultipleChoiceDescription =
      'quiz.multiple_choice_description';
  static const String quizReverseMultipleChoiceDescription =
      'quiz.reverse_multiple_choice_description';
  static const String quizBuildDescription = 'quiz.build_description';
  static const String quizTypeDescription = 'quiz.type_description';
  static const String quizContinue = 'quiz.continue';
  static const String quizCheck = 'quiz.check';
  static const String quizCorrectAnswer = 'quiz.correct_answer';
  static const String quizYourAnswer = 'quiz.your_answer';
  static const String quizUndo = 'quiz.undo';
  static const String quizTapTokens = 'quiz.tap_tokens';
  static const String quizComplete = 'quiz.complete';
  static const String quizCorrect = 'quiz.correct';
  static const String quizIncorrect = 'quiz.incorrect';
  static const String quizTryAgain = 'quiz.try_again';
  static const String quizDone = 'quiz.done';
  static const String quizUnavailableTitle = 'quiz.unavailable_title';
  static const String quizUnavailableMessage = 'quiz.unavailable_message';
  static const String quizNoQuestion = 'quiz.no_question';
  static const String quizScore = 'quiz.score';

  static const String appLoadError = 'app.load_error';
  static const String audioPlayPronunciation = 'audio.play_pronunciation';

  static const String watchTitle = 'watch.title';
  static const String watchStatusConnected = 'watch.status_connected';
  static const String watchStatusAppNotInstalled =
      'watch.status_app_not_installed';
  static const String watchStatusUnavailable = 'watch.status_unavailable';
  static const String watchContentTitle = 'watch.content_title';
  static const String watchDailyWindow = 'watch.daily_window';
  static const String watchFrequency = 'watch.frequency';
  static const String watchTimesPerDay = 'watch.times_per_day';
  static const String watchSendPreview = 'watch.send_preview';
  static const String watchSyncSuccess = 'watch.sync_success';
  static const String watchSyncFailed = 'watch.sync_failed';
  static const String watchEmptySelection = 'watch.empty_selection';
  static const String watchSelectedCount = 'watch.selected_count';
  static const String watchWindowStart = 'watch.window_start';
  static const String watchWindowEnd = 'watch.window_end';
  static const String watchSyncSaved = 'watch.sync_saved';
  static const String watchSyncUpdated = 'watch.sync_updated';
  static const String watchContentBoth = 'watch.content_both';
  static const String watchChooseContent = 'watch.choose_content';
  static const String watchClearSelection = 'watch.clear_selection';
  static const String watchSelectionLimit = 'watch.selection_limit';
  static const String watchInvalidWindow = 'watch.invalid_window';
  static const String watchZeroDeliveries = 'watch.zero_deliveries';
  static const String watchUnreasonableFrequency =
      'watch.unreasonable_frequency';
  static const String watchReminders = 'watch.reminders';
  static const String watchActiveHours = 'watch.active_hours';
  static const String watchScheduleEnabled = 'watch.schedule_enabled';
  static const String watchNextReminder = 'watch.next_reminder';
  static const String watchRemindersPaused = 'watch.reminders_paused';
  static const String watchStarterSet = 'watch.starter_set';
  static const String watchSelectedOfMax = 'watch.selected_of_max';
  static const String watchLimitReached = 'watch.limit_reached';
  static const String watchBrowseHint = 'watch.browse_hint';
  static const String watchSearchHint = 'watch.search_hint';
  static const String watchChangeSelection = 'watch.change_selection';
  static const String watchPreviewSchedule = 'watch.preview_schedule';
  static const String watchStatusReady = 'watch.status_ready';
  static const String watchNextReminders = 'watch.next_reminders';

  /// Production chrome keys that every shipped UI table must fill.
  /// Language display names are resolved from [LearnerLanguages].
  static const List<String> chrome = <String>[
    navHome,
    navAlphabet,
    navWords,
    navPhrases,
    navFavorites,
    navSettings,
    navBottomNavigation,
    wrongAnswersTitle,
    wrongAnswersEmptyTitle,
    wrongAnswersEmptyMessage,
    wrongAnswersPractice,
    wrongAnswersCharacters,
    wrongAnswersMissCount,
    alphabetExample,
    alphabetMeaning,
    alphabetEmptyTitle,
    alphabetEmptyMessage,
    wordsEmptyTitle,
    wordsEmptyCategoriesTitle,
    wordsEmptyCategoriesMessage,
    phrasesEmptyTitle,
    phrasesEmptyCategoriesTitle,
    phrasesEmptyCategoriesMessage,
    favoritesWords,
    favoritesPhrases,
    favoritesEmptyWords,
    favoritesEmptyPhrases,
    favoritesAdd,
    favoritesRemove,
    learnedMark,
    learnedUnmark,
    settingsTitle,
    settingsTranslationLanguage,
    settingsSoundEffects,
    settingsHaptics,
    settingsPrivacy,
    settingsPrivacyBody,
    settingsPrivacyLocalContent,
    settingsPrivacyNoAccount,
    settingsPrivacyNoAds,
    settingsPrivacyNoTracking,
    settingsPrivacyOnDevice,
    quizTitle,
    quizChoose,
    quizPractice,
    quizMixed,
    quizMixedDescription,
    quizMultipleChoice,
    quizReverseMultipleChoice,
    quizBuildWord,
    quizBuildPhrase,
    quizBuildAnswer,
    quizTypeAnswer,
    quizMultipleChoiceDescription,
    quizReverseMultipleChoiceDescription,
    quizBuildDescription,
    quizTypeDescription,
    quizContinue,
    quizCheck,
    quizCorrectAnswer,
    quizYourAnswer,
    quizUndo,
    quizTapTokens,
    quizComplete,
    quizCorrect,
    quizIncorrect,
    quizTryAgain,
    quizDone,
    quizUnavailableTitle,
    quizUnavailableMessage,
    quizNoQuestion,
    quizScore,
    appLoadError,
    audioPlayPronunciation,
    watchTitle,
    watchStatusConnected,
    watchStatusAppNotInstalled,
    watchStatusUnavailable,
    watchContentTitle,
    watchDailyWindow,
    watchFrequency,
    watchTimesPerDay,
    watchSendPreview,
    watchSyncSuccess,
    watchSyncFailed,
    watchEmptySelection,
    watchSelectedCount,
    watchWindowStart,
    watchWindowEnd,
    watchSyncSaved,
    watchSyncUpdated,
    watchContentBoth,
    watchChooseContent,
    watchClearSelection,
    watchSelectionLimit,
    watchInvalidWindow,
    watchZeroDeliveries,
    watchUnreasonableFrequency,
    watchReminders,
    watchActiveHours,
    watchScheduleEnabled,
    watchNextReminder,
    watchRemindersPaused,
    watchStarterSet,
    watchSelectedOfMax,
    watchLimitReached,
    watchBrowseHint,
    watchSearchHint,
    watchChangeSelection,
    watchPreviewSchedule,
    watchStatusReady,
    watchNextReminders,
  ];

  static const List<String> _uiPrefixes = <String>[
    'nav.',
    'settings.',
    'quiz.',
    'favorites.',
    'learned.',
    'alphabet.',
    'wrong_answers.',
    'words.',
    'phrases.',
    'app.',
    'audio.',
    'watch.',
    'language.',
    'common.',
  ];

  static bool isUiKey(String key) {
    if (chrome.contains(key)) {
      return true;
    }
    for (final String prefix in _uiPrefixes) {
      if (key.startsWith(prefix)) {
        return true;
      }
    }
    return false;
  }
}
