import SwiftUI

private struct WatchLearnerLanguageKey: EnvironmentKey {
    static let defaultValue = "en"
}

extension EnvironmentValues {
    var watchLearnerLanguage: String {
        get { self[WatchLearnerLanguageKey.self] }
        set { self[WatchLearnerLanguageKey.self] = WatchCopy.normalized(newValue) }
    }
}

/// Watch chrome follows the iPhone Translation Language, not the watchOS locale.
enum WatchCopy {
    enum Key: String, CaseIterable {
        case appMark = "watch.mark.app_name"
        case today = "watch.home.today"
        case word = "watch.content.word"
        case phrase = "watch.content.phrase"
        case words = "watch.content.words"
        case phrases = "watch.content.phrases"
        case setUpOnIPhone = "watch.empty.setup_on_iphone"
        case chooseLearningContent = "watch.empty.choose_content"
        case chooseWordsOnIPhone = "watch.empty.choose_words"
        case previous = "watch.action.previous"
        case next = "watch.action.next"
        case onWatch = "watch.status.on_watch"
    }

    static func string(_ key: Key, language: String) -> String {
        let code = normalized(language)
        if let value = tables[code]?[key.rawValue], !value.isEmpty {
            return value
        }
        return tables["en"]?[key.rawValue] ?? key.rawValue
    }

    static func contentType(isPhrase: Bool, language: String) -> String {
        string(isPhrase ? .phrase : .word, language: language)
    }

    static func normalized(_ language: String) -> String {
        let trimmed = language.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if trimmed.isEmpty {
            return "en"
        }
        let base = trimmed.split(separator: "-").first.map(String.init) ?? "en"
        return tables[base] == nil ? "en" : base
    }

