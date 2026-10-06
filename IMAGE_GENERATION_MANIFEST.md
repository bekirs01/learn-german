# Image generation manifest

See `docs/VISUAL_MAPPING.md` for the canonical category ID → asset ID table.

Current files are optional. Missing PNGs fall back to painted art; drop a replacement at the mapped path with no Dart changes. Register the folders in `pubspec.yaml`.

```yaml
flutter:
  assets:
    - assets/images/backgrounds/
    - assets/images/categories/words/
    - assets/images/categories/phrases/
    - assets/images/alphabet/
    - assets/images/home/
```

## Shared art direction

- Premium editorial still-life with a tactile 3D clay/gouache feel
- Varied palette: teal `#1B6568`, terracotta `#C46A3C`, dusty plum `#6A5A86`, sage `#3A7F62`, ivory `#F4EFE6`
- Avoid childish cartoons and beige-on-beige repetition
- Gentle studio light from the upper left; subject large in frame
- No text, letters, logos, UI chrome, watermarks, or emojis

## Background

| Path | Aspect | Purpose | Generation description |
| --- | --- | --- | --- |
| `assets/images/backgrounds/paper_crumpled.png` | 3:4 | Full-bleed app paper field. Subtle crumpled stationery, not a repeating tile. | Photographed close-up of premium crumpled handmade cream watercolor paper filling the frame. Warm ivory `#F4EFE6`. Natural cotton fiber, soft irregular folds and gentle creases with quiet valley shadows. No repeating tile, no text, no stains, no grid. Calm even studio lighting. Physical stationery, not digital noise. |

## Word categories (1:1, 2048×2048 preferred)

| Path | Purpose | Generation description |
| --- | --- | --- |
| `assets/images/categories/words/animals.png` | Animals card | Friendly fox and small bird on cream paper. No cage. |
| `assets/images/categories/words/food.png` | Food card | Ceramic bowl of bread, fruit, and water on linen. |
| `assets/images/categories/words/body.png` | Body card | Calm simplified figure showing hands and profile as a still-life, not a mascot. |
| `assets/images/categories/words/emotions.png` | Emotions card | Two smooth abstract faces, one smiling and one thoughtful. |
| `assets/images/categories/words/family.png` | Family card | Three small wooden figures standing together on a table. |
| `assets/images/categories/words/home.png` | Home card | Cozy house still-life: window, plant, kettle. |
| `assets/images/categories/words/nature.png` | Nature card | Quiet landscape: hills, a tree, and a sun. |
| `assets/images/categories/words/work.png` | Work card | Wooden desk with notebook, lamp, and ceramic cup. |
| `assets/images/categories/words/sports.png` | Sports card | Tennis racket, ball, and water bottle. |
| `assets/images/categories/words/shopping.png` | Shopping card | Paper shopping bag, folded cloth, and fruit. |
| `assets/images/categories/words/travel.png` | Travel card | Compact leather suitcase and folded map in front of hills. |
| `assets/images/categories/words/numbers.png` | Numbers card | Three wooden counting blocks of different sizes. No numerals. |
| `assets/images/categories/words/basics.png` | Basics card | Open notebook, plant, and ceramic cup. Teal and cream. |
| `assets/images/categories/words/colors.png` | Colors card | Three paint pans in teal, terracotta, and plum. |
| `assets/images/categories/words/people.png` | People card | Two simplified adult silhouettes as still-life, not mascots. |
| `assets/images/categories/words/drinks.png` | Drinks card | Glass carafe and ceramic cup with citrus. |
| `assets/images/categories/words/clothing.png` | Clothing card | Folded shirt, shoes, and hat. |
| `assets/images/categories/words/weather.png` | Weather card | Cloud, rain thread, and sun disc. No symbols. |
| `assets/images/categories/words/school.png` | School card | Open book, pencil, and notebook. |
| `assets/images/categories/words/transportation.png` | Transportation card | Compact train and bicycle. |
| `assets/images/categories/words/health.png` | Health card | Small bottle, cloth, and bowl. No medical marks. |
| `assets/images/categories/words/time.png` | Time card | Clock face with no numerals, plus sun and moon. |
| `assets/images/categories/words/places.png` | Places card | Small building, tree, and path. |

## Phrase categories (1:1, 2048×2048 preferred)

