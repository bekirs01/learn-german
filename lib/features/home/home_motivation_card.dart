import 'package:flutter/material.dart';
import 'package:lingo_core/core/l10n/ui_strings.dart';
import 'package:lingo_core/core/theme/app_theme.dart';
import 'package:lingo_core/core/theme/lingo_tokens.dart';
import 'package:lingo_core/features/home/home_motivation.dart';

/// Daily Home quote: readable body copy plus a named author.
class HomeMotivationCard extends StatelessWidget {
  const HomeMotivationCard({super.key, required this.quote});

  static const ValueKey<String> quoteKey = ValueKey<String>(
    'home-motivation-quote',
  );
  static const ValueKey<String> authorKey = ValueKey<String>(
    'home-motivation-author',
  );

  final HomeQuote quote;

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String author = quote.author.trim();
    // Bake the paper wash into an opaque cream so the card is not a second
    // frosted pane sitting over the crumpled field.
    final Color fill = Color.alphaBlend(
      theme.colors.paperFill,
      theme.colors.cardFill,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: LingoRadii.card,
        border: Border.all(color: theme.colors.paperRim, width: 0.7),
        boxShadow: theme.shadows.paper,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          LingoSpacing.lg,
          16,
          LingoSpacing.lg,
          14,
        ),
        child: Semantics(
          label: author.isEmpty ? quote.text : '${quote.text}. $author',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                quote.text,
                key: quoteKey,
                textAlign: TextAlign.start,
                softWrap: true,
                style: (textTheme.bodyLarge ?? const TextStyle()).copyWith(
                  fontSize: 16,
                  height: 1.34,
                  letterSpacing: -0.12,
                  fontWeight: FontWeight.w400,
                  color: theme.colors.onSurface,
                ),
              ),
              if (author.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  '— $author',
                  key: authorKey,
                  textAlign: TextAlign.end,
                  softWrap: true,
                  style: (textTheme.labelMedium ?? const TextStyle()).copyWith(
                    fontSize: 13,
                    height: 1.2,
                    letterSpacing: 0.04,
                    fontWeight: FontWeight.w500,
                    color: theme.colors.onSurfaceMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Resolves the current local-day quote for the active Translation Language.
class HomeMotivationQuote extends StatelessWidget {
  const HomeMotivationQuote({super.key});

  @override
  Widget build(BuildContext context) {
    final String language = UiScope.languageOf(context);
    return HomeMotivationCard(quote: HomeMotivationQuotes.todayFor(language));
  }
}
