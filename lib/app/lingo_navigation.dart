import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Imperative navigation helpers. Screens push widgets, not named routes.
abstract final class LingoNavigation {
  static Future<T?> push<T extends Object?>(BuildContext context, Widget page) {
    return Navigator.of(context).push<T>(route(context, page));
  }

  static Route<T> route<T extends Object?>(BuildContext context, Widget page) {
    final TargetPlatform platform = Theme.of(context).platform;
    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      return CupertinoPageRoute<T>(builder: (BuildContext context) => page);
    }
    return MaterialPageRoute<T>(builder: (BuildContext context) => page);
  }
}
