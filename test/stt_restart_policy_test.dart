import 'package:flutter_test/flutter_test.dart';
import 'package:sesli_tesbih/services/stt_restart_policy.dart';

void main() {
  group('SttRestartPolicy', () {
    test('ordinary restarts keep the short delay', () {
      final p = SttRestartPolicy();
      // a session ends every ~8 s of silence (iOS pauseFor) — never a storm
      for (var i = 0; i < 20; i++) {
        expect(p.nextDelayMs(i * 8000), 350);
      }
    });

    test('a failing recogniser is slowed down instead of hammered', () {
      final p = SttRestartPolicy();
      var now = 0;
      final delays = <int>[];
      // every start fails immediately and asks for a restart 350 ms later
      for (var i = 0; i < 10; i++) {
        final d = p.nextDelayMs(now);
        delays.add(d);
        now += d;
      }
      // starts out fast, ends up capped — and never below the base
      expect(delays.first, 350);
      expect(delays.reduce((a, b) => a > b ? a : b), lessThanOrEqualTo(3000));
      expect(delays.last, greaterThan(350));
      // far fewer open/close cycles than the old fixed 350 ms (≈ 28 in 10 s)
      var t = 0, cycles = 0;
      final q = SttRestartPolicy();
      while (t < 10000) {
        t += q.nextDelayMs(t);
        cycles++;
      }
      expect(cycles, lessThan(14));
    });

    test('chanting on Android (a result after every session) never escalates',
        () {
      final p = SttRestartPolicy();
      var now = 0;
      for (var i = 0; i < 40; i++) {
        // an utterance ends the session, a result arrived → progress
        p.noteProgress();
        expect(p.nextDelayMs(now += 900), 350);
      }
    });

    test('recovery: the delay drops back once the storm is over', () {
      final p = SttRestartPolicy();
      var now = 0;
      for (var i = 0; i < 8; i++) {
        now += p.nextDelayMs(now);
      }
      expect(p.isStorm(now), isTrue);
      // the recogniser works again and delivers a result
      p.noteProgress();
      expect(p.isStorm(now), isFalse);
      expect(p.nextDelayMs(now + 500), 350);
    });

    test('a quiet minute forgets an old storm by itself', () {
      final p = SttRestartPolicy();
      var now = 0;
      for (var i = 0; i < 8; i++) {
        now += p.nextDelayMs(now);
      }
      expect(p.nextDelayMs(now + 60000), 350);
    });

    test('keeps a longer back-off the caller already needed', () {
      final p = SttRestartPolicy();
      expect(p.nextDelayMs(0, minDelayMs: 800), 800);
    });
  });
}
