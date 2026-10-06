import 'package:lingo_core/core/l10n/learner_languages.dart';

/// Watch chrome strings keyed by the iPhone Translation Language.
///
/// The Watch app mirrors this table in Swift. Tests use this copy so UI
/// language can be verified without a watchOS target.
abstract final class WatchLearnerCopy {
  static const String today = 'watch.home.today';
  static const String word = 'watch.content.word';
  static const String phrase = 'watch.content.phrase';
  static const String words = 'watch.content.words';
  static const String phrases = 'watch.content.phrases';
  static const String setUpOnIPhone = 'watch.empty.setup_on_iphone';
  static const String chooseLearningContent = 'watch.empty.choose_content';
  static const String chooseWordsOnIPhone = 'watch.empty.choose_words';
  static const String previous = 'watch.action.previous';
  static const String next = 'watch.action.next';
  static const String onWatch = 'watch.status.on_watch';

  static const List<String> keys = <String>[
    today,
    word,
    phrase,
    words,
    phrases,
    setUpOnIPhone,
    chooseLearningContent,
    chooseWordsOnIPhone,
    previous,
    next,
    onWatch,
  ];

  static String resolve(String key, String learnerLanguageCode) {
    final String language = LearnerLanguages.baseCode(learnerLanguageCode);
    final String? direct = _usable(_tables[language]?[key]);
    if (direct != null) {
      return direct;
    }
    return _usable(_tables[LearnerLanguages.fallbackCode]?[key]) ?? key;
  }

