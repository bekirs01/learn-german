import 'package:flutter/material.dart';
import 'package:lingo_core/core/theme/app_theme.dart';
import 'package:lingo_core/core/theme/lingo_tokens.dart';
import 'package:lingo_core/core/widgets/lingo_motion.dart';
import 'package:lingo_core/core/widgets/lingo_paper.dart';
import 'package:lingo_core/core/widgets/lingo_progress.dart';

/// Standard screen chrome: paper field, optional app bar, optional footer.
class LingoPage extends StatelessWidget {
  const LingoPage({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.footer,
    this.showAppBar = true,
    this.titleSpacing,
  });

  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final Widget? footer;
  final bool showAppBar;
  final double? titleSpacing;

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);
    final String? title = this.title;
    final bool canPop = ModalRoute.of(context)?.canPop ?? false;

    return Scaffold(
      backgroundColor: theme.colors.canvas,
      resizeToAvoidBottomInset: true,
      appBar: showAppBar
          ? AppBar(
              toolbarHeight: LingoSpacing.toolbar,
              leadingWidth: LingoSpacing.toolbar + LingoSpacing.sm,
              titleSpacing: titleSpacing ?? 0,
              automaticallyImplyLeading: false,
              leading: canPop ? const LingoBackButton() : null,
              title: title == null
                  ? null
                  : Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
              actions: actions,
              actionsPadding: const EdgeInsetsDirectional.only(
                end: LingoSpacing.xs,
              ),
            )
          : null,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const LingoPaperBackdrop(),
          Column(
            children: <Widget>[
              Expanded(child: body),
              ?footer,
            ],
          ),
        ],
      ),
    );
  }
}

/// Compact iOS-style back control used by pushed [LingoPage] chrome.
class LingoBackButton extends StatelessWidget {
  const LingoBackButton({super.key});

