/// Pure-Dart core of "Engine B" — the audio burst segmenter that counts
/// speech reps from the microphone level envelope.
///
/// Extracted from the counter screen so the algorithm can be verified with
/// synthetic waveforms in unit tests (see test/burst_segmenter_test.dart).
///
/// Algorithm:
///  1. Auto-range the raw platform level into 0..1. iOS reports dB ≈ −60..0
///     while Android reports RMS ≈ −2..10; running min/max with slow decay
///     calibrates to any device.
///  2. Noise floor = mean of the quietest ~25 % of the last 30 frames.
///  3. A burst OPENS when the level rises above floor + [kOnsetRise]
///     → one rep (if [minGapMs] has passed since the previous rep).
///  4. Inside a burst the running peak is tracked. A dip below
///     max(floor + rise·0.4, peak − [kDipDelta]) CLOSES the burst, so the
///     next rise counts as a new rep — even when fast chained speech never
///     returns to the noise floor.
///  5. A burst that never dips (fully continuous speech) is split by time
///     every [splitMs], which adapts to the user's measured pace.
class BurstSegmenter {
  BurstSegmenter({
    this.minGapMs = 260,
    this.maxSplitMs = 1000,
    this.onRep,
  });

  /// Minimum wall-clock gap between two counted reps.
  int minGapMs;

  /// Ceiling for sustained-burst splitting.
  int maxSplitMs;

  /// Called once per detected rep with the timestamp (ms).
  void Function(int nowMs)? onRep;

  static const double kOnsetRise = 0.14; // rise above floor to open a burst
  static const double kDipDelta = 0.16;  // dip below peak that ends a burst

  // Auto-ranging raw level bounds
  double _rawMin = double.infinity;
  double _rawMax = double.negativeInfinity;

  // Circular buffer of normalised levels → local noise floor
  final List<double> _lvlBuf = List.filled(30, 0.0);
  int _lvlBufIdx = 0;

  // Hysteresis burst state
  bool _inBurst = false;
  double _burstPeak = 0.0;
  int _lastOnsetMs = 0;
  double _repEstimateMs = 700; // learned per-rep duration (EMA of gaps)

  /// Split interval for continuous speech with no measurable dips.
  int get splitMs =>
      (_repEstimateMs * 1.3).round().clamp(minGapMs + 150, maxSplitMs);

  /// Clears the in-burst state (e.g. when a listening session restarts).
  /// Keeps the learned range and pace.
  void resetBurstState() {
    _inBurst = false;
    _burstPeak = 0.0;
  }

  /// Feeds one raw mic-level frame at [nowMs].
  /// Returns the normalised level (0..1) for UI visualisation.
  double process(double raw, int nowMs) {
    // 1 — auto-ranging normalisation
    if (raw < _rawMin) {
      _rawMin = raw;
    } else {
      _rawMin += (raw - _rawMin) * 0.003;
    }
    if (raw > _rawMax) {
      _rawMax = raw;
    } else {
      _rawMax += (raw - _rawMax) * 0.003;
    }
    final range = _rawMax - _rawMin;
    final level =
        range < 0.5 ? 0.0 : ((raw - _rawMin) / range).clamp(0.0, 1.0);

    // 2 — noise floor from normalised history.
    // Capped at 0.45: during long uninterrupted speech the history fills
    // with loud frames and the floor would otherwise rise to speech level,
    // blocking re-detection until the user pauses.
    _lvlBuf[_lvlBufIdx] = level;
    _lvlBufIdx = (_lvlBufIdx + 1) % _lvlBuf.length;
    final sorted = List<double>.from(_lvlBuf)..sort();
    var floor = sorted.take(8).fold(0.0, (a, b) => a + b) / 8;
    if (floor > 0.45) floor = 0.45;

    final onThresh = floor + kOnsetRise;
    final offThresh = (floor + kOnsetRise * 0.4) > (_burstPeak - kDipDelta)
        ? (floor + kOnsetRise * 0.4)
        : (_burstPeak - kDipDelta);

    if (!_inBurst) {
      // 3 — burst opens → one rep
      if (level >= onThresh) {
        _inBurst = true;
        _burstPeak = level;
        _registerOnset(nowMs);
      }
    } else {
      if (level > _burstPeak) _burstPeak = level;
      if (level <= offThresh) {
        // 4 — dip detected → burst closed, next rise is a new rep
        _inBurst = false;
      } else if (nowMs - _lastOnsetMs >= splitMs) {
        // 5 — continuous speech without dips → split by duration
        _burstPeak = level;
        _registerOnset(nowMs);
      }
    }
    return level;
  }

  void _registerOnset(int now) {
    final gap = now - _lastOnsetMs;
    if (_lastOnsetMs > 0 && gap < minGapMs) return;
    if (_lastOnsetMs > 0 && gap < 3000) {
      // learn the user's pace → drives sustained-burst splitting
      _repEstimateMs = _repEstimateMs * 0.7 + gap * 0.3;
    }
    _lastOnsetMs = now;
    onRep?.call(now);
  }
}