  static String? _usable(String? value) {
    if (value == null) {
      return null;
    }
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static final Map<String, Map<String, String>> _tables =
      <String, Map<String, String>>{
        'en': <String, String>{
          today: 'Today',
          word: 'Word',
          phrase: 'Phrase',
          words: 'Words',
          phrases: 'Phrases',
          setUpOnIPhone: 'Set up on iPhone',
          chooseLearningContent: 'Choose your learning content...',
          chooseWordsOnIPhone: 'Choose words on iPhone',
          previous: 'Previous',
          next: 'Next',
          onWatch: 'On Watch',
        },
        'tr': <String, String>{
          today: 'Bugün',
          word: 'Kelime',
          phrase: 'İfade',
          words: 'Kelimeler',
          phrases: 'İfadeler',
          setUpOnIPhone: 'iPhone’da kur',
          chooseLearningContent: 'Öğrenme içeriğini seç...',
          chooseWordsOnIPhone: 'Kelimeleri iPhone’dan seç',
          previous: 'Önceki',
          next: 'Sonraki',
          onWatch: 'Saatte',
        },
        'es': <String, String>{
          today: 'Hoy',
          word: 'Palabra',
          phrase: 'Frase',
          words: 'Palabras',
          phrases: 'Frases',
          setUpOnIPhone: 'Configurar en iPhone',
          chooseLearningContent: 'Elige tu contenido de aprendizaje...',
          chooseWordsOnIPhone: 'Elige palabras en el iPhone',
          previous: 'Anterior',
          next: 'Siguiente',
          onWatch: 'En el Watch',
        },
        'ar': <String, String>{
          today: 'اليوم',
          word: 'كلمة',
          phrase: 'عبارة',
          words: 'الكلمات',
          phrases: 'العبارات',
          setUpOnIPhone: 'الإعداد على iPhone',
          chooseLearningContent: 'اختر محتوى التعلم...',
          chooseWordsOnIPhone: 'اختر الكلمات على iPhone',
          previous: 'السابق',
          next: 'التالي',
          onWatch: 'على الساعة',
        },
        'fr': <String, String>{
          today: 'Aujourd’hui',
          word: 'Mot',
          phrase: 'Phrase',
          words: 'Mots',
          phrases: 'Phrases',
          setUpOnIPhone: 'Configurer sur iPhone',
          chooseLearningContent: 'Choisis ton contenu d’apprentissage...',
          chooseWordsOnIPhone: 'Choisis des mots sur iPhone',
          previous: 'Précédent',
          next: 'Suivant',
          onWatch: 'Sur la Watch',
        },
        'de': <String, String>{
          today: 'Heute',
          word: 'Wort',
          phrase: 'Satz',
          words: 'Wörter',
          phrases: 'Sätze',
          setUpOnIPhone: 'Auf iPhone einrichten',
          chooseLearningContent: 'Wähle deine Lerninhalte...',
          chooseWordsOnIPhone: 'Wörter auf dem iPhone wählen',
          previous: 'Zurück',
          next: 'Weiter',
          onWatch: 'Auf der Watch',
        },
        'ru': <String, String>{
          today: 'Сегодня',
          word: 'Слово',
          phrase: 'Фраза',
          words: 'Слова',
          phrases: 'Фразы',
          setUpOnIPhone: 'Настройте на iPhone',
          chooseLearningContent: 'Выберите учебный контент...',
          chooseWordsOnIPhone: 'Выберите слова на iPhone',
          previous: 'Назад',
          next: 'Далее',
          onWatch: 'На часах',
        },
        'pt': <String, String>{
          today: 'Hoje',
          word: 'Palavra',
          phrase: 'Frase',
          words: 'Palavras',
          phrases: 'Frases',
          setUpOnIPhone: 'Configurar no iPhone',
          chooseLearningContent: 'Escolha o conteúdo de aprendizagem...',
          chooseWordsOnIPhone: 'Escolha palavras no iPhone',
          previous: 'Anterior',
          next: 'Seguinte',
          onWatch: 'No Watch',
        },
        'it': <String, String>{
          today: 'Oggi',
          word: 'Parola',
          phrase: 'Frase',
          words: 'Parole',
          phrases: 'Frasi',
          setUpOnIPhone: 'Configura su iPhone',
          chooseLearningContent: 'Scegli i contenuti di apprendimento...',
          chooseWordsOnIPhone: 'Scegli le parole su iPhone',
          previous: 'Precedente',
          next: 'Successivo',
          onWatch: 'Su Watch',
        },
        'ja': <String, String>{
          today: '今日',
          word: '単語',
          phrase: 'フレーズ',
          words: '単語',
          phrases: 'フレーズ',
          setUpOnIPhone: 'iPhoneで設定',
          chooseLearningContent: '学習コンテンツを選んでください...',
          chooseWordsOnIPhone: 'iPhoneで単語を選ぶ',
          previous: '前へ',
          next: '次へ',
          onWatch: 'Watch上',
        },
        'ko': <String, String>{
          today: '오늘',
          word: '단어',
          phrase: '표현',
          words: '단어',
          phrases: '표현',
          setUpOnIPhone: 'iPhone에서 설정',
          chooseLearningContent: '학습 콘텐츠를 선택하세요...',
          chooseWordsOnIPhone: 'iPhone에서 단어를 선택하세요',
          previous: '이전',
          next: '다음',
          onWatch: 'Watch에서',
        },
        'zh': <String, String>{
          today: '今天',
          word: '单词',
          phrase: '短语',
          words: '单词',
          phrases: '短语',
          setUpOnIPhone: '在 iPhone 上设置',
          chooseLearningContent: '选择学习内容...',
          chooseWordsOnIPhone: '在 iPhone 上选择单词',
          previous: '上一个',
          next: '下一个',
          onWatch: '在手表上',
        },
        'hi': <String, String>{
          today: 'आज',
          word: 'शब्द',
          phrase: 'वाक्यांश',
          words: 'शब्द',
          phrases: 'वाक्यांश',
          setUpOnIPhone: 'iPhone पर सेट अप करें',
          chooseLearningContent: 'अपनी सीखने की सामग्री चुनें...',
          chooseWordsOnIPhone: 'iPhone पर शब्द चुनें',
          previous: 'पिछला',
          next: 'अगला',
          onWatch: 'Watch पर',
        },
        'id': <String, String>{
          today: 'Hari ini',
          word: 'Kata',
          phrase: 'Frasa',
          words: 'Kata',
          phrases: 'Frasa',
          setUpOnIPhone: 'Atur di iPhone',
          chooseLearningContent: 'Pilih konten belajarmu...',
          chooseWordsOnIPhone: 'Pilih kata di iPhone',
          previous: 'Sebelumnya',
          next: 'Berikutnya',
          onWatch: 'Di Watch',
        },
        'fa': <String, String>{
          today: 'امروز',
          word: 'واژه',
          phrase: 'عبارت',
          words: 'واژه‌ها',
          phrases: 'عبارت‌ها',
          setUpOnIPhone: 'در iPhone راه‌اندازی کنید',
          chooseLearningContent: 'محتوای یادگیری را انتخاب کنید...',
          chooseWordsOnIPhone: 'واژه‌ها را در iPhone انتخاب کنید',
          previous: 'قبلی',
          next: 'بعدی',
          onWatch: 'روی ساعت',
        },
      };
}
