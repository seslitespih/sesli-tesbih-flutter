/// Decides how long to wait before re-opening the speech recogniser.
///
/// WHY THIS EXISTS ("mikrofon sürekli açılıp kapanıyor")
/// ----------------------------------------------------
/// The counter keeps the mic alive by restarting the recogniser every time a
/// session ends. That is right when sessions end because the user spoke or
/// paused. It is wrong when sessions end because they FAIL at once — the
/// recogniser is busy, a start is refused, the audio route flips — because
/// the fixed 350 ms delay then turns into a loop of ~3 mic open/close cycles
/// per second: the mic indicator flickers, audio from other apps is
/// interrupted each time, and every cycle is a hole in which speech is lost.
///
/// Restarts requested less than [chainGapMs] after the previous one form a
/// CHAIN. Once a chain reaches [stormThreshold] restarts it is a storm, and
/// the delay doubles with every further link (up to [maxDelayMs]). The chain
/// survives the escalated delays (they are shorter than [chainGapMs]) and
/// ends only when the recogniser shows life ([noteProgress]) or goes quiet
/// for longer than [chainGapMs].
///
/// Normal use never forms a chain: iOS ends a silent session every 8+ s, and
/// Android restarts once per utterance — but every utterance delivers a
/// result, and [noteProgress] clears the chain.
class SttRestartPolicy {
  SttRestartPolicy({
    this.baseDelayMs = 350,
    this.chainGapMs = 4000,
    this.stormThreshold = 5,
    this.maxDelayMs = 3000,
  });

  /// Delay used while sessions end normally.
  final int baseDelayMs;

  /// Restarts closer together than this belong to the same chain.
  final int chainGapMs;

  /// Chain length at which restarts start being slowed down.
  final int stormThreshold;

  /// Ceiling for the escalated delay — bounded so a recovered recogniser is
  /// never left deaf for long. Must stay below [chainGapMs].
  final int maxDelayMs;

  int _chain = 0;
  int _lastMs = -1 << 30;

  /// Length of the current restart chain (diagnostics).
  int get chainLength => _chain;

  /// True while restarts are being slowed down.
  bool isStorm(int nowMs) =>
      _chain >= stormThreshold && nowMs - _lastMs <= chainGapMs;

  /// The recogniser showed signs of life (a result arrived, a rep counted):
  /// whatever restarted before was healthy, so the chain is forgotten.
  void noteProgress() => _chain = 0;

  /// Records a restart requested at [nowMs] and returns how long to wait
  /// before performing it. [minDelayMs] lets callers keep a longer back-off
  /// they already needed (e.g. after a "busy" error).
  int nextDelayMs(int nowMs, {int minDelayMs = 0}) {
    if (nowMs - _lastMs > chainGapMs) _chain = 0;
    _chain++;
    _lastMs = nowMs;
    var delay = baseDelayMs;
    final over = _chain - stormThreshold;
    if (over >= 0) {
      // first storm restart doubles the base, then 4×, 8×, …
      delay = baseDelayMs << (over + 1).clamp(1, 6);
      if (delay > maxDelayMs) delay = maxDelayMs;
    }
    return delay < minDelayMs ? minDelayMs : delay;
  }

  void reset() {
    _chain = 0;
    _lastMs = -1 << 30;
  }
}
