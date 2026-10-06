import 'package:flutter/foundation.dart';
import 'package:lingo_core/core/l10n/learner_languages.dart';

/// One localized Home quote. Index alignment is the localization contract:
/// entry N in every language is the same daily quote.
@immutable
class HomeQuote {
  const HomeQuote({required this.text, required this.author});

  final String text;
  final String author;

  @override
  bool operator ==(Object other) {
    return other is HomeQuote && text == other.text && author == other.author;
  }

  @override
  int get hashCode => Object.hash(text, author);
}

/// Bundled Home quote tables.
abstract final class HomeMotivationL10n {
  static const int poolSize = 50;

  static List<HomeQuote> linesFor(String languageCode) {
    final String code = LearnerLanguages.baseCode(languageCode);
    return _tables[code] ?? english;
  }

  static const List<HomeQuote> english = <HomeQuote>[
    HomeQuote(
      text: 'The journey of a thousand miles begins with a single step.',
      author: 'Lao Tzu',
    ),
    HomeQuote(
      text: 'It always seems impossible until it is done.',
      author: 'Nelson Mandela',
    ),
    HomeQuote(
      text: 'The secret of getting ahead is getting started.',
      author: 'Mark Twain',
    ),
    HomeQuote(
      text: 'Little by little, one travels far.',
      author: 'J.R.R. Tolkien',
    ),
    HomeQuote(
      text: 'Do what you can, with what you have, where you are.',
      author: 'Theodore Roosevelt',
    ),
    HomeQuote(
      text: 'Change is the end result of all true learning.',
      author: 'Leo Buscaglia',
    ),
    HomeQuote(
      text: 'The beginning is the most important part of the work.',
      author: 'Plato',
    ),
    HomeQuote(
      text: 'Fall seven times and stand up eight.',
      author: 'Japanese proverb',
    ),
    HomeQuote(
      text: 'Start where you are. Use what you have. Do what you can.',
      author: 'Arthur Ashe',
    ),
    HomeQuote(
      text: 'Success is the sum of small efforts, repeated day after day.',
      author: 'Robert Collier',
    ),
    HomeQuote(
      text: 'We are what we repeatedly do. Excellence, then, is a habit.',
      author: 'Aristotle',
    ),
    HomeQuote(
      text: 'An investment in knowledge pays the best interest.',
      author: 'Benjamin Franklin',
    ),
    HomeQuote(
      text: 'Learning never exhausts the mind.',
      author: 'Leonardo da Vinci',
    ),
    HomeQuote(
      text: 'He who learns but does not think is lost.',
      author: 'Confucius',
    ),
    HomeQuote(
      text: 'To have another language is to possess a second soul.',
      author: 'Charlemagne',
    ),
    HomeQuote(
      text: 'The limits of my language mean the limits of my world.',
      author: 'Ludwig Wittgenstein',
    ),
    HomeQuote(
      text: 'Learning is a treasure that follows its owner everywhere.',
      author: 'Chinese proverb',
    ),
    HomeQuote(
      text:
          'Knowledge is a garden: if it is not cultivated, it cannot be harvested.',
      author: 'African proverb',
    ),
    HomeQuote(
      text:
          'The beautiful thing about learning is that no one can take it from you.',
      author: 'B.B. King',
    ),
    HomeQuote(
      text: 'Believe you can and you are halfway there.',
      author: 'Theodore Roosevelt',
    ),
    HomeQuote(
      text: 'There is no substitute for hard work.',
      author: 'Thomas Edison',
    ),
    HomeQuote(
      text:
          'Genius is one percent inspiration and ninety-nine percent perspiration.',
      author: 'Thomas Edison',
    ),
    HomeQuote(
      text: 'Energy and persistence conquer all things.',
      author: 'Benjamin Franklin',
    ),
    HomeQuote(
      text:
          'The best time to plant a tree was twenty years ago. The second best time is now.',
      author: 'Chinese proverb',
    ),
    HomeQuote(
      text:
          'If you want to go fast, go alone. If you want to go far, go together.',
      author: 'African proverb',
    ),
    HomeQuote(
      text: 'A river cuts through rock not by power, but by persistence.',
      author: 'James N. Watkins',
    ),
    HomeQuote(
      text: 'Small deeds done are better than great deeds planned.',
      author: 'Peter Marshall',
    ),
    HomeQuote(
      text: "Don't watch the clock; do what it does. Keep going.",
      author: 'Sam Levenson',
    ),
    HomeQuote(
      text: "Whether you think you can or you think you can't, you are right.",
      author: 'Henry Ford',
    ),
    HomeQuote(
      text: 'In the middle of difficulty lies opportunity.',
      author: 'Albert Einstein',
    ),
    HomeQuote(
      text:
          'Education is the most powerful weapon you can use to change the world.',
      author: 'Nelson Mandela',
    ),
    HomeQuote(
      text: 'A different language is a different vision of life.',
      author: 'Federico Fellini',
    ),
    HomeQuote(
      text: 'Practice is the best of all instructors.',
      author: 'Publilius Syrus',
    ),
    HomeQuote(
      text: 'It does not matter how slowly you go as long as you do not stop.',
      author: 'Confucius',
    ),
    HomeQuote(
      text: "Real knowledge is to know the extent of one's ignorance.",
      author: 'Confucius',
    ),
    HomeQuote(
      text: 'The roots of education are bitter, but the fruit is sweet.',
      author: 'Aristotle',
    ),
    HomeQuote(
      text:
          'Live as if you were to die tomorrow. Learn as if you were to live forever.',
      author: 'Mahatma Gandhi',
    ),
    HomeQuote(
      text:
          'Be not afraid of growing slowly, be afraid only of standing still.',
      author: 'Chinese proverb',
    ),
    HomeQuote(text: 'Nothing will work unless you do.', author: 'Maya Angelou'),
    HomeQuote(
      text: 'The only true wisdom is in knowing you know nothing.',
      author: 'Socrates',
    ),
    HomeQuote(
      text: 'Chance favors the prepared mind.',
      author: 'Louis Pasteur',
    ),
    HomeQuote(
      text: 'What we learn with pleasure we never forget.',
      author: 'Alfred Mercier',
    ),
    HomeQuote(
      text: 'A book is a garden carried in the pocket.',
      author: 'Arabian proverb',
    ),
    HomeQuote(
      text: 'The palest ink is better than the best memory.',
      author: 'Chinese proverb',
    ),
    HomeQuote(
      text: 'Patience is bitter, but its fruit is sweet.',
      author: 'Aristotle',
    ),
    HomeQuote(
      text: 'By learning you will teach; by teaching you will learn.',
      author: 'Latin proverb',
    ),
    HomeQuote(
      text: 'Not knowing is bad; not wishing to know is worse.',
      author: 'Nigerian proverb',
    ),
    HomeQuote(
      text: 'The expert in anything was once a beginner.',
      author: 'Helen Hayes',
    ),
    HomeQuote(
      text:
          'You do not have to be great to start, but you have to start to be great.',
      author: 'Zig Ziglar',
    ),
    HomeQuote(
      text:
          'One language sets you in a corridor for life. Two languages open every door.',
      author: 'Frank Smith',
    ),
  ];

  static const List<HomeQuote> turkish = <HomeQuote>[
    HomeQuote(
      text: 'Bin millik yolculuk tek bir adımla başlar.',
      author: 'Lao Tzu',
    ),
    HomeQuote(
      text: 'İş bitene kadar her şey imkânsız görünür.',
      author: 'Nelson Mandela',
    ),
    HomeQuote(text: 'İlerlemenin sırrı başlamaktır.', author: 'Mark Twain'),
    HomeQuote(
      text: 'Azar azar gidilir, ama uzaklara varılır.',
      author: 'J.R.R. Tolkien',
    ),
    HomeQuote(
      text: 'Elinden geleni, elindekilerle, bulunduğun yerde yap.',
      author: 'Theodore Roosevelt',
    ),
    HomeQuote(
      text: 'Değişim, gerçek öğrenmenin sonucudur.',
      author: 'Leo Buscaglia',
    ),
    HomeQuote(text: 'İşin en önemli kısmı başlamaktır.', author: 'Platon'),
    HomeQuote(text: 'Yedi kez düş, sekiz kez kalk.', author: 'Japon atasözü'),
    HomeQuote(
      text: 'Olduğun yerden başla. Elindekini kullan. Yapabildiğini yap.',
      author: 'Arthur Ashe',
    ),
    HomeQuote(
      text: 'Başarı, her gün tekrarlanan küçük çabaların toplamıdır.',
      author: 'Robert Collier',
    ),
    HomeQuote(
      text: 'Tekrar tekrar yaptığımız şeyiz. Mükemmellik bir alışkanlıktır.',
      author: 'Aristoteles',
    ),
    HomeQuote(
      text: 'Bilgiye yapılan yatırım en iyi faizi öder.',
      author: 'Benjamin Franklin',
    ),
    HomeQuote(
      text: 'Öğrenmek zihni asla tüketmez.',
      author: 'Leonardo da Vinci',
    ),
    HomeQuote(text: 'Öğrenip düşünmeyen kişi kaybolur.', author: 'Konfüçyüs'),
    HomeQuote(
      text: 'Başka bir dile sahip olmak ikinci bir ruha sahip olmaktır.',
      author: 'Charlemagne',
    ),
    HomeQuote(
      text: 'Dilimizin sınırları, dünyamızın sınırlarıdır.',
      author: 'Ludwig Wittgenstein',
    ),
    HomeQuote(
      text: 'Öğrenmek, sahibini her yere takip eden bir hazinedir.',
      author: 'Çin atasözü',
    ),
    HomeQuote(
      text: 'Bilgi bir bahçedir: işlenmezse hasat edilemez.',
      author: 'Afrika atasözü',
    ),
    HomeQuote(
      text: 'Öğrenmenin güzelliği, kimsenin onu senden alamamasıdır.',
      author: 'B.B. King',
    ),
    HomeQuote(
      text: 'Yapabileceğine inan; yolun yarısındasın.',
      author: 'Theodore Roosevelt',
    ),
    HomeQuote(
      text: 'Sıkı çalışmanın yerini hiçbir şey tutamaz.',
      author: 'Thomas Edison',
    ),
    HomeQuote(
      text: 'Deha yüzde bir ilham, yüzde doksan dokuz terdir.',
      author: 'Thomas Edison',
    ),
    HomeQuote(
      text: 'Enerji ve sebat her şeyi yener.',
      author: 'Benjamin Franklin',
    ),
    HomeQuote(
      text:
          'Bir ağaç dikmek için en iyi zaman yirmi yıl önceydi. İkinci en iyi zaman şimdi.',
      author: 'Çin atasözü',
    ),
    HomeQuote(
      text:
          'Hızlı gitmek istiyorsan yalnız git. Uzağa gitmek istiyorsan birlikte git.',
      author: 'Afrika atasözü',
    ),
    HomeQuote(
      text: 'Nehir kayayı gücüyle değil, sebatıyla yarar.',
      author: 'James N. Watkins',
    ),
    HomeQuote(
      text: 'Yapılmış küçük işler, planlanmış büyük işlerden iyidir.',
      author: 'Peter Marshall',
    ),
    HomeQuote(
      text: 'Saate bakma; onun yaptığını yap. Devam et.',
      author: 'Sam Levenson',
    ),
    HomeQuote(
      text: 'Yapabilirim ya da yapamam dersen, ikisinde de haklısın.',
      author: 'Henry Ford',
    ),
    HomeQuote(
      text: 'Zorluğun tam ortasında fırsat yatar.',
      author: 'Albert Einstein',
    ),
    HomeQuote(
      text:
          'Eğitim, dünyayı değiştirmek için kullanabileceğin en güçlü silahtır.',
      author: 'Nelson Mandela',
    ),
    HomeQuote(
      text: 'Farklı bir dil, hayata farklı bir bakıştır.',
      author: 'Federico Fellini',
    ),
    HomeQuote(
      text: 'Alıştırmak, bütün öğretmenlerin en iyisidir.',
      author: 'Publilius Syrus',
    ),
    HomeQuote(
      text: 'Ne kadar yavaş gittiğin önemli değil, yeter ki durma.',
      author: 'Konfüçyüs',
    ),
    HomeQuote(
      text: 'Gerçek bilgi, bilgisizliğinin sınırını bilmektir.',
      author: 'Konfüçyüs',
    ),
    HomeQuote(
      text: 'Eğitimin kökleri acıdır, ama meyvesi tatlıdır.',
      author: 'Aristoteles',
    ),
    HomeQuote(
      text: 'Yarın ölecekmiş gibi yaşa. Sonsuza dek yaşayacakmış gibi öğren.',
      author: 'Mahatma Gandhi',
    ),
    HomeQuote(
      text: 'Yavaş büyümekten korkma; durup kalmaktan kork.',
      author: 'Çin atasözü',
    ),
    HomeQuote(
      text: 'Sen çalışmazsan hiçbir şey işe yaramaz.',
      author: 'Maya Angelou',
    ),
    HomeQuote(
      text: 'Tek gerçek bilgelik, hiçbir şey bilmediğini bilmektir.',
      author: 'Sokrates',
    ),
    HomeQuote(
      text: 'Şans, hazırlıklı zihnin yanındadır.',
      author: 'Louis Pasteur',
    ),
    HomeQuote(
      text: 'Zevkle öğrendiğimizi asla unutmayız.',
      author: 'Alfred Mercier',
    ),
    HomeQuote(
      text: 'Kitap, cepte taşınan bir bahçedir.',
      author: 'Arap atasözü',
    ),
    HomeQuote(
      text: 'En soluk mürekkep, en iyi bellekten üstündür.',
      author: 'Çin atasözü',
    ),
    HomeQuote(
      text: 'Sabır acıdır, ama meyvesi tatlıdır.',
      author: 'Aristoteles',
    ),
    HomeQuote(
      text: 'Öğrenerek öğretirsin; öğreterek öğrenirsin.',
      author: 'Latin atasözü',
    ),
    HomeQuote(
      text: 'Bilmemek kötüdür; öğrenmek istememek daha kötüdür.',
      author: 'Nijerya atasözü',
    ),
    HomeQuote(
      text: 'Her alandaki uzman bir zamanlar yeni başlayandı.',
      author: 'Helen Hayes',
    ),
    HomeQuote(
      text:
          'Başlamak için büyük olmana gerek yok; büyük olmak için başlamalısın.',
      author: 'Zig Ziglar',
    ),
    HomeQuote(
      text:
          'Bir dil seni hayat boyu bir koridora koyar. İki dil her kapıyı açar.',
      author: 'Frank Smith',
    ),
  ];