    private static let tables: [String: [String: String]] = [
        "en": [
            "watch.mark.app_name": "Learn German",
            "watch.home.today": "Today",
            "watch.content.word": "Word",
            "watch.content.phrase": "Phrase",
            "watch.content.words": "Words",
            "watch.content.phrases": "Phrases",
            "watch.empty.setup_on_iphone": "Set up on iPhone",
            "watch.empty.choose_content": "Choose your learning content...",
            "watch.empty.choose_words": "Choose words on iPhone",
            "watch.action.previous": "Previous",
            "watch.action.next": "Next",
            "watch.status.on_watch": "On Watch",
        ],
        "tr": [
            "watch.mark.app_name": "Learn German",
            "watch.home.today": "Bugün",
            "watch.content.word": "Kelime",
            "watch.content.phrase": "İfade",
            "watch.content.words": "Kelimeler",
            "watch.content.phrases": "İfadeler",
            "watch.empty.setup_on_iphone": "iPhone’da kur",
            "watch.empty.choose_content": "Öğrenme içeriğini seç...",
            "watch.empty.choose_words": "Kelimeleri iPhone’dan seç",
            "watch.action.previous": "Önceki",
            "watch.action.next": "Sonraki",
            "watch.status.on_watch": "Saatte",
        ],
        "es": [
            "watch.mark.app_name": "Learn German",
            "watch.home.today": "Hoy",
            "watch.content.word": "Palabra",
            "watch.content.phrase": "Frase",
            "watch.content.words": "Palabras",
            "watch.content.phrases": "Frases",
            "watch.empty.setup_on_iphone": "Configurar en iPhone",
            "watch.empty.choose_content": "Elige tu contenido de aprendizaje...",
            "watch.empty.choose_words": "Elige palabras en el iPhone",
            "watch.action.previous": "Anterior",
            "watch.action.next": "Siguiente",
            "watch.status.on_watch": "En el Watch",
        ],
        "ar": [
            "watch.mark.app_name": "Learn German",
            "watch.home.today": "اليوم",
            "watch.content.word": "كلمة",
            "watch.content.phrase": "عبارة",
            "watch.content.words": "الكلمات",
            "watch.content.phrases": "العبارات",
            "watch.empty.setup_on_iphone": "الإعداد على iPhone",
            "watch.empty.choose_content": "اختر محتوى التعلم...",
            "watch.empty.choose_words": "اختر الكلمات على iPhone",
            "watch.action.previous": "السابق",
            "watch.action.next": "التالي",
            "watch.status.on_watch": "على الساعة",
        ],
        "fr": [
            "watch.mark.app_name": "Learn German",
            "watch.home.today": "Aujourd’hui",
            "watch.content.word": "Mot",
            "watch.content.phrase": "Phrase",
            "watch.content.words": "Mots",
            "watch.content.phrases": "Phrases",
            "watch.empty.setup_on_iphone": "Configurer sur iPhone",
            "watch.empty.choose_content": "Choisis ton contenu d’apprentissage...",
            "watch.empty.choose_words": "Choisis des mots sur iPhone",
            "watch.action.previous": "Précédent",
            "watch.action.next": "Suivant",
            "watch.status.on_watch": "Sur la Watch",
        ],
        "de": [
            "watch.mark.app_name": "Learn German",
            "watch.home.today": "Heute",
            "watch.content.word": "Wort",
            "watch.content.phrase": "Satz",
            "watch.content.words": "Wörter",
            "watch.content.phrases": "Sätze",
            "watch.empty.setup_on_iphone": "Auf iPhone einrichten",
            "watch.empty.choose_content": "Wähle deine Lerninhalte...",
            "watch.empty.choose_words": "Wörter auf dem iPhone wählen",
            "watch.action.previous": "Zurück",
            "watch.action.next": "Weiter",
            "watch.status.on_watch": "Auf der Watch",
        ],
        "ru": [
            "watch.mark.app_name": "Learn German",
            "watch.home.today": "Сегодня",
            "watch.content.word": "Слово",
            "watch.content.phrase": "Фраза",
            "watch.content.words": "Слова",
            "watch.content.phrases": "Фразы",
            "watch.empty.setup_on_iphone": "Настройте на iPhone",
            "watch.empty.choose_content": "Выберите учебный контент...",
            "watch.empty.choose_words": "Выберите слова на iPhone",
            "watch.action.previous": "Назад",
            "watch.action.next": "Далее",
            "watch.status.on_watch": "На часах",
        ],
        "pt": [
            "watch.mark.app_name": "Learn German",
            "watch.home.today": "Hoje",
            "watch.content.word": "Palavra",
            "watch.content.phrase": "Frase",
            "watch.content.words": "Palavras",
            "watch.content.phrases": "Frases",
            "watch.empty.setup_on_iphone": "Configurar no iPhone",
            "watch.empty.choose_content": "Escolha o conteúdo de aprendizagem...",
            "watch.empty.choose_words": "Escolha palavras no iPhone",
            "watch.action.previous": "Anterior",
            "watch.action.next": "Seguinte",
            "watch.status.on_watch": "No Watch",
        ],
        "it": [
            "watch.mark.app_name": "Learn German",
            "watch.home.today": "Oggi",
            "watch.content.word": "Parola",
            "watch.content.phrase": "Frase",
            "watch.content.words": "Parole",
            "watch.content.phrases": "Frasi",
            "watch.empty.setup_on_iphone": "Configura su iPhone",
            "watch.empty.choose_content": "Scegli i contenuti di apprendimento...",
            "watch.empty.choose_words": "Scegli le parole su iPhone",
            "watch.action.previous": "Precedente",
            "watch.action.next": "Successivo",
            "watch.status.on_watch": "Su Watch",
        ],
        "ja": [
            "watch.mark.app_name": "Learn German",
            "watch.home.today": "今日",
            "watch.content.word": "単語",
            "watch.content.phrase": "フレーズ",
            "watch.content.words": "単語",
            "watch.content.phrases": "フレーズ",
            "watch.empty.setup_on_iphone": "iPhoneで設定",
            "watch.empty.choose_content": "学習コンテンツを選んでください...",
            "watch.empty.choose_words": "iPhoneで単語を選ぶ",
            "watch.action.previous": "前へ",
            "watch.action.next": "次へ",
            "watch.status.on_watch": "Watch上",
        ],
        "ko": [
            "watch.mark.app_name": "Learn German",
            "watch.home.today": "오늘",
            "watch.content.word": "단어",
            "watch.content.phrase": "표현",
            "watch.content.words": "단어",
            "watch.content.phrases": "표현",
            "watch.empty.setup_on_iphone": "iPhone에서 설정",
            "watch.empty.choose_content": "학습 콘텐츠를 선택하세요...",
            "watch.empty.choose_words": "iPhone에서 단어를 선택하세요",
            "watch.action.previous": "이전",
            "watch.action.next": "다음",
            "watch.status.on_watch": "Watch에서",
        ],
        "zh": [
            "watch.mark.app_name": "Learn German",
            "watch.home.today": "今天",
            "watch.content.word": "单词",
            "watch.content.phrase": "短语",
            "watch.content.words": "单词",
            "watch.content.phrases": "短语",
            "watch.empty.setup_on_iphone": "在 iPhone 上设置",
            "watch.empty.choose_content": "选择学习内容...",
            "watch.empty.choose_words": "在 iPhone 上选择单词",
            "watch.action.previous": "上一个",
            "watch.action.next": "下一个",
            "watch.status.on_watch": "在手表上",
        ],
        "hi": [
            "watch.mark.app_name": "Learn German",
            "watch.home.today": "आज",
            "watch.content.word": "शब्द",
            "watch.content.phrase": "वाक्यांश",
            "watch.content.words": "शब्द",
            "watch.content.phrases": "वाक्यांश",
            "watch.empty.setup_on_iphone": "iPhone पर सेट अप करें",
            "watch.empty.choose_content": "अपनी सीखने की सामग्री चुनें...",
            "watch.empty.choose_words": "iPhone पर शब्द चुनें",
            "watch.action.previous": "पिछला",
            "watch.action.next": "अगला",
            "watch.status.on_watch": "Watch पर",
        ],
        "id": [
            "watch.mark.app_name": "Learn German",
            "watch.home.today": "Hari ini",
            "watch.content.word": "Kata",
            "watch.content.phrase": "Frasa",
            "watch.content.words": "Kata",
            "watch.content.phrases": "Frasa",
            "watch.empty.setup_on_iphone": "Atur di iPhone",
            "watch.empty.choose_content": "Pilih konten belajarmu...",
            "watch.empty.choose_words": "Pilih kata di iPhone",
            "watch.action.previous": "Sebelumnya",
            "watch.action.next": "Berikutnya",
            "watch.status.on_watch": "Di Watch",
        ],
        "fa": [
            "watch.mark.app_name": "Learn German",
            "watch.home.today": "امروز",
            "watch.content.word": "واژه",
            "watch.content.phrase": "عبارت",
            "watch.content.words": "واژه‌ها",
            "watch.content.phrases": "عبارت‌ها",
            "watch.empty.setup_on_iphone": "در iPhone راه‌اندازی کنید",
            "watch.empty.choose_content": "محتوای یادگیری را انتخاب کنید...",
            "watch.empty.choose_words": "واژه‌ها را در iPhone انتخاب کنید",
            "watch.action.previous": "قبلی",
            "watch.action.next": "بعدی",
            "watch.status.on_watch": "روی ساعت",
        ],
    ]
}
