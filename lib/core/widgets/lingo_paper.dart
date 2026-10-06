import 'package:flutter/material.dart';
import 'package:lingo_core/core/assets/lingo_assets.dart';
import 'package:lingo_core/core/theme/app_theme.dart';
import 'package:lingo_core/core/theme/lingo_tokens.dart';
import 'package:lingo_core/core/widgets/lingo_artwork.dart';

/// App-wide paper field. The crumpled photograph is the signature;
/// a light cream wash keeps type readable on top.
class LingoPaperBackdrop extends StatelessWidget {
  const LingoPaperBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final Color canvas = LingoTheme.of(context).colors.canvas;
    final Size size = MediaQuery.sizeOf(context);

    return RepaintBoundary(
      child: ColoredBox(
        color: canvas,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Positioned.fill(
              child: lingoSkipDecodedPhotos
                  ? const SizedBox.shrink()
                  : Image.asset(
                      LingoAssets.paperCrumpled,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      cacheWidth: lingoCacheWidth(context, size.width),
                      filterQuality: FilterQuality.medium,
                      gaplessPlayback: true,
                      errorBuilder:
                          (
                            BuildContext context,
                            Object error,
                            StackTrace? stackTrace,
                          ) {
                            return const SizedBox.shrink();
                          },
                    ),
            ),
            Positioned.fill(
              child: ColoredBox(color: canvas.withValues(alpha: 0.14)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grouped chrome that lets the crumpled paper read through a cream wash.
class LingoPaperSurface extends StatelessWidget {
  const LingoPaperSurface({
    super.key,
    required this.child,
    this.borderRadius = LingoRadii.card,
    this.padding,
    this.clip = true,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);
    final LingoColors colors = theme.colors;
    final EdgeInsetsGeometry? padding = this.padding;
    final Widget content = padding == null
        ? child
        : Padding(padding: padding, child: child);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.paperFill,
        borderRadius: borderRadius,
        border: Border.all(color: colors.paperRim, width: 0.7),
        boxShadow: theme.shadows.paper,
      ),
      child: clip
          ? ClipRRect(borderRadius: borderRadius, child: content)
          : content,
    );
  }
}
