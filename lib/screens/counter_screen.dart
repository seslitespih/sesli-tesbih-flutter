import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    with TickerProviderStateMixin {
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
  int _sessionPartialCount = 0;   // tracks running STT count within session

  // ───────────────────────────────────────────────────────────────────────
  //  ENGINE B — Audio burst segmenter (core logic in BurstSegmenter,
  //  unit-tested with synthetic waveforms in test/burst_segmenter_test.dart)
  // ───────────────────────────────────────────────────────────────────────
  late final BurstSegmenter _segmenter = BurstSegmenter(
    onRep: (nowMs) {
      if (!_isListening || !mounted) return;
      final credit = _reconciler.onAudioRep(nowMs);
      if (credit > 0) _incrementCount(credit);
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
    _loadDhikrAndPrefs();
  }

  @override
  void dispose() {
    _isListening = false;
    _speech.stop();
    _pulseCtrl.dispose();
    _ringCtrl.dispose();
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

    if (mounted) {
      setState(() {
        _dhikr = dhikr;
        _count = 0; // her açılışta sıfırdan başla
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
    _speechAvailable = await _speech.initialize(
      onStatus: _onStatus,
      onError: _onError,
    );
    if (!_speechAvailable && mounted) {
      setState(() => _statusText = _s(
            'Ses tanıma desteklenmiyor',
            'Speech recognition not available',
            'التعرف على الصوت غير متاح',
          ));
      return;
    }
    if (mounted) {
      // Auto-start counts from the first spoken dhikr: previously the mic
      // session opened here but _isListening stayed false, so the UI showed
      // "Başlat" while the mic was already recording and nothing counted.
      setState(() => _isListening = true);
      _startListening();
    }
  }

  Future<void> _startListening() async {
    if (!_speechAvailable || !mounted) return;

    // Reset per-session STT counter; keep the rolling STT gate (same dhikr)
    _sessionPartialCount = 0;
    _segmenter.resetBurstState();

    // STT her zaman Türkçe modelde çalışır: zikir kelimelerini fonetik
    // olarak en iyi TR tanıyıcı yakalıyor (EN tanıyıcı "i like it" gibi
    // saçmalıyor, AR tanıyıcı Arap harfli çıktı verip eşleşmiyor).
    const prefix = 'tr';
    String localeId = '';
    try {
      final locales = await _speech.locales();
      final match = locales
          .where((l) => l.localeId.startsWith(prefix))
          .map((l) => l.localeId)
          .firstOrNull;
      if (match != null) localeId = match;
    } catch (_) {}

    // Start STT session
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
        pauseFor: const Duration(seconds: 8),
      ),
    );

  }

  void _onStatus(String status) {
    if (!mounted) return;
    if (status == SpeechToText.listeningStatus) {
      setState(() {
        _statusText = _s('Dinleniyor...', 'Listening...', 'يستمع...');
        _micLevel = 0.5;
      });
    } else if (status == SpeechToText.notListeningStatus ||
        status == SpeechToText.doneStatus) {
      // Do NOT reset _sessionPartialCount here — the final result may
      // arrive AFTER this status callback, causing double-counting.
      if (_isListening) {
        // Restart immediately (no delay) so no speech is missed.
        Future.delayed(Duration.zero, () {
          if (_isListening && mounted) _startListening();
        });
      }
    }
  }

  void _onError(SpeechRecognitionError error) {
    if (!mounted || !_isListening) return;
    final delay = error.errorMsg.contains('busy') ? 500 : 50;
    Future.delayed(Duration(milliseconds: delay), () {
      if (_isListening && mounted) _startListening();
    });
  }

  void _onResult(SpeechRecognitionResult result) {
    final text = result.recognizedWords;
    if (text.isEmpty) return;

    final count = _countOccurrences(text);
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    // Rolling gate: an STT match keeps Engine B unlocked for a few seconds.
    if (count > 0) _reconciler.noteSttMatch(nowMs);

    // Increment only the NEW occurrences since the last partial update.
    final delta = (count - _sessionPartialCount).clamp(0, 99);

    if (result.finalResult) {
      _sessionPartialCount = 0;
    } else if (count > _sessionPartialCount) {
      // Only advance upward — STT sometimes revises its text downward.
      _sessionPartialCount = count;
    }

    if (delta > 0 && mounted && _isListening) {
      final credit = _reconciler.onSttDelta(delta, nowMs);
      if (credit > 0) _incrementCount(credit);
    }
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

  /// Count occurrences via the shared, unit-tested matcher.
  int _countOccurrences(String rawText) =>
      countDhikrOccurrences(rawText, _dhikr.keywords);

  void _incrementCount(int by) {
    if (by <= 0) return;

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
    HapticFeedback.lightImpact();
    _pulseCtrl.forward().then((_) => _pulseCtrl.reverse());
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
    _isListening = false;
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
      _sessionPartialCount = 0;
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
        child: Column(
          children: [
            _buildTopBar(lang),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                    if (_dhikr.arabicText.isNotEmpty) _buildArabicCard(),
                    if (_dhikr.source.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        '${_s("Kaynak", "Source", "المصدر")}: ${_dhikr.source}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    _buildCircularCounter(),
                    const SizedBox(height: 12),
                    Text(
                      _remaining == 0 && _count > 0
                          ? _s('✓ Hedefe ulaşıldı!', '✓ Target reached!',
                              '✓ تم الوصول للهدف!')
                          : _s('Kalan: $_remaining', 'Remaining: $_remaining',
                              'المتبقي: $_remaining'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: (_remaining == 0 && _count > 0)
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: (_remaining == 0 && _count > 0)
                            ? AppColors.greenAccent
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _buildMicSection(),
                    const SizedBox(height: 6),
                    Text(
                      _statusText,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    _buildTapButton(),
                    const SizedBox(height: 28),
                    _buildActionButtons(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        style: const TextStyle(
          fontSize: 18,
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

    return SizedBox(
      width: 230,
      height: 230,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow
          Container(
            width: 230,
            height: 230,
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
            width: 218,
            height: 218,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: Colors.white),
          ),
          // Arc
          CustomPaint(
            size: const Size(218, 218),
            painter: _ArcPainter(
              progress: _progress,
              bgColor: AppColors.greenLight,
              fgColor: arcColor,
              strokeWidth: 15,
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
                    fontSize: 78,
                    fontWeight: FontWeight.bold,
                    color: isComplete
                        ? const Color(0xFFC9A227)
                        : AppColors.greenDark,
                    height: 1.0,
                  ),
                ),
                Text(
                  '/ $_targetCount',
                  style: const TextStyle(
                      fontSize: 18, color: AppColors.textSecondary),
                ),
                if (_roundCount > 0) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
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
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
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
    return SizedBox(
      height: 80,
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
                    width: 68 + _micLevel * 20,
                    height: 68 + _micLevel * 20,
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
                    width: 52 + _micLevel * 14,
                    height: 52 + _micLevel * 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.greenAccent, width: 1.5),
                    ),
                  ),
                ),
                Container(
                  width: 50,
                  height: 50,
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
                      const Icon(Icons.mic, color: Colors.white, size: 26),
                ),
              ],
            );
          } else {
            return Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                  color: Colors.grey.shade200, shape: BoxShape.circle),
              child: const Icon(Icons.mic_off,
                  color: AppColors.textSecondary, size: 26),
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
        width: 110,
        height: 110,
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
            const Icon(Icons.touch_app_outlined,
                color: AppColors.greenDark, size: 28),
            const SizedBox(height: 2),
            Text(
              _s('Dokun', 'Tap', 'لمس'),
              style: const TextStyle(
                  color: AppColors.greenDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
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
        ),
        _ActionButton(
          label: _s('Sıfırla', 'Reset', 'إعادة'),
          icon: Icons.refresh_rounded,
          gradient: const LinearGradient(
              colors: [Color(0xFFA8861D), Color(0xFFC9A227)]),
          onTap: _reset,
        ),
        _ActionButton(
          label: _s('Hedef', 'Target', 'الهدف'),
          icon: Icons.flag_rounded,
          gradient: const LinearGradient(
              colors: [Color(0xFF16305F), Color(0xFF2C4A7C)]),
          onTap: _showTargetDialog,
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

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
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
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
