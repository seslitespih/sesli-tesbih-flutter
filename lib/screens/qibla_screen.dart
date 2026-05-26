import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import '../main.dart';
import '../services/locale_service.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen>
    with SingleTickerProviderStateMixin {
  double _qiblaAngle = 0.0;
  double _deviceHeading = 0.0;
  bool _locationLoaded = false;
  bool _aligned = false;
  String _statusText = '';

  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _glowAnim = CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut);

    _loadQibla();
    _listenCompass();
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadQibla() async {
    if (mounted) {
      setState(() => _statusText =
          _s('Konum alınıyor...', 'Getting location...', 'جارٍ تحديد الموقع...'));
    }
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setQiblaFor(41.0082, 28.9784);
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _setQiblaFor(41.0082, 28.9784);
        return;
      }
      final pos = await Geolocator.getLastKnownPosition() ??
          await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
          );
      _setQiblaFor(pos.latitude, pos.longitude);
    } catch (_) {
      _setQiblaFor(41.0082, 28.9784);
    }
  }

  void _setQiblaFor(double lat, double lng) {
    final angle = _calculateQibla(lat, lng);
    if (mounted) {
      setState(() {
        _qiblaAngle = angle;
        _locationLoaded = true;
        _statusText = '';
      });
    }
  }

  double _calculateQibla(double userLat, double userLng) {
    const meccaLat = 21.4225;
    const meccaLng = 39.8262;
    final lat1 = userLat * math.pi / 180;
    const lat2 = meccaLat * math.pi / 180;
    final dLng = (meccaLng - userLng) * math.pi / 180;
    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    final bearing = math.atan2(y, x) * 180 / math.pi;
    return (bearing + 360) % 360;
  }

  void _listenCompass() {
    FlutterCompass.events?.listen((event) {
      final heading = event.heading;
      if (heading == null || !mounted) return;
      final normalized = (heading + 360) % 360;
      final needleAngle = (_qiblaAngle - normalized + 360) % 360;
      final diff = needleAngle > 180 ? 360 - needleAngle : needleAngle;
      setState(() {
        _deviceHeading = normalized;
        _aligned = diff <= 5;
      });
    });
  }

  double get _needleAngle {
    final angle = (_qiblaAngle - _deviceHeading + 360) % 360;
    return angle * math.pi / 180;
  }

  String _s(String tr, String en, String ar) =>
      LocaleService.instance.tr(tr, en, ar);

  @override
  Widget build(BuildContext context) {
    final title = _s('Kıble Yönü', 'Qibla Direction', 'اتجاه القبلة');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(title),
            Expanded(
              child: Center(
                child: _statusText.isNotEmpty && !_locationLoaded
                    ? _buildLoading()
                    : _buildCompass(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(String title) {
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
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              title,
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

  Widget _buildLoading() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(color: AppColors.greenMid),
        const SizedBox(height: 16),
        Text(
          _statusText,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildCompass() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status text
          AnimatedBuilder(
            animation: _glowAnim,
            builder: (context, _) {
              return AnimatedOpacity(
                opacity: _aligned ? 1.0 : 0.85,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: _aligned
                        ? LinearGradient(
                            colors: [
                              AppColors.greenDark,
                              Color.lerp(
                                AppColors.greenDark,
                                AppColors.greenAccent,
                                _glowAnim.value * 0.4,
                              )!,
                            ],
                          )
                        : null,
                    color: _aligned ? null : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: _aligned
                            ? AppColors.greenAccent.withValues(alpha: 0.4 * _glowAnim.value)
                            : Colors.black.withValues(alpha: 0.08),
                        blurRadius: _aligned ? 16 : 6,
                        spreadRadius: _aligned ? 2 : 0,
                      ),
                    ],
                  ),
                  child: Text(
                    _aligned
                        ? _s('✓ Kıble yönündesiniz!',
                            "✓ You're facing Qibla!", '✓ أنت في اتجاه القبلة!')
                        : _s('Kıble Yönü', 'Qibla Direction', 'اتجاه القبلة'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _aligned ? Colors.white : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            '${_qiblaAngle.round()}°',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          // Compass widget
          AnimatedBuilder(
            animation: _glowAnim,
            builder: (context, _) {
              return SizedBox(
                width: 280,
                height: 280,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer glow when aligned
                    if (_aligned)
                      Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.greenAccent.withValues(
                                alpha: 0.35 * _glowAnim.value,
                              ),
                              blurRadius: 28,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    // Compass circle
                    Container(
                      width: 270,
                      height: 270,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: _aligned
                              ? AppColors.greenAccent
                              : Colors.grey.shade200,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                    // Tick marks
                    CustomPaint(
                      size: const Size(270, 270),
                      painter: _CompassTickPainter(),
                    ),
                    // Cardinal labels
                    ..._buildCardinalLabels(),
                    // Needle
                    Transform.rotate(
                      angle: _needleAngle,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // North tip (points to Qibla)
                          Container(
                            width: 10,
                            height: 90,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: _aligned
                                    ? [
                                        const Color(0xFF4CAF50),
                                        const Color(0xFF2E7D32),
                                      ]
                                    : [
                                        const Color(0xFF2E7D32),
                                        const Color(0xFF1B5E20),
                                      ],
                              ),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(5),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (_aligned
                                          ? AppColors.greenAccent
                                          : AppColors.greenMid)
                                      .withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          // Center pivot
                          Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              gradient: RadialGradient(
                                colors: [
                                  Color(0xFF4CAF50),
                                  Color(0xFF1B5E20),
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                          // South tip
                          Container(
                            width: 10,
                            height: 65,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Kaaba emoji in center
                    const Positioned(
                      child: Text('🕋', style: TextStyle(fontSize: 24)),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 28),
          // Info text
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Text(
              _s(
                'Kıble hesaplaması GPS konumunuza göre yapılmıştır.',
                'Qibla calculated based on your GPS location.',
                'تم حساب القبلة بناءً على موقع GPS الخاص بك.',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCardinalLabels() {
    final labels = {
      'N': 0.0,
      'E': 90.0,
      'S': 180.0,
      'W': 270.0,
    };
    return labels.entries.map((e) {
      final rad = e.value * math.pi / 180;
      const r = 118.0;
      final dx = r * math.sin(rad);
      final dy = -r * math.cos(rad);
      return Positioned(
        left: 135 + dx - 11,
        top: 135 + dy - 11,
        child: SizedBox(
          width: 22,
          height: 22,
          child: Center(
            child: Text(
              e.key,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: e.key == 'N'
                    ? AppColors.greenDark
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}

// ─── Compass Tick Painter ─────────────────────────────────────────────────────

class _CompassTickPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.width / 2 - 4;

    for (var i = 0; i < 36; i++) {
      final angle = i * 10 * math.pi / 180 - math.pi / 2;
      final isCardinal = i % 9 == 0;
      final isMinor = i % 3 == 0;
      final tickLen = isCardinal ? 14.0 : (isMinor ? 9.0 : 5.0);
      final paint = Paint()
        ..color = isCardinal
            ? AppColors.greenDark
            : (isMinor
                ? AppColors.textSecondary
                : Colors.grey.shade300)
        ..strokeWidth = isCardinal ? 2.0 : 1.0;

      final start = Offset(
        center.dx + (outerR - tickLen) * math.cos(angle),
        center.dy + (outerR - tickLen) * math.sin(angle),
      );
      final end = Offset(
        center.dx + outerR * math.cos(angle),
        center.dy + outerR * math.sin(angle),
      );
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(_CompassTickPainter old) => false;
}
