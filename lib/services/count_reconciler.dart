import 'dart:math' as math;

/// Pure-Dart reconciler that merges the two counting engines into one
/// trustworthy total (see test/count_reconciler_test.dart).
///
///  • Engine A (STT keyword matching) is ACCURATE at normal pace but
///    collapses repeated words during very fast chanting.
///  • Engine B (audio burst segmenter) reacts to any loud burst — it also
///    fires on syllables inside one word ("süb-ha-nal-lah"), breathing and
///    echo, so on its own it overcounts badly.
///
/// Accuracy rules (v3 — fixes "said it once, counter ran to 9"):
///
///  1. Engine B is gated: its reps only count within [sttGateMs] of the
///     last STT keyword match. Real chanting refreshes the gate with every
///     partial result; when the user stops, the gate shuts in seconds.
///  2. Engine B's lead over STT must be EARNED. While the user counts at a
///     normal pace (or says the dhikr once), STT is authoritative and the
///     lead is 0 — the total can never exceed what STT heard. Only when
///     STT itself registers a fast chanting pace ([chantMinReps] reps
///     within [chantWindowMs]) may Engine B run ahead, and then by at most
///     min([maxLead], sttTotal ~/ 2) — covering STT's collapsed repeats
///     without letting noise inflate the count.
///  3. The credited total is the cumulative max of both engines, so a rep
///     seen first by Engine B and later by STT is never counted twice.
class CountReconciler {
  CountReconciler({
    this.sttGateMs = 3000,
    this.chantWindowMs = 3000,
    this.chantMinReps = 4,
    this.maxLead = 5,
  });

  /// Engine B reps are valid only this long after an STT keyword match.
  final int sttGateMs;

  /// STT must count [chantMinReps] within this window to unlock any lead.
  final int chantWindowMs;
  final int chantMinReps;

  /// Absolute ceiling for how far Engine B may run ahead of STT.
  final int maxLead;

  int sttTotal = 0;
  int audioTotal = 0;
  int creditedTotal = 0;

  bool _everConfirmed = false;
  int _lastSttMatchMs = 0;
  final List<int> _sttIncMs = []; // timestamps of recent STT increments

  /// Fresh-evidence requirement: the lead dies this long after the last
  /// STT-counted rep, so noise right after the user stops can barely add.
  static const int _kChantFreshMs = 1500;

  /// True while STT itself is registering a fast chanting pace.
  bool isChanting(int nowMs) {
    _sttIncMs.removeWhere((t) => nowMs - t > chantWindowMs);
    if (_sttIncMs.length < chantMinReps) return false;
    return (nowMs - _sttIncMs.last) <= _kChantFreshMs;
  }

  /// How far Engine B may currently lead STT.
  int allowedLead(int nowMs) =>
      isChanting(nowMs) ? math.min(maxLead, sttTotal ~/ 2) : 0;

  /// Call whenever an STT result matched the dhikr (count > 0),
  /// even if it added no new occurrences — it keeps the gate open.
  void noteSttMatch(int nowMs) {
    _everConfirmed = true;
    _lastSttMatchMs = nowMs;
  }

  /// STT counted [delta] NEW occurrences. Returns reps to credit to the UI.
  int onSttDelta(int delta, int nowMs) {
    if (delta <= 0) return 0;
    sttTotal += delta;
    for (var i = 0; i < delta; i++) {
      _sttIncMs.add(nowMs);
    }
    return _reconcile(nowMs);
  }

  /// Engine B detected one burst rep. Returns reps to credit to the UI.
  int onAudioRep(int nowMs) {
    if (!_everConfirmed || (nowMs - _lastSttMatchMs) > sttGateMs) return 0;
    audioTotal++;
    return _reconcile(nowMs);
  }

  int _reconcile(int nowMs) {
    final cap = sttTotal + allowedLead(nowMs);
    if (audioTotal > cap) audioTotal = cap;
    final t = math.max(sttTotal, audioTotal);
    if (t <= creditedTotal) return 0;
    final credit = t - creditedTotal;
    creditedTotal = t;
    return credit;
  }

  void reset() {
    sttTotal = 0;
    audioTotal = 0;
    creditedTotal = 0;
    _everConfirmed = false;
    _lastSttMatchMs = 0;
    _sttIncMs.clear();
  }
}