  static const ValueKey<String> buttonKey = ValueKey<String>('lingo-back');

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);
    final String tooltip = MaterialLocalizations.of(context).backButtonTooltip;

    return Semantics(
      key: buttonKey,
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: LingoTapScale(
          onPressed: () {
            Navigator.of(context).maybePop();
          },
          child: SizedBox(
            width: LingoSpacing.toolbar,
            height: LingoSpacing.toolbar,
            child: Align(
              alignment: AlignmentDirectional.center,
              child: Transform.scale(
                scaleX: Directionality.of(context) == TextDirection.rtl
                    ? -1
                    : 1,
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 17,
                  color: theme.colors.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Trailing chrome for root tabs that no longer repeat the tab name.
class LingoRootActions extends StatelessWidget {
  const LingoRootActions({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: LingoSpacing.sm),
      child: Align(alignment: AlignmentDirectional.centerEnd, child: child),
    );
  }
}

/// Leading-aligned title used on root tabs instead of a compact app bar.
class LingoLargeTitle extends StatelessWidget {
  const LingoLargeTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final LingoTheme theme = LingoTheme.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String? subtitle = this.subtitle;
    final Widget? trailing = this.trailing;

    final Widget titleText = Semantics(
      header: true,
      child: Text(
        title,
        style: textTheme.displayLarge,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: LingoSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (trailing == null)
            titleText
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(child: titleText),
                const SizedBox(width: LingoSpacing.md),
                trailing,
              ],
            ),
          if (subtitle != null && subtitle.isNotEmpty) ...<Widget>[
            const SizedBox(height: LingoSpacing.sm),
            Text(
              subtitle,
              style: textTheme.bodyLarge?.copyWith(
                color: theme.colors.onSurfaceMuted,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

/// Max-width, guttered scrolling column used by most Lingo screens.
class LingoContent extends StatelessWidget {
  const LingoContent({
    super.key,
    this.children = const <Widget>[],
    this.header,
    this.itemCount,
    this.itemBuilder,
    this.itemGap,
    this.empty,
    this.controller,
    this.storageKey,
    this.topSafeArea = false,
    this.bottomPadding,
    this.topInset,
    this.showScrollProgress = false,
  });

  final List<Widget> children;
  final Widget? header;
  final int? itemCount;
  final IndexedWidgetBuilder? itemBuilder;
  final double? itemGap;
  final Widget? empty;
  final ScrollController? controller;
  final String? storageKey;
  final bool topSafeArea;
  final double? bottomPadding;
  final double? topInset;
  final bool showScrollProgress;

  @override
  Widget build(BuildContext context) {
    final LingoMetrics metrics = LingoMetrics.of(context);
    final MediaQueryData media = MediaQuery.of(context);
    final double top =
        topInset ??
        (topSafeArea
            ? media.padding.top + metrics.rootTopGap
            : LingoSpacing.lg);
    final double bottom =
        bottomPadding ?? metrics.floatingChromeClearance + media.padding.bottom;
    final String? storageKey = this.storageKey;
    final IndexedWidgetBuilder? itemBuilder = this.itemBuilder;

    final Widget list = itemBuilder == null
        ? ListView(
            key: storageKey == null ? null : PageStorageKey<String>(storageKey),
            controller: controller,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              metrics.horizontalGutter,
              top,
              metrics.horizontalGutter,
              bottom,
            ),
            children: children,
          )
        : _LingoLazyLearningList(
            storageKey: storageKey,
            controller: controller,
            metrics: metrics,
            top: top,
            bottom: bottom,
            gap: itemGap ?? LingoSpacing.sm,
            header: header,
            itemCount: itemCount ?? 0,
            itemBuilder: itemBuilder,
            empty: empty,
          );

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: metrics.maxContentWidth),
        child: LingoEdgeScrollProgress(
          enabled: showScrollProgress,
          child: list,
        ),
      ),
    );
  }
}

class _LingoLazyLearningList extends StatelessWidget {
  const _LingoLazyLearningList({
    required this.metrics,
    required this.top,
    required this.bottom,
    required this.gap,
    required this.itemCount,
    required this.itemBuilder,
    this.storageKey,
    this.controller,
    this.header,
    this.empty,
  });

  final LingoMetrics metrics;
  final double top;
  final double bottom;
  final double gap;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final String? storageKey;
  final ScrollController? controller;
  final Widget? header;
  final Widget? empty;

  @override
  Widget build(BuildContext context) {
    final Widget? header = this.header;
    final Widget? empty = this.empty;
    final String? storageKey = this.storageKey;
    final bool showIntro = header != null || (itemCount == 0 && empty != null);

    return CustomScrollView(
      key: storageKey == null ? null : PageStorageKey<String>(storageKey),
      controller: controller,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: <Widget>[
        if (showIntro)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              metrics.horizontalGutter,
              top,
              metrics.horizontalGutter,
              itemCount == 0 ? bottom : 0,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  ?header,
                  if (itemCount == 0 && empty != null) ...<Widget>[
                    if (header != null) SizedBox(height: gap),
                    empty,
                  ],
                ],
              ),
            ),
          ),
        if (itemCount > 0)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              metrics.horizontalGutter,
              showIntro ? gap : top,
              metrics.horizontalGutter,
              bottom,
            ),
            sliver: SliverList.separated(
              itemCount: itemCount,
              itemBuilder: itemBuilder,
              separatorBuilder: (BuildContext context, int index) {
                return SizedBox(height: gap);
              },
            ),
          ),
      ],
    );
  }
}

/// One- or two-column layout that stacks on compact widths and large text.
class LingoPairGrid extends StatelessWidget {
  const LingoPairGrid({
    super.key,
    required this.children,
    this.spacing,
    this.stack,
  });

  final List<Widget> children;
  final double? spacing;
  final bool? stack;

  @override
  Widget build(BuildContext context) {
    final LingoMetrics metrics = LingoMetrics.of(context);
    final double spacing = this.spacing ?? metrics.categoryGridGap;
    final bool stack =
        this.stack ?? (metrics.stackTightCards || children.length == 1);

    if (stack || children.length == 1) {
      return Column(
        children: <Widget>[
          for (int index = 0; index < children.length; index++) ...<Widget>[
            if (index > 0) SizedBox(height: spacing),
            children[index],
          ],
        ],
      );
    }

    final List<Widget> rows = <Widget>[];
    for (int index = 0; index < children.length; index += 2) {
      final Widget left = children[index];
      final Widget? right = index + 1 < children.length
          ? children[index + 1]
          : null;
      rows.add(
        Padding(
          padding: EdgeInsets.only(
            bottom: index + 2 < children.length ? spacing : 0,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: left),
              SizedBox(width: spacing),
              Expanded(child: right ?? const SizedBox.shrink()),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

/// Tinted rounded icon well used on cards and headers.
class LingoIconWell extends StatelessWidget {
  const LingoIconWell({
    super.key,
    required this.icon,
    this.color,
    this.size = LingoIconSize.lg,
  });

  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Color color = this.color ?? LingoTheme.of(context).colors.primary;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(LingoRadii.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(LingoSpacing.sm),
        child: Icon(icon, color: color, size: size),
      ),
    );
  }
}
