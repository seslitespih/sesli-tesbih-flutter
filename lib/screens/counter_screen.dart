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

class CounterScreen extends StatefulWidget {
  final int dhikrId;
  const CounterScreen({super.key, required this.dhikrId});

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen>
    with TickerProviderStateMixin {
  late Dhikr _dhikr;
  bool _dhikrLoaded = false;

  final SpeechToText _speech = SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;
  double _micLevel = 0.5;

  int _count = 0;
  int _targetCount = 33;
  int _sessionPartialCount = 0;

  // ── Audio-onset backup counter ─────────────────────────────────────────────
  // Counts speech bursts via mic level. When STT misses an utterance
  // completely, the audio counter adds 1 after a short STT-processing delay.
  bool _audioInSpeech = false;
  int _audioSpeechFrames = 0;
  int _audioSilenceFrames = 0;
  int _countAtSpeechStart = 0;

  static const double _kAudioOnset = 0.26;  // normalized level → speech started
  static const double _kAudioOffset = 0.08; // normalized level → silence
  static const int _kMinSpeechFrames = 4;   // ≥4 frames (~400 ms) = real utterance
  static const int _kSilenceToEnd = 4;      // 4 frames (~400 ms) silence = utterance done

  // Debug: last words the STT heard (shown in UI so user can tune keywords)
  String _lastRecognizedText = '';

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  late AnimationController _ringCtrl;

  String _statusText = '';

  // ── init ──────────────────────────────────────────────────────────────────

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

  Future<void> _loadDhikrAndPrefs() async {
    final custom = await CustomDhikrManager.load();
    final all = [...kDhikrList, ...custom];
    final dhikr = all.firstWhere(
      (d) => d.id == widget.dhikrId,
      orElse: () => all.first,
    );

    final prefs = await SharedPreferences.getInstance();
    final savedCount = prefs.getInt('count_${dhikr.id}') ?? 0;
    final savedTarget =
        prefs.getInt('target_${dhikr.id}') ?? dhikr.targetCount;

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

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: _onStatus,
      onError: _onError,
    );
    if (!_speechAvailable && mounted) {
      setState(() {
        _statusText = _s(
          'Ses tanıma desteklenmiyor',
          'Speech recognition not available',
          'التعرف على الصوت غير متاح',
        );
      });
      return;
    }
    if (mounted) _startListening();
  }

  // ── STT callbacks ─────────────────────────────────────────────────────────