  static const List<HomeQuote> spanish = <HomeQuote>[
    HomeQuote(
      text: 'El viaje de mil millas comienza con un solo paso.',
      author: 'Lao Tse',
    ),
    HomeQuote(
      text: 'Siempre parece imposible hasta que se hace.',
      author: 'Nelson Mandela',
    ),
    HomeQuote(text: 'El secreto de avanzar es empezar.', author: 'Mark Twain'),
    HomeQuote(text: 'Poco a poco se llega lejos.', author: 'J.R.R. Tolkien'),
    HomeQuote(
      text: 'Haz lo que puedas, con lo que tengas, donde estés.',
      author: 'Theodore Roosevelt',
    ),
    HomeQuote(
      text: 'El cambio es el resultado de todo aprendizaje verdadero.',
      author: 'Leo Buscaglia',
    ),
    HomeQuote(
      text: 'El comienzo es la parte más importante del trabajo.',
      author: 'Platón',
    ),
    HomeQuote(
      text: 'Cae siete veces y levántate ocho.',
      author: 'Proverbio japonés',
    ),
    HomeQuote(
      text: 'Empieza donde estás. Usa lo que tienes. Haz lo que puedas.',
      author: 'Arthur Ashe',
    ),
    HomeQuote(
      text: 'El éxito es la suma de pequeños esfuerzos, repetidos cada día.',
      author: 'Robert Collier',
    ),
    HomeQuote(
      text: 'Somos lo que hacemos una y otra vez. La excelencia es un hábito.',
      author: 'Aristóteles',
    ),
    HomeQuote(
      text: 'Una inversión en conocimiento paga el mejor interés.',
      author: 'Benjamin Franklin',
    ),
    HomeQuote(
      text: 'Aprender nunca agota la mente.',
      author: 'Leonardo da Vinci',
    ),
    HomeQuote(
      text: 'Quien aprende y no piensa, se pierde.',
      author: 'Confucio',
    ),
    HomeQuote(
      text: 'Tener otra lengua es poseer una segunda alma.',
      author: 'Carlomagno',
    ),
    HomeQuote(
      text: 'Los límites de mi lenguaje son los límites de mi mundo.',
      author: 'Ludwig Wittgenstein',
    ),
    HomeQuote(
      text: 'El aprendizaje es un tesoro que sigue a su dueño a todas partes.',
      author: 'Proverbio chino',
    ),
    HomeQuote(
      text: 'El saber es un jardín: si no se cultiva, no se cosecha.',
      author: 'Proverbio africano',
    ),
    HomeQuote(
      text: 'Lo bello de aprender es que nadie puede quitártelo.',
      author: 'B.B. King',
    ),
    HomeQuote(
      text: 'Cree que puedes y ya estás a mitad de camino.',
      author: 'Theodore Roosevelt',
    ),
    HomeQuote(
      text: 'No hay sustituto para el trabajo duro.',
      author: 'Thomas Edison',
    ),
    HomeQuote(
      text:
          'El genio es un uno por ciento de inspiración y un noventa y nueve de transpiración.',
      author: 'Thomas Edison',
    ),
    HomeQuote(
      text: 'La energía y la perseverancia lo conquistan todo.',
      author: 'Benjamin Franklin',
    ),
    HomeQuote(
      text:
          'El mejor momento para plantar un árbol fue hace veinte años. El segundo mejor es ahora.',
      author: 'Proverbio chino',
    ),
    HomeQuote(
      text:
          'Si quieres ir rápido, ve solo. Si quieres llegar lejos, ve acompañado.',
      author: 'Proverbio africano',
    ),
    HomeQuote(
      text: 'El río corta la roca no por su fuerza, sino por su constancia.',
      author: 'James N. Watkins',
    ),
    HomeQuote(
      text:
          'Los pequeños actos hechos valen más que los grandes actos planeados.',
      author: 'Peter Marshall',
    ),
    HomeQuote(
      text: 'No mires el reloj; haz lo que él hace. Sigue.',
      author: 'Sam Levenson',
    ),
    HomeQuote(
      text: 'Tanto si crees que puedes como si crees que no, tienes razón.',
      author: 'Henry Ford',
    ),
    HomeQuote(
      text: 'En medio de la dificultad reside la oportunidad.',
      author: 'Albert Einstein',
    ),
    HomeQuote(
      text:
          'La educación es el arma más poderosa que puedes usar para cambiar el mundo.',
      author: 'Nelson Mandela',
    ),
    HomeQuote(
      text: 'Una lengua distinta es una visión distinta de la vida.',
      author: 'Federico Fellini',
    ),
    HomeQuote(
      text: 'La práctica es la mejor de todas las maestras.',
      author: 'Publilio Siro',
    ),
    HomeQuote(
      text: 'No importa lo despacio que vayas, mientras no te detengas.',
      author: 'Confucio',
    ),
    HomeQuote(
      text: 'El verdadero saber es conocer el alcance de la propia ignorancia.',
      author: 'Confucio',
    ),
    HomeQuote(
      text: 'Las raíces de la educación son amargas, pero su fruto es dulce.',
      author: 'Aristóteles',
    ),
    HomeQuote(
      text:
          'Vive como si fueras a morir mañana. Aprende como si fueras a vivir para siempre.',
      author: 'Mahatma Gandhi',
    ),
    HomeQuote(
      text: 'No temas crecer despacio; teme tan solo quedarte quieto.',
      author: 'Proverbio chino',
    ),
    HomeQuote(
      text: 'Nada funcionará a menos que tú lo hagas.',
      author: 'Maya Angelou',
    ),
    HomeQuote(
      text: 'La única sabiduría verdadera es saber que no sabes nada.',
      author: 'Sócrates',
    ),
    HomeQuote(
      text: 'La suerte favorece a la mente preparada.',
      author: 'Louis Pasteur',
    ),
    HomeQuote(
      text: 'Lo que aprendemos con gusto no lo olvidamos jamás.',
      author: 'Alfred Mercier',
    ),
    HomeQuote(
      text: 'Un libro es un jardín que se lleva en el bolsillo.',
      author: 'Proverbio árabe',
    ),
    HomeQuote(
      text: 'La tinta más pálida vale más que la mejor memoria.',
      author: 'Proverbio chino',
    ),
    HomeQuote(
      text: 'La paciencia es amarga, pero su fruto es dulce.',
      author: 'Aristóteles',
    ),
    HomeQuote(
      text: 'Al aprender enseñarás; al enseñar aprenderás.',
      author: 'Proverbio latino',
    ),
    HomeQuote(
      text: 'No saber es malo; no desear saber es peor.',
      author: 'Proverbio nigeriano',
    ),
    HomeQuote(
      text: 'El experto en cualquier cosa fue una vez un principiante.',
      author: 'Helen Hayes',
    ),
    HomeQuote(
      text:
          'No tienes que ser grande para empezar, pero tienes que empezar para ser grande.',
      author: 'Zig Ziglar',
    ),
    HomeQuote(
      text:
          'Un idioma te coloca en un pasillo de por vida. Dos idiomas abren todas las puertas.',
      author: 'Frank Smith',
    ),
  ];

  static const List<HomeQuote> arabic = <HomeQuote>[
    HomeQuote(text: 'رحلة الألف ميل تبدأ بخطوة واحدة.', author: 'لاو تزو'),
    HomeQuote(
      text: 'يبدو الأمر مستحيلاً دائماً حتى يُنجَز.',
      author: 'نيلسون مانديلا',
    ),
    HomeQuote(text: 'سر التقدّم هو أن تبدأ.', author: 'مارك توين'),
    HomeQuote(
      text: 'قليلاً قليلاً يبلغ المرء البعيد.',
      author: 'ج. ر. ر. تولكين',
    ),
    HomeQuote(
      text: 'افعل ما تستطيع، بما لديك، حيث أنت.',
      author: 'ثيودور روزفلت',
    ),
    HomeQuote(text: 'التغيير هو نتيجة كل تعلم حقيقي.', author: 'ليو بوسكاليا'),
    HomeQuote(text: 'البداية أهم جزء في العمل.', author: 'أفلاطون'),
    HomeQuote(text: 'اسقط سبع مرات وقم في الثامنة.', author: 'مثل ياباني'),
    HomeQuote(
      text: 'ابدأ حيث أنت. استخدم ما لديك. افعل ما تستطيع.',
      author: 'آرثر آش',
    ),
    HomeQuote(
      text: 'النجاح مجموع جهود صغيرة تتكرر يوماً بعد يوم.',
      author: 'روبرت كولير',
    ),
    HomeQuote(text: 'نحن ما نكرره. التميّز إذن عادة.', author: 'أرسطو'),
    HomeQuote(
      text: 'الاستثمار في المعرفة يدفع أفضل فائدة.',
      author: 'بنجامين فرانكلين',
    ),
    HomeQuote(
      text: 'التعلم لا يُرهق العقل أبداً.',
      author: 'ليوناردو دا فينشي',
    ),
    HomeQuote(text: 'من يتعلم ولا يفكر فهو ضائع.', author: 'كونفوشيوس'),
    HomeQuote(text: 'امتلاك لغة أخرى امتلاك لروح ثانية.', author: 'شارلمان'),
    HomeQuote(text: 'حدود لغتي هي حدود عالمي.', author: 'لودفيغ فيتغنشتاين'),
    HomeQuote(text: 'التعلم كنز يتبع صاحبه أينما ذهب.', author: 'مثل صيني'),
    HomeQuote(
      text: 'المعرفة حديقة: إن لم تُزرع لم تُحصد.',
      author: 'مثل أفريقي',
    ),
    HomeQuote(
      text: 'جمال التعلم أن لا أحد يستطيع أن يأخذه منك.',
      author: 'بي. بي. كينغ',
    ),
    HomeQuote(
      text: 'آمن بأنك قادر، وقد قطعت نصف الطريق.',
      author: 'ثيودور روزفلت',
    ),
    HomeQuote(text: 'لا بديل عن العمل الجاد.', author: 'توماس إديسون'),
    HomeQuote(
      text: 'العبقرية واحد في المئة إلهام وتسعة وتسعون عرقاً.',
      author: 'توماس إديسون',
    ),
    HomeQuote(
      text: 'الطاقة والمثابرة يقهران كل شيء.',
      author: 'بنجامين فرانكلين',
    ),
    HomeQuote(
      text: 'أفضل وقت لغرس شجرة كان قبل عشرين عاماً. وثاني أفضل وقت هو الآن.',
      author: 'مثل صيني',
    ),
    HomeQuote(
      text: 'إن أردت السرعة فاذهب وحدك. وإن أردت البعيد فاذهب معاً.',
      author: 'مثل أفريقي',
    ),
    HomeQuote(
      text: 'النهر يشق الصخر لا بقوته بل بمثابرته.',
      author: 'جيمس ن. واتكنز',
    ),
    HomeQuote(
      text: 'الأعمال الصغيرة المنجزة خير من الأعمال الكبيرة المخططة.',
      author: 'بيتر مارشال',
    ),
    HomeQuote(
      text: 'لا تراقب الساعة؛ افعل ما تفعله. استمر.',
      author: 'سام ليفنسون',
    ),
    HomeQuote(
      text: 'سواء ظننت أنك تستطيع أو لا تستطيع، فأنت على حق.',
      author: 'هنري فورد',
    ),
    HomeQuote(text: 'في قلب الصعوبة تكمن الفرصة.', author: 'ألبرت أينشتاين'),
    HomeQuote(
      text: 'التعليم أقوى سلاح يمكنك استخدامه لتغيير العالم.',
      author: 'نيلسون مانديلا',
    ),
    HomeQuote(
      text: 'لغة مختلفة رؤية مختلفة للحياة.',
      author: 'فيديريكو فيليني',
    ),
    HomeQuote(
      text: 'الممارسة أفضل المعلمين جميعاً.',
      author: 'بوبليليوس سيروس',
    ),
    HomeQuote(text: 'لا يهم كم تبطئ ما دمت لا تتوقف.', author: 'كونفوشيوس'),
    HomeQuote(text: 'المعرفة الحقيقية أن تعرف مدى جهلك.', author: 'كونفوشيوس'),
    HomeQuote(text: 'جذور التعليم مرّة، أما ثمرتها فحُلوة.', author: 'أرسطو'),
    HomeQuote(
      text: 'عِش كأنك تموت غداً. وتعلّم كأنك تحيا إلى الأبد.',
      author: 'المهاتما غاندي',
    ),
    HomeQuote(
      text: 'لا تخف من النمو البطيء، خف فقط من الوقوف.',
      author: 'مثل صيني',
    ),
    HomeQuote(text: 'لن ينجح شيء ما لم تعمل أنت.', author: 'مايا أنجيلو'),
    HomeQuote(
      text: 'الحكمة الحقة الوحيدة أن تعلم أنك لا تعلم شيئاً.',
      author: 'سقراط',
    ),
    HomeQuote(text: 'الحظ يحالف العقل المستعد.', author: 'لويس باستور'),
    HomeQuote(text: 'ما نتعلمه بسرور لا ننساه أبداً.', author: 'ألفريد مرسييه'),
    HomeQuote(text: 'الكتاب حديقة تُحمَل في الجيب.', author: 'مثل عربي'),
    HomeQuote(text: 'أبهت الحبر خير من أقوى ذاكرة.', author: 'مثل صيني'),
    HomeQuote(text: 'الصبر مرّ، أما ثمرته فحُلوة.', author: 'أرسطو'),
    HomeQuote(text: 'بالتعلم تعلّم؛ وبالتعليم تتعلم.', author: 'مثل لاتيني'),
    HomeQuote(
      text: 'الجهل سيئ؛ وعدم الرغبة في المعرفة أسوأ.',
      author: 'مثل نيجيري',
    ),
    HomeQuote(
      text: 'الخبير في أي شيء كان مبتدئاً يوماً.',
      author: 'هيلين هايز',
    ),
    HomeQuote(
      text: 'لا يلزم أن تكون عظيماً لتبدأ، لكن يلزم أن تبدأ لتصبح عظيماً.',
      author: 'زيغ زيغلر',
    ),
    HomeQuote(
      text: 'لغة واحدة تضعك في ممر مدى الحياة. ولغتان تفتحان كل باب.',
      author: 'فرانك سميث',
    ),
  ];

