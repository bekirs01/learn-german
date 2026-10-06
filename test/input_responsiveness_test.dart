import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_core/core/feedback/feedback_service.dart';
import 'package:lingo_core/core/theme/app_theme.dart';
import 'package:lingo_core/core/widgets/lingo_bottom_nav.dart';
import 'package:lingo_core/core/widgets/lingo_controls.dart';
import 'package:lingo_core/core/widgets/lingo_motion.dart';
import 'package:lingo_core/core/widgets/lingo_pressable.dart';

void main() {
  tearDown(FeedbackService.resetInstance);

  testWidgets('pressable shows compression on pointer down', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_harness(onPressed: () {}));

    expect(
      tester
          .state<LingoPressableState>(find.byType(LingoPressable))
          .debugPressed,
      isFalse,
    );

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.text('Go')),
    );
    await tester.pump();
    expect(
      tester
          .state<LingoPressableState>(find.byType(LingoPressable))
          .debugPressed,
      isTrue,
    );

    await gesture.up();
    await tester.pump();
    expect(
      tester
          .state<LingoPressableState>(find.byType(LingoPressable))
          .debugPressed,
      isFalse,
    );
  });

  testWidgets('pressable action runs on tap without waiting for haptics', (
    WidgetTester tester,
  ) async {
    int taps = 0;
    final Completer<void> hang = Completer<void>();
    FeedbackService.instance = FeedbackService(
      haptics: HapticService(driver: _HangingHapticDriver(hang)),
      soundEnabled: false,
    );

    await tester.pumpWidget(_harness(onPressed: () => taps += 1));
    await tester.tap(find.text('Go'));
    expect(taps, 1);
    hang.complete();
  });

  testWidgets('cancelled press does not fire the action', (
    WidgetTester tester,
  ) async {
    int taps = 0;
    await tester.pumpWidget(_harness(onPressed: () => taps += 1));

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.text('Go')),
    );
    await tester.pump();
    await gesture.moveBy(const Offset(0, 40));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(taps, 0);
    expect(
      tester
          .state<LingoPressableState>(find.byType(LingoPressable))
          .debugPressed,
      isFalse,
    );
  });

  testWidgets('disabled pressable ignores taps', (WidgetTester tester) async {
    int taps = 0;
    await tester.pumpWidget(
      _harness(onPressed: () => taps += 1, enabled: false),
    );

    await tester.tap(find.text('Go'));
    await tester.pump();
    expect(taps, 0);
  });

  testWidgets('rapid taps do not collapse into one action', (
    WidgetTester tester,
  ) async {
    int taps = 0;
    await tester.pumpWidget(_harness(onPressed: () => taps += 1));

    await tester.tap(find.text('Go'));
    await tester.tap(find.text('Go'));
    expect(taps, 2);
  });

  testWidgets('navbar selection callback runs on tap', (
    WidgetTester tester,
  ) async {
    int selected = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: const SizedBox.shrink(),
          bottomNavigationBar: LingoFloatingBottomNav(
            destinations: const <LingoNavDestination>[
              LingoNavDestination(label: 'Home', glyph: LingoNavGlyph.home),
              LingoNavDestination(label: 'Words', glyph: LingoNavGlyph.words),
            ],
            selectedIndex: selected,
            onSelected: (int index) => selected = index,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey<String>('nav-item-1')));
    expect(selected, 1);
  });

  testWidgets('glyph button tap does not wait for a hanging haptic', (
    WidgetTester tester,
  ) async {
    int taps = 0;
    final Completer<void> hang = Completer<void>();
    FeedbackService.instance = FeedbackService(
      haptics: HapticService(driver: _HangingHapticDriver(hang)),
      soundEnabled: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: LingoGlyphButton(
            icon: Icons.favorite_border_rounded,
            tooltip: 'Save',
            onPressed: () => taps += 1,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(LingoGlyphButton));
    expect(taps, 1);
    hang.complete();
  });

  testWidgets('tap scale compresses on pointer down', (
    WidgetTester tester,
  ) async {
    int taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Center(
            child: LingoTapScale(
              onPressed: () => taps += 1,
              child: const SizedBox(width: 80, height: 80, child: Text('Row')),
            ),
          ),
        ),
      ),
    );

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.text('Row')),
    );
    await tester.pump();
    expect(
      tester.state<LingoTapScaleState>(find.byType(LingoTapScale)).debugPressed,
      isTrue,
    );

    await gesture.up();
    await tester.pump();
    expect(taps, 1);
    expect(
      tester.state<LingoTapScaleState>(find.byType(LingoTapScale)).debugPressed,
      isFalse,
    );
  });
}

Widget _harness({required VoidCallback onPressed, bool enabled = true}) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      body: Center(
        child: LingoPressable(
          enabled: enabled,
          onPressed: onPressed,
          child: const Text('Go'),
        ),
      ),
    ),
  );
}

final class _HangingHapticDriver implements HapticDriver {
  _HangingHapticDriver(this._hang);

  final Completer<void> _hang;

  @override
  Future<void> play(HapticLevel level) => _hang.future;
}
