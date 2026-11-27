/// Notices a recognition session that has gone deaf while the user is still
/// chanting, so the screen can renew it.
///
/// WHY THIS EXISTS ("saymıyor")
/// ----------------------------
/// Measured on a real recogniser (Android emulator, synthetic Turkish speech
/// injected into the microphone): at normal and slow pace roughly one run in
/// four under-counts. Every miss has the same shape — the recogniser counted
/// the first reps, then stopped returning ANY result while the microphone
/// level callbacks kept reporting speech. The session either died quietly
/// ("listening" → "notListening" with no result) or stayed open and mute. The
/// counter just waited, so every remaining rep was lost.
///
/// The watchdog turns that into an observable condition:
///
///  • the user was chanting recently (a dhikr match within [activeWindowMs]),
///  • the recogniser has produced no result for [silentForMs],
///  • and the microphone has heard at least [minBursts] speech-like bursts
///    since that last result.
///
/// All three together mean "the user is still talking and nobody is
/// listening", and [shouldRenew] says so — at most once per [cooldownMs], so
/// it can never become a mic on/off loop. Ordinary silence (no bursts) and
/// unrelated talk (no recent dhikr match) never trigger it.
class SttStallWatchdog {
  SttStallWatchdog({
    this.activeWindowMs = 20000,
    this.silentForMs = 3500,
    this.minBursts = 3,
    this.cooldownMs = 8000,
  });

  /// A dhikr match this recent counts as "the user is chanting".
  final int activeWindowMs;

  /// How long the recogniser must have been mute.
  final int silentForMs;

  /// Speech-like bursts needed since the last result.
  final int minBursts;

  /// Minimum time between two renewals.
  final int cooldownMs;

  int _lastResultMs = 0;
  int _lastMatchMs = -1 << 30;
  int _lastRenewMs = -1 << 30;
  int _bursts = 0;
  int _renewals = 0;

  /// Renewals requested so far (diagnostics).
  int get renewals => _renewals;

  /// Bursts heard since the last result (diagnostics).
  int get burstsSinceResult => _bursts;

  /// The recogniser delivered a non-empty result. [matched] is true when it
  /// contained the dhikr being counted.
  void noteResult(int nowMs, {required bool matched}) {
    _lastResultMs = nowMs;
    _bursts = 0;
    if (matched) _lastMatchMs = nowMs;
  }

  /// The microphone heard one speech-like burst.
  void noteBurst() => _bursts++;

  /// A session (re)started: the silence clock begins now.
  void noteSessionStart(int nowMs) {
    _lastResultMs = nowMs;
    _bursts = 0;
  }

  /// True when the session should be renewed now. Call it periodically.
  bool shouldRenew(int nowMs) {
    if (nowMs - _lastMatchMs > activeWindowMs) return false;
    if (nowMs - _lastResultMs < silentForMs) return false;
    if (_bursts < minBursts) return false;
    if (nowMs - _lastRenewMs < cooldownMs) return false;
    _lastRenewMs = nowMs;
    _bursts = 0;
    _renewals++;
    return true;
  }

  void reset() {
    _lastResultMs = 0;
    _lastMatchMs = -1 << 30;
    _lastRenewMs = -1 << 30;
    _bursts = 0;
    _renewals = 0;
  }
}