  static const List<HomeQuote> french = <HomeQuote>[
    HomeQuote(
      text: 'Un voyage de mille lieues commence par un seul pas.',
      author: 'Lao Tseu',
    ),
    HomeQuote(
      text: 'Cela semble toujours impossible jusqu’à ce que ce soit fait.',
      author: 'Nelson Mandela',
    ),
    HomeQuote(
      text: 'Le secret d’avancer, c’est de commencer.',
      author: 'Mark Twain',
    ),
    HomeQuote(text: 'Petit à petit, on va loin.', author: 'J.R.R. Tolkien'),
    HomeQuote(
      text: 'Fais ce que tu peux, avec ce que tu as, là où tu es.',
      author: 'Theodore Roosevelt',
    ),
    HomeQuote(
      text: 'Le changement est le fruit de tout vrai apprentissage.',
      author: 'Leo Buscaglia',
    ),
    HomeQuote(
      text: 'Le commencement est la partie la plus importante du travail.',
      author: 'Platon',
    ),
    HomeQuote(
      text: 'Tombe sept fois, relève-toi huit.',
      author: 'Proverbe japonais',
    ),
    HomeQuote(
      text: 'Commence où tu es. Utilise ce que tu as. Fais ce que tu peux.',
      author: 'Arthur Ashe',
    ),
    HomeQuote(
      text: 'Le succès est la somme de petits efforts, répétés chaque jour.',
      author: 'Robert Collier',
    ),
    HomeQuote(
      text: 'Nous sommes ce que nous répétons. L’excellence est une habitude.',
      author: 'Aristote',
    ),
    HomeQuote(
      text: 'Un investissement dans le savoir paie le meilleur intérêt.',
      author: 'Benjamin Franklin',
    ),
    HomeQuote(
      text: 'Apprendre n’épuise jamais l’esprit.',
      author: 'Léonard de Vinci',
    ),
    HomeQuote(
      text: 'Celui qui apprend sans penser est perdu.',
      author: 'Confucius',
    ),
    HomeQuote(
      text: 'Posséder une autre langue, c’est posséder une seconde âme.',
      author: 'Charlemagne',
    ),
    HomeQuote(
      text: 'Les limites de mon langage sont les limites de mon monde.',
      author: 'Ludwig Wittgenstein',
    ),
    HomeQuote(
      text: 'Apprendre est un trésor qui suit son maître partout.',
      author: 'Proverbe chinois',
    ),
    HomeQuote(
      text:
          'Le savoir est un jardin : s’il n’est pas cultivé, on ne le récolte pas.',
      author: 'Proverbe africain',
    ),
    HomeQuote(
      text: 'La beauté d’apprendre, c’est que personne ne peut te l’enlever.',
      author: 'B.B. King',
    ),
    HomeQuote(
      text: 'Crois que tu peux, et tu as déjà fait la moitié du chemin.',
      author: 'Theodore Roosevelt',
    ),
    HomeQuote(text: 'Rien ne remplace le travail.', author: 'Thomas Edison'),
    HomeQuote(
      text:
          'Le génie est un pour cent d’inspiration et quatre-vingt-dix-neuf de transpiration.',
      author: 'Thomas Edison',
    ),
    HomeQuote(
      text: 'L’énergie et la persévérance viennent à bout de tout.',
      author: 'Benjamin Franklin',
    ),
    HomeQuote(
      text:
          'Le meilleur moment pour planter un arbre, c’était il y a vingt ans. Le deuxième meilleur, c’est maintenant.',
      author: 'Proverbe chinois',
    ),
    HomeQuote(
      text:
          'Si tu veux aller vite, vas-y seul. Si tu veux aller loin, vas-y ensemble.',
      author: 'Proverbe africain',
    ),
    HomeQuote(
      text: 'La rivière fend la roche non par sa force, mais par sa constance.',
      author: 'James N. Watkins',
    ),
    HomeQuote(
      text:
          'Les petits actes faits valent mieux que les grands actes projetés.',
      author: 'Peter Marshall',
    ),
    HomeQuote(
      text: 'Ne regarde pas l’horloge ; fais ce qu’elle fait. Continue.',
      author: 'Sam Levenson',
    ),
    HomeQuote(
      text: 'Que tu penses pouvoir ou ne pas pouvoir, tu as raison.',
      author: 'Henry Ford',
    ),
    HomeQuote(
      text: 'Au milieu de la difficulté se trouve l’opportunité.',
      author: 'Albert Einstein',
    ),
    HomeQuote(
      text:
          'L’éducation est l’arme la plus puissante que tu puisses utiliser pour changer le monde.',
      author: 'Nelson Mandela',
    ),
    HomeQuote(
      text: 'Une autre langue est une autre vision de la vie.',
      author: 'Federico Fellini',
    ),
    HomeQuote(
      text: 'La pratique est la meilleure de toutes les maîtresses.',
      author: 'Publilius Syrus',
    ),
    HomeQuote(
      text: 'Peu importe la lenteur, pourvu que tu ne t’arrêtes pas.',
      author: 'Confucius',
    ),
    HomeQuote(
      text: 'Le vrai savoir est de connaître l’étendue de son ignorance.',
      author: 'Confucius',
    ),
    HomeQuote(
      text:
          'Les racines de l’éducation sont amères, mais le fruit en est doux.',
      author: 'Aristote',
    ),
    HomeQuote(
      text:
          'Vis comme si tu devais mourir demain. Apprends comme si tu devais vivre toujours.',
      author: 'Mahatma Gandhi',
    ),
    HomeQuote(
      text:
          'Ne crains pas de grandir lentement ; crains seulement de rester immobile.',
      author: 'Proverbe chinois',
    ),
    HomeQuote(
      text: 'Rien ne marchera si tu ne le fais pas.',
      author: 'Maya Angelou',
    ),
    HomeQuote(
      text: 'La seule vraie sagesse est de savoir que l’on ne sait rien.',
      author: 'Socrate',
    ),
    HomeQuote(
      text: 'La chance sourit à l’esprit préparé.',
      author: 'Louis Pasteur',
    ),
    HomeQuote(
      text: 'Ce que nous apprenons avec plaisir, nous ne l’oublions jamais.',
      author: 'Alfred Mercier',
    ),
    HomeQuote(
      text: 'Un livre est un jardin que l’on porte dans sa poche.',
      author: 'Proverbe arabe',
    ),
    HomeQuote(
      text: 'L’encre la plus pâle vaut mieux que la meilleure mémoire.',
      author: 'Proverbe chinois',
    ),
    HomeQuote(
      text: 'La patience est amère, mais son fruit est doux.',
      author: 'Aristote',
    ),
    HomeQuote(
      text: 'En apprenant tu enseigneras ; en enseignant tu apprendras.',
      author: 'Proverbe latin',
    ),
    HomeQuote(
      text: 'Ne pas savoir est mauvais ; ne pas vouloir savoir est pire.',
      author: 'Proverbe nigérian',
    ),
    HomeQuote(
      text: 'L’expert en toute chose fut d’abord un débutant.',
      author: 'Helen Hayes',
    ),
    HomeQuote(
      text:
          'Tu n’as pas besoin d’être grand pour commencer, mais tu dois commencer pour devenir grand.',
      author: 'Zig Ziglar',
    ),
    HomeQuote(
      text:
          'Une langue te place dans un couloir pour la vie. Deux langues ouvrent toutes les portes.',
      author: 'Frank Smith',
    ),
  ];

  static const List<HomeQuote> german = <HomeQuote>[
    HomeQuote(
      text: 'Eine Reise von tausend Meilen beginnt mit einem einzigen Schritt.',
      author: 'Laozi',
    ),
    HomeQuote(
      text: 'Es scheint immer unmöglich, bis es getan ist.',
      author: 'Nelson Mandela',
    ),
    HomeQuote(
      text: 'Das Geheimnis des Vorankommens ist anzufangen.',
      author: 'Mark Twain',
    ),
    HomeQuote(
      text: 'Stück für Stück kommt man weit.',
      author: 'J.R.R. Tolkien',
    ),
    HomeQuote(
      text: 'Tu, was du kannst, mit dem, was du hast, dort wo du bist.',
      author: 'Theodore Roosevelt',
    ),
    HomeQuote(
      text: 'Veränderung ist das Ergebnis allen echten Lernens.',
      author: 'Leo Buscaglia',
    ),
    HomeQuote(
      text: 'Der Anfang ist der wichtigste Teil der Arbeit.',
      author: 'Platon',
    ),
    HomeQuote(
      text: 'Falle siebenmal und stehe achtmal auf.',
      author: 'Japanisches Sprichwort',
    ),
    HomeQuote(
      text: 'Fang dort an, wo du bist. Nutze, was du hast. Tu, was du kannst.',
      author: 'Arthur Ashe',
    ),
    HomeQuote(
      text:
          'Erfolg ist die Summe kleiner Anstrengungen, Tag für Tag wiederholt.',
      author: 'Robert Collier',
    ),
    HomeQuote(
      text: 'Wir sind, was wir wiederholt tun. Exzellenz ist eine Gewohnheit.',
      author: 'Aristoteles',
    ),
    HomeQuote(
      text: 'Eine Investition in Wissen zahlt die besten Zinsen.',
      author: 'Benjamin Franklin',
    ),
    HomeQuote(
      text: 'Lernen erschöpft den Geist nie.',
      author: 'Leonardo da Vinci',
    ),
    HomeQuote(
      text: 'Wer lernt und nicht denkt, ist verloren.',
      author: 'Konfuzius',
    ),
    HomeQuote(
      text:
          'Eine andere Sprache zu haben heißt, eine zweite Seele zu besitzen.',
      author: 'Karl der Große',
    ),
    HomeQuote(
      text: 'Die Grenzen meiner Sprache bedeuten die Grenzen meiner Welt.',
      author: 'Ludwig Wittgenstein',
    ),
    HomeQuote(
      text: 'Lernen ist ein Schatz, der seinem Besitzer überallhin folgt.',
      author: 'Chinesisches Sprichwort',
    ),
    HomeQuote(
      text:
          'Wissen ist ein Garten: wird er nicht gepflegt, gibt es keine Ernte.',
      author: 'Afrikanisches Sprichwort',
    ),
    HomeQuote(
      text: 'Das Schöne am Lernen ist, dass es dir niemand nehmen kann.',
      author: 'B.B. King',
    ),
    HomeQuote(
      text: 'Glaube, dass du es kannst, und du bist schon auf halbem Weg.',
      author: 'Theodore Roosevelt',
    ),
    HomeQuote(
      text: 'Für harte Arbeit gibt es keinen Ersatz.',
      author: 'Thomas Edison',
    ),
    HomeQuote(
      text:
          'Genie ist ein Prozent Inspiration und neunundneunzig Prozent Transpiration.',
      author: 'Thomas Edison',
    ),
    HomeQuote(
      text: 'Energie und Ausdauer besiegen alles.',
      author: 'Benjamin Franklin',
    ),
    HomeQuote(
      text:
          'Die beste Zeit, einen Baum zu pflanzen, war vor zwanzig Jahren. Die zweitbeste ist jetzt.',
      author: 'Chinesisches Sprichwort',
    ),
    HomeQuote(
      text:
          'Willst du schnell gehen, geh allein. Willst du weit gehen, geh gemeinsam.',
      author: 'Afrikanisches Sprichwort',
    ),
    HomeQuote(
      text:
          'Ein Fluss schneidet den Fels nicht durch Kraft, sondern durch Ausdauer.',
      author: 'James N. Watkins',
    ),
    HomeQuote(
      text:
          'Kleine Taten, die getan sind, sind besser als große, die geplant bleiben.',
      author: 'Peter Marshall',
    ),
    HomeQuote(
      text: 'Schau nicht auf die Uhr; tu, was sie tut. Mach weiter.',
      author: 'Sam Levenson',
    ),
    HomeQuote(
      text:
          'Ob du denkst, du kannst es, oder du kannst es nicht — du hast recht.',
      author: 'Henry Ford',
    ),
    HomeQuote(
      text: 'In der Mitte der Schwierigkeit liegt die Gelegenheit.',
      author: 'Albert Einstein',
    ),
    HomeQuote(
      text:
          'Bildung ist die mächtigste Waffe, die du nutzen kannst, um die Welt zu verändern.',
      author: 'Nelson Mandela',
    ),
    HomeQuote(
      text: 'Eine andere Sprache ist eine andere Sicht auf das Leben.',
      author: 'Federico Fellini',
    ),
    HomeQuote(
      text: 'Übung ist die beste aller Lehrerinnen.',
      author: 'Publilius Syrus',
    ),
    HomeQuote(
      text:
          'Es spielt keine Rolle, wie langsam du gehst, solange du nicht stehen bleibst.',
      author: 'Konfuzius',
    ),
    HomeQuote(
      text: 'Wahres Wissen heißt, das Maß der eigenen Unwissenheit zu kennen.',
      author: 'Konfuzius',
    ),
    HomeQuote(
      text: 'Die Wurzeln der Bildung sind bitter, aber die Frucht ist süß.',
      author: 'Aristoteles',
    ),
    HomeQuote(
      text:
          'Lebe, als würdest du morgen sterben. Lerne, als würdest du ewig leben.',
      author: 'Mahatma Gandhi',
    ),
    HomeQuote(
      text: 'Fürchte nicht, langsam zu wachsen; fürchte nur, stillzustehen.',
      author: 'Chinesisches Sprichwort',
    ),
    HomeQuote(
      text: 'Nichts wird gelingen, wenn du es nicht tust.',
      author: 'Maya Angelou',
    ),
    HomeQuote(
      text: 'Die einzige wahre Weisheit ist zu wissen, dass man nichts weiß.',
      author: 'Sokrates',
    ),
    HomeQuote(
      text: 'Der Zufall begünstigt den vorbereiteten Geist.',
      author: 'Louis Pasteur',
    ),
    HomeQuote(
      text: 'Was wir mit Freude lernen, vergessen wir nie.',
      author: 'Alfred Mercier',
    ),
    HomeQuote(
      text: 'Ein Buch ist ein Garten, den man in der Tasche trägt.',
      author: 'Arabisches Sprichwort',
    ),
    HomeQuote(
      text: 'Die blasseste Tinte ist besser als das beste Gedächtnis.',
      author: 'Chinesisches Sprichwort',
    ),
    HomeQuote(
      text: 'Geduld ist bitter, aber ihre Frucht ist süß.',
      author: 'Aristoteles',
    ),
    HomeQuote(
      text:
          'Indem du lernst, wirst du lehren; indem du lehrst, wirst du lernen.',
      author: 'Lateinisches Sprichwort',
    ),
    HomeQuote(
      text:
          'Nicht zu wissen ist schlecht; nicht wissen zu wollen ist schlechter.',
      author: 'Nigerianisches Sprichwort',
    ),
    HomeQuote(
      text: 'Der Experte in allem war einmal ein Anfänger.',
      author: 'Helen Hayes',
    ),
    HomeQuote(
      text:
          'Du musst nicht groß sein, um anzufangen, aber du musst anfangen, um groß zu werden.',
      author: 'Zig Ziglar',
    ),
    HomeQuote(
      text:
          'Eine Sprache stellt dich lebenslang in einen Flur. Zwei Sprachen öffnen jede Tür.',
      author: 'Frank Smith',
    ),
  ];

