import 'package:flutter_test/flutter_test.dart';
import 'package:sesli_tesbih/services/stt_diagnostics.dart';

void main() {
  group('SttDiagnostics', () {
    test('records events with seconds since the first one', () {
      final d = SttDiagnostics();
      d.log(5000, 'status', 'listening');
      d.log(6500, 'result', 'final=false n=1');
      final out = d.dump();
      expect(out, contains('0.00  status  listening'));
      expect(out, contains('1.50  result  final=false n=1'));
    });

    test('counts per tag so a storm is visible at a glance', () {
      final d = SttDiagnostics();
      for (var i = 0; i < 7; i++) {
        d.log(i * 100, 'restart', 'reason=done');
      }
      d.log(900, 'error', 'error_no_match');
      expect(d.counter('restart'), 7);
      expect(d.dump(), contains('error=1 restart=7'));
    });

    test('is a ring buffer: oldest events go, counters keep the totals', () {
      final d = SttDiagnostics(capacity: 5);
      for (var i = 0; i < 12; i++) {
        d.log(i, 'tick', '$i');
      }
      expect(d.length, 5);
      expect(d.dropped, 7);
      expect(d.counter('tick'), 12);
      final out = d.dump();
      expect(out, contains('oldest 7 events dropped'));
      expect(out, contains('tick  11'));
      expect(out, isNot(contains('tick  0\n')));
    });

    test('prints the caller\'s header first', () {
      final d = SttDiagnostics();
      d.log(0, 'status', 'listening');
      expect(d.dump(header: 'platform=ios v1.5.6').startsWith('platform=ios'),
          isTrue);
    });

    test('clear starts a fresh timeline', () {
      final d = SttDiagnostics();
      d.log(1000, 'a');
      d.clear();
      d.log(9000, 'b');
      expect(d.dump(), contains('0.00  b'));
      expect(d.counter('a'), 0);
    });
  });
}
