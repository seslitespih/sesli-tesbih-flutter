import 'package:flutter_test/flutter_test.dart';
import 'package:sesli_tesbih/services/burst_segmenter.dart';

/// Simulates a microphone level stream feeding the segmenter.
class MicSim {
  final BurstSegmenter seg;
  final int frameMs;
  int t = 0;
  int reps = 0;

  MicSim({int minGapMs = 260, int maxSplitMs = 1000, this.frameMs = 50})
      : seg = BurstSegmenter(minGapMs: minGapMs, maxSplitMs: maxSplitMs) {
    seg.onRep = (_) => reps++;
  }

  /// Feeds [durationMs] worth of frames at constant [raw] level.
  void feed(double raw, int durationMs) {
    final n = durationMs ~/ frameMs;
    for (var i = 0; i < n; i++) {
      seg.process(raw, t);
      t += frameMs;
    }
  }

  /// Feeds frames alternating between two levels (speech wobble).
  void feedWobble(double a, double b, int durationMs) {
    final n = durationMs ~/ frameMs;
    for (var i = 0; i < n; i++) {
      seg.process(i.isEven ? a : b, t);
      t += frameMs;
    }
  }
}

void main() {
  group('BurstSegmenter — Android-like RMS scale (quiet≈0.5, loud≈8)', () {
    test('counts slow isolated reps exactly', () {
      final sim = MicSim();
      sim.feed(0.5, 2000); // warmup silence
      for (var i = 0; i < 10; i++) {
        sim.feed(8.0, 300); // word
        sim.feed(0.5, 700); // silence
      }
      expect(sim.reps, 10);
    });

    test('segments fast chained speech (~3 reps/s) with shallow dips', () {
      final sim = MicSim();
      sim.feed(0.5, 2000);
      // 15 fast reps: 200 ms loud, 100 ms shallow dip (never back to floor)
      for (var i = 0; i < 15; i++) {
        sim.feed(8.0, 200);
        sim.feed(5.0, 100);
      }
      // Old frame-based algorithm counted ~1 here. Require ≥ 13 of 15.
      expect(sim.reps, greaterThanOrEqualTo(13));
      expect(sim.reps, lessThanOrEqualTo(16));
    });

    test('splits fully continuous speech by time', () {
      final sim = MicSim();
      sim.feed(0.5, 2000);
      // 5 s of continuous speech with natural wobble but no real dips
      sim.feedWobble(7.4, 8.0, 5000);
      // splitMs starts near 910 ms and adapts → expect roughly 4-8 reps
      expect(sim.reps, greaterThanOrEqualTo(4));
      expect(sim.reps, lessThanOrEqualTo(9));
    });

    test('respects the minimum gap for long dhikr', () {
      final sim = MicSim(minGapMs: 2000, maxSplitMs: 3500);
      sim.feed(0.5, 2000);
      // Fast bursts every ~333 ms must NOT each count for a long dhikr
      for (var i = 0; i < 15; i++) {
        sim.feed(8.0, 200);
        sim.feed(0.5, 133);
      }
      // 15 bursts over ~5 s with a 2 s min gap → at most 3-4 reps
      expect(sim.reps, lessThanOrEqualTo(4));
    });

    test('counts nothing in silence / low jitter', () {
      final sim = MicSim();
      for (var i = 0; i < 200; i++) {
        sim.feed(i.isEven ? 0.4 : 0.6, 50);
      }
      expect(sim.reps, 0);
    });
  });

  group('BurstSegmenter — iOS-like dB scale (quiet≈−50, loud≈−12)', () {
    test('counts slow isolated reps exactly (auto-ranging works on dB)', () {
      final sim = MicSim();
      sim.feed(-50.0, 2000);
      for (var i = 0; i < 10; i++) {
        sim.feed(-12.0, 300);
        sim.feed(-50.0, 700);
      }
      expect(sim.reps, 10);
    });

    test('segments fast chained speech on dB scale', () {
      final sim = MicSim();
      sim.feed(-50.0, 2000);
      for (var i = 0; i < 15; i++) {
        sim.feed(-12.0, 200);
        sim.feed(-26.0, 100); // shallow dip in dB
      }
      expect(sim.reps, greaterThanOrEqualTo(13));
    });
  });
}