  static const List<HomeQuote> russian = <HomeQuote>[
    HomeQuote(
      text: 'Путь в тысячу миль начинается с одного шага.',
      author: 'Лао-цзы',
    ),
    HomeQuote(
      text: 'Это всегда кажется невозможным, пока не сделано.',
      author: 'Нельсон Мандела',
    ),
    HomeQuote(text: 'Секрет продвижения вперёд — начать.', author: 'Марк Твен'),
    HomeQuote(text: 'Понемногу заходишь далеко.', author: 'Дж. Р. Р. Толкин'),
    HomeQuote(
      text: 'Делай, что можешь, тем, что есть, там, где ты есть.',
      author: 'Теодор Рузвельт',
    ),
    HomeQuote(
      text: 'Перемена — итог всякого настоящего учения.',
      author: 'Лео Бускалья',
    ),
    HomeQuote(text: 'Начало — самая важная часть работы.', author: 'Платон'),
    HomeQuote(
      text: 'Упади семь раз и встань восемь.',
      author: 'Японская пословица',
    ),
    HomeQuote(
      text:
          'Начни там, где ты есть. Используй то, что есть. Делай, что можешь.',
      author: 'Артур Эш',
    ),
    HomeQuote(
      text: 'Успех — сумма малых усилий, повторяемых изо дня в день.',
      author: 'Роберт Коллиер',
    ),
    HomeQuote(
      text: 'Мы — то, что повторяем. Совершенство — это привычка.',
      author: 'Аристотель',
    ),
    HomeQuote(
      text: 'Вложение в знание приносит лучший процент.',
      author: 'Бенджамин Франклин',
    ),
    HomeQuote(
      text: 'Учение никогда не утомляет ум.',
      author: 'Леонардо да Винчи',
    ),
    HomeQuote(
      text: 'Тот, кто учится и не думает, потерян.',
      author: 'Конфуций',
    ),
    HomeQuote(
      text: 'Владеть другим языком — значит иметь вторую душу.',
      author: 'Карл Великий',
    ),
    HomeQuote(
      text: 'Границы моего языка означают границы моего мира.',
      author: 'Людвиг Витгенштейн',
    ),
    HomeQuote(
      text: 'Учение — сокровище, которое всюду следует за хозяином.',
      author: 'Китайская пословица',
    ),
    HomeQuote(
      text: 'Знание — сад: если его не возделывать, урожая не будет.',
      author: 'Африканская пословица',
    ),
    HomeQuote(
      text: 'Прелесть учения в том, что его никто не отнимет.',
      author: 'Би Би Кинг',
    ),
    HomeQuote(
      text: 'Поверь, что можешь — и ты уже на полпути.',
      author: 'Теодор Рузвельт',
    ),
    HomeQuote(text: 'Труду нет замены.', author: 'Томас Эдисон'),
    HomeQuote(
      text: 'Гений — один процент вдохновения и девяносто девять пота.',
      author: 'Томас Эдисон',
    ),
    HomeQuote(
      text: 'Энергия и настойчивость побеждают всё.',
      author: 'Бенджамин Франклин',
    ),
    HomeQuote(
      text:
          'Лучшее время посадить дерево было двадцать лет назад. Второе лучшее — сейчас.',
      author: 'Китайская пословица',
    ),
    HomeQuote(
      text: 'Хочешь идти быстро — иди один. Хочешь идти далеко — идите вместе.',
      author: 'Африканская пословица',
    ),
    HomeQuote(
      text: 'Река рассекает скалу не силой, а постоянством.',
      author: 'Джеймс Н. Уоткинс',
    ),
    HomeQuote(
      text:
          'Малые дела, которые сделаны, лучше великих, которые лишь задуманы.',
      author: 'Питер Маршалл',
    ),
    HomeQuote(
      text: 'Не смотри на часы; делай то, что они делают. Продолжай.',
      author: 'Сэм Левенсон',
    ),
    HomeQuote(
      text: 'Думаешь, что можешь, или думаешь, что не можешь — ты прав.',
      author: 'Генри Форд',
    ),
    HomeQuote(
      text: 'Посреди трудности лежит возможность.',
      author: 'Альберт Эйнштейн',
    ),
    HomeQuote(
      text: 'Образование — самое мощное оружие, которым можно изменить мир.',
      author: 'Нельсон Мандела',
    ),
    HomeQuote(
      text: 'Другой язык — это другое видение жизни.',
      author: 'Федерико Феллини',
    ),
    HomeQuote(
      text: 'Практика — лучшая из всех наставниц.',
      author: 'Публилий Сир',
    ),
    HomeQuote(
      text: 'Неважно, как медленно ты идёшь, лишь бы не останавливаться.',
      author: 'Конфуций',
    ),
    HomeQuote(
      text: 'Истинное знание — знать меру собственного незнания.',
      author: 'Конфуций',
    ),
    HomeQuote(
      text: 'Корни образования горьки, но плод сладок.',
      author: 'Аристотель',
    ),
    HomeQuote(
      text:
          'Живи так, будто умрёшь завтра. Учись так, будто будешь жить вечно.',
      author: 'Махатма Ганди',
    ),
    HomeQuote(
      text: 'Не бойся расти медленно — бойся стоять на месте.',
      author: 'Китайская пословица',
    ),
    HomeQuote(
      text: 'Ничто не сработает, пока не сработаешь ты.',
      author: 'Майя Энджелоу',
    ),
    HomeQuote(
      text: 'Единственная истинная мудрость — знать, что ты ничего не знаешь.',
      author: 'Сократ',
    ),
    HomeQuote(
      text: 'Случай благоприятствует подготовленному уму.',
      author: 'Луи Пастер',
    ),
    HomeQuote(
      text: 'То, что мы учим с удовольствием, мы никогда не забываем.',
      author: 'Альфред Мерсье',
    ),
    HomeQuote(
      text: 'Книга — сад, который носят в кармане.',
      author: 'Арабская пословица',
    ),
    HomeQuote(
      text: 'Самые бледные чернила лучше самой сильной памяти.',
      author: 'Китайская пословица',
    ),
    HomeQuote(
      text: 'Терпение горько, но плод его сладок.',
      author: 'Аристотель',
    ),
    HomeQuote(
      text: 'Обучаясь, будешь учить; уча, будешь учиться.',
      author: 'Латинская пословица',
    ),
    HomeQuote(
      text: 'Не знать — плохо; не желать знать — ещё хуже.',
      author: 'Нигерийская пословица',
    ),
    HomeQuote(
      text: 'Эксперт в любом деле когда-то был новичком.',
      author: 'Хелен Хейс',
    ),
    HomeQuote(
      text:
          'Не нужно быть великим, чтобы начать, но нужно начать, чтобы стать великим.',
      author: 'Зиг Зиглар',
    ),
    HomeQuote(
      text:
          'Один язык ставит тебя в коридор на всю жизнь. Два языка открывают каждую дверь.',
      author: 'Фрэнк Смит',
    ),
  ];

