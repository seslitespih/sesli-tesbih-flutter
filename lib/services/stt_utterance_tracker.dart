/// Pure-Dart bookkeeping for "Engine A" results — decides how many NEW
/// occurrences a speech-to-text result really adds (see
/// test/stt_utterance_tracker_test.dart).
///
/// WHY THIS EXISTS (the Android over-count bug, v1.5.2)
/// ---------------------------------------------------
/// iOS keeps ONE long recognition session open, so occurrences could simply
/// be measured against a per-session counter. Android's SpeechRecognizer
/// ends the session after every utterance and the plugin restarts it — and
/// the OLD session's final result routinely lands AFTER the new session has
/// already reported "listening". The old code reset its counter on that
/// status, so the late final was measured against 0 and the whole utterance
/// was credited a SECOND time: saying "sübhanallah" three times counted 6-7.
///
/// The fix is to stop trusting session boundaries and track the recognised
/// TEXT instead, which behaves identically on both platforms:
///
///  1. Re-delivery guard — a result whose text is identical to the previous
///     one and arrives within [duplicateWindowMs] adds nothing. That is the
///     late/duplicated final; a genuine repeat needs the user to speak
///     again, which takes far longer than the window.
///  2. Utterance tracking — recognisers grow their text while an utterance
///     is in progress ("süb" → "sübhan" → "sübhanallah"), so a result that
///     extends the previous text continues the same utterance and only its
///     GROWTH is credited. Anything else starts a fresh utterance.
///  3. Human-pace ceiling — inside one utterance no more than one rep per
///     [minRepMs] may be credited (plus the one in flight when the first
///     partial arrived). This absorbs the recogniser's habit of echoing a
///     word it heard once ("sübhanallah sübhanallah" from a single rep)
///     without capping real chanting, because the ceiling grows with time.
class SttUtteranceTracker {
  SttUtteranceTracker({
    this.duplicateWindowMs = 1500,
    this.finalDuplicateWindowMs = 2500,
    this.continuationWindowMs = 4000,
    this.rewriteWindowMs = 700,
    this.minRepMs = 420,
  });

  /// Identical text arriving within this window is a re-delivery, not a rep.
  final int duplicateWindowMs;

  /// Finals get a longer window: Android confirms an utterance up to two
  /// seconds after its last partial, and re-sends it once more when the
  /// session is restarted.
  final int finalDuplicateWindowMs;

  /// A text extension older than this starts a new utterance anyway.
  final int continuationWindowMs;

  /// While a session is open the recogniser also REVISES its earlier guess
  /// ("sultan allah" → "sübhanallah"), which breaks the prefix rule. A
  /// replacement this soon after the last result is still the same
  /// utterance — nobody can complete another dhikr that fast.
  final int rewriteWindowMs;

  /// Fastest humanly possible repetition of the current dhikr.
  int minRepMs;

  String _lastNorm = '';
  int _lastMs = 0;
  int _uttStartMs = 0;
  int _credited = 0;
  bool _closed = false; // last result was final → utterance is over

  /// Occurrences credited so far for the utterance in progress (tests/debug).
  int get creditedInUtterance => _credited;

  /// [normText] must already be normalised (see dhikr_matcher.dart) and
  /// [occurrences] is the keyword count found in that whole text.
  /// Returns how many reps to hand to the reconciler.
  int onResult({
    required String normText,
    required int occurrences,
    required int nowMs,
    bool isFinal = false,
  }) {
    if (normText.isEmpty) return 0;

    // 1 — late / duplicated delivery of the result we just processed
    final window = isFinal ? finalDuplicateWindowMs : duplicateWindowMs;
    if (normText == _lastNorm && nowMs - _lastMs <= window) {
      _lastMs = nowMs;
      return 0;
    }

    // 2 — same utterance while an open session keeps GROWING its text, or
    //     revises it within a hair's breadth of the previous result
    final elapsed = nowMs - _lastMs;
    final continues = !_closed &&
        _lastNorm.isNotEmpty &&
        ((normText.length > _lastNorm.length &&
                normText.startsWith(_lastNorm) &&
                elapsed <= continuationWindowMs) ||
            elapsed <= rewriteWindowMs);
    if (!continues) {
      _uttStartMs = nowMs;
      _credited = 0;
    }
    _lastNorm = normText;
    _lastMs = nowMs;
    _closed = isFinal;

    var delta = occurrences - _credited;
    if (delta <= 0) return 0;

    // 3 — human-pace ceiling for this utterance
    final maxByPace = ((nowMs - _uttStartMs) ~/ minRepMs) + 1;
    if (_credited + delta > maxByPace) delta = maxByPace - _credited;
    if (delta <= 0) return 0;

    _credited += delta;
    return delta;
  }

  /// Full reset (counter reset / screen re-entry).
  void reset() {
    _lastNorm = '';
    _lastMs = 0;
    _uttStartMs = 0;
    _credited = 0;
    _closed = false;
  }
}
