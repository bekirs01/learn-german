import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lingo_core/core/feedback/feedback_service.dart';

/// Developer-only control surface for exercising [FeedbackService].
///
/// Not registered in app navigation, the bottom bar, or production routes.
/// Widget tests and a local `home:` swap are the intended entry points.
class FeedbackHarness extends StatefulWidget {
  const FeedbackHarness({super.key, this.service});

  final FeedbackService? service;

  @override
  State<FeedbackHarness> createState() => _FeedbackHarnessState();
}

class _FeedbackHarnessState extends State<FeedbackHarness> {
  static const List<FeedbackEvent> _events = <FeedbackEvent>[
    FeedbackEvent.tap,
    FeedbackEvent.selection,
    FeedbackEvent.quizCorrect,
    FeedbackEvent.quizWrong,
    FeedbackEvent.favoriteAdded,
    FeedbackEvent.letterSelected,
  ];

  late final FeedbackService _controller =
      widget.service ?? FeedbackService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feedback harness')),
      body: ListView(
        children: <Widget>[
          SwitchListTile(
            title: const Text('Sound'),
            value: _controller.soundEnabled,
            onChanged: (bool value) {
              setState(() {
                _controller.soundEnabled = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Haptics'),
            value: _controller.hapticsEnabled,
            onChanged: (bool value) {
              setState(() {
                _controller.hapticsEnabled = value;
              });
            },
          ),
          for (final FeedbackEvent event in _events)
            ListTile(
              title: Text(event.name),
              onTap: () {
                unawaited(_controller.dispatch(event));
              },
            ),
        ],
      ),
    );
  }
}
