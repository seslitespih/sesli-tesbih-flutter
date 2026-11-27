import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart' show openAppSettings;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../models/dhikr.dart';
import '../data/dhikr_data.dart';
import '../data/esma_data.dart';
import '../services/burst_segmenter.dart';
import '../services/count_reconciler.dart';
import '../services/custom_dhikr_manager.dart';
import '../services/dhikr_matcher.dart';
import '../services/locale_service.dart';
import '../services/review_service.dart';
import '../services/stt_diagnostics.dart';
import '../services/stt_restart_policy.dart';
import '../services/stt_stall_watchdog.dart';
import '../services/stt_utterance_tracker.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  DUAL-ENGINE DHIKR COUNTER  (v2 — fast-speech fix)
//
//  Engine A — STT (speech-to-text keyword matching)
//    • Accurate when it works; collapses repeated words during fast speech
//    • Runs as a continuous session (5-min listenFor, 8-s pauseFor)
//
//  Engine B — Audio burst segmenter (mic level envelope)
//    • Auto-ranging level normalisation: iOS reports dB ≈ −60..0 while
//      Android reports RMS ≈ −2..10 — the old fixed formula made the level
//      permanently 0 on iOS, disabling this engine entirely.
//    • Hysteresis peak/dip segmentation: a new rep is detected when the
//      level dips below (peak − delta) and rises again, even if it never
//      returns to the noise floor — this is what segments fast chained
//      speech like "allahallahallah".
//    • Wall-clock (ms) gaps instead of frame counts — frame rates differ
//      wildly between platforms (iOS ≈ 25-50 fps, Android ≈ 10 fps).
//    • Sustained-burst splitting: continuous loud speech with no
//      measurable dip is credited every _splitMs (adaptive to user pace).
//    • Gate: counts only while STT has matched the dhikr within the last
//      20 s (rolling confirmation — blocks TV/noise when user stops).
//
//  Reconciler (event-driven — logic in lib/services/count_reconciler.dart,
//  scenario-tested in test/count_reconciler_test.dart)
//    • Credits MAX(sttTotal, audioTotal) to the total
//    • v3 overcount fix: Engine B's lead over STT is EARNED — while the
//      user speaks at a normal pace (or once), STT is authoritative and
//      the lead is 0, so syllable dips ("süb-ha-nal-lah") and post-speech
//      noise can never inflate the count. Only when STT itself registers
//      a fast chanting pace may Engine B run ahead (max 5).
// ═══════════════════════════════════════════════════════════════════════════

class CounterScreen extends StatefulWidget {
  final int dhikrId;
  const CounterScreen({super.key, required this.dhikrId});

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // ── Dhikr data ─────────────────────────────────────────────────────────
  late Dhikr _dhikr;
  bool _dhikrLoaded = false;

  // ── UI state ────────────────────────────────────────────────────────────
  int _count = 0;
  int _targetCount = 33;
  String _statusText = '';

  // ── Animation controllers ────────────────────────────────────────────────
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _ringCtrl;

  // ───────────────────────────────────────────────────────────────────────
  //  ENGINE A — STT
  // ───────────────────────────────────────────────────────────────────────
  final SpeechToText _speech = SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;
  double _micLevel = 0.5;

  /// Turns raw STT results into "how many NEW reps" — platform-independent,
  /// unit-tested in test/stt_utterance_tracker_test.dart. Replaces the old
  /// per-session counter that double-counted on Android (see the class doc).
  /// iOS returns one cumulative transcript per session, so it must not be
  /// split into "utterances" — doing so re-counted everything said before a
  /// pause (said 10 → showed 15; see SttUtteranceTracker.cumulativeTranscript).
  final SttUtteranceTracker _utterances =
      SttUtteranceTracker(
          // Test builds only (--dart-define=LEGACY_TRACKER=true): the pre-1.5.5
          // per-utterance rules on iOS, to compare against the fix.
          cumulativeTranscript:
              Platform.isIOS && !const bool.fromEnvironment('LEGACY_TRACKER'));

  /// Single-flight session restart: Android fires BOTH an error and a
  /// status change for the same dropped session, and two overlapping
  /// listen() calls leave the recogniser permanently busy.
  Timer? _restartTimer;
  bool _restartInFlight = false;
  int _pendingDelayMs = 0;

