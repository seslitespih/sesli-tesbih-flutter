import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:adhan_dart/adhan_dart.dart';
import '../main.dart';
import '../services/locale_service.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  String _city = '';
  String _dateStr = '';
  bool _loading = true;
  String _error = '';

  String _fajr = '--:--';
  String _sunrise = '--:--';
  String _dhuhr = '--:--';
  String _asr = '--:--';
  String _maghrib = '--:--';
  String _isha = '--:--';
  int _nextPrayerIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadPrayerTimes();
  }

  Future<void> _loadPrayerTimes() async {
    try {
      final position = await _getLocation();
      final lat = position?.latitude ?? 41.0082;
      final lng = position?.longitude ?? 28.9784;

      String cityName = '';
      if (position != null) {
        try {
          final placemarks = await placemarkFromCoordinates(lat, lng);
          cityName = placemarks.firstOrNull?.locality ??
              placemarks.firstOrNull?.administrativeArea ??
              '';
        } catch (_) {}
      }
      if (cityName.isEmpty) cityName = position == null ? 'İstanbul' : '';

      _showTimes(lat, lng, cityName);
    } catch (e) {
      _showTimes(41.0082, 28.9784, 'İstanbul');
    }
  }

  Future<Position?> _getLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getLastKnownPosition() ??
          await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
          );
    } catch (_) {
      return null;
    }
  }

  void _showTimes(double lat, double lng, String city) {
    try {
      final coords = Coordinates(lat, lng);
      final params = CalculationMethod.muslimWorldLeague.getParameters();
      final now = DateTime.now();
      final dateComponents = DateComponents.from(now);
      final prayerTimes = PrayerTimes(coords, dateComponents, params);

      final fmt = _formatTime;
      final prayers = [
        prayerTimes.fajr,
        prayerTimes.sunrise,
        prayerTimes.dhuhr,
        prayerTimes.asr,
        prayerTimes.maghrib,
        prayerTimes.isha,
      ];

      int nextIdx = -1;
      for (var i = 0; i < prayers.length; i++) {
        if (prayers[i] != null && prayers[i]!.isAfter(now)) {
          nextIdx = i;
          break;
        }
      }

      final months = [
        '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
        'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
      ];

      if (mounted) {
        setState(() {
          _city = city.isNotEmpty ? city : '${lat.toStringAsFixed(2)}°, ${lng.toStringAsFixed(2)}°';
          _dateStr = '${now.day} ${months[now.month]} ${now.year}';
          _fajr = fmt(prayerTimes.fajr);
          _sunrise = fmt(prayerTimes.sunrise);
          _dhuhr = fmt(prayerTimes.dhuhr);
          _asr = fmt(prayerTimes.asr);
          _maghrib = fmt(prayerTimes.maghrib);
          _isha = fmt(prayerTimes.isha);
          _nextPrayerIndex = nextIdx;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Hesaplama hatası: $e';
          _loading = false;
        });
      }
    }
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '--:--';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _s(String tr, String en, String ar) =>
      LocaleService.instance.tr(tr, en, ar);

  @override
  Widget build(BuildContext context) {
    final lang = LocaleService.instance.language;
    final title = _s('Namaz Vakitleri', 'Prayer Times', 'أوقات الصلاة');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(title),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error.isNotEmpty
                      ? Center(child: Text(_error))
                      : _buildContent(lang),
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

  Widget _buildContent(String lang) {
    final prayerNames = lang == 'en'
        ? ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha']
        : lang == 'ar'
            ? ['الفجر', 'الشروق', 'الظهر', 'العصر', 'المغرب', 'العشاء']
            : ['İmsak', 'Güneş', 'Öğle', 'İkindi', 'Akşam', 'Yatsı'];

    final times = [_fajr, _sunrise, _dhuhr, _asr, _maghrib, _isha];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  _city,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.greenDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _dateStr,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(prayerNames.length, (i) {
          final isNext = i == _nextPrayerIndex;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: isNext ? AppColors.greenLight : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isNext
                  ? const BorderSide(color: AppColors.greenAccent, width: 2)
                  : BorderSide.none,
            ),
            child: ListTile(
              leading: Icon(
                Icons.access_time,
                color: isNext ? AppColors.greenDark : AppColors.textSecondary,
              ),
              title: Text(
                prayerNames[i],
                style: TextStyle(
                  fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
                  color: isNext ? AppColors.greenDark : AppColors.textPrimary,
                ),
              ),
              trailing: Text(
                times[i],
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isNext ? AppColors.greenDark : AppColors.textPrimary,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
