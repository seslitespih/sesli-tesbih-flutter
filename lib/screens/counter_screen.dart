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
import '../services/custom_dhikr_manager.dart';
import '../services/locale_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  DUAL-ENGINE DHIKR COUNTER
//
//  Engine A — STT (speech-to-text keyword matching)
//    • Accurate when it works; can miss words during fast speech
//    • Runs as a continuous session (5-min listenFor, 8-s pauseFor)
//
//  Engine B — Audio-onset detector (mic level waveform)
//    • Counts every "speech burst" using a local-floor onset algorithm
//    • Does NOT depend on word recognition → works for any speed
//    • Gate: only activates after Engine A confirms the correct dhikr
//
//  Reconciler (every 1.5 s)
//    • Compares how many counts each engine added in the window
//    • Credits MAX(sttWindow, audioWindow) to the total
//    • Engine B can add at most 2 extra per window (noise cap)
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
  String _lastRecognizedText = '';  // shows what STT heard (debug / UX)

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
  //  ENGINE B — Audio-onset detector
  // ───────────────────────────────────────────────────────────────────────
  // Circular level buffer used to compute a local noise floor.
  // onSoundLevelChange fires ≈ every 100 ms → 20 frames ≈ 2 s of history.
  final List<double> _lvlBuf = List.filled(20, 0.0);
  int _lvlBufIdx = 0;

  // Onset state machine
  bool _audioAbove = false;      // currently inside a speech burst
  int _framesAboveNow = 0;       // consecutive frames above threshold
  int _framesSinceOnset = 0;     // frames elapsed since last confirmed onset

  // Gate: Engine B only fires after Engine A has confirmed the dhikr once.
  // This prevents background noise being counted before the user starts.
  bool _dhikrConfirmed = false;

  // Onset tuning constants
  static const double _kOnsetRise = 0.16;   // must rise this much above floor
  static const int _kConfirmFrames = 2;     // frames above threshold to confirm onset
  static const int _kNoiseCapPerWindow = 2; // max audio-only adds per window

  // ───────────────────────────────────────────────────────────────────────
  //  RECONCILER
  // ───────────────────────────────────────────────────────────────────────
  int _audioOnsetWindow = 0;   // Engine B onsets in current window
  int _sttDeltaWindow = 0;     // Engine A deltas applied in current window
  Timer? _windowTimer;
  static const int _kWindowMs = 1500; // reconcile every 1.5 s

  // ───────────────────────────────────────────────────────────────────────
  //  Adaptive onset minimum (long dhikr = longer gap required)
  // ───────────────────────────────────────────────────────────────────────
  int get _minFramesBetweenOnsets {
    if (!_dhikrLoaded) return 5;
    final len = _dhikr.arabicText.length;
    if (len > 60) return 22; // very long dhikr (Tefrice/Münciye): ≥2.2 s
    if (len > 25) return 11; // medium (Kulhuvallah): ≥1.1 s
    return 3;                // short (Subhanallah etc.): ≥300 ms
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
    _windowTimer?.cancel();
    _pulseCtrl.dispose();
    _ringCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  LOADING
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _loadDhikrAndPrefs() async {
    final custom = await CustomDhikrManager.load();
    final all = [...kDhikrList, ...custom];
    final dhikr = all.firstWhere(
      (d) => d.id == widget.dhikrId,
      orElse: () => all.first,
    );
    final prefs = await SharedPreferences.getInstance();
    final savedCount = prefs.getInt('count_${dhikr.id}') ?? 0;
    final savedTarget = prefs.getInt('target_${dhikr.id}') ?? dhikr.targetCount;

    if (mounted) {
      setState(() {
        _dhikr = dhikr;
        _count = savedCount;
        _targetCount = savedTarget;
        _dhikrLoaded = true;
        _statusText = _s('Başlatılıyor...', 'Starting...', 'جارٍ التحميل...');
      });
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
    if (mounted) _startListening();
  }

  Future<void> _startListening() async {
    if (!_speechAvailable || !mounted) return;

    // Reset per-session STT counter; keep _dhikrConfirmed (still same dhikr)
    _sessionPartialCount = 0;
    _audioAbove = false;
    _framesAboveNow = 0;
    _framesSinceOnset = 0;

    // Locale detection
    final lang = LocaleService.instance.language;
    final prefix = lang == 'ar' ? 'ar' : (lang == 'en' ? 'en' : 'tr');
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
      onSoundLevelChange: (raw) {
        final normalized = ((raw + 2.0) / 12.0).clamp(0.0, 1.0);
        if (mounted) setState(() => _micLevel = normalized.clamp(0.1, 1.0));
        _onMicLevel(normalized); // feed Engine B
      },
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: false,
        listenMode: ListenMode.dictation,
        localeId: localeId,
        listenFor: const Duration(minutes: 5),
        pauseFor: const Duration(seconds: 8),
      ),
    );

    // Start reconciler timer when session begins
    _windowTimer?.cancel();
    _windowTimer = Timer.periodic(
      Duration(milliseconds: _kWindowMs),
      (_) => _reconcileWindow(),
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

    // Update debug display
    if (mounted) {
      setState(() {
        _lastRecognizedText =
            text.length > 60 ? '…${text.substring(text.length - 60)}' : text;
      });
    }

    final count = _countOccurrences(text);

    // Gate: once Engine A finds the keyword, unlock Engine B.
    if (count > 0) _dhikrConfirmed = true;

    // Increment only the NEW occurrences since the last partial update.
    final delta = (count - _sessionPartialCount).clamp(0, 99);

    if (result.finalResult) {
      _sessionPartialCount = 0;
    } else if (count > _sessionPartialCount) {
      // Only advance upward — STT sometimes revises its text downward.
      _sessionPartialCount = count;
    }

    if (delta > 0 && mounted) _incrementCount(delta, fromStt: true);
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  ENGINE B — Audio-onset detector
  // ═══════════════════════════════════════════════════════════════════════
  //
  //  Algorithm:
  //   1. Maintain a circular buffer of recent mic levels.
  //   2. Compute local noise floor = average of the quietest 25 % of frames.
  //   3. An "onset" = level rises > floor + _kOnsetRise for ≥ _kConfirmFrames
  //      consecutive frames AND ≥ _minFramesBetweenOnsets have elapsed since
  //      the previous onset.
  //   4. Count onset → _audioOnsetWindow++ (if _dhikrConfirmed).
  //
  //  The adaptive minimum gap prevents a single long dhikr (Kulhuvallah)
  //  from being counted multiple times within one recitation.

  void _onMicLevel(double level) {
    if (!_isListening) return;

    // Update circular buffer
    _lvlBuf[_lvlBufIdx] = level;
    _lvlBufIdx = (_lvlBufIdx + 1) % _lvlBuf.length;
    _framesSinceOnset++;

    // Local noise floor: mean of the 5 quietest recent frames
    final sorted = List<double>.from(_lvlBuf)..sort();
    final floor = sorted.take(5).fold(0.0, (a, b) => a + b) / 5;

    final isAbove = level > floor + _kOnsetRise;

    if (isAbove) {
      _framesAboveNow++;
    } else {
      _framesAboveNow = 0;
      _audioAbove = false; // allow next onset to be detected
    }

    // Confirmed onset: not already in a burst, above for enough frames,
    // and enough time has elapsed since the previous onset.
    if (_framesAboveNow >= _kConfirmFrames &&
        !_audioAbove &&
        _framesSinceOnset >= _minFramesBetweenOnsets) {
      _audioAbove = true;
      _framesSinceOnset = 0;
      if (_dhikrConfirmed) {
        _audioOnsetWindow++;
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  RECONCILER — fires every 1.5 s
  // ═══════════════════════════════════════════════════════════════════════
  //
  //  STT already called _incrementCount(sttDelta) in real-time.
  //  Audio onsets were counted in _audioOnsetWindow.
  //
  //  If audio detected MORE than STT, add the excess (capped at
  //  _kNoiseCapPerWindow to prevent noise runaway).

  void _reconcileWindow() {
    if (!mounted || !_isListening || !_dhikrConfirmed) {
      _audioOnsetWindow = 0;
      _sttDeltaWindow = 0;
      return;
    }

    final audioN = _audioOnsetWindow;
    final sttN = _sttDeltaWindow;
    final excess = (audioN - sttN).clamp(0, _kNoiseCapPerWindow);

    if (excess > 0) {
      _incrementCount(excess, fromStt: false);
    }

    _audioOnsetWindow = 0;
    _sttDeltaWindow = 0;
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  COUNTING HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Normalise a string: collapse Turkic/Arabic diacritics → ASCII letters only.
  String _normalize(String s) {
    return s
        .toLowerCase()
        .replaceAll('â', 'a').replaceAll('î', 'i').replaceAll('û', 'u')
        .replaceAll('ê', 'e').replaceAll('ā', 'a').replaceAll('ī', 'i')
        .replaceAll('ū', 'u').replaceAll('ğ', 'g').replaceAll('ı', 'i')
        .replaceAll('ü', 'u').replaceAll('ö', 'o').replaceAll('ş', 's')
        .replaceAll('ç', 'c')
        .replaceAllMapped(RegExp(r'[^a-z]'), (_) => '');
  }

  /// Count occurrences: try all keywords, return the maximum found.
  int _countOccurrences(String rawText) {
    final text = _normalize(rawText);
    int maxCount = 0;
    for (final keyword in _dhikr.keywords) {
      final kw = _normalize(keyword);
      if (kw.isEmpty) continue;
      var n = 0, pos = 0;
      while (true) {
        final found = text.indexOf(kw, pos);
        if (found == -1) break;
        n++;
        pos = found + kw.length;
      }
      if (n > maxCount) maxCount = n;
    }
    return maxCount;
  }

  /// Central increment — tracks whether the delta came from STT or audio.
  void _incrementCount(int by, {bool fromStt = false}) {
    if (by <= 0) return;
    if (fromStt) _sttDeltaWindow += by;

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
    _windowTimer?.cancel();
    _windowTimer = null;
    _audioOnsetWindow = 0;
    _sttDeltaWindow = 0;
    _audioAbove = false;
    _framesAboveNow = 0;
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
      _audioOnsetWindow = 0;
      _sttDeltaWindow = 0;
      _dhikrConfirmed = false;  // need fresh STT confirmation after reset
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
                    const SizedBox(height: 10),
                    Text(
                      _dhikr.localizedMeaning(lang),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                      ),
                    ),
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
                    // Show what STT heard — helps user diagnose if keywords need tuning
                    if (_lastRecognizedText.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '"$_lastRecognizedText"',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary.withValues(alpha: 0.6),
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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
          colors: [Color(0xFF1A5C1E), Color(0xFF2E7D32), Color(0xFF43A047)],
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
          colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
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
    final arcColor =
        isComplete ? const Color(0xFFFFCA28) : AppColors.greenAccent;

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
                        ? const Color(0xFFFFCA28)
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
                          colors: [Color(0xFF1B5E20), Color(0xFF388E3C)]),
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
                      colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
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
            colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
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
              colors: [Color(0xFF1B5E20), Color(0xFF388E3C)]),
          onTap: _toggleListening,
        ),
        _ActionButton(
          label: _s('Sıfırla', 'Reset', 'إعادة'),
          icon: Icons.refresh_rounded,
          gradient: const LinearGradient(
              colors: [Color(0xFFE65100), Color(0xFFF57C00)]),
          onTap: _reset,
        ),
        _ActionButton(
          label: _s('Hedef', 'Target', 'الهدف'),
          icon: Icons.flag_rounded,
          gradient: const LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF1976D2)]),
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