  static const List<HomeQuote> portuguese = <HomeQuote>[
    HomeQuote(
      text: 'A jornada de mil milhas começa com um único passo.',
      author: 'Lao Tsé',
    ),
    HomeQuote(
      text: 'Parece sempre impossível até estar feito.',
      author: 'Nelson Mandela',
    ),
    HomeQuote(text: 'O segredo de avançar é começar.', author: 'Mark Twain'),
    HomeQuote(text: 'Pouco a pouco se vai longe.', author: 'J.R.R. Tolkien'),
    HomeQuote(
      text: 'Faz o que puderes, com o que tens, onde estás.',
      author: 'Theodore Roosevelt',
    ),
    HomeQuote(
      text: 'A mudança é o resultado de toda a aprendizagem verdadeira.',
      author: 'Leo Buscaglia',
    ),
    HomeQuote(
      text: 'O começo é a parte mais importante do trabalho.',
      author: 'Platão',
    ),
    HomeQuote(
      text: 'Cai sete vezes e levanta-te oito.',
      author: 'Provérbio japonês',
    ),
    HomeQuote(
      text: 'Começa onde estás. Usa o que tens. Faz o que puderes.',
      author: 'Arthur Ashe',
    ),
    HomeQuote(
      text: 'O sucesso é a soma de pequenos esforços, repetidos dia após dia.',
      author: 'Robert Collier',
    ),
    HomeQuote(
      text: 'Somos o que repetimos. A excelência é um hábito.',
      author: 'Aristóteles',
    ),
    HomeQuote(
      text: 'Um investimento no conhecimento paga o melhor juro.',
      author: 'Benjamin Franklin',
    ),
    HomeQuote(
      text: 'Aprender nunca esgota a mente.',
      author: 'Leonardo da Vinci',
    ),
    HomeQuote(
      text: 'Quem aprende e não pensa está perdido.',
      author: 'Confúcio',
    ),
    HomeQuote(
      text: 'Ter outra língua é possuir uma segunda alma.',
      author: 'Carlos Magno',
    ),
    HomeQuote(
      text: 'Os limites da minha linguagem são os limites do meu mundo.',
      author: 'Ludwig Wittgenstein',
    ),
    HomeQuote(
      text: 'Aprender é um tesouro que segue o dono a toda a parte.',
      author: 'Provérbio chinês',
    ),
    HomeQuote(
      text: 'O saber é um jardim: se não for cultivado, não se colhe.',
      author: 'Provérbio africano',
    ),
    HomeQuote(
      text: 'O belo de aprender é que ninguém to pode tirar.',
      author: 'B.B. King',
    ),
    HomeQuote(
      text: 'Acredita que podes e já estás a meio caminho.',
      author: 'Theodore Roosevelt',
    ),
    HomeQuote(
      text: 'Não há substituto para o trabalho duro.',
      author: 'Thomas Edison',
    ),
    HomeQuote(
      text:
          'O génio é um por cento de inspiração e noventa e nove de transpiração.',
      author: 'Thomas Edison',
    ),
    HomeQuote(
      text: 'A energia e a persistência conquistam todas as coisas.',
      author: 'Benjamin Franklin',
    ),
    HomeQuote(
      text:
          'O melhor momento para plantar uma árvore foi há vinte anos. O segundo melhor é agora.',
      author: 'Provérbio chinês',
    ),
    HomeQuote(
      text:
          'Se queres ir depressa, vai sozinho. Se queres ir longe, vai em conjunto.',
      author: 'Provérbio africano',
    ),
    HomeQuote(
      text: 'O rio corta a rocha não pela força, mas pela persistência.',
      author: 'James N. Watkins',
    ),
    HomeQuote(
      text: 'Pequenos atos feitos valem mais do que grandes atos planeados.',
      author: 'Peter Marshall',
    ),
    HomeQuote(
      text: 'Não olhes para o relógio; faz o que ele faz. Continua.',
      author: 'Sam Levenson',
    ),
    HomeQuote(
      text: 'Quer penses que podes, quer penses que não podes, tens razão.',
      author: 'Henry Ford',
    ),
    HomeQuote(
      text: 'No meio da dificuldade está a oportunidade.',
      author: 'Albert Einstein',
    ),
    HomeQuote(
      text:
          'A educação é a arma mais poderosa que podes usar para mudar o mundo.',
      author: 'Nelson Mandela',
    ),
    HomeQuote(
      text: 'Uma língua diferente é uma visão diferente da vida.',
      author: 'Federico Fellini',
    ),
    HomeQuote(
      text: 'A prática é a melhor de todos os mestres.',
      author: 'Publílio Siro',
    ),
    HomeQuote(
      text: 'Não importa quão devagar vás, desde que não pares.',
      author: 'Confúcio',
    ),
    HomeQuote(
      text: 'O verdadeiro saber é conhecer a extensão da própria ignorância.',
      author: 'Confúcio',
    ),
    HomeQuote(
      text: 'As raízes da educação são amargas, mas o fruto é doce.',
      author: 'Aristóteles',
    ),
    HomeQuote(
      text:
          'Vive como se fosses morrer amanhã. Aprende como se fosses viver para sempre.',
      author: 'Mahatma Gandhi',
    ),
    HomeQuote(
      text: 'Não temas crescer devagar; teme apenas ficar parado.',
      author: 'Provérbio chinês',
    ),
    HomeQuote(
      text: 'Nada funcionará a menos que tu o faças.',
      author: 'Maya Angelou',
    ),
    HomeQuote(
      text: 'A única verdadeira sabedoria é saber que nada se sabe.',
      author: 'Sócrates',
    ),
    HomeQuote(
      text: 'O acaso favorece a mente preparada.',
      author: 'Louis Pasteur',
    ),
    HomeQuote(
      text: 'O que aprendemos com prazer nunca esquecemos.',
      author: 'Alfred Mercier',
    ),
    HomeQuote(
      text: 'Um livro é um jardim que se leva no bolso.',
      author: 'Provérbio árabe',
    ),
    HomeQuote(
      text: 'A tinta mais pálida vale mais do que a melhor memória.',
      author: 'Provérbio chinês',
    ),
    HomeQuote(
      text: 'A paciência é amarga, mas o seu fruto é doce.',
      author: 'Aristóteles',
    ),
    HomeQuote(
      text: 'Ao aprender ensinarás; ao ensinar aprenderás.',
      author: 'Provérbio latino',
    ),
    HomeQuote(
      text: 'Não saber é mau; não querer saber é pior.',
      author: 'Provérbio nigeriano',
    ),
    HomeQuote(
      text: 'O especialista em qualquer coisa já foi um principiante.',
      author: 'Helen Hayes',
    ),
    HomeQuote(
      text:
          'Não precisas de ser grande para começar, mas precisas de começar para ser grande.',
      author: 'Zig Ziglar',
    ),
    HomeQuote(
      text:
          'Uma língua coloca-te num corredor para a vida. Duas línguas abrem todas as portas.',
      author: 'Frank Smith',
    ),
  ];

  static const List<HomeQuote> italian = <HomeQuote>[
    HomeQuote(
      text: 'Il viaggio di mille miglia inizia con un solo passo.',
      author: 'Lao Tzu',
    ),
    HomeQuote(
      text: 'Sembra sempre impossibile finché non è fatto.',
      author: 'Nelson Mandela',
    ),
    HomeQuote(
      text: 'Il segreto per andare avanti è cominciare.',
      author: 'Mark Twain',
    ),
    HomeQuote(text: 'Poco a poco si va lontano.', author: 'J.R.R. Tolkien'),
    HomeQuote(
      text: 'Fai ciò che puoi, con ciò che hai, dove sei.',
      author: 'Theodore Roosevelt',
    ),
    HomeQuote(
      text: 'Il cambiamento è il risultato di ogni vero apprendimento.',
      author: 'Leo Buscaglia',
    ),
    HomeQuote(
      text: 'L’inizio è la parte più importante del lavoro.',
      author: 'Platone',
    ),
    HomeQuote(
      text: 'Cadi sette volte e rialzati otto.',
      author: 'Proverbio giapponese',
    ),
    HomeQuote(
      text: 'Inizia dove sei. Usa ciò che hai. Fai ciò che puoi.',
      author: 'Arthur Ashe',
    ),
    HomeQuote(
      text: 'Il successo è la somma di piccoli sforzi, ripetuti ogni giorno.',
      author: 'Robert Collier',
    ),
    HomeQuote(
      text: 'Siamo ciò che ripetiamo. L’eccellenza è un’abitudine.',
      author: 'Aristotele',
    ),
    HomeQuote(
      text: 'Un investimento nella conoscenza paga il miglior interesse.',
      author: 'Benjamin Franklin',
    ),
    HomeQuote(
      text: 'Imparare non stanca mai la mente.',
      author: 'Leonardo da Vinci',
    ),
    HomeQuote(text: 'Chi impara e non pensa è perduto.', author: 'Confucio'),
    HomeQuote(
      text: 'Avere un’altra lingua è possedere una seconda anima.',
      author: 'Carlomagno',
    ),
    HomeQuote(
      text: 'I limiti del mio linguaggio sono i limiti del mio mondo.',
      author: 'Ludwig Wittgenstein',
    ),
    HomeQuote(
      text: 'Imparare è un tesoro che segue il suo padrone ovunque.',
      author: 'Proverbio cinese',
    ),
    HomeQuote(
      text: 'Il sapere è un giardino: se non si coltiva, non si raccoglie.',
      author: 'Proverbio africano',
    ),
    HomeQuote(
      text: 'La bellezza dell’imparare è che nessuno può togliertelo.',
      author: 'B.B. King',
    ),
    HomeQuote(
      text: 'Credi di poterlo fare e sei già a metà strada.',
      author: 'Theodore Roosevelt',
    ),
    HomeQuote(
      text: 'Non c’è sostituto per il lavoro duro.',
      author: 'Thomas Edison',
    ),
    HomeQuote(
      text: 'Il genio è un percento ispirazione e novantanove sudore.',
      author: 'Thomas Edison',
    ),
    HomeQuote(
      text: 'Energia e persistenza vincono ogni cosa.',
      author: 'Benjamin Franklin',
    ),
    HomeQuote(
      text:
          'Il momento migliore per piantare un albero era vent’anni fa. Il secondo migliore è adesso.',
      author: 'Proverbio cinese',
    ),
    HomeQuote(
      text:
          'Se vuoi andare veloce, vai da solo. Se vuoi andare lontano, vai insieme.',
      author: 'Proverbio africano',
    ),
    HomeQuote(
      text: 'Il fiume taglia la roccia non con la forza, ma con la costanza.',
      author: 'James N. Watkins',
    ),
    HomeQuote(
      text:
          'I piccoli gesti compiuti valgono più dei grandi gesti soltanto pensati.',
      author: 'Peter Marshall',
    ),
    HomeQuote(
      text: 'Non guardare l’orologio; fai ciò che fa lui. Continua.',
      author: 'Sam Levenson',
    ),
    HomeQuote(
      text: 'Che tu pensi di poterlo fare o no, hai ragione.',
      author: 'Henry Ford',
    ),
    HomeQuote(
      text: 'Nel mezzo della difficoltà sta l’opportunità.',
      author: 'Albert Einstein',
    ),
    HomeQuote(
      text:
          'L’istruzione è l’arma più potente che puoi usare per cambiare il mondo.',
      author: 'Nelson Mandela',
    ),
    HomeQuote(
      text: 'Una lingua diversa è una diversa visione della vita.',
      author: 'Federico Fellini',
    ),
    HomeQuote(
      text: 'La pratica è la migliore di tutte le maestre.',
      author: 'Publilio Siro',
    ),
    HomeQuote(
      text: 'Non importa quanto piano vai, purché non ti fermi.',
      author: 'Confucio',
    ),
    HomeQuote(
      text: 'La vera conoscenza è sapere l’estensione della propria ignoranza.',
      author: 'Confucio',
    ),
    HomeQuote(
      text: 'Le radici dell’educazione sono amare, ma il frutto è dolce.',
      author: 'Aristotele',
    ),
    HomeQuote(
      text:
          'Vivi come se dovessi morire domani. Impara come se dovessi vivere per sempre.',
      author: 'Mahatma Gandhi',
    ),
    HomeQuote(
      text: 'Non temere di crescere piano; temi soltanto di restare fermo.',
      author: 'Proverbio cinese',
    ),
    HomeQuote(
      text: 'Nulla funzionerà se non lo fai tu.',
      author: 'Maya Angelou',
    ),
    HomeQuote(
      text: 'L’unica vera saggezza è sapere di non sapere nulla.',
      author: 'Socrate',
    ),
    HomeQuote(
      text: 'Il caso favorisce la mente preparata.',
      author: 'Louis Pasteur',
    ),
    HomeQuote(
      text: 'Ciò che impariamo con piacere non lo dimentichiamo mai.',
      author: 'Alfred Mercier',
    ),
    HomeQuote(
      text: 'Un libro è un giardino che si porta in tasca.',
      author: 'Proverbio arabo',
    ),
    HomeQuote(
      text: 'L’inchiostro più pallido vale più della memoria migliore.',
      author: 'Proverbio cinese',
    ),
    HomeQuote(
      text: 'La pazienza è amara, ma il suo frutto è dolce.',
      author: 'Aristotele',
    ),
    HomeQuote(
      text: 'Imparando insegnerai; insegnando imparerai.',
      author: 'Proverbio latino',
    ),
    HomeQuote(
      text: 'Non sapere è male; non voler sapere è peggio.',
      author: 'Proverbio nigeriano',
    ),
    HomeQuote(
      text: 'L’esperto in qualsiasi cosa è stato un principiante.',
      author: 'Helen Hayes',
    ),
    HomeQuote(
      text:
          'Non devi essere grande per iniziare, ma devi iniziare per diventare grande.',
      author: 'Zig Ziglar',
    ),
    HomeQuote(
      text:
          'Una lingua ti mette in un corridoio per la vita. Due lingue aprono ogni porta.',
      author: 'Frank Smith',
    ),
  ];

