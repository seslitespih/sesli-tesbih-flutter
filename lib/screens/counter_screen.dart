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
    with SingleTickerProviderStateMixin {
  static const _prefsName = 'sesli_tesbih_prefs';

  late Dhikr _dhikr;
  bool _dhikrLoaded = false;

  final SpeechToText _speech = SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;
  double _micLevel = 0.5;

  int _count = 0;
  int _targetCount = 33;

  // Partial result tracking (per listen session)
  int _sessionPartialCount = 0;

  // Adaptive cooldown
  int _lastCountTime = 0;
  int _adaptiveCooldownMs = 400;
  final List<int> _paceTracker = [];

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  String _statusText = '';

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );
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

  void _onStatus(String status) {
    if (!mounted) return;
    if (status == SpeechToText.listeningStatus) {
      setState(() {
        _statusText = _s('Dinleniyor...', 'Listening...', 'يستمع...');
        _micLevel = 0.5;
      });
    } else if (status == SpeechToText.notListeningStatus ||
        status == SpeechToText.doneStatus) {
      // Reset partial counter for new session
      _sessionPartialCount = 0;
      if (_isListening) {
        // Restart immediately
        Future.delayed(const Duration(milliseconds: 80), () {
          if (_isListening && mounted) _startListening();
        });
      }
    }
  }

  void _onError(SpeechRecognitionError error) {
    if (!mounted || !_isListening) return;
    final delay = error.errorMsg.contains('busy') ? 400 : 150;
    Future.delayed(Duration(milliseconds: delay), () {
      if (_isListening && mounted) {
        _sessionPartialCount = 0;
        _startListening();
      }
    });
  }

  Future<void> _startListening() async {
    if (!_speechAvailable || !mounted) return;
    _sessionPartialCount = 0;

    // Determine best locale
    String localeId = 'tr-TR';
    try {
      final locales = await _speech.locales();
      final trLocale = locales
          .where((l) => l.localeId.startsWith('tr'))
          .map((l) => l.localeId)
          .firstOrNull;
      if (trLocale != null) localeId = trLocale;
    } catch (_) {}

    await _speech.listen(
      onResult: _onResult,
      partialResults: true,
      localeId: localeId,
      cancelOnError: false,
      listenMode: ListenMode.dictation,
      onSoundLevelChange: (level) {
        if (mounted) {
          setState(() {
            _micLevel = ((level + 2.0) / 12.0).clamp(0.1, 1.0);
          });
        }
      },
    );
  }

  void _onResult(SpeechRecognitionResult result) {
    final text = result.recognizedWords;
    if (text.isEmpty) return;

    final rawOcc = _countOccurrences(text);
    final delta = (rawOcc - _sessionPartialCount).clamp(0, 99);

    if (result.finalResult) {
      _sessionPartialCount = 0;
    } else {
      _sessionPartialCount = rawOcc;
    }

    if (delta > 0) _countFromSpeech(delta);
  }

  void _countFromSpeech(int delta) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsed = now - _lastCountTime;

    if (_lastCountTime > 0 && elapsed < _adaptiveCooldownMs) return;

    // Update adaptive cooldown based on pace
    if (_lastCountTime > 0 && elapsed < 10000) {
      _paceTracker.add(elapsed);
      if (_paceTracker.length > 5) _paceTracker.removeAt(0);
      if (_paceTracker.length >= 2) {
        final avg = _paceTracker.reduce((a, b) => a + b) ~/ _paceTracker.length;
        _adaptiveCooldownMs = (avg * 65 ~/ 100).clamp(200, 1200);
      }
    }

    _lastCountTime = now;
    if (mounted) _incrementCount(delta);
  }

  // Normalize text: remove diacritics, Turkic chars → ASCII, remove spaces/punctuation
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
    final sorted = _dhikr.keywords
        .where((k) => k.isNotEmpty)
        .toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final keyword in sorted) {
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
      if (n > 0) return n;
    }
    return 0;
  }

  void _incrementCount(int by) {
    setState(() {
      _count += by;
      if (_count % _targetCount == 0 && _count > 0) {
        _statusText = _s(
          '${_count ~/ _targetCount}. tur tamamlandı!',
          'Round ${_count ~/ _targetCount} completed!',
          'اكتملت الجولة ${_count ~/ _targetCount}!',
        );
      } else if (_isListening) {
        _statusText = _s('Dinleniyor...', 'Listening...', 'يستمع...');
      }
    });
    _saveCount();
    _triggerFeedback();
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

  void _triggerFeedback() {
    HapticFeedback.lightImpact();
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
      _lastCountTime = 0;
      _adaptiveCooldownMs = 400;
      _paceTracker.clear();
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
        title: Text(_s('Hedef Değiştir', 'Change Target', 'تغيير الهدف')),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
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

  int get _cycleCount => _count % _targetCount;
  double get _progress =>
      (_cycleCount == 0 && _count > 0) ? 1.0 : _cycleCount / _targetCount;
  int get _remaining =>
      (_cycleCount == 0 && _count > 0) ? 0 : _targetCount - _cycleCount;

  String _s(String tr, String en, String ar) =>
      LocaleService.instance.tr(tr, en, ar);

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
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    if (_dhikr.arabicText.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.greenLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _dhikr.arabicText,
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(
                            fontSize: 18,
                            color: AppColors.greenDark,
                            height: 1.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      _dhikr.localizedMeaning(lang),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: _progress,
                        minHeight: 10,
                        backgroundColor: AppColors.greenLight,
                        color: AppColors.greenAccent,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _remaining == 0 && _count > 0
                          ? _s('Hedefe ulaşıldı!', 'Target reached!', 'تم الوصول للهدف!')
                          : _s('Kalan: $_remaining', 'Remaining: $_remaining', 'المتبقي: $_remaining'),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Count display with pulse animation
                    ScaleTransition(
                      scale: _pulseAnim,
                      child: Column(
                        children: [
                          Text(
                            '$_count',
                            style: const TextStyle(
                              fontSize: 88,
                              fontWeight: FontWeight.bold,
                              color: AppColors.greenDark,
                              height: 1,
                            ),
                          ),
                          Text(
                            '/ $_targetCount',
                            style: const TextStyle(
                              fontSize: 22,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Mic icon
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _isListening ? _micLevel.clamp(0.3, 1.0) : 0.0,
                      child: Icon(
                        Icons.mic,
                        size: 48,
                        color: AppColors.greenAccent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _statusText,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Tap button
                    GestureDetector(
                      onTap: () => _incrementCount(1),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.greenLight,
                          border: Border.all(
                            color: AppColors.greenAccent,
                            width: 3,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _s('Dokun', 'Tap', 'لمس'),
                            style: const TextStyle(
                              color: AppColors.greenDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ActionButton(
                          label: _isListening
                              ? _s('Duraklat', 'Pause', 'إيقاف')
                              : _s('Başlat', 'Start', 'ابدأ'),
                          icon: _isListening ? Icons.pause : Icons.play_arrow,
                          color: AppColors.greenMid,
                          onTap: _toggleListening,
                        ),
                        _ActionButton(
                          label: _s('Sıfırla', 'Reset', 'إعادة'),
                          icon: Icons.refresh,
                          color: Colors.orange,
                          onTap: _reset,
                        ),
                        _ActionButton(
                          label: _s('Hedef', 'Target', 'الهدف'),
                          icon: Icons.flag_outlined,
                          color: AppColors.greenDark,
                          onTap: _showTargetDialog,
                        ),
                      ],
                    ),
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
      color: AppColors.greenDark,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  @override
  void dispose() {
    _isListening = false;
    _speech.stop();
    _pulseCtrl.dispose();
    super.dispose();
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
