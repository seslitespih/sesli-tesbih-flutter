import 'package:flutter_test/flutter_test.dart';
import 'package:sesli_tesbih/services/burst_segmenter.dart';
import 'package:sesli_tesbih/services/count_reconciler.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  Accuracy scenarios for the dual-engine counter.
//
//  The 1.4.1 field bug: saying "Sübhanallah" ONCE ran the counter up to 9 —
//  Engine B (burst segmenter) counted the word's own syllables plus trailing
//  breath/echo, and the old reconciler let audio lead STT by 15 for 20 s.
//  These tests pin the v3 rules: STT is authoritative at normal pace; Engine
//  B may only run ahead during STT-confirmed fast chanting, and then by ≤ 5.
// ═══════════════════════════════════════════════════════════════════════════

void main() {
  group('CountReconciler — unit scenarios', () {
    test('single utterance can never overcount (the "1 said → 9 shown" bug)',
        () {
      final r = CountReconciler();
      // Engine B fires on 3 syllables BEFORE STT ever matched → all ignored.
      expect(r.onAudioRep(1000), 0);
      expect(r.onAudioRep(1500), 0);
      expect(r.onAudioRep(1950), 0);
      // STT recognises the word: exactly one rep credited.
      r.noteSttMatch(2100);
      expect(r.onSttDelta(1, 2100), 1);
      // Trailing echo / breathing bursts inside the 3 s gate: lead is 0 at
      // normal pace, so nothing more may be credited.
      var extra = 0;
      for (var t = 2400; t < 8000; t += 450) {
        extra += r.onAudioRep(t);
      }
      expect(extra, 0);
      expect(r.creditedTotal, 1);
    });

    test('slow counting is exactly STT — Engine B double-fires are absorbed',
        () {
      final r = CountReconciler();
      var credited = 0;
      var t = 0;
      for (var rep = 0; rep < 10; rep++) {
        t += 1500; // one dhikr every 1.5 s — normal pace
        // Engine B fires twice per utterance (syllable dip)…
        credited += r.onAudioRep(t);
        credited += r.onAudioRep(t + 450);
        // …then STT confirms exactly one.
        r.noteSttMatch(t + 700);
        credited += r.onSttDelta(1, t + 700);
      }
      expect(credited, 10);
      expect(r.creditedTotal, 10);
    });

    test('fast chanting: Engine B fills STT collapse, bounded by lead ≤ 5',
        () {
      final r = CountReconciler();
      // User does 30 real reps at 350 ms; STT only registers 18 of them
      // (collapse), via partials that add one every ~580 ms.
      var credited = 0;
      var audioT = 1000, sttT = 1000;
      var audioFired = 0, sttFired = 0;
      while (audioFired < 30 || sttFired < 18) {
        if (audioFired < 30 && audioT <= sttT) {
          credited += r.onAudioRep(audioT);
          audioFired++;
          audioT += 350;
        } else {
          r.noteSttMatch(sttT);
          credited += r.onSttDelta(1, sttT);
          sttFired++;
          sttT += 580;
        }
      }
      // Must count at least what STT confirmed, may exceed it by ≤ 5,
      // and must never exceed the 30 real reps.
      expect(credited, r.creditedTotal);
      expect(r.creditedTotal, greaterThanOrEqualTo(18));
      expect(r.creditedTotal, lessThanOrEqualTo(23));
    });

    test('noise after chanting stops adds at most a rep or two, then dies',
        () {
      final r = CountReconciler();
      // 12 quick STT-confirmed reps → chanting mode is active.
      var t = 0;
      for (var i = 0; i < 12; i++) {
        t += 500;
        r.noteSttMatch(t);
        r.onSttDelta(1, t);
        r.onAudioRep(t + 100);
      }
      final atStop = r.creditedTotal;
      expect(atStop, 12);
      // User stops at t; room noise keeps producing bursts every 450 ms.
      var extra = 0;
      for (var n = t + 450; n < t + 12000; n += 450) {
        extra += r.onAudioRep(n);
      }
      // Lead evidence goes stale after 1.5 s and the gate after 3 s:
      // at most ~3 noise bursts can slip in, never a runaway count.
      expect(extra, lessThanOrEqualTo(3));
      // And well after the gate closed, nothing counts at all.
      expect(r.onAudioRep(t + 20000), 0);
    });

    test('STT-only device (Engine B silent) still counts exactly', () {
      final r = CountReconciler();
      var credited = 0;
      for (var i = 1; i <= 33; i++) {
        r.noteSttMatch(i * 1000);
        credited += r.onSttDelta(1, i * 1000);
      }
      expect(credited, 33);
    });

    test('rep seen by audio first and STT later is counted once', () {
      final r = CountReconciler();
      // Establish chanting mode (4 quick reps seen by both engines).
      var t = 0;
      for (var i = 0; i < 4; i++) {
        t += 500;
        r.noteSttMatch(t);
        r.onSttDelta(1, t);
        r.onAudioRep(t + 50);
      }
      expect(r.creditedTotal, 4);
      // Audio detects the 5th rep first (lead allowed: min(5, 4~/2)=2)…
      expect(r.onAudioRep(t + 300), 1);
      // …STT confirms the same rep later: no double count.
      r.noteSttMatch(t + 900);
      expect(r.onSttDelta(1, t + 900), 0);
      expect(r.creditedTotal, 5);
    });

    test('reset requires fresh STT confirmation', () {
      final r = CountReconciler();
      r.noteSttMatch(1000);
      r.onSttDelta(1, 1000);
      r.reset();
      expect(r.creditedTotal, 0);
      expect(r.onAudioRep(1200), 0); // gate closed again
    });
  });

  group('End-to-end: BurstSegmenter + CountReconciler (Android RMS scale)',
      () {
    test('one spoken "sübhanallah" with syllable dips credits exactly 1', () {
      final r = CountReconciler();
      final seg = BurstSegmenter(minGapMs: 420, maxSplitMs: 1000);
      var credited = 0;
      var t = 0;
      seg.onRep = (now) => credited += r.onAudioRep(now);

      void feed(double raw, int ms) {
        for (var i = 0; i < ms ~/ 50; i++) {
          seg.process(raw, t);
          t += 50;
        }
      }

      feed(0.5, 2000); // room tone warm-up
      // "süb-ha-nal-lah": 4 loud syllables with deep stop-consonant dips.
      for (var s = 0; s < 4; s++) {
        feed(8.0, 200);
        feed(2.0, 100);
      }
      // STT partial arrives ~400 ms after the word ends.
      r.noteSttMatch(t + 400);
      credited += r.onSttDelta(1, t + 400);
      // Breath + echo for the next 6 s.
      feed(0.5, 400);
      feed(4.0, 200); // breath burst
      feed(0.5, 1500);
      feed(4.5, 200); // another noise burst
      feed(0.5, 4000);

      expect(credited, 1);
    });

    test('10 slow spoken reps credit exactly 10', () {
      final r = CountReconciler();
      final seg = BurstSegmenter(minGapMs: 420, maxSplitMs: 1000);
      var credited = 0;
      var t = 0;
      seg.onRep = (now) => credited += r.onAudioRep(now);

      void feed(double raw, int ms) {
        for (var i = 0; i < ms ~/ 50; i++) {
          seg.process(raw, t);
          t += 50;
        }
      }

      feed(0.5, 2000);
      for (var rep = 0; rep < 10; rep++) {
        // 4 syllables with dips — Engine B may see several bursts.
        for (var s = 0; s < 4; s++) {
          feed(8.0, 200);
          feed(2.0, 100);
        }
        // STT confirms one occurrence shortly after the word.
        r.noteSttMatch(t + 300);
        credited += r.onSttDelta(1, t + 300);
        feed(0.5, 1200); // pause between reps
      }
      expect(credited, 10);
    });

    test('fast chanting still counts close to the real rep count', () {
      final r = CountReconciler();
      final seg = BurstSegmenter(minGapMs: 420, maxSplitMs: 1000);
      var credited = 0;
      var t = 0;
      seg.onRep = (now) => credited += r.onAudioRep(now);

      void feed(double raw, int ms) {
        for (var i = 0; i < ms ~/ 50; i++) {
          seg.process(raw, t);
          t += 50;
        }
      }

      feed(0.5, 2000);
      // 24 fast chained reps (500 ms speech + 100 ms shallow dip each);
      // STT drops every 3rd rep (typical partial-result collapse).
      var sttSeen = 0;
      for (var rep = 0; rep < 24; rep++) {
        feed(8.0, 500);
        feed(5.0, 100);
        if (rep % 3 != 2) {
          r.noteSttMatch(t);
          credited += r.onSttDelta(1, t);
          sttSeen++;
        }
      }
      expect(sttSeen, 16);
      // Real reps: 24. STT alone: 16. The duo must land in between,
      // never exceeding reality.
      expect(credited, greaterThanOrEqualTo(16));
      expect(credited, lessThanOrEqualTo(24));
      expect(credited, greaterThan(17)); // Engine B must add real value
    });
  });
}