  static const List<HomeQuote> japanese = <HomeQuote>[
    HomeQuote(text: '千里の道も一歩から始まる。', author: '老子'),
    HomeQuote(text: '成し遂げるまでは、いつも不可能に見える。', author: 'ネルソン・マンデラ'),
    HomeQuote(text: '先に進む秘訣は、まず始めることだ。', author: 'マーク・トウェイン'),
    HomeQuote(text: '少しずつ進めば、遠くへ行ける。', author: 'J.R.R.トールキン'),
    HomeQuote(text: '今いる場所で、今あるもので、できることをせよ。', author: 'セオドア・ルーズベルト'),
    HomeQuote(text: '変化こそ、真の学びの結果である。', author: 'レオ・バスカリア'),
    HomeQuote(text: '仕事でいちばん大切なのは始まりである。', author: 'プラトン'),
    HomeQuote(text: '七回転んでも、八回立ち上がれ。', author: '日本のことわざ'),
    HomeQuote(text: '今いる場所から始めよ。あるものを使い、できることをせよ。', author: 'アーサー・アッシュ'),
    HomeQuote(text: '成功とは、日々くり返す小さな努力の総和である。', author: 'ロバート・コリアー'),
    HomeQuote(text: '人はくり返す行いそのものだ。卓越とは習慣である。', author: 'アリストテレス'),
    HomeQuote(text: '知識への投資は、いちばん高い利子を生む。', author: 'ベンジャミン・フランクリン'),
    HomeQuote(text: '学ぶことは心を疲れさせない。', author: 'レオナルド・ダ・ヴィンチ'),
    HomeQuote(text: '学んで考えなければ、道に迷う。', author: '孔子'),
    HomeQuote(text: 'もう一つの言語を持つことは、第二の魂を持つことだ。', author: 'カール大帝'),
    HomeQuote(text: '私の言語の限界は、私の世界の限界である。', author: 'ルートヴィヒ・ウィトゲンシュタイン'),
    HomeQuote(text: '学びは、持ち主の行く先どこまでもついてくる宝物だ。', author: '中国のことわざ'),
    HomeQuote(text: '知識は庭である。耕さなければ実りはない。', author: 'アフリカのことわざ'),
    HomeQuote(text: '学びの美しさは、誰にも奪えないことだ。', author: 'B.B.キング'),
    HomeQuote(text: 'できると信じれば、もう半分まで来ている。', author: 'セオドア・ルーズベルト'),
    HomeQuote(text: '努力に代わるものはない。', author: 'トーマス・エジソン'),
    HomeQuote(text: '天才とは、ひらめき1パーセント、あとの99パーセントは汗である。', author: 'トーマス・エジソン'),
    HomeQuote(text: '活力と粘り強さは、すべてに勝つ。', author: 'ベンジャミン・フランクリン'),
    HomeQuote(text: '木を植える最上の時は二十年前だった。次に良い時は今だ。', author: '中国のことわざ'),
    HomeQuote(text: '速く行きたいなら一人で行け。遠くへ行きたいなら共に行け。', author: 'アフリカのことわざ'),
    HomeQuote(text: '川が岩を断つのは力ではなく、絶え間ない流れによる。', author: 'ジェームズ・N・ワトキンス'),
    HomeQuote(text: '成し遂げた小さな行いのほうが、計画だけの大きな行いより勝る。', author: 'ピーター・マーシャル'),
    HomeQuote(text: '時計を見るな。時計がするように、進み続けよ。', author: 'サム・レベンソン'),
    HomeQuote(text: 'できると思っても、できないと思っても、その通りになる。', author: 'ヘンリー・フォード'),
    HomeQuote(text: '困難のただ中に機会がある。', author: 'アルベルト・アインシュタイン'),
    HomeQuote(text: '教育は、世界を変えるために使える最も強力な武器である。', author: 'ネルソン・マンデラ'),
    HomeQuote(text: '違う言語は、人生への違う見方である。', author: 'フェデリコ・フェリーニ'),
    HomeQuote(text: '練習こそ、すべての教師のうち最良のものである。', author: 'プブリリウス・シュルス'),
    HomeQuote(text: 'どれほど遅くてもよい。止まらなければ。', author: '孔子'),
    HomeQuote(text: '真の知とは、自分の無知の広さを知ることだ。', author: '孔子'),
    HomeQuote(text: '教育の根は苦いが、その実は甘い。', author: 'アリストテレス'),
    HomeQuote(text: '明日死ぬかのように生きよ。永遠に生きるかのように学べ。', author: 'マハトマ・ガンディー'),
    HomeQuote(text: 'ゆっくり育つことを恐れるな。ただ立ち止まることを恐れよ。', author: '中国のことわざ'),
    HomeQuote(text: 'あなたが動かなければ、何も動かない。', author: 'マヤ・アンジェロウ'),
    HomeQuote(text: '唯一の真の知恵は、自分が何も知らないと知ることだ。', author: 'ソクラテス'),
    HomeQuote(text: '幸運は、準備された心に味方する。', author: 'ルイ・パスツール'),
    HomeQuote(text: '楽しみながら学んだことは、決して忘れない。', author: 'アルフレッド・メルシエ'),
    HomeQuote(text: '本は、ポケットに入る庭である。', author: 'アラビアのことわざ'),
    HomeQuote(text: 'いちばん薄い墨でも、いちばん良い記憶に勝る。', author: '中国のことわざ'),
    HomeQuote(text: '忍耐は苦いが、その実は甘い。', author: 'アリストテレス'),
    HomeQuote(text: '学ぶことで教え、教えることで学ぶ。', author: 'ラテンのことわざ'),
    HomeQuote(text: '知らないことは悪い。知ろうとしないことはさらに悪い。', author: 'ナイジェリアのことわざ'),
    HomeQuote(text: 'どんな分野の達人も、かつては初心者だった。', author: 'ヘレン・ヘイズ'),
    HomeQuote(text: '始めるために偉大である必要はない。偉大になるために始めなければならない。', author: 'ジグ・ジグラー'),
    HomeQuote(text: '一つの言語は生涯の廊下に置く。二つの言語はすべての扉を開く。', author: 'フランク・スミス'),
  ];

  static const List<HomeQuote> korean = <HomeQuote>[
    HomeQuote(text: '천 리 길도 한 걸음에서 시작된다.', author: '노자'),
    HomeQuote(text: '해내기 전까지는 언제나 불가능해 보인다.', author: '넬슨 만델라'),
    HomeQuote(text: '앞으로 가는 비결은 시작하는 것이다.', author: '마크 트웨인'),
    HomeQuote(text: '조금씩 가면 멀리 간다.', author: 'J.R.R. 톨킨'),
    HomeQuote(text: '있는 곳에서, 가진 것으로, 할 수 있는 일을 하라.', author: '시어도어 루스벨트'),
    HomeQuote(text: '변화는 참된 배움의 결과이다.', author: '리오 부스칼리아'),
    HomeQuote(text: '일의 가장 중요한 부분은 시작이다.', author: '플라톤'),
    HomeQuote(text: '일곱 번 넘어지고 여덟 번 일어나라.', author: '일본 속담'),
    HomeQuote(text: '있는 곳에서 시작하라. 가진 것을 쓰고, 할 수 있는 일을 하라.', author: '아서 애시'),
    HomeQuote(text: '성공은 날마다 반복하는 작은 노력의 합이다.', author: '로버트 콜리어'),
    HomeQuote(text: '우리는 반복하는 그것이다. 탁월함은 습관이다.', author: '아리스토텔레스'),
    HomeQuote(text: '지식에 대한 투자는 가장 높은 이자를 준다.', author: '벤저민 프랭클린'),
    HomeQuote(text: '배움은 마음을 지치게 하지 않는다.', author: '레오나르도 다 빈치'),
    HomeQuote(text: '배우고 생각하지 않으면 길을 잃는다.', author: '공자'),
    HomeQuote(text: '다른 언어를 갖는 것은 두 번째 영혼을 갖는 것이다.', author: '샤를마뉴'),
    HomeQuote(text: '내 언어의 한계는 내 세계의 한계이다.', author: '루트비히 비트겐슈타인'),
    HomeQuote(text: '배움은 주인을 어디든 따라가는 보물이다.', author: '중국 속담'),
    HomeQuote(text: '지식은 정원이다. 가꾸지 않으면 거둘 수 없다.', author: '아프리카 속담'),
    HomeQuote(text: '배움의 아름다움은 아무도 빼앗을 수 없다는 것이다.', author: 'B.B. 킹'),
    HomeQuote(text: '할 수 있다고 믿으면 이미 절반은 온 것이다.', author: '시어도어 루스벨트'),
    HomeQuote(text: '열심히 일하는 것을 대신할 것은 없다.', author: '토머스 에디슨'),
    HomeQuote(text: '천재는 영감 1퍼센트와 땀 99퍼센트이다.', author: '토머스 에디슨'),
    HomeQuote(text: '에너지와 끈기는 모든 것을 이긴다.', author: '벤저민 프랭클린'),
    HomeQuote(
      text: '나무를 심기 가장 좋은 때는 20년 전이었다. 두 번째로 좋은 때는 지금이다.',
      author: '중국 속담',
    ),
    HomeQuote(text: '빨리 가려면 혼자 가고, 멀리 가려면 함께 가라.', author: '아프리카 속담'),
    HomeQuote(text: '강은 힘으로가 아니라 끈기로 바위를 가른다.', author: '제임스 N. 왓킨스'),
    HomeQuote(text: '이루어진 작은 일이 계획만 된 큰 일보다 낫다.', author: '피터 마셜'),
    HomeQuote(text: '시계를 보지 말고, 시계가 하는 일을 하라. 계속 가라.', author: '샘 레븐슨'),
    HomeQuote(text: '할 수 있다고 생각하든 없다고 생각하든, 당신이 옳다.', author: '헨리 포드'),
    HomeQuote(text: '어려움의 한가운데에 기회가 있다.', author: '알베르트 아인슈타인'),
    HomeQuote(text: '교육은 세상을 바꾸는 데 쓸 수 있는 가장 강력한 무기다.', author: '넬슨 만델라'),
    HomeQuote(text: '다른 언어는 삶에 대한 다른 시선이다.', author: '페데리코 펠리니'),
    HomeQuote(text: '연습은 모든 스승 가운데 가장 뛰어나다.', author: '푸블리리우스 시루스'),
    HomeQuote(text: '얼마나 천천히 가든 멈추지만 않으면 된다.', author: '공자'),
    HomeQuote(text: '참된 앎은 자신의 무지한 정도를 아는 것이다.', author: '공자'),
    HomeQuote(text: '교육의 뿌리는 쓰지만 열매는 달다.', author: '아리스토텔레스'),
    HomeQuote(text: '내일 죽을 것처럼 살고, 영원히 살 것처럼 배워라.', author: '마하트마 간디'),
    HomeQuote(text: '천천히 자라는 것을 두려워하지 말고, 멈춰 서는 것만 두려워하라.', author: '중국 속담'),
    HomeQuote(text: '당신이 하지 않으면 아무것도 되지 않는다.', author: '마야 안젤루'),
    HomeQuote(text: '유일한 참된 지혜는 아무것도 모른다는 것을 아는 것이다.', author: '소크라테스'),
    HomeQuote(text: '기회는 준비된 마음을 돕는다.', author: '루이 파스퇴르'),
    HomeQuote(text: '즐거움으로 배운 것은 결코 잊지 않는다.', author: '알프레드 메르시에'),
    HomeQuote(text: '책은 주머니에 넣는 정원이다.', author: '아랍 속담'),
    HomeQuote(text: '가장 옅은 잉크가 가장 좋은 기억보다 낫다.', author: '중국 속담'),
    HomeQuote(text: '인내는 쓰지만 그 열매는 달다.', author: '아리스토텔레스'),
    HomeQuote(text: '배우며 가르치고, 가르치며 배운다.', author: '라틴 속담'),
    HomeQuote(text: '모르는 것은 나쁘고, 알려고 하지 않는 것은 더 나쁘다.', author: '나이지리아 속담'),
    HomeQuote(text: '어떤 분야의 전문가도 한때는 초보자였다.', author: '헬렌 헤이즈'),
    HomeQuote(text: '시작하려면 위대할 필요는 없지만, 위대해지려면 시작해야 한다.', author: '지그 지글러'),
    HomeQuote(text: '한 언어는 평생의 복도에 세운다. 두 언어는 모든 문을 연다.', author: '프랭크 스미스'),
  ];

  static const List<HomeQuote> chinese = <HomeQuote>[
    HomeQuote(text: '千里之行，始于足下。', author: '老子'),
    HomeQuote(text: '事情在完成之前，总显得不可能。', author: '纳尔逊·曼德拉'),
    HomeQuote(text: '前进的秘诀，就是开始。', author: '马克·吐温'),
    HomeQuote(text: '一点点走，也能走得很远。', author: 'J.R.R.托尔金'),
    HomeQuote(text: '在你所在之处，用你所有的，做你能做的。', author: '西奥多·罗斯福'),
    HomeQuote(text: '改变，是一切真正学习的结果。', author: '利奥·布斯卡利亚'),
    HomeQuote(text: '开始，是工作中最重要的部分。', author: '柏拉图'),
    HomeQuote(text: '跌倒七次，第八次站起来。', author: '日本谚语'),
    HomeQuote(text: '从你所在之处开始。用你所有的。做你能做的。', author: '亚瑟·阿什'),
    HomeQuote(text: '成功是日复一日重复的小小努力之和。', author: '罗伯特·科利尔'),
    HomeQuote(text: '我们就是反复做的事。卓越因此是一种习惯。', author: '亚里士多德'),
    HomeQuote(text: '对知识的投资，会带来最好的利息。', author: '本杰明·富兰克林'),
    HomeQuote(text: '学习永远不会使心智疲惫。', author: '列奥纳多·达·芬奇'),
    HomeQuote(text: '学而不思则罔。', author: '孔子'),
    HomeQuote(text: '拥有另一种语言，就是拥有第二个灵魂。', author: '查理曼'),
    HomeQuote(text: '我的语言的界限，意味着我的世界的界限。', author: '路德维希·维特根斯坦'),
    HomeQuote(text: '学问是跟着主人走遍各处的宝藏。', author: '中国谚语'),
    HomeQuote(text: '知识如园地：不耕耘，便无收获。', author: '非洲谚语'),
    HomeQuote(text: '学习最美之处，是谁也无法从你身上夺走。', author: 'B.B.金'),
    HomeQuote(text: '相信你能做到，你就已经走完一半。', author: '西奥多·罗斯福'),
    HomeQuote(text: '没有任何东西可以代替勤奋。', author: '托马斯·爱迪生'),
    HomeQuote(text: '天才是百分之一的灵感，加上百分之九十九的汗水。', author: '托马斯·爱迪生'),
    HomeQuote(text: '精力与坚持能战胜一切。', author: '本杰明·富兰克林'),
    HomeQuote(text: '种树最好的时机是二十年前。其次就是现在。', author: '中国谚语'),
    HomeQuote(text: '想走得快，就独自走。想走得远，就一起走。', author: '非洲谚语'),
    HomeQuote(text: '河流切开岩石，靠的不是力量，而是坚持。', author: '詹姆斯·N·沃特金斯'),
    HomeQuote(text: '做成的小事，胜过只停留在计划里的大事。', author: '彼得·马歇尔'),
    HomeQuote(text: '不要盯着时钟；学它那样，继续走。', author: '萨姆·莱文森'),
    HomeQuote(text: '你认为自己能，或认为自己不能，你都是对的。', author: '亨利·福特'),
    HomeQuote(text: '困难的正中间，藏着机会。', author: '阿尔伯特·爱因斯坦'),
    HomeQuote(text: '教育是你能用来改变世界的最有力的武器。', author: '纳尔逊·曼德拉'),
    HomeQuote(text: '另一种语言，是对生命的另一种看见。', author: '费德里科·费里尼'),
    HomeQuote(text: '练习是所有老师中最好的一位。', author: '普布利利乌斯·西鲁斯'),
    HomeQuote(text: '走得再慢也无妨，只要不停下。', author: '孔子'),
    HomeQuote(text: '真正的知识，是知道自己无知到什么程度。', author: '孔子'),
    HomeQuote(text: '教育的根是苦的，果实却是甜的。', author: '亚里士多德'),
    HomeQuote(text: '像明天就会死去那样生活。像将永远活着那样学习。', author: '圣雄甘地'),
    HomeQuote(text: '不要害怕慢慢成长，只害怕停滞不前。', author: '中国谚语'),
    HomeQuote(text: '你若不动，什么都不会发生。', author: '玛雅·安吉罗'),
    HomeQuote(text: '唯一真正的智慧，是知道自己一无所知。', author: '苏格拉底'),
    HomeQuote(text: '机会青睐有准备的头脑。', author: '路易·巴斯德'),
    HomeQuote(text: '带着喜悦学会的东西，我们永不忘记。', author: '阿尔弗雷德·梅西耶'),
    HomeQuote(text: '书是装在口袋里的一座园子。', author: '阿拉伯谚语'),
    HomeQuote(text: '最淡的墨水，也胜过最好的记性。', author: '中国谚语'),
    HomeQuote(text: '忍耐是苦的，果实却是甜的。', author: '亚里士多德'),
    HomeQuote(text: '因学习而能教；因教导而能学。', author: '拉丁谚语'),
    HomeQuote(text: '不知道是不好的；不想知道更不好。', author: '尼日利亚谚语'),
    HomeQuote(text: '任何领域的专家，都曾是初学者。', author: '海伦·海斯'),
    HomeQuote(text: '开始不必伟大，但要变得伟大就必须开始。', author: '齐格·金克拉'),
    HomeQuote(text: '一种语言把你放进一生的走廊。两种语言打开每一扇门。', author: '弗兰克·史密斯'),
  ];