  /// Slows restarts down while the recogniser keeps failing instantly, so a
  /// broken session cannot flicker the mic on and off several times a second.
  /// 150 ms (was 350): on a real recogniser every ms of this gap is speech the
  /// counter never hears. The tracker already treats a late final from the old
  /// session as a re-delivery, so the extra wait bought nothing.
  final SttRestartPolicy _restartPolicy = SttRestartPolicy(baseDelayMs: 150);

  /// Renews a session that went deaf while the user is still chanting (the
  /// recogniser stops returning results but the mic still hears speech).
  final SttStallWatchdog _watchdog = SttStallWatchdog();
  Timer? _watchdogTimer;

  /// Flight recorder for the counting engine. Long-press the status line to
  /// copy it — the only way to see what the phone's recogniser really did.
  final SttDiagnostics _diag = SttDiagnostics();

  /// Mic / speech-recognition permission was refused. Without this the screen
  /// only said "not supported" and gave no way out.
  bool _micDenied = false;

  int _nowMs() => DateTime.now().millisecondsSinceEpoch;
  void _log(String tag, [String detail = '']) {
    _diag.log(_nowMs(), tag, detail);
    // Debug builds only: lets an emulator test read the same timeline from
    // `adb logcat` that the user copies from the app.
    if (kDebugMode) debugPrint('DIAG ${_nowMs()} $tag $detail');
  }

  /// STT locale, looked up ONCE. _speech.locales() used to run before every
  /// session restart; on Android it is an ordered broadcast to the recogniser
  /// that can take hundreds of ms, and Android restarts after every utterance
  /// — so each rep waited on it ("voice response very slow", Play review 3 Sep).
  String? _sttLocaleId;

  /// Mic was on when the app went to the background → turn it back on when
  /// the user returns. iOS kept getting listen() retries from the background
  /// and could kill the app ("kendi kendine kapanıyor", App Store review 5 Oct).
  bool _resumeAfterBackground = false;

  // ───────────────────────────────────────────────────────────────────────
  //  ENGINE B — Audio burst segmenter (core logic in BurstSegmenter,
  //  unit-tested with synthetic waveforms in test/burst_segmenter_test.dart)
  // ───────────────────────────────────────────────────────────────────────
  late final BurstSegmenter _segmenter = BurstSegmenter(
    onRep: (nowMs) {
      if (!_isListening || !mounted) return;
      _watchdog.noteBurst();
      final credit = _reconciler.onAudioRep(nowMs);
      _log('burst', 'credit=$credit');
      if (credit > 0) _incrementCount(credit, 'audio');
    },
  );

  // ───────────────────────────────────────────────────────────────────────
  //  RECONCILER — merges the two engines; see lib/services/count_reconciler
  // ───────────────────────────────────────────────────────────────────────
  final CountReconciler _reconciler = CountReconciler();

  // ───────────────────────────────────────────────────────────────────────
  //  Adaptive per-dhikr timing (0 = short, 1 = medium, 2 = long)
  // ───────────────────────────────────────────────────────────────────────
  int get _lenClass {
    if (!_dhikrLoaded) return 1;
    final len = _dhikr.arabicText.length;
    if (len > 60) return 2; // very long (Tefrice/Münciye)
    if (len > 25) return 1; // medium (Kulhuvallah, Bismillahillezi)
    return 0;               // short (Subhanallah, Allah, ...)
  }

