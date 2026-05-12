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

class _QiblaScreenState extends State<QiblaScreen> {
  double _qiblaAngle = 0.0;
  double _deviceHeading = 0.0;
  bool _locationLoaded = false;
  bool _aligned = false;
  String _statusText = '';

  @override
  void initState() {
    super.initState();
    _loadQibla();
    _listenCompass();
  }

  Future<void> _loadQibla() async {
    if (mounted) setState(() => _statusText = 'Konum alınıyor...');
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
            locationSettings:
                const LocationSettings(accuracy: LocationAccuracy.low),
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

  // Haversine-based qibla bearing toward Mecca
  double _calculateQibla(double userLat, double userLng) {
    const meccaLat = 21.4225;
    const meccaLng = 39.8262;

    final lat1 = userLat * math.pi / 180;
    final lat2 = meccaLat * math.pi / 180;
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
      final normalizedHeading = (heading + 360) % 360;
      final needleAngle = (_qiblaAngle - normalizedHeading + 360) % 360;
      final diff = needleAngle > 180 ? 360 - needleAngle : needleAngle;
      final newAligned = diff <= 5;

      setState(() {
        _deviceHeading = normalizedHeading;
        _aligned = newAligned;
      });
    });
  }

  // Needle rotation: points toward qibla relative to device heading
  double get _needleAngle {
    final angle = (_qiblaAngle - _deviceHeading + 360) % 360;
    return angle * math.pi / 180;
  }

  String _s(String tr, String en, String ar) =>
      LocaleService.instance.tr(tr, en, ar);

  @override
  Widget build(BuildContext context) {
    final lang = LocaleService.instance.language;
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
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 12),
                          Text(_statusText),
                        ],
                      )
                    : _buildCompass(lang),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(String title) {
    return Container(
      color: AppColors.greenDark,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  Widget _buildCompass(String lang) {
    final alignedText = _s(
      'Kıble yönündesiniz!',
      "You're facing Qibla!",
      'أنت في اتجاه القبلة!',
    );
    final dirText = _s('Kıble Yönü', 'Qibla Direction', 'اتجاه القبلة');

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _aligned ? alignedText : dirText,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _aligned ? AppColors.greenAccent : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '${_qiblaAngle.round()}°',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 260,
            height: 260,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Compass circle
                Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 12,
                      )
                    ],
                  ),
                ),
                // Cardinal directions
                ..._buildCardinalLabels(),
                // Needle
                Transform.rotate(
                  angle: _needleAngle,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // North tip (points to Qibla)
                      Container(
                        width: 12,
                        height: 80,
                        decoration: BoxDecoration(
                          color: _aligned
                              ? AppColors.greenAccent
                              : AppColors.greenDark,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                      ),
                      // Center pivot
                      Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: AppColors.greenDark,
                          shape: BoxShape.circle,
                        ),
                      ),
                      // South tip
                      Container(
                        width: 12,
                        height: 60,
                        color: Colors.grey.shade300,
                      ),
                    ],
                  ),
                ),
                // Kaaba icon at center
                const Text('🕋', style: TextStyle(fontSize: 22)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
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
        ],
      ),
    );
  }

  List<Widget> _buildCardinalLabels() {
    const labels = {'N': 0.0, 'E': 90.0, 'S': 180.0, 'W': 270.0};
    return labels.entries.map((e) {
      final rad = e.value * math.pi / 180;
      const r = 110.0;
      final dx = r * math.sin(rad);
      final dy = -r * math.cos(rad);
      return Positioned(
        left: 130 + dx - 10,
        top: 130 + dy - 10,
        child: SizedBox(
          width: 20,
          height: 20,
          child: Center(
            child: Text(
              e.key,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}
