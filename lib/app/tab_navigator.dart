import 'package:flutter/material.dart';
import 'package:lingo_core/app/lingo_navigation.dart';

/// Nested navigator for a single bottom-navigation tab.
///
/// The [NavigatorState] key is owned by the shell so stacks survive tab
/// switches. New screens are pushed with [LingoNavigation.route], not names.
class TabNavigator extends StatelessWidget {
  const TabNavigator({
    super.key,
    required this.navigatorKey,
    required this.root,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget root;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (RouteSettings settings) {
        return LingoNavigation.route(context, root);
      },
    );
  }
}
