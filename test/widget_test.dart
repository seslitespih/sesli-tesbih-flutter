import 'package:flutter_test/flutter_test.dart';
import 'package:sesli_tesbih/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SesliTesbihApp());
    // Let the splash screen's navigation timer fire so no timers are
    // pending when the test tears down.
    await tester.pump(const Duration(seconds: 4));
  });
}
