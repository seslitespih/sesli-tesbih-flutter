import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sesli_tesbih/screens/counter_screen.dart';

/// Layout regression tests: on compact Android phones the counter screen was
/// taller than the viewport, so the Start / Reset / Target row sat below the
/// fold. Everything must fit without scrolling, down to a 360×640 screen.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Speech plugins do not exist in the test host; report "unavailable".
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugin.csdcorp.com/speech_to_text'),
      (call) async => call.method == 'initialize' ? false : null,
    );
  });

  Future<void> pumpCounter(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: CounterScreen(dhikrId: 1)),
    );
    // The mic ring animates forever, so settle by hand.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
  }

  for (final size in const [
    Size(360, 640), // compact Android (e.g. Galaxy A-series, older devices)
    Size(360, 740), // mainstream Android
    Size(393, 852), // iPhone 15 class
  ]) {
    testWidgets('controls fit on ${size.width.toInt()}×${size.height.toInt()}',
        (tester) async {
      await pumpCounter(tester, size);
      expect(tester.takeException(), isNull);

      // The action row is the last element: if its bottom edge is inside the
      // viewport, nothing below the fold is hidden.
      final resetIcon = find.byIcon(Icons.refresh_rounded);
      expect(resetIcon, findsOneWidget);

      final box = tester.getRect(resetIcon);
      expect(box.bottom, lessThanOrEqualTo(size.height),
          reason: 'reset button is pushed off a ${size.height.toInt()} dp '
              'tall screen');
      expect(box.top, greaterThan(0));
    });
  }

  testWidgets('tapping the counter still increments after scaling',
      (tester) async {
    await pumpCounter(tester, const Size(360, 640));
    expect(find.text('0'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.touch_app_outlined));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('1'), findsOneWidget);
  });
}