  /// Configures the segmenter's timing for the loaded dhikr.
  /// Short-class min gap raised 260 → 420 ms: even a fast "sübhanallah"
  /// takes ~500 ms to say, and 260 ms let its own syllables count as reps.
  void _configureSegmenter() {
    _segmenter.minGapMs = const [420, 900, 2000][_lenClass];
    _segmenter.maxSplitMs = const [1000, 2000, 3500][_lenClass];
    // Same physical limit for Engine A: the recogniser may not claim more
    // reps per second than a human mouth can produce.
    _utterances.minRepMs = _segmenter.minGapMs;
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  INIT / DISPOSE
  // ═══════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    WidgetsBinding.instance.addObserver(this);
    _watchdogTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _watchdogTick());
    _loadDhikrAndPrefs();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_dhikrLoaded) return;
    _log('lifecycle', state.name);
    if (state == AppLifecycleState.paused) {
      _saveCount();
      if (_isListening) {
        _resumeAfterBackground = true;
        _stopListening();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (!_speechAvailable) {
        // Back from Settings after granting the mic / speech permission (or
        // after a failed first start): try again instead of staying dead
        // until the user leaves and re-enters the screen.
        _resumeAfterBackground = false;
        _initSpeech();
      } else if (_resumeAfterBackground) {
        _resumeAfterBackground = false;
        if (!_isListening) _toggleListening();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _isListening = false;
    _restartTimer?.cancel();
    _watchdogTimer?.cancel();
    _speech.stop();
    _pulseCtrl.dispose();
    _ringCtrl.dispose();
    // Finished a round and closed the counter: store rating "happy moment".
    ReviewService.instance.onCounterClosed();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  LOADING
  // ═══════════════════════════════════════════════════════════════════════

  /// Esmaül Hüsna girişinden gelen id'ler 2000 + isim numarasıdır;
  /// isimden geçici bir zikir tanımı üretilir ("Yâ Latîf" gibi).
  Dhikr _dhikrFromEsma(EsmaName e) {
    final stripped = e.name.replaceFirst(
        RegExp(r'^(el|er|es|eş|ed|en|et|ez)-', caseSensitive: false), '');
    final isAllah = e.name == 'Allah';
    return Dhikr(
      id: 2000 + e.number,
      nameTr: isAllah ? 'Allah' : 'Yâ $stripped',
      nameEn: isAllah ? 'Allah' : 'Ya $stripped',
      nameAr: isAllah ? e.arabic : 'يَا ${e.arabic}',
      arabicText: e.arabic,
      meaningTr: '',
      meaningEn: '',
      targetCount: 33,
      keywords: [stripped, 'ya $stripped'],
      source: 'Tirmizî, Deavât 82 (Esmâ-i Hüsnâ)',
    );
  }

  Future<void> _loadDhikrAndPrefs() async {
    late final Dhikr dhikr;
    if (widget.dhikrId >= 2000) {
      final esma = kEsmaList.firstWhere(
        (e) => e.number == widget.dhikrId - 2000,
        orElse: () => kEsmaList.first,
      );
      dhikr = _dhikrFromEsma(esma);
    } else {
      final custom = await CustomDhikrManager.load();
      final all = [...kDhikrList, ...custom];
      dhikr = all.firstWhere(
        (d) => d.id == widget.dhikrId,
        orElse: () => all.first,
      );
    }
    final prefs = await SharedPreferences.getInstance();
    final savedTarget = prefs.getInt('target_${dhikr.id}') ?? dhikr.targetCount;
    // Kaldığı yerden devam: sayı her artışta kaydediliyordu ama açılışta 0'dan
    // başlatılıyordu → uygulama kapanınca sayım kayboluyordu (App Store yorumu
    // 5 Eki: "saydıklarım kayıt olmuyor"). Sıfırlamak için Sıfırla düğmesi var.
    // Test builds only (--dart-define=AUTO_RESET=true): every launch starts at 0.
    const autoReset = bool.fromEnvironment('AUTO_RESET');
    final savedCount = autoReset ? 0 : (prefs.getInt('count_${dhikr.id}') ?? 0);

    if (mounted) {
      setState(() {
        _dhikr = dhikr;
        _count = savedCount;
        _targetCount = savedTarget;
        _dhikrLoaded = true;
        _statusText = _s('Başlatılıyor...', 'Starting...', 'جارٍ التحميل...');
      });
      _configureSegmenter();
      await _initSpeech();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  ENGINE A — STT
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onStatus: _onStatus,
        onError: _onError,
      );
    } catch (e) {
      _speechAvailable = false;
      _log('init-error', '$e');
    }
    var hasPermission = true;
    if (!_speechAvailable) {
      try {
        hasPermission = await _speech.hasPermission;
      } catch (_) {}
    }
    _log('init',
        'available=$_speechAvailable permission=$hasPermission os=${Platform.operatingSystem}');
    if (!_speechAvailable && mounted) {
      setState(() {
        _micDenied = !hasPermission;
        _statusText = _micDenied
            ? _s(
                'Mikrofon izni gerekli · Ayarlar\'ı aç',
                'Microphone permission needed · Open Settings',
                'مطلوب إذن الميكروفون · فتح الإعدادات',
              )
            : _s(
                'Ses tanıma desteklenmiyor',
                'Speech recognition not available',
                'التعرف على الصوت غير متاح',
              );
      });
      return;
    }
    if (mounted) {
      if (_micDenied) setState(() => _micDenied = false);
      // Auto-start counts from the first spoken dhikr: previously the mic
      // session opened here but _isListening stayed false, so the UI showed
      // "Başlat" while the mic was already recording and nothing counted.
      setState(() => _isListening = true);
      _startListening();
    }
  }

  /// Restarts the recognition session ONCE, however many callbacks report
  /// the same drop. Android delivers `error_no_match` + `notListening` +
  /// `done` for a single ended session; firing listen() three times made the
  /// recogniser return "busy" and stop counting altogether.
  ///
  /// [reason] is only for the diagnostics log. [minDelayMs] is a back-off the
  /// caller needs on top of the policy's own (e.g. after a "busy" error).
  void _scheduleRestart(String reason, {int minDelayMs = 0}) {
    if (!_isListening || !mounted) return;
    final now = _nowMs();
    int delayMs;
    if (_restartTimer?.isActive ?? false) {
      // The same dropped session is reported as error + notListening + done.
      // It is ONE restart: count it once, and let only a longer back-off
      // (busy) replace the timer already running.
      if (minDelayMs <= _pendingDelayMs) {
        _log('restart-merged', 'reason=$reason');
        return;
      }
      delayMs = minDelayMs;
    } else {
      delayMs = _restartPolicy.nextDelayMs(now, minDelayMs: minDelayMs);
    }
    _pendingDelayMs = delayMs;
    _log('restart',
        'reason=$reason delay=${delayMs}ms chain=${_restartPolicy.chainLength}'
        '${_restartPolicy.isStorm(now) ? " STORM" : ""}');
    _restartTimer?.cancel();
    _restartTimer = Timer(Duration(milliseconds: delayMs), () async {
      if (!_isListening || !mounted || _restartInFlight) return;
      if (_speech.isListening) return; // session recovered on its own
      _restartInFlight = true;
      try {
        await _startListening();
      } finally {
        _restartInFlight = false;
      }
    });
  }

  Future<void> _startListening() async {
    if (!_speechAvailable || !mounted) return;

    // NOTE: the utterance tracker is deliberately NOT reset here. The old
    // session's final result routinely arrives AFTER the new session has
    // started (Android) and must still be recognised as a re-delivery of
    // text we already credited — that is exactly what the tracker does.
    _segmenter.resetBurstState();

    // STT her zaman Türkçe modelde çalışır: zikir kelimelerini fonetik
    // olarak en iyi TR tanıyıcı yakalıyor (EN tanıyıcı "i like it" gibi
    // saçmalıyor, AR tanıyıcı Arap harfli çıktı verip eşleşmiyor).
    const prefix = 'tr';
    if (_sttLocaleId == null) {
      String localeId = '';
      try {
        final locales = await _speech.locales();
        final match = locales
            .where((l) => l.localeId.startsWith(prefix))
            .map((l) => l.localeId)
            .firstOrNull;
        if (match != null) localeId = match;
      } catch (_) {}
      _sttLocaleId = localeId;
    }
    final localeId = _sttLocaleId!;

    if (_speech.isListening || !_isListening || !mounted) return;

    // Start STT session
    _log('listen', 'locale=$localeId');
    try {
      await _speech.listen(
        onResult: _onResult,
        onSoundLevelChange: _onMicLevel, // feed Engine B (raw platform units)
        // NOT: pencere zamanlayıcısı kaldırıldı — uzlaştırma artık olay anında
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: ListenMode.dictation,
          localeId: localeId,
          listenFor: const Duration(minutes: 5),
          // iOS keeps ONE long task alive, and speech_to_text stops it itself
          // after pauseFor of silence — so with 8 s the mic closed and reopened
          // every 8 s of quiet (measured in the iOS simulator: listening at
          // +1.2 s, notListening at +9.3 s, restart, again at +17.8 s …). Results
          // keep the task alive while the user chants, so a long pauseFor only
          // changes what happens in silence: one renewal a minute instead of
          // seven. Android ends its own sessions, so it keeps 8 s.
          pauseFor: Duration(seconds: Platform.isIOS ? 55 : 8),
        ),
      );
    } catch (e) {
      // Android throws if the recogniser is still tearing the old session
      // down — back off and try again instead of dying silently.
      _log('listen-failed', '$e');
      _scheduleRestart('listen-threw', minDelayMs: 600);
    }
  }

  /// Once a second: has the recogniser gone mute while the user keeps
  /// chanting? If so, give it a fresh session (rate-limited by the watchdog).
  void _watchdogTick() {
    if (!mounted || !_isListening || _restartInFlight) return;
    if (_restartTimer?.isActive ?? false) return;
    final now = _nowMs();
    if (!_watchdog.shouldRenew(now)) return;
    _log('watchdog',
        'renew session (bursts heard, no result) #${_watchdog.renewals}');
    _speech.cancel();
    _scheduleRestart('watchdog');
  }

  void _onStatus(String status) {
    if (!mounted) return;
    _log('status', status);
    if (status == SpeechToText.listeningStatus) {
      _watchdog.noteSessionStart(_nowMs());
      // NOTE: nothing is reset here. Android reports the new session as
      // listening BEFORE the previous session's final result arrives, and
      // resetting the occurrence counter at this point was what made every
      // spoken dhikr count twice. Result bookkeeping is text-based now.
      setState(() {
        _statusText = _s('Dinleniyor...', 'Listening...', 'يستمع...');
        _micLevel = 0.5;
      });
    } else if (status == SpeechToText.notListeningStatus ||
        status == SpeechToText.doneStatus) {
      // The plugin only forwards `done` after the session's final result, so
      // the transcript we were tracking is over (no-op on Android).
      if (status == SpeechToText.doneStatus) {
        _utterances.markSessionEnded(DateTime.now().millisecondsSinceEpoch);
      }
      // Android ends the session after every utterance; keep the mic alive.
      // The delay also gives the pending final result time to land.
      _scheduleRestart('status-$status');
    }
  }

  void _onError(SpeechRecognitionError error) {
    if (!mounted) return;
    _log('error', '${error.errorMsg} permanent=${error.permanent}');
    if (!_isListening) return;
    // "busy" means the previous session is still shutting down — a longer
    // back-off (and a cancel) is the only thing that clears it.
    if (error.errorMsg.contains('busy')) {
      _speech.cancel();
      _scheduleRestart('error-busy', minDelayMs: 800);
    } else {
      // no-match / speech-timeout are normal between reps.
      _scheduleRestart('error-${error.errorMsg}');
    }
  }

  void _onResult(SpeechRecognitionResult result) {
    if (!mounted || !_isListening) return;
    final text = result.recognizedWords;
    if (text.isEmpty) return;
    // Any text means the recogniser is alive and hearing speech: whatever
    // restarted before was healthy, not a failure loop.
    _restartPolicy.noteProgress();

    final normalized = normalizeDhikrText(text);
    final count = countDhikrOccurrences(text, _dhikr.keywords);
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    _watchdog.noteResult(nowMs, matched: count > 0);

    // Rolling gate: an STT match keeps Engine B unlocked for a few seconds.
    if (count > 0) _reconciler.noteSttMatch(nowMs);

    // How much of this text is genuinely new speech? Handles Android's
    // duplicated/late finals and the recogniser echoing a word it heard
    // once — see SttUtteranceTracker.
    final delta = _utterances.onResult(
      normText: normalized,
      occurrences: count,
      nowMs: nowMs,
      isFinal: result.finalResult,
    );

    final credit =
        delta > 0 ? _reconciler.onSttDelta(delta, nowMs) : 0;
    // Last 48 chars only: the end of the transcript is what changed.
    final tail = normalized.length > 48
        ? '…${normalized.substring(normalized.length - 48)}'
        : normalized;
    _log('result',
        '${result.finalResult ? "FINAL" : "part"} n=$count delta=$delta '
        'credit=$credit len=${normalized.length} "$tail"');
    if (credit > 0) _incrementCount(credit, 'stt');
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  ENGINE B — feeds raw mic levels into the BurstSegmenter
  //  (algorithm lives in lib/services/burst_segmenter.dart)
  // ═══════════════════════════════════════════════════════════════════════

  void _onMicLevel(double raw) {
    if (!_isListening) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final level = _segmenter.process(raw, now);
    if (mounted) setState(() => _micLevel = level.clamp(0.1, 1.0));
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  COUNTING HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  void _incrementCount(int by, [String source = '']) {
    if (by <= 0) return;
    _log('count', '+$by via $source → ${_count + by}');

    setState(() {
      _count += by;
      if (_count % _targetCount == 0 && _count > 0) {
        _statusText = _s(
          '${_count ~/ _targetCount}. tur tamamlandı! 🎉',
          'Round ${_count ~/ _targetCount} completed! 🎉',
          'اكتملت الجولة ${_count ~/ _targetCount}! 🎉',
        );
      } else if (_isListening) {
        _statusText = _s('Dinleniyor...', 'Listening...', 'يستمع...');
      }
    });
    _saveCount();
    if (_count % _targetCount == 0) ReviewService.instance.noteRoundCompleted();
    HapticFeedback.lightImpact();
    _pulseCtrl.forward().then((_) => _pulseCtrl.reverse());
  }

  /// Copies the diagnostics timeline to the clipboard (status-line long-press).
  Future<void> _copyDiagnostics() async {
    final header = 'sesli_tesbih diagnostics\n'
        'platform=${Platform.operatingSystem} ${Platform.operatingSystemVersion}\n'
        'dhikr=${_dhikrLoaded ? _dhikr.id : -1} count=$_count target=$_targetCount\n'
        'speechAvailable=$_speechAvailable listening=$_isListening '
        'locale=$_sttLocaleId chain=${_restartPolicy.chainLength}\n'
        'tracker=${_utterances.cumulativeTranscript ? "cumulative" : "per-utterance"}';
    await Clipboard.setData(ClipboardData(text: _diag.dump(header: header)));
    HapticFeedback.mediumImpact();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_s('Tanılama kaydı kopyalandı', 'Diagnostics copied',
          'تم نسخ سجل التشخيص')),
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _saveCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('count_${_dhikr.id}', _count);
  }

  Future<void> _saveTarget() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('target_${_dhikr.id}', _targetCount);
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  CONTROLS
  // ═══════════════════════════════════════════════════════════════════════

  void _stopListening() {
    _log('stop');
    _isListening = false;
    _restartTimer?.cancel();
    _speech.stop();
    _segmenter.resetBurstState();
    setState(() {
      _statusText = _s('Duraklatıldı', 'Paused', 'متوقف');
      _micLevel = 0.0;
    });
  }

  void _toggleListening() {
    if (_isListening) {
      _stopListening();
    } else {
      // Resuming is a clean break: whatever text the recogniser had is gone.
      _log('start');
      _utterances.reset();
      _restartPolicy.reset();
      _watchdog.reset();
      setState(() {
        _isListening = true;
        _statusText = _s('Başlatılıyor...', 'Starting...', 'جارٍ البدء...');
      });
      _startListening();
    }
  }

  void _reset() {
    setState(() {
      _count = 0;
      _utterances.reset();
      _reconciler.reset(); // need fresh STT confirmation after reset
      _segmenter.resetBurstState();
      if (_isListening) {
        _statusText = _s('Dinleniyor...', 'Listening...', 'يستمع...');
      }
    });
    _saveCount();
  }

  void _showTargetDialog() {
    final ctrl = TextEditingController(text: _targetCount.toString())
      ..selection = TextSelection.fromPosition(
        TextPosition(offset: _targetCount.toString().length),
      );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(_s('Hedef Değiştir', 'Change Target', 'تغيير الهدف')),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            prefixIcon: const Icon(Icons.flag_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_s('İptal', 'Cancel', 'إلغاء')),
          ),
          ElevatedButton(
            onPressed: () {
              final v = int.tryParse(ctrl.text) ?? _targetCount;
              setState(() => _targetCount = v.clamp(1, 99999));
              _saveTarget();
              Navigator.pop(ctx);
            },
            child: Text(_s('Kaydet', 'Save', 'حفظ')),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  COMPUTED PROPERTIES
  // ═══════════════════════════════════════════════════════════════════════

  int get _cycleCount => _count % _targetCount;
  double get _progress =>
      (_cycleCount == 0 && _count > 0) ? 1.0 : _cycleCount / _targetCount;
  int get _remaining =>
      (_cycleCount == 0 && _count > 0) ? 0 : _targetCount - _cycleCount;
  int get _roundCount => _count ~/ _targetCount;

  String _s(String tr, String en, String ar) =>
      LocaleService.instance.tr(tr, en, ar);

  // ═══════════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    if (!_dhikrLoaded) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final lang = LocaleService.instance.language;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildTopBar(lang),
            // Compact Android phones are ~150 dp shorter than the iPhone this
            // screen was laid out on, which pushed the Start/Reset/Target row
            // off-screen. Everything scales down to the space actually
            // available (scrolling stays as the last-resort fallback).
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  _ui = (constraints.maxHeight / _kDesignHeight)
                      .clamp(0.62, 1.0);
                  return _buildBody();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Vertical space the counter layout wants at full size (logical px).
  static const double _kDesignHeight = 760;

  /// Scale factor applied to every fixed dimension on this screen.
  double _ui = 1.0;

  double _sc(double v) => v * _ui;

  Widget _buildBody() {
    return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                  horizontal: 20, vertical: _sc(14)),
                child: Column(
                  children: [
                    if (_dhikr.arabicText.isNotEmpty) _buildArabicCard(),
                    if (_dhikr.source.isNotEmpty) ...[
                      SizedBox(height: _sc(10)),
                      Text(
                        '${_s("Kaynak", "Source", "المصدر")}: ${_dhikr.source}',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: _sc(11),
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                      ),
                    ],
                    SizedBox(height: _sc(24)),
                    _buildCircularCounter(),
                    SizedBox(height: _sc(12)),
                    Text(
                      _remaining == 0 && _count > 0
                          ? _s('✓ Hedefe ulaşıldı!', '✓ Target reached!',
                              '✓ تم الوصول للهدف!')
                          : _s('Kalan: $_remaining', 'Remaining: $_remaining',
                              'المتبقي: $_remaining'),
                      style: TextStyle(
                        fontSize: _sc(13),
                        fontWeight: (_remaining == 0 && _count > 0)
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: (_remaining == 0 && _count > 0)
                            ? AppColors.greenAccent
                            : AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: _sc(22)),
                    _buildMicSection(),
                    SizedBox(height: _sc(6)),
                    // Long-press copies the engine's flight recorder, so a
                    // counting problem can be pasted back for diagnosis.
                    // When the mic permission was refused the same line is the
                    // way out: tap it to open the app's Settings page. (No
                    // extra row — that pushed the controls off small phones.)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _micDenied ? openAppSettings : null,
                      onLongPress: _copyDiagnostics,
                      child: Text(
                        _statusText,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: _sc(13),
                          color: _micDenied
                              ? AppColors.greenAccent
                              : AppColors.textSecondary,
                          decoration:
                              _micDenied ? TextDecoration.underline : null,
                        ),
                      ),
                    ),
                    SizedBox(height: _sc(20)),
                    _buildTapButton(),
                    SizedBox(height: _sc(24)),
                    _buildActionButtons(),
                    SizedBox(height: _sc(16)),
                  ],
                ),
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────

  Widget _buildTopBar(String lang) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A1735), Color(0xFF16305F), Color(0xFF1E3A6E)],
        ),
      ),
      // The gradient runs behind the status bar instead of leaving a pale
      // strip above it (Android draws edge-to-edge).
      padding: EdgeInsets.fromLTRB(
          4, MediaQuery.paddingOf(context).top + 4, 4, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              _stopListening();
              Navigator.pop(context);
            },
          ),
          Expanded(
            child: Text(
              _dhikr.localizedName(lang),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // ── Arabic text card ───────────────────────────────────────────────────

  Widget _buildArabicCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: _sc(14)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFDFBF3), Color(0xFFF1E8CF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppColors.greenAccent.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: AppColors.greenMid.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        _dhikr.arabicText,
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontSize: _sc(18),
          color: AppColors.greenDark,
          height: 1.9,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ── Circular progress counter ──────────────────────────────────────────

  Widget _buildCircularCounter() {
    final isComplete = _remaining == 0 && _count > 0;
    final arcColor = isComplete ? AppColors.gold : AppColors.greenMid;

    final outer = _sc(230);
    final inner = _sc(218);

    return SizedBox(
      width: outer,
      height: outer,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow
          Container(
            width: outer,
            height: outer,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.greenMid.withValues(alpha: 0.15),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),
          // White background
          Container(
            width: inner,
            height: inner,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: Colors.white),
          ),
          // Arc
          CustomPaint(
            size: Size(inner, inner),
            painter: _ArcPainter(
              progress: _progress,
              bgColor: AppColors.greenLight,
              fgColor: arcColor,
              strokeWidth: _sc(15),
            ),
          ),
          // Count + target + round badge
          ScaleTransition(
            scale: _pulseAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$_count',
                  style: TextStyle(
                    fontSize: _sc(78),
                    fontWeight: FontWeight.bold,
                    color: isComplete
                        ? const Color(0xFFC9A227)
                        : AppColors.greenDark,
                    height: 1.0,
                  ),
                ),
                Text(
                  '/ $_targetCount',
                  style: TextStyle(
                      fontSize: _sc(18), color: AppColors.textSecondary),
                ),
                if (_roundCount > 0) ...[
                  SizedBox(height: _sc(6)),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: _sc(12), vertical: _sc(4)),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF10234C), Color(0xFF1E3A6E)]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.greenDark.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '$_roundCount. ${_s("tur", "round", "جولة")}',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: _sc(12),
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Mic / audio visualiser ─────────────────────────────────────────────

  Widget _buildMicSection() {
    final mic = _sc(50);
    return SizedBox(
      height: _sc(78),
      child: AnimatedBuilder(
        animation: _ringCtrl,
        builder: (context, _) {
          final t = _ringCtrl.value;
          if (_isListening) {
            return Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: ((1 - t) * 0.35 * _micLevel).clamp(0.0, 1.0),
                  child: Container(
                    width: _sc(68 + _micLevel * 20),
                    height: _sc(68 + _micLevel * 20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.greenAccent, width: 2),
                    ),
                  ),
                ),
                Opacity(
                  opacity:
                      ((1 - ((t + 0.4) % 1.0)) * 0.5 * _micLevel)
                          .clamp(0.0, 1.0),
                  child: Container(
                    width: _sc(52 + _micLevel * 14),
                    height: _sc(52 + _micLevel * 14),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.greenAccent, width: 1.5),
                    ),
                  ),
                ),
                Container(
                  width: mic,
                  height: mic,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFD4AF37), Color(0xFF16305F)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.greenAccent.withValues(alpha: 0.5),
                        blurRadius: 14,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child:
                      Icon(Icons.mic, color: Colors.white, size: _sc(26)),
                ),
              ],
            );
          } else {
            return Container(
              width: mic,
              height: mic,
              decoration: BoxDecoration(
                  color: Colors.grey.shade200, shape: BoxShape.circle),
              child: Icon(Icons.mic_off,
                  color: AppColors.textSecondary, size: _sc(26)),
            );
          }
        },
      ),
    );
  }

  // ── Tap button ─────────────────────────────────────────────────────────

  Widget _buildTapButton() {
    return GestureDetector(
      onTap: () => _incrementCount(1),
      child: Container(
        width: _sc(108),
        height: _sc(108),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFDFBF3), Color(0xFFF1E8CF)],
          ),
          border: Border.all(color: AppColors.greenAccent, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.greenMid.withValues(alpha: 0.25),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app_outlined,
                color: AppColors.greenDark, size: _sc(28)),
            SizedBox(height: _sc(2)),
            Text(
              _s('Dokun', 'Tap', 'لمس'),
              style: TextStyle(
                  color: AppColors.greenDark,
                  fontWeight: FontWeight.bold,
                  fontSize: _sc(14)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Action buttons ─────────────────────────────────────────────────────

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ActionButton(
          label: _isListening
              ? _s('Duraklat', 'Pause', 'إيقاف')
              : _s('Başlat', 'Start', 'ابدأ'),
          icon: _isListening ? Icons.pause_circle : Icons.play_circle,
          gradient: const LinearGradient(
              colors: [Color(0xFF10234C), Color(0xFF1E3A6E)]),
          onTap: _toggleListening,
          scale: _ui,
        ),
        _ActionButton(
          label: _s('Sıfırla', 'Reset', 'إعادة'),
          icon: Icons.refresh_rounded,
          gradient: const LinearGradient(
              colors: [Color(0xFFA8861D), Color(0xFFC9A227)]),
          onTap: _reset,
          scale: _ui,
        ),
        _ActionButton(
          label: _s('Hedef', 'Target', 'الهدف'),
          icon: Icons.flag_rounded,
          gradient: const LinearGradient(
              colors: [Color(0xFF16305F), Color(0xFF2C4A7C)]),
          onTap: _showTargetDialog,
          scale: _ui,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  ARC PAINTER
// ═══════════════════════════════════════════════════════════════════════════

class _ArcPainter extends CustomPainter {
  final double progress;
  final Color bgColor;
  final Color fgColor;
  final double strokeWidth;

  const _ArcPainter({
    required this.progress,
    required this.bgColor,
    required this.fgColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = bgColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = fgColor
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      progress != old.progress || fgColor != old.fgColor;
}

// ═══════════════════════════════════════════════════════════════════════════
//  ACTION BUTTON
// ═══════════════════════════════════════════════════════════════════════════

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;
  final double scale;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onTap,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 58 * scale,
            height: 58 * scale,
            decoration: BoxDecoration(
              gradient: gradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28 * scale),
          ),
          SizedBox(height: 6 * scale),
          // Long localised labels (fr/id/ur) must shrink, not overflow.
          SizedBox(
            width: 96 * scale,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12 * scale,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
