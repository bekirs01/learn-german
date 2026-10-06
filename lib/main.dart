import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:lingo_core/app/app.dart';
import 'package:lingo_core/core/feedback/feedback_service.dart';
import 'package:lingo_core/data/user_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final UserPreferences prefs = await UserPreferences.bootstrap();
  FeedbackService.instance.soundEnabled = prefs.getSoundEnabled();
  FeedbackService.instance.hapticsEnabled = prefs.getHapticsEnabled();
  unawaited(FeedbackService.instance.warmUp());
  runApp(const LingoCoreApp());
}