  static const List<HomeQuote> hindi = <HomeQuote>[
    HomeQuote(
      text: 'हज़ार मील की यात्रा एक ही कदम से शुरू होती है।',
      author: 'लाओ त्ज़ु',
    ),
    HomeQuote(
      text: 'जब तक पूरा न हो, सब कुछ असंभव लगता है।',
      author: 'नेल्सन मंडेला',
    ),
    HomeQuote(text: 'आगे बढ़ने का रहस्य शुरू करना है।', author: 'मार्क ट्वेन'),
    HomeQuote(
      text: 'थोड़ा-थोड़ा करके व्यक्ति दूर तक पहुँच जाता है।',
      author: 'जे.आर.आर. टॉल्किन',
    ),
    HomeQuote(
      text: 'जो कर सकते हो, जो है उसी से, जहाँ हो वहीं करो।',
      author: 'थियोडोर रूज़वेल्ट',
    ),
    HomeQuote(
      text: 'परिवर्तन हर सच्चे सीखने का परिणाम है।',
      author: 'लियो बुस्कालिया',
    ),
    HomeQuote(text: 'काम का सबसे ज़रूरी हिस्सा शुरुआत है।', author: 'प्लेटो'),
    HomeQuote(text: 'सात बार गिरो और आठवीं बार उठो।', author: 'जापानी कहावत'),
    HomeQuote(
      text: 'जहाँ हो वहीं से शुरू करो। जो है उसे इस्तेमाल करो। जो बन सके करो।',
      author: 'आर्थर ऐश',
    ),
    HomeQuote(
      text: 'सफलता रोज़ दोहराए गए छोटे प्रयासों का योग है।',
      author: 'रॉबर्ट कॉलियर',
    ),
    HomeQuote(
      text: 'हम वही हैं जो बार-बार करते हैं। उत्कृष्टता एक आदत है।',
      author: 'अरस्तू',
    ),
    HomeQuote(
      text: 'ज्ञान में निवेश सबसे अच्छा ब्याज देता है।',
      author: 'बेंजामिन फ्रैंकलिन',
    ),
    HomeQuote(
      text: 'सीखना मन को कभी थकाता नहीं।',
      author: 'लियोनार्डो दा विंची',
    ),
    HomeQuote(
      text: 'जो सीखता है पर सोचता नहीं, वह भटक जाता है।',
      author: 'कन्फ़्यूशियस',
    ),
    HomeQuote(text: 'दूसरी भाषा रखना दूसरी आत्मा रखना है।', author: 'शारलेमेन'),
    HomeQuote(
      text: 'मेरी भाषा की सीमाएँ मेरे संसार की सीमाएँ हैं।',
      author: 'लुडविग विट्गेन्स्टाइन',
    ),
    HomeQuote(
      text: 'सीखना एक खज़ाना है जो मालिक के साथ हर जगह जाता है।',
      author: 'चीनी कहावत',
    ),
    HomeQuote(
      text: 'ज्ञान एक बगीचा है: जोता न जाए तो फसल नहीं होती।',
      author: 'अफ़्रीकी कहावत',
    ),
    HomeQuote(
      text: 'सीखने की खूबसूरती यह है कि कोई इसे तुमसे छीन नहीं सकता।',
      author: 'बी.बी. किंग',
    ),
    HomeQuote(
      text: 'मान लो कि तुम कर सकते हो — तुम आधे रास्ते पर हो।',
      author: 'थियोडोर रूज़वेल्ट',
    ),
    HomeQuote(text: 'कड़ी मेहनत का कोई विकल्प नहीं।', author: 'थॉमस एडिसन'),
    HomeQuote(
      text: 'प्रतिभा एक प्रतिशत प्रेरणा और निन्यानवे प्रतिशत पसीना है।',
      author: 'थॉमस एडिसन',
    ),
    HomeQuote(
      text: 'ऊर्जा और दृढ़ता सब कुछ जीत लेती हैं।',
      author: 'बेंजामिन फ्रैंकलिन',
    ),
    HomeQuote(
      text:
          'पेड़ लगाने का सबसे अच्छा समय बीस साल पहले था। दूसरा सबसे अच्छा समय अब है।',
      author: 'चीनी कहावत',
    ),
    HomeQuote(
      text: 'तेज़ जाना हो तो अकेले जाओ। दूर जाना हो तो साथ चलो।',
      author: 'अफ़्रीकी कहावत',
    ),
    HomeQuote(
      text: 'नदी चट्टान को शक्ति से नहीं, लगातार बहने से काटती है।',
      author: 'जेम्स एन. वाटकिंस',
    ),
    HomeQuote(
      text: 'किए गए छोटे काम, केवल सोचे गए बड़े कामों से बेहतर हैं।',
      author: 'पीटर मार्शल',
    ),
    HomeQuote(
      text: 'घड़ी मत देखो; वही करो जो वह करती है। चलते रहो।',
      author: 'सैम लेवेन्सन',
    ),
    HomeQuote(
      text: 'सोचो कि कर सकते हो या नहीं — दोनों में तुम सही हो।',
      author: 'हेनरी फ़ोर्ड',
    ),
    HomeQuote(
      text: 'कठिनाई के बीच में ही अवसर होता है।',
      author: 'अल्बर्ट आइंस्टाइन',
    ),
    HomeQuote(
      text: 'शिक्षा वह सबसे शक्तिशाली हथियार है जिससे दुनिया बदली जा सकती है।',
      author: 'नेल्सन मंडेला',
    ),
    HomeQuote(
      text: 'अलग भाषा, जीवन की अलग दृष्टि है।',
      author: 'फ़ेदेरिको फ़ेलिनी',
    ),
    HomeQuote(
      text: 'अभ्यास सभी शिक्षकों में सबसे अच्छा है।',
      author: 'पब्लिलियस साइरस',
    ),
    HomeQuote(
      text: 'कितनी धीमी गति से चलो, इससे फ़र्क नहीं — बस रुकना मत।',
      author: 'कन्फ़्यूशियस',
    ),
    HomeQuote(
      text: 'सच्चा ज्ञान अपनी अज्ञानता की हद जानना है।',
      author: 'कन्फ़्यूशियस',
    ),
    HomeQuote(
      text: 'शिक्षा की जड़ें कड़वी हैं, पर फल मीठा है।',
      author: 'अरस्तू',
    ),
    HomeQuote(
      text: 'ऐसे जियो जैसे कल मरना हो। ऐसे सीखो जैसे हमेशा जीना हो।',
      author: 'महात्मा गाँधी',
    ),
    HomeQuote(
      text: 'धीरे बढ़ने से मत डरो; केवल रुक जाने से डरो।',
      author: 'चीनी कहावत',
    ),
    HomeQuote(
      text: 'तुम काम न करो तो कुछ भी काम नहीं करेगा।',
      author: 'माया एंजेलो',
    ),
    HomeQuote(
      text: 'एकमात्र सच्ची बुद्धि यह जानना है कि तुम कुछ नहीं जानते।',
      author: 'सुकरात',
    ),
    HomeQuote(text: 'संयोग तैयार मन का साथ देता है।', author: 'लुई पास्चर'),
    HomeQuote(
      text: 'जो आनंद से सीखते हैं, उसे हम कभी नहीं भूलते।',
      author: 'अल्फ़्रेड मर्सिए',
    ),
    HomeQuote(text: 'किताब जेब में रखी एक बाग़ है।', author: 'अरब कहावत'),
    HomeQuote(
      text: 'सबसे हल्की स्याही सबसे अच्छी याददाश्त से बेहतर है।',
      author: 'चीनी कहावत',
    ),
    HomeQuote(text: 'धैर्य कड़वा है, पर उसका फल मीठा है।', author: 'अरस्तू'),
    HomeQuote(
      text: 'सीखकर तुम सिखाओगे; सिखाकर तुम सीखोगे।',
      author: 'लैटिन कहावत',
    ),
    HomeQuote(
      text: 'न जानना बुरा है; जानना न चाहना और बुरा है।',
      author: 'नाइजीरियाई कहावत',
    ),
    HomeQuote(
      text: 'हर क्षेत्र का विशेषज्ञ कभी नौसिखिया था।',
      author: 'हेलेन हेज़',
    ),
    HomeQuote(
      text:
          'शुरू करने के लिए महान होना ज़रूरी नहीं, पर महान होने के लिए शुरू करना ज़रूरी है।',
      author: 'ज़िग ज़िग्लर',
    ),
    HomeQuote(
      text:
          'एक भाषा तुम्हें जीवन भर गलियारे में रखती है। दो भाषाएँ हर दरवाज़ा खोलती हैं।',
      author: 'फ़्रैंक स्मिथ',
    ),
  ];

