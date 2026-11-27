import 'package:flutter_test/flutter_test.dart';
import 'package:sesli_tesbih/services/dhikr_matcher.dart';
import 'package:sesli_tesbih/services/stt_utterance_tracker.dart';

/// Scenario tests for the STT result bookkeeping.
///
/// The headline case is the Android regression that shipped in 1.5.1:
/// saying "sübhanallah" three times counted 6-7, because Android restarts
/// the recognition session after every utterance and the old session's
/// final result lands after the new session already reported "listening".
void main() {
  const keywords = ['subhanallah', 'sübhanallah'];

  /// Feeds a raw recogniser string exactly as the screen does.
  int feed(SttUtteranceTracker t, String raw, int atMs,
          {bool isFinal = false}) =>
      t.onResult(
        normText: normalizeDhikrText(raw),
        occurrences: countDhikrOccurrences(raw, keywords),
        nowMs: atMs,
        isFinal: isFinal,
      );

  group('Android session restart', () {
    test('three spoken dhikr count exactly three (the 1.5.1 bug)', () {
      final t = SttUtteranceTracker();
      var total = 0;
      var now = 0;

      for (var rep = 0; rep < 3; rep++) {
        // partials grow within the session
        total += feed(t, 'süb', now += 300);
        total += feed(t, 'sübhan', now += 250);
        total += feed(t, 'sübhanallah', now += 250);
        // final of that session
        total += feed(t, 'sübhanallah', now += 400, isFinal: true);
        // session ends, a new one starts and the OLD final is re-delivered
        total += feed(t, 'sübhanallah', now += 300, isFinal: true);
        // user pauses before the next rep
        now += 2500;
      }

      expect(total, 3);
    });

    test('a genuine repeat in the next session still counts', () {
      final t = SttUtteranceTracker();
      var total = 0;
      total += feed(t, 'sübhanallah', 1000, isFinal: true);
      // the user spoke again; the recogniser needed a moment to restart
      total += feed(t, 'sübhanallah', 1000 + 3000);
      expect(total, 2);
    });

    test('identical text inside the window is dropped', () {
      final t = SttUtteranceTracker(duplicateWindowMs: 1500);
      expect(feed(t, 'sübhanallah', 1000), 1);
      expect(feed(t, 'sübhanallah', 1900), 0);
    });
  });

  // iOS keeps ONE session open and returns the WHOLE transcript every time
  // (the plugin even stitches the text after a pause onto what came before).
  // The per-utterance rules re-counted everything said before a pause:
  // said 10 → 15, said 33 → 55.
  group('iOS cumulative transcript', () {
    SttUtteranceTracker ios() =>
        SttUtteranceTracker(minRepMs: 420, cumulativeTranscript: true);
    String words(int n) => List.filled(n, 'sübhanallah').join(' ');

    test('a pause between rounds does not re-count what was said (10 → 15)',
        () {
      final t = ios();
      var total = 0;
      var now = 0;
      for (var i = 1; i <= 5; i++) {
        total += feed(t, words(i), now += 1000);
      }
      now += 6000; // user pauses, the session stays open
      for (var i = 6; i <= 10; i++) {
        total += feed(t, words(i), now += 1000);
      }
      expect(total, 10);
    });

    test('33 in rounds of 11 with 5 s pauses counts 33 (was 55)', () {
      final t = ios();
      var total = 0;
      var now = 0;
      var n = 0;
      for (var round = 0; round < 3; round++) {
        for (var i = 0; i < 11; i++) {
          total += feed(t, words(++n), now += 900);
        }
        now += 5000;
      }
      expect(total, 33);
    });

    test('a very long pause (minutes) still adds only the new reps', () {
      final t = ios();
      var total = 0;
      total += feed(t, words(3), 3000); // first result: pace-capped to 1
      total += feed(t, '${words(3)} sü', 4200); // text grows → the other two
      expect(total, 3);
      // minutes of silence, then the recogniser repeats itself: nothing new
      expect(feed(t, words(3), 90000), 0);
      // one more rep afterwards is exactly one
      expect(feed(t, words(4), 95000), 1);
    });

    test('a final that only re-spells the tail adds nothing (3 → 4)', () {
      final t = ios();
      var total = 0;
      var now = 0;
      for (var i = 1; i <= 3; i++) {
        total += feed(t, words(i), now += 1000);
      }
      total += feed(t, '${words(3)} allah', now += 600);
      total += feed(t, words(3), now += 1500, isFinal: true);
      expect(total, 3);
    });

    test('a hypothesis that flips down and back up is counted once', () {
      final t = ios();
      var total = 0;
      var now = 0;
      total += feed(t, words(2), now += 1000);
      total += feed(t, 'sübhanallah sultan allah', now += 1200); // 2 → 1
      total += feed(t, words(2), now += 1200); //                   1 → 2
      expect(total, 2);
    });

    test('a new session starts a new transcript, even if it repeats the old',
        () {
      final t = ios();
      var total = 0;
      var now = 0;
      total += feed(t, words(1), now += 1000);
      total += feed(t, words(1), now += 400, isFinal: true);
      t.markSessionEnded(now += 100);
      // session 2: the user says it twice — text extends the old transcript
      now += 9000;
      total += feed(t, words(1), now += 500);
      total += feed(t, words(2), now += 700);
      expect(total, 3);
    });

    test("the old session's late final is not new speech", () {
      final t = ios();
      var total = 0;
      var now = 0;
      for (var i = 1; i <= 3; i++) {
        total += feed(t, words(i), now += 1000);
      }
      t.markSessionEnded(now += 8000); // pauseFor → stop()
      // new session already running when the old final lands, re-spelled
      total += feed(t, '${words(3)} allah', now += 300, isFinal: true);
      // …then the new session hears one fresh rep
      total += feed(t, words(1), now += 2500);
      expect(total, 4);
    });

    test('a transcript that collapses without a final starts over', () {
      final t = ios();
      var total = 0;
      var now = 0;
      for (var i = 1; i <= 5; i++) {
        total += feed(t, words(i), now += 1000);
      }
      // reset the plugin did not stitch: only the post-pause words remain
      total += feed(t, words(1), now += 6000);
      expect(total, 6);
    });

    test('Android mode is untouched: the per-utterance rules still apply', () {
      final t = SttUtteranceTracker(minRepMs: 420); // cumulative: false
      t.markSessionEnded(0); // no-op outside cumulative mode
      expect(feed(t, words(1), 1000), 1);
      expect(feed(t, words(1), 1000 + 3000), 1);
    });
  });

  group('continuous chanting', () {
    test('growing text credits only the new occurrences', () {
      final t = SttUtteranceTracker();
      var now = 0;
      expect(feed(t, 'sübhanallah', now += 700), 1);
      expect(feed(t, 'sübhanallah sübhanallah', now += 700), 1);
      expect(feed(t, 'sübhanallah sübhanallah sübhanallah', now += 700), 1);
      expect(
          feed(t, 'sübhanallah sübhanallah sübhanallah', now += 300,
              isFinal: true),
          0);
    });

    test('fast chanting is not capped below the human pace limit', () {
      final t = SttUtteranceTracker(minRepMs: 420);
      var now = 0;
      var total = 0;
      // 8 reps over 4 s ≈ 500 ms each — physically possible, must all count
      for (var i = 1; i <= 8; i++) {
        total += feed(t, List.filled(i, 'sübhanallah').join(' '), now += 500);
      }
      expect(total, 8);
    });
  });

  group('recogniser artefacts', () {
    test('echoed word from a single rep is capped by the pace limit', () {
      final t = SttUtteranceTracker(minRepMs: 420);
      // One 300 ms utterance the recogniser transcribed three times over.
      final credited = feed(t, 'sübhanallah sübhanallah sübhanallah', 300) +
          feed(t, 'sübhanallah sübhanallah sübhanallah', 500);
      expect(credited, lessThan(3));
    });

    test('a revised transcription is not a second dhikr', () {
      final t = SttUtteranceTracker();
      // The recogniser first mishears the word, then corrects itself.
      expect(feed(t, 'sultan allah', 600), 0);
      expect(feed(t, 'sübhanallah', 900), 1);
      // …and correcting it again adds nothing.
      expect(feed(t, 'sübhan allah', 1200), 0);
    });

    test('a rewrite that adds a rep still credits exactly one', () {
      final t = SttUtteranceTracker();
      expect(feed(t, 'sübhanallah', 700), 1);
      // second rep arrives with the first word re-spelled
      expect(feed(t, 'subhanellah sübhanallah', 1100), 0);
      expect(feed(t, 'sübhanallah sübhanallah', 1400), 1);
    });

    test('unrelated speech never counts', () {
      final t = SttUtteranceTracker();
      expect(feed(t, 'hava bugün çok güzel', 500), 0);
      expect(feed(t, '', 900), 0);
    });

    test('reset clears the utterance state', () {
      final t = SttUtteranceTracker();
      expect(feed(t, 'sübhanallah', 500), 1);
      t.reset();
      // same text right after a reset is a fresh utterance again
      expect(feed(t, 'sübhanallah', 700), 1);
    });
  });
}
