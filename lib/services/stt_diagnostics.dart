/// On-device flight recorder for the counting engine.
///
/// The recurring complaints — "doesn't count", "doesn't hear me", "counts too
/// much", "the mic keeps switching on and off" — cannot be settled from
/// source code: they depend on what the platform recogniser actually did on a
/// real phone. This keeps the last [capacity] events (status changes, errors,
/// restarts, results, credited reps) with timestamps, so one copy-paste from
/// the phone shows the sequence that went wrong.
///
/// Plain Dart on purpose: no plugins, unit-testable, and nothing leaves the
/// device unless the user copies the text out themselves.
class SttDiagnostics {
  SttDiagnostics({this.capacity = 400});

  final int capacity;

  final List<_Entry> _entries = [];
  final Map<String, int> _counters = {};
  int _startMs = -1;
  int _dropped = 0;

  /// Number of events currently held.
  int get length => _entries.length;

  /// Events discarded because the buffer was full.
  int get dropped => _dropped;

  int counter(String name) => _counters[name] ?? 0;

  /// Adds one event. [tag] groups it ("status", "error", "restart", …);
  /// each tag also feeds a counter so the summary shows totals at a glance.
  void log(int nowMs, String tag, [String detail = '']) {
    if (_startMs < 0) _startMs = nowMs;
    _counters[tag] = (_counters[tag] ?? 0) + 1;
    _entries.add(_Entry(nowMs - _startMs, tag, detail));
    if (_entries.length > capacity) {
      _entries.removeAt(0);
      _dropped++;
    }
  }

  void clear() {
    _entries.clear();
    _counters.clear();
    _startMs = -1;
    _dropped = 0;
  }

  /// Human-readable report: a header the caller fills in (platform, app
  /// version…), the counters, then the timeline (seconds since the first
  /// event).
  String dump({String header = ''}) {
    final b = StringBuffer();
    if (header.isNotEmpty) b.writeln(header);
    final names = _counters.keys.toList()..sort();
    b.writeln('counters: '
        '${names.map((n) => '$n=${_counters[n]}').join(' ')}');
    if (_dropped > 0) b.writeln('(oldest $_dropped events dropped)');
    for (final e in _entries) {
      final s = (e.ms / 1000).toStringAsFixed(2).padLeft(8);
      b.writeln('$s  ${e.tag}${e.detail.isEmpty ? '' : '  ${e.detail}'}');
    }
    return b.toString();
  }
}

class _Entry {
  _Entry(this.ms, this.tag, this.detail);
  final int ms;
  final String tag;
  final String detail;
}
