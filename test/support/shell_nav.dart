import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_core/core/widgets/lingo_bottom_nav.dart';

/// Icon-only bottom tabs keep their labels in semantics, not as [Text].
abstract final class ShellTabIndex {
  static const int home = 0;
  static const int words = 1;
  static const int phrases = 2;
  static const int favorites = 3;
  static const int settings = 4;
}

Finder shellTab(int index) {
  return find.byKey(ValueKey<String>('nav-item-$index'));
}

List<String> shellTabLabels(WidgetTester tester) {
  return tester
      .widgetList<LingoBottomNavItem>(find.byType(LingoBottomNavItem))
      .map((LingoBottomNavItem item) => item.label)
      .toList(growable: false);
}
