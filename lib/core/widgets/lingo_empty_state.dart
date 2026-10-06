import 'package:flutter/material.dart';
import 'package:lingo_core/core/theme/app_theme.dart';
import 'package:lingo_core/core/theme/lingo_tokens.dart';
import 'package:lingo_core/core/widgets/lingo_layout.dart';

class LingoEmptyState extends StatelessWidget {
  const LingoEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.framed = true,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final bool framed;

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Widget? action = this.action;
    final String? message = this.message;

    final Widget content = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: LingoSpacing.lg,
        vertical: framed ? LingoSpacing.xxxl : LingoSpacing.xxl,
      ),
      child: Column(
        children: <Widget>[
          LingoIconWell(
            icon: icon,
            color: theme.colors.tertiary,
            size: LingoIconSize.xl,
          ),
          const SizedBox(height: LingoSpacing.md),
          Text(
            title,
            style: textTheme.titleMedium,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (message != null && message.isNotEmpty) ...<Widget>[
            const SizedBox(height: LingoSpacing.sm),
            Text(
              message,
              style: textTheme.bodyMedium?.copyWith(
                color: theme.colors.onSurfaceMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (action != null) ...<Widget>[
            const SizedBox(height: LingoSpacing.xl),
            action,
          ],
        ],
      ),
    );

    if (!framed) {
      return content;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colors.paperFill,
        borderRadius: LingoRadii.card,
        border: Border.all(color: theme.colors.paperRim, width: 0.7),
        boxShadow: theme.shadows.paper,
      ),
      child: content,
    );
  }
}
