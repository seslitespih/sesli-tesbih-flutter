import 'package:flutter_test/flutter_test.dart';
import 'package:sesli_tesbih/services/stt_stall_watchdog.dart';

void main() {
  group('SttStallWatchdog', () {
    test('a recogniser that went mute while the user keeps chanting is renewed',
        () {
      final w = SttStallWatchdog();
      // rhythm: result at 3.3 s, 5.2 s … 15.9 s, then nothing
      for (final t in [3300, 5200, 7100, 8900, 10600, 12400, 14200, 15900]) {
        w.noteResult(t, matched: true);
      }
      expect(w.shouldRenew(16000), isFalse); // just heard it
      // words 9 and 10 are spoken, the recogniser stays silent
      w.noteBurst(); // 17.4
      w.noteBurst(); // 18.1
      w.noteBurst(); // 19.1
      expect(w.shouldRenew(18000), isFalse); // not mute long enough yet
      expect(w.shouldRenew(19500), isTrue);
    });

    test('plain silence never triggers it (no bursts)', () {
      final w = SttStallWatchdog();
      w.noteResult(1000, matched: true);
      expect(w.shouldRenew(60000), isFalse);
    });

    test('unrelated talk never triggers it (no recent dhikr match)', () {
      final w = SttStallWatchdog();
      w.noteSessionStart(0);
      for (var i = 0; i < 10; i++) {
        w.noteBurst();
      }
      expect(w.shouldRenew(30000), isFalse);
      // results that do not contain the dhikr do not make it "active"
      w.noteResult(31000, matched: false);
      for (var i = 0; i < 10; i++) {
        w.noteBurst();
      }
      expect(w.shouldRenew(40000), isFalse);
    });

    test('stops being active once the user has been quiet for a while', () {
      final w = SttStallWatchdog(activeWindowMs: 20000);
      w.noteResult(1000, matched: true);
      for (var i = 0; i < 5; i++) {
        w.noteBurst();
      }
      expect(w.shouldRenew(25000), isFalse); // matched 24 s ago
    });

    test('cannot become a mic on/off loop: one renewal per cooldown', () {
      final w = SttStallWatchdog(cooldownMs: 8000);
      w.noteResult(1000, matched: true);
      var renewals = 0;
      // the user chants on for 20 s and the recogniser never recovers
      for (var t = 5000; t <= 25000; t += 500) {
        w.noteBurst();
        if (w.shouldRenew(t)) renewals++;
      }
      expect(renewals, lessThanOrEqualTo(3));
      expect(renewals, greaterThanOrEqualTo(1));
    });

    test('a result clears the burst count, so a healthy session is left alone',
        () {
      final w = SttStallWatchdog();
      w.noteResult(1000, matched: true);
      w.noteBurst();
      w.noteBurst();
      w.noteResult(2500, matched: true); // recogniser keeps up
      w.noteBurst();
      expect(w.burstsSinceResult, 1);
      expect(w.shouldRenew(9000), isFalse); // only 1 burst, no stall
    });

    test('a fresh session restarts the silence clock', () {
      final w = SttStallWatchdog();
      w.noteResult(1000, matched: true);
      w.noteSessionStart(9000);
      for (var i = 0; i < 4; i++) {
        w.noteBurst();
      }
      expect(w.shouldRenew(10000), isFalse); // new session, 1 s old
      expect(w.shouldRenew(13000), isTrue);
    });
  });
}
