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
///
/// WHY [cumulativeTranscript] EXISTS (the iOS over-count bug)
/// ----------------------------------------------------------
/// The rules above assume a result holds ONE utterance. On iOS it holds the
/// WHOLE SESSION: the speech_to_text plugin keeps one recognition task open
/// and even stitches the text after a pause onto what came before (its
/// SpeechResultAggregator). Saying "sübhanallah" 5×, pausing a few seconds
/// and saying it 5× more therefore delivers "sübhanallah ×6", "×7" … — and
/// rule 2 calls every extension after [continuationWindowMs] a NEW
/// utterance, forgets what it already credited, and counts the first five
/// again at one per [minRepMs]. Said 10, the counter showed 15; said 33, 55.
///
/// In [cumulativeTranscript] mode a result keeps belonging to the running
/// transcript until that transcript is really over:
///  • a final result arrived, or the recogniser reported `done`
///    ([markSessionEnded]) — the next result starts a new transcript;
///  • the text collapsed to under half its length (a reset the plugin did
///    not stitch) — a revision never does that.
/// Inside a transcript the credited count is a high-water mark, so a
/// recogniser that revises its text up and down never counts a rep twice.
/// Status events are NOT used to OPEN a transcript: the old task's final can
/// still land after the next one has started, and it must stay recognisable
/// as the old transcript (see [lateFinalWindowMs]).
class SttUtteranceTracker {
  SttUtteranceTracker({
    this.duplicateWindowMs = 1500,
    this.finalDuplicateWindowMs = 2500,
    this.continuationWindowMs = 4000,
    this.rewriteWindowMs = 700,
    this.minRepMs = 420,
    this.cumulativeTranscript = false,
    this.lateFinalWindowMs = 3000,
  });

  /// True where one recognition session returns ONE growing transcript for
  /// its whole lifetime (iOS). Android keeps the per-utterance rules.
  final bool cumulativeTranscript;

  /// Cumulative mode: a final that lands this long after its session ended
  /// is still that session's transcript, not new speech.
  final int lateFinalWindowMs;

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
  bool _ended = false; // recogniser reported `done` (cumulative mode)
  int _endedMs = 0;

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
    //     revises it within a hair's breadth of the previous result.
    //     iOS (cumulative transcript): same transcript until it really ends.
    final elapsed = nowMs - _lastMs;
    final continues = cumulativeTranscript
        ? _continuesTranscript(normText, nowMs, isFinal)
        : !_closed &&
            _lastNorm.isNotEmpty &&
            ((normText.length > _lastNorm.length &&
                    normText.startsWith(_lastNorm) &&
                    elapsed <= continuationWindowMs) ||
                elapsed <= rewriteWindowMs);
    if (!continues) {
      _uttStartMs = nowMs;
      _credited = 0;
      _ended = false;
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

  /// The recogniser reported `done` for the running session (cumulative mode
  /// only). The NEXT result then starts a new transcript — unless it is that
  /// session's own late final, see [lateFinalWindowMs].
  void markSessionEnded(int nowMs) {
    if (!cumulativeTranscript) return;
    _ended = true;
    _endedMs = nowMs;
  }

  /// Cumulative mode: does [t] belong to the transcript we already hold?
  bool _continuesTranscript(String t, int nowMs, bool isFinal) {
    if (_lastNorm.isEmpty) return false;
    if (_closed || _ended) {
      // The transcript is over. Only that session's own final may still be on
      // its way, and it has to look like the text we already credited.
      final since = nowMs - (_ended ? _endedMs : _lastMs);
      return isFinal && since <= lateFinalWindowMs && _sameTranscript(t);
    }
    // Open session: text only grows or is revised. A collapse to under half
    // its length is a reset the plugin did not stitch → new transcript.
    return t.length * 2 >= _lastNorm.length;
  }

  /// True when [t] and the last text agree on most of the shorter one.
  bool _sameTranscript(String t) {
    final shorter = t.length < _lastNorm.length ? t.length : _lastNorm.length;
    var i = 0;
    while (i < shorter && t.codeUnitAt(i) == _lastNorm.codeUnitAt(i)) {
      i++;
    }
    return i * 10 >= shorter * 6;
  }

  /// Full reset (counter reset / screen re-entry).
  void reset() {
    _lastNorm = '';
    _lastMs = 0;
    _uttStartMs = 0;
    _credited = 0;
    _closed = false;
    _ended = false;
    _endedMs = 0;
  }
}