  void _onStatus(String status) {
    if (!mounted) return;
    if (status == SpeechToText.listeningStatus) {
      setState(() {
        _statusText = _s('Dinleniyor...', 'Listening...', 'يستمع...');
        _micLevel = 0.5;
      });
    } else if (status == SpeechToText.notListeningStatus ||
        status == SpeechToText.doneStatus) {
      // Do NOT reset _sessionPartialCount here — final result may arrive after
      // this status. _startListening() resets it at the correct time.
      if (_isListening) {
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

  Future<void> _startListening() async {
    if (!_speechAvailable || !mounted) return;
    _sessionPartialCount = 0;
    _audioInSpeech = false;
    _audioSpeechFrames = 0;
    _audioSilenceFrames = 0;

    final selectedLang = LocaleService.instance.language;
    final preferredPrefix = selectedLang == 'ar'
        ? 'ar'
        : (selectedLang == 'en' ? 'en' : 'tr');
    String localeId = '';
    try {
      final locales = await _speech.locales();
      final match = locales
          .where((l) => l.localeId.startsWith(preferredPrefix))
          .map((l) => l.localeId)
          .firstOrNull;
      if (match != null) localeId = match;
    } catch (_) {}

    await _speech.listen(
      onResult: _onResult,
      onSoundLevelChange: (level) {
        final normalized = ((level + 2.0) / 12.0).clamp(0.0, 1.0);
        if (mounted) setState(() => _micLevel = normalized.clamp(0.1, 1.0));
        _onMicLevel(normalized);
      },
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: false,
        listenMode: ListenMode.dictation,
        localeId: localeId.isNotEmpty ? localeId : '',
        listenFor: const Duration(minutes: 5),  // keep session alive for 5 min
        pauseFor: const Duration(seconds: 8),   // 8 s silence = session end
      ),
    );
  }

  void _onResult(SpeechRecognitionResult result) {
    final text = result.recognizedWords;
    if (text.isEmpty) return;

    // Show what STT heard so the user can tune custom keywords if needed
    if (mounted) {
      setState(() {
        _lastRecognizedText =
            text.length > 55 ? '…${text.substring(text.length - 55)}' : text;
      });
    }

    final rawOcc = _countOccurrences(text);
    final delta = (rawOcc - _sessionPartialCount).clamp(0, 99);

    if (result.finalResult) {
      _sessionPartialCount = 0;
    } else if (rawOcc > _sessionPartialCount) {
      // Only advance upward — STT sometimes revises down mid-stream,
      // which would falsely re-trigger a delta on the next partial.
      _sessionPartialCount = rawOcc;
    }

    if (delta > 0 && mounted) _incrementCount(delta);
  }

  // ── Audio-onset backup counting ────────────────────────────────────────────
  // Called on every mic-level update (~100 ms interval).
  // Detects speech onset/offset and, after giving STT 600 ms to respond,
  // adds 1 if STT completely missed the utterance.
  void _onMicLevel(double level) {
    if (!_isListening) return;

    if (!_audioInSpeech) {
      if (level > _kAudioOnset) {
        _audioInSpeech = true;
        _audioSpeechFrames = 1;
        _audioSilenceFrames = 0;
        _countAtSpeechStart = _count;
      }
    } else {
      if (level > _kAudioOffset) {
        _audioSpeechFrames++;
        _audioSilenceFrames = 0;
      } else {
        _audioSilenceFrames++;
        if (_audioSilenceFrames >= _kSilenceToEnd) {
          final frames = _audioSpeechFrames;
          final cStart = _countAtSpeechStart;
          _audioInSpeech = false;
          _audioSpeechFrames = 0;
          _audioSilenceFrames = 0;

          if (frames >= _kMinSpeechFrames) {
            // Give STT 600 ms to process this utterance first.
            // If the count is still the same afterward, STT missed it → add 1.
            Future.delayed(const Duration(milliseconds: 600), () {
              if (mounted && _isListening && _count == cStart) {
                _incrementCount(1);
              }
            });
          }
        }
      }
    }
  }

  // ── Counting logic ────────────────────────────────────────────────────────

  String _normalize(String s) {
    return s
        .toLowerCase()
        .replaceAll('â', 'a')
        .replaceAll('î', 'i')
        .replaceAll('û', 'u')
        .replaceAll('ê', 'e')
        .replaceAll('ā', 'a')
        .replaceAll('ī', 'i')
        .replaceAll('ū', 'u')
        .replaceAll('ğ', 'g')
        .replaceAll('ı', 'i')
        .replaceAll('ü', 'u')
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ç', 'c')
        .replaceAllMapped(RegExp(r'[^a-z]'), (_) => '');
  }

  int _countOccurrences(String rawText) {
    final text = _normalize(rawText);
    int maxCount = 0;
    for (final keyword in _dhikr.keywords) {
      final kw = _normalize(keyword);
      if (kw.isEmpty) continue;
      var n = 0;
      var pos = 0;
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

  void _incrementCount(int by) {
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

  void _stopListening() {
    _isListening = false;
    _speech.stop();
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

  // ── Computed values ───────────────────────────────────────────────────────

  int get _cycleCount => _count % _targetCount;
  double get _progress =>
      (_cycleCount == 0 && _count > 0) ? 1.0 : _cycleCount / _targetCount;
  int get _remaining =>
      (_cycleCount == 0 && _count > 0) ? 0 : _targetCount - _cycleCount;
  int get _roundCount => _count ~/ _targetCount;

  String _s(String tr, String en, String ar) =>
      LocaleService.instance.tr(tr, en, ar);

  // ── Build ─────────────────────────────────────────────────────────────────

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                          ? _s(
                              '✓ Hedefe ulaşıldı!',
                              '✓ Target reached!',
                              '✓ تم الوصول للهدف!',
                            )
                          : _s(
                              'Kalan: $_remaining',
                              'Remaining: $_remaining',
                              'المتبقي: $_remaining',
                            ),
                      style: TextStyle(
                        fontSize: 13,
                        color: (_remaining == 0 && _count > 0)
                            ? AppColors.greenAccent
                            : AppColors.textSecondary,
                        fontWeight: (_remaining == 0 && _count > 0)
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _buildMicSection(),
                    const SizedBox(height: 6),
                    Text(
                      _statusText,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (_lastRecognizedText.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '"$_lastRecognizedText"',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary.withValues(alpha: 0.65),
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
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

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
        border: Border.all(color: AppColors.greenAccent.withValues(alpha: 0.4)),
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

  Widget _buildCircularCounter() {
    final isComplete = _remaining == 0 && _count > 0;
    final arcColor = isComplete
        ? const Color(0xFFFFCA28)
        : AppColors.greenAccent;

    return SizedBox(
      width: 230,
      height: 230,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
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
          // White background circle
          Container(
            width: 218,
            height: 218,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
          // Arc progress
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
                    fontSize: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (_roundCount > 0) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
                      ),
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
                        fontWeight: FontWeight.bold,
                      ),
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
                // Outer ring
                Opacity(
                  opacity: ((1 - t) * 0.35 * _micLevel).clamp(0.0, 1.0),
                  child: Container(
                    width: 68 + _micLevel * 20,
                    height: 68 + _micLevel * 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.greenAccent,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                // Middle ring
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
                        color: AppColors.greenAccent,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                // Mic icon core
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
                  child: const Icon(Icons.mic, color: Colors.white, size: 26),
                ),
              ],
            );
          } else {
            return Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mic_off,
                  color: AppColors.textSecondary, size: 26),
            );
          }
        },
      ),
    );
  }

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
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
            colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
          ),
          onTap: _toggleListening,
        ),
        _ActionButton(
          label: _s('Sıfırla', 'Reset', 'إعادة'),
          icon: Icons.refresh_rounded,
          gradient: const LinearGradient(
            colors: [Color(0xFFE65100), Color(0xFFF57C00)],
          ),
          onTap: _reset,
        ),
        _ActionButton(
          label: _s('Hedef', 'Target', 'الهدف'),
          icon: Icons.flag_rounded,
          gradient: const LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
          ),
          onTap: _showTargetDialog,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _isListening = false;
    _speech.stop();
    _pulseCtrl.dispose();
    _ringCtrl.dispose();
    super.dispose();
  }
}

// ─── Arc Painter ─────────────────────────────────────────────────────────────

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

    // Background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = bgColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke,
    );

    // Progress arc
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

// ─── Action Button ────────────────────────────────────────────────────────────

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