| Path | Purpose | Generation description |
| --- | --- | --- |
| `assets/images/categories/phrases/greetings.png` | Greetings card | Open doorway with warm light and a small plant. |
| `assets/images/categories/phrases/introductions.png` | Introductions card | Two teacups meeting on a shared saucer. |
| `assets/images/categories/phrases/restaurant.png` | Restaurant card | Plate, glass, folded napkin, and cutlery. |
| `assets/images/categories/phrases/hotel.png` | Hotel card | Key, small suitcase, and a pillow. |
| `assets/images/categories/phrases/airport.png` | Airport card | Folded pass, small suitcase, distant plane silhouette. No readable text. |
| `assets/images/categories/phrases/directions.png` | Directions card | Paper map, compass, and a winding path mark. No letters. |
| `assets/images/categories/phrases/doctor.png` | Doctor card | Stethoscope, small bottle, and folded cloth. No red-cross mark. |
| `assets/images/categories/phrases/emergency.png` | Emergency card | Lantern, plain tin, and coiled rope. No symbols or text. |
| `assets/images/categories/phrases/shopping.png` | Shopping card | Market stall with produce, paper bag, and woven basket. |
| `assets/images/categories/phrases/transportation.png` | Transportation card | Compact train, bicycle, and a blank ticket stub. |
| `assets/images/categories/phrases/daily_conversation.png` | Daily conversation card | Two chairs at a small table with steaming cups and window light. |
| `assets/images/categories/phrases/questions.png` | Questions card | Folded map and a small pointing pin. No letters. |
| `assets/images/categories/phrases/cafe.png` | Cafe card | Coffee cup, saucer, and pastry. |
| `assets/images/categories/phrases/pharmacy.png` | Pharmacy card | Two small bottles and a folded paper sachet. No text. |
| `assets/images/categories/phrases/social_situations.png` | Social situations card | Gift box and two cups on a small table. |

## Alphabet examples (1:1, 1024×1024)

Per-letter still-lifes live in `assets/images/alphabet/` and are referenced from `alphabet.json` via `language_pack.json` → `assetIndex`. Replace the PNG; keep the ID. Do not paint the letter into the image.

| Path | German example | Notes |
| --- | --- | --- |
| `apple.png` | Apfel | Reused |
| `book.png` | Buch | Reused |
| `computer.png` | Computer | New |
| `delfin.png` | Delfin | New |
| `egg.png` | Ei | Reused |
| `fish.png` | Fisch | Reused |
| `garden.png` | Garten | Reused |
| `house.png` | Haus | Reused |
| `igel.png` | Igel | New |
| `jacke.png` | Jacke | New |
| `cat.png` | Katze | Reused (moved from C) |
| `lamp.png` | Lampe | Reused |
| `moon.png` | Mond | Reused |
| `night.png` | Nacht | Reused |
| `orange.png` | Orange | Reused |
| `paper.png` | Papier | Reused |
| `qualle.png` | Qualle | New |
| `rain.png` | Regen | Reused |
| `sun.png` | Sonne | Reused |
| `table.png` | Tisch | Reused |
| `uhr.png` | Uhr | New |
| `violin.png` | Violine | Reused |
| `water.png` | Wasser | Reused |
| `xylophon.png` | Xylophon | New |
| `yacht.png` | Yacht | New |
| `zoo.png` | Zoo | Reused |
| `aepfel.png` | Äpfel | New |
| `oel.png` | Öl | New |
| `uebung.png` | Übung | New |
| `strasse.png` | Straße | New |

Removed unused English-only stills: `dog.png`, `ice.png`, `juice.png`, `key.png`, `queen.png`, `umbrella.png`, `box.png`, `yellow.png`.

## Home destinations (1:1, 1024×1024 or 2048×2048)

| Path | Purpose | Generation description |
| --- | --- | --- |
| `assets/images/home/alphabet.png` | Alphabet Home card | Teal ink pot, calligraphy brush, blank ivory paper, plum wax seal. No letters. |
| `assets/images/home/words.png` | Words Home card | Closed cream clothbound book, terracotta ribbon, blank ivory vocabulary cards. No letters. |
| `assets/images/home/phrases.png` | Phrases Home card | Two ceramic cups facing each other on a shared saucer. Conversation still-life. No text. |
| `assets/images/home/quiz.png` | Quiz Home card | Stacked ceramic tokens in teal, terracotta, and plum. No marks or text. |
| `assets/images/home/wrong_answers.png` | Wrong Answers Home card | Notebook with a folded corner, wooden pencil, terracotta ribbon. No letters or X marks. |
| `assets/images/home/apple_watch.png` | Apple Watch Home card | Cream ceramic rounded-square wristwatch with a teal band, blank ivory flashcard, terracotta wax disc. No logo, numerals, UI, or text. |

## Do not generate in this set

- App icon, launch image, or store screenshots
- Dark-mode variants
- Category names painted into the image
