import 'package:flutter/material.dart';
import 'package:lingo_core/core/theme/app_theme.dart';
import 'package:lingo_core/core/theme/lingo_feedback.dart';
import 'package:lingo_core/core/theme/lingo_tokens.dart';
import 'package:lingo_core/core/widgets/lingo_pressable.dart';
import 'package:lingo_core/features/home/home_artwork.dart';

/// Near-square Home destination. Artwork fills the card; the title sits on a
/// compact cream lip rather than a separate caption block.
class HomeDestinationCard extends StatelessWidget {
  const HomeDestinationCard({
    super.key,
    required this.label,
    required this.art,
    required this.onPressed,
    this.detail,
  });

  static const double cardAspectRatio = 1.04;
  static const double _labelHeight = 1.08;
  static const double _labelSize = 13;

  final String label;
  final HomeDestinationArt art;
  final VoidCallback onPressed;

  /// Optional calm secondary value, such as a Wrong Answers count.
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color tint = homeArtTint(art, theme.colors);
    final TextStyle labelStyle = (textTheme.labelMedium ?? const TextStyle())
        .copyWith(
          fontSize: _labelSize,
          height: _labelHeight,
          letterSpacing: -0.16,
          fontWeight: FontWeight.w600,
          color: theme.colors.onSurface,
        );
    final Color cardColor =
        Color.lerp(theme.colors.cardFill, tint, 0.05) ?? theme.colors.cardFill;
    final Color wellColor =
        Color.lerp(theme.colors.cardFill, tint, 0.10) ?? theme.colors.cardFill;
    final String? detail = this.detail;
    final String semanticLabel = detail == null || detail.isEmpty
        ? label
        : '$label, $detail';

    return LingoPressable(
      onPressed: onPressed,
      feedbackKind: LingoFeedbackKind.select,
      color: cardColor,
      depth: LingoElevation.raised,
      borderRadius: LingoRadii.poster,
      padding: EdgeInsets.zero,
      minHeight: 0,
      semanticLabel: semanticLabel,
      semanticButton: true,
      child: AspectRatio(
        aspectRatio: cardAspectRatio,
        child: ColoredBox(
          color: wellColor,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              HomeArtwork(
                art: art,
                fit: BoxFit.cover,
                alignment: homeArtAlignment(art),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          cardColor.withValues(alpha: 0),
                          cardColor.withValues(alpha: 0.72),
                          cardColor.withValues(alpha: 0.96),
                        ],
                        stops: const <double>[0, 0.42, 1],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 22, 10, 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              label,
                              style: labelStyle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (detail != null && detail.isNotEmpty) ...<Widget>[
                            const SizedBox(width: LingoSpacing.sm),
                            _HomeCountBadge(value: detail, art: art),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeCountBadge extends StatelessWidget {
  const _HomeCountBadge({required this.value, required this.art});

  final String value;
  final HomeDestinationArt art;

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colors.surfaceRaised.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(LingoRadii.pill),
        border: Border.all(color: theme.colors.paperRim, width: 0.7),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: LingoSpacing.sm,
          vertical: 3,
        ),
        child: Text(
          value,
          key: art == HomeDestinationArt.wrongAnswers
              ? const ValueKey<String>('home-wrong-answers-count')
              : null,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            height: 1.1,
            fontWeight: FontWeight.w600,
            color: theme.colors.onSurface,
          ),
          maxLines: 1,
        ),
      ),
    );
  }
}
