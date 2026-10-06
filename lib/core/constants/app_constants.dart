import 'package:lingo_core/domain/product_config.dart';

abstract final class AppConstants {
  static String get appId => ProductConfig.current.id;
  static String get appDisplayName => ProductConfig.current.displayName;
  static const String appVersion = '0.1.0';
}