  static const List<HomeQuote> indonesian = <HomeQuote>[
    HomeQuote(
      text: 'Perjalanan seribu mil dimulai dengan satu langkah.',
      author: 'Lao Tzu',
    ),
    HomeQuote(
      text: 'Semuanya tampak mustahil sampai selesai dikerjakan.',
      author: 'Nelson Mandela',
    ),
    HomeQuote(text: 'Rahasia maju adalah mulai.', author: 'Mark Twain'),
    HomeQuote(
      text: 'Sedikit demi sedikit, orang sampai jauh.',
      author: 'J.R.R. Tolkien',
    ),
    HomeQuote(
      text: 'Lakukan yang kau bisa, dengan yang kau punya, di tempatmu berada.',
      author: 'Theodore Roosevelt',
    ),
    HomeQuote(
      text: 'Perubahan adalah hasil dari semua pembelajaran yang sungguh.',
      author: 'Leo Buscaglia',
    ),
    HomeQuote(
      text: 'Awal adalah bagian terpenting dari pekerjaan.',
      author: 'Plato',
    ),
    HomeQuote(
      text: 'Jatuh tujuh kali, bangkit delapan kali.',
      author: 'Peribahasa Jepang',
    ),
    HomeQuote(
      text:
          'Mulailah di tempatmu. Gunakan yang kau punya. Lakukan yang kau bisa.',
      author: 'Arthur Ashe',
    ),
    HomeQuote(
      text: 'Sukses adalah jumlah usaha kecil yang diulang setiap hari.',
      author: 'Robert Collier',
    ),
    HomeQuote(
      text: 'Kita adalah apa yang kita ulang. Keunggulan adalah kebiasaan.',
      author: 'Aristoteles',
    ),
    HomeQuote(
      text: 'Investasi pada pengetahuan memberi bunga terbaik.',
      author: 'Benjamin Franklin',
    ),
    HomeQuote(
      text: 'Belajar tidak pernah melelahkan pikiran.',
      author: 'Leonardo da Vinci',
    ),
    HomeQuote(
      text: 'Siapa yang belajar tetapi tidak berpikir, akan tersesat.',
      author: 'Konfusius',
    ),
    HomeQuote(
      text: 'Memiliki bahasa lain berarti memiliki jiwa kedua.',
      author: 'Charlemagne',
    ),
    HomeQuote(
      text: 'Batas bahasaku adalah batas duniaku.',
      author: 'Ludwig Wittgenstein',
    ),
    HomeQuote(
      text: 'Belajar adalah harta yang mengikuti pemiliknya ke mana pun.',
      author: 'Peribahasa Tionghoa',
    ),
    HomeQuote(
      text: 'Pengetahuan adalah kebun: jika tidak diolah, tidak bisa dipanen.',
      author: 'Peribahasa Afrika',
    ),
    HomeQuote(
      text: 'Indahnya belajar ialah tak seorang pun bisa mengambilnya darimu.',
      author: 'B.B. King',
    ),
    HomeQuote(
      text: 'Percaya kau mampu, dan kau sudah di tengah jalan.',
      author: 'Theodore Roosevelt',
    ),
    HomeQuote(
      text: 'Tidak ada pengganti kerja keras.',
      author: 'Thomas Edison',
    ),
    HomeQuote(
      text:
          'Jenius adalah satu persen inspirasi dan sembilan puluh sembilan persen keringat.',
      author: 'Thomas Edison',
    ),
    HomeQuote(
      text: 'Energi dan ketekunan menaklukkan segala hal.',
      author: 'Benjamin Franklin',
    ),
    HomeQuote(
      text:
          'Waktu terbaik menanam pohon adalah dua puluh tahun lalu. Yang kedua terbaik adalah sekarang.',
      author: 'Peribahasa Tionghoa',
    ),
    HomeQuote(
      text:
          'Jika ingin cepat, pergilah sendiri. Jika ingin jauh, pergilah bersama.',
      author: 'Peribahasa Afrika',
    ),
    HomeQuote(
      text:
          'Sungai membelah batu bukan karena kekuatan, tetapi karena ketekunan.',
      author: 'James N. Watkins',
    ),
    HomeQuote(
      text:
          'Perbuatan kecil yang selesai lebih baik daripada rencana besar yang hanya dirancang.',
      author: 'Peter Marshall',
    ),
    HomeQuote(
      text: 'Jangan menatap jam; lakukan apa yang dilakukannya. Teruslah.',
      author: 'Sam Levenson',
    ),
    HomeQuote(
      text: 'Baik kau pikir mampu atau tidak, kau benar.',
      author: 'Henry Ford',
    ),
    HomeQuote(
      text: 'Di tengah kesulitan terletak kesempatan.',
      author: 'Albert Einstein',
    ),
    HomeQuote(
      text: 'Pendidikan adalah senjata paling ampuh untuk mengubah dunia.',
      author: 'Nelson Mandela',
    ),
    HomeQuote(
      text: 'Bahasa yang berbeda adalah cara pandang hidup yang berbeda.',
      author: 'Federico Fellini',
    ),
    HomeQuote(
      text: 'Latihan adalah guru terbaik dari semua guru.',
      author: 'Publilius Syrus',
    ),
    HomeQuote(
      text: 'Tidak soal seberapa pelan kau berjalan, asalkan tidak berhenti.',
      author: 'Konfusius',
    ),
    HomeQuote(
      text: 'Pengetahuan sejati adalah mengetahui batas ketidaktahuan sendiri.',
      author: 'Konfusius',
    ),
    HomeQuote(
      text: 'Akar pendidikan itu pahit, tetapi buahnya manis.',
      author: 'Aristoteles',
    ),
    HomeQuote(
      text:
          'Hiduplah seolah kau akan mati besok. Belajarlah seolah kau akan hidup selamanya.',
      author: 'Mahatma Gandhi',
    ),
    HomeQuote(
      text: 'Jangan takut tumbuh pelan; takutlah hanya jika diam di tempat.',
      author: 'Peribahasa Tionghoa',
    ),
    HomeQuote(
      text: 'Tidak ada yang akan berhasil kecuali kau mengerjakannya.',
      author: 'Maya Angelou',
    ),
    HomeQuote(
      text:
          'Satu-satunya kebijaksanaan sejati adalah mengetahui bahwa kau tidak tahu apa-apa.',
      author: 'Sokrates',
    ),
    HomeQuote(
      text: 'Kesempatan berpihak pada pikiran yang siap.',
      author: 'Louis Pasteur',
    ),
    HomeQuote(
      text:
          'Apa yang kita pelajari dengan senang hati tidak pernah kita lupakan.',
      author: 'Alfred Mercier',
    ),
    HomeQuote(
      text: 'Buku adalah kebun yang dibawa di saku.',
      author: 'Peribahasa Arab',
    ),
    HomeQuote(
      text: 'Tinta paling pucat lebih baik daripada ingatan terbaik.',
      author: 'Peribahasa Tionghoa',
    ),
    HomeQuote(
      text: 'Kesabaran itu pahit, tetapi buahnya manis.',
      author: 'Aristoteles',
    ),
    HomeQuote(
      text:
          'Dengan belajar kau akan mengajar; dengan mengajar kau akan belajar.',
      author: 'Peribahasa Latin',
    ),
    HomeQuote(
      text: 'Tidak tahu itu buruk; tidak ingin tahu lebih buruk.',
      author: 'Peribahasa Nigeria',
    ),
    HomeQuote(
      text: 'Ahli dalam apa pun pernah menjadi pemula.',
      author: 'Helen Hayes',
    ),
    HomeQuote(
      text:
          'Kau tidak harus hebat untuk mulai, tetapi kau harus mulai untuk menjadi hebat.',
      author: 'Zig Ziglar',
    ),
    HomeQuote(
      text:
          'Satu bahasa menempatkanmu di koridor seumur hidup. Dua bahasa membuka setiap pintu.',
      author: 'Frank Smith',
    ),
  ];

  static const List<HomeQuote> persian = <HomeQuote>[
    HomeQuote(text: 'سفر هزار مایلی با یک گام آغاز می‌شود.', author: 'لائوتسه'),
    HomeQuote(
      text: 'همیشه ناممکن به نظر می‌رسد تا آن‌که انجام شود.',
      author: 'نلسون ماندلا',
    ),
    HomeQuote(text: 'راز پیش رفتن، شروع کردن است.', author: 'مارک تواین'),
    HomeQuote(text: 'کم‌کم می‌توان دور رفت.', author: 'جی.آر.آر. تالکین'),
    HomeQuote(
      text: 'آنچه می‌توانی را، با آنچه داری، همان‌جا که هستی انجام بده.',
      author: 'تئودور روزولت',
    ),
    HomeQuote(
      text: 'تغییر، نتیجهٔ هر یادگیری راستین است.',
      author: 'لئو بوسکالیا',
    ),
    HomeQuote(text: 'آغاز، مهم‌ترین بخش کار است.', author: 'افلاطون'),
    HomeQuote(
      text: 'هفت بار بیفت و بار هشتم برخیز.',
      author: 'ضرب‌المثل ژاپنی',
    ),
    HomeQuote(
      text:
          'از جایی که هستی شروع کن. از آنچه داری بهره ببر. آنچه می‌توانی بکن.',
      author: 'آرتور اش',
    ),
    HomeQuote(
      text: 'موفقیت مجموع کوشش‌های کوچکی است که هر روز تکرار می‌شوند.',
      author: 'رابرت کولیر',
    ),
    HomeQuote(
      text: 'ما همان چیزی هستیم که پیوسته انجام می‌دهیم. تعالی یک عادت است.',
      author: 'ارسطو',
    ),
    HomeQuote(
      text: 'سرمایه‌گذاری در دانش بهترین سود را می‌دهد.',
      author: 'بنجامین فرانکلین',
    ),
    HomeQuote(
      text: 'یادگیری هرگز ذهن را خسته نمی‌کند.',
      author: 'لئوناردو داوینچی',
    ),
    HomeQuote(text: 'آن که می‌آموزد و نمی‌اندیشد، گم است.', author: 'کنفوسیوس'),
    HomeQuote(
      text: 'داشتن زبانی دیگر یعنی داشتن روحی دوم.',
      author: 'شارلمانی',
    ),
    HomeQuote(
      text: 'مرزهای زبان من، مرزهای جهان من است.',
      author: 'لودویگ ویتگنشتاین',
    ),
    HomeQuote(
      text: 'یادگیری گنجی است که صاحبش را همه جا دنبال می‌کند.',
      author: 'ضرب‌المثل چینی',
    ),
    HomeQuote(
      text: 'دانش باغی است: اگر کشت نشود، برداشتی نیست.',
      author: 'ضرب‌المثل آفریقایی',
    ),
    HomeQuote(
      text: 'زیبایی یادگیری آن است که هیچ‌کس نمی‌تواند آن را از تو بگیرد.',
      author: 'بی.بی. کینگ',
    ),
    HomeQuote(
      text: 'باور کن که می‌توانی؛ نیمه‌راه آمده‌ای.',
      author: 'تئودور روزولت',
    ),
    HomeQuote(text: 'هیچ جایگزینی برای کار سخت نیست.', author: 'توماس ادیسون'),
    HomeQuote(
      text: 'نبوغ یک درصد الهام و نودونه درصد عرق است.',
      author: 'توماس ادیسون',
    ),
    HomeQuote(
      text: 'انرژی و پایداری همه چیز را شکست می‌دهد.',
      author: 'بنجامین فرانکلین',
    ),
    HomeQuote(
      text:
          'بهترین زمان کاشتن درخت بیست سال پیش بود. دومین زمان خوب، اکنون است.',
      author: 'ضرب‌المثل چینی',
    ),
    HomeQuote(
      text: 'اگر تند می‌خواهی، تنها برو. اگر دور می‌خواهی، با هم بروید.',
      author: 'ضرب‌المثل آفریقایی',
    ),
    HomeQuote(
      text: 'رود سنگ را نه با نیرو، که با پایداری می‌شکافد.',
      author: 'جیمز ان. واتکینز',
    ),
    HomeQuote(
      text:
          'کارهای کوچک انجام‌شده بهتر از کارهای بزرگ فقط برنامه‌ریزی‌شده است.',
      author: 'پیتر مارشال',
    ),
    HomeQuote(
      text: 'به ساعت نگاه نکن؛ همان کار او را بکن. ادامه بده.',
      author: 'سام لِونسون',
    ),
    HomeQuote(
      text: 'چه فکر کنی می‌توانی و چه فکر کنی نمی‌توانی، راست می‌گویی.',
      author: 'هنری فورد',
    ),
    HomeQuote(text: 'در میان دشواری، فرصت نهفته است.', author: 'آلبرت اینشتین'),
    HomeQuote(
      text:
          'آموزش نیرومندترین سلاحی است که می‌توانی برای تغییر جهان به کار ببری.',
      author: 'نلسون ماندلا',
    ),
    HomeQuote(
      text: 'زبانی دیگر، نگاهی دیگر به زندگی است.',
      author: 'فدریکو فلینی',
    ),
    HomeQuote(
      text: 'تمرین بهترین آموزگار همهٔ آموزگاران است.',
      author: 'پوبلیلیوس سیروس',
    ),
    HomeQuote(
      text: 'مهم نیست چقدر آهسته می‌روی، فقط نایست.',
      author: 'کنفوسیوس',
    ),
    HomeQuote(
      text: 'دانش راستین دانستن اندازهٔ نادانی خویش است.',
      author: 'کنفوسیوس',
    ),
    HomeQuote(text: 'ریشهٔ آموزش تلخ است، اما میوه‌اش شیرین.', author: 'ارسطو'),
    HomeQuote(
      text:
          'چنان زندگی کن که گویی فردا می‌میری. چنان بیاموز که گویی جاودانه می‌مانی.',
      author: 'مهاتما گاندی',
    ),
    HomeQuote(
      text: 'از رشد آهسته نترس؛ فقط از ایستادن بترس.',
      author: 'ضرب‌المثل چینی',
    ),
    HomeQuote(
      text: 'هیچ چیز کار نمی‌کند مگر آنکه تو کار کنی.',
      author: 'مایا آنجلو',
    ),
    HomeQuote(
      text: 'تنها خرد راستین دانستن این است که هیچ نمی‌دانی.',
      author: 'سقراط',
    ),
    HomeQuote(text: 'بخت با ذهن آماده یار است.', author: 'لوئی پاستور'),
    HomeQuote(
      text: 'آنچه با لذت می‌آموزیم هرگز فراموش نمی‌کنیم.',
      author: 'آلفرد مرسیه',
    ),
    HomeQuote(
      text: 'کتاب باغی است که در جیب حمل می‌شود.',
      author: 'ضرب‌المثل عربی',
    ),
    HomeQuote(
      text: 'کم‌رنگ‌ترین جوهر از بهترین حافظه بهتر است.',
      author: 'ضرب‌المثل چینی',
    ),
    HomeQuote(text: 'شکیبایی تلخ است، اما میوه‌اش شیرین.', author: 'ارسطو'),
    HomeQuote(
      text: 'با آموختن خواهی آموخت؛ با آموختن به دیگران خواهی آموخت.',
      author: 'ضرب‌المثل لاتین',
    ),
    HomeQuote(
      text: 'ندانستن بد است؛ نخواستن دانستن بدتر است.',
      author: 'ضرب‌المثل نیجریه‌ای',
    ),
    HomeQuote(
      text: 'کارشناس هر چیز زمانی تازه‌کار بوده است.',
      author: 'هلن هیز',
    ),
    HomeQuote(
      text: 'برای شروع لازم نیست بزرگ باشی، اما برای بزرگ شدن باید شروع کنی.',
      author: 'زیگ زیگلر',
    ),
    HomeQuote(
      text:
          'یک زبان تو را مادام‌العمر در راهرو می‌گذارد. دو زبان هر در را می‌گشاید.',
      author: 'فرانک اسمیت',
    ),
  ];

  static const Map<String, List<HomeQuote>> _tables = <String, List<HomeQuote>>{
    'en': english,
    'tr': turkish,
    'es': spanish,
    'ar': arabic,
    'fr': french,
    'de': german,
    'ru': russian,
    'pt': portuguese,
    'it': italian,
    'ja': japanese,
    'ko': korean,
    'zh': chinese,
    'hi': hindi,
    'id': indonesian,
    'fa': persian,
  };
}
