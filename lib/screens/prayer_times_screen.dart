import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
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

  // Country code → Aladhan method number
  int _methodForCountry(String? cc) {
    switch (cc?.toUpperCase()) {
      case 'TR':
        return 13; // Diyanet İşleri Başkanlığı
      case 'SA':
      case 'AE':
      case 'KW':
      case 'QA':
      case 'BH':
      case 'OM':
        return 4; // Umm al-Qura (Gulf)
      case 'EG':
        return 5; // Egyptian General Authority
      case 'US':
      case 'CA':
        return 2; // ISNA
      case 'PK':
      case 'IN':
      case 'BD':
      case 'AF':
        return 1; // University of Islamic Sciences, Karachi
      case 'SG':
      case 'MY':
        return 11; // MUIS Singapore
      case 'IR':
        return 7; // Tehran
      case 'GB':
      case 'FR':
      case 'DE':
      case 'NL':
      case 'BE':
        return 3; // Muslim World League (Europe)
      default:
        return 3; // Muslim World League (worldwide default)
    }
  }

  // Country code → school (0=Shafi'i, 1=Hanafi)
  int _schoolForCountry(String? cc) {
    const hanafi = {'TR', 'PK', 'IN', 'BD', 'AF', 'AZ', 'UZ', 'KZ', 'TM', 'TJ', 'KG'};
    return hanafi.contains(cc?.toUpperCase()) ? 1 : 0;
  }

  Future<void> _loadPrayerTimes() async {
    try {
      final position = await _getLocation();
      final lat = position?.latitude ?? 41.0082;
      final lng = position?.longitude ?? 28.9784;

      String cityName = '';
      String? countryCode;

      if (position != null) {
        try {
          final placemarks = await placemarkFromCoordinates(lat, lng);
          final p = placemarks.firstOrNull;
          cityName = p?.locality ?? p?.administrativeArea ?? '';
          countryCode = p?.isoCountryCode;
        } catch (_) {}
      }

      if (cityName.isEmpty) cityName = position == null ? 'Istanbul' : '';

      // Try Aladhan API first
      final apiOk = await _fetchFromAladhan(lat, lng, cityName, countryCode);
      if (!apiOk) {
        // Fallback: local calculation with adhan_dart
        _showTimesLocal(lat, lng, cityName);
      }
    } catch (e) {
      _showTimesLocal(41.0082, 28.9784, 'Istanbul');
    }
  }

  Future<bool> _fetchFromAladhan(
      double lat, double lng, String city, String? countryCode) async {
    try {
      final method = _methodForCountry(countryCode);
      final school = _schoolForCountry(countryCode);
      final uri = Uri.parse(
        'https://api.aladhan.com/v1/timings'
        '?latitude=$lat&longitude=$lng&method=$method&school=$school',
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return false;

      final body = json.decode(response.body) as Map<String, dynamic>;
      if (body['code'] != 200) return false;

      final timings = body['data']['timings'] as Map<String, dynamic>;
      final date = body['data']['date']['readable'] as String? ?? '';

      if (mounted) {
        setState(() {
          _city = city.isNotEmpty
              ? city
              : '${lat.toStringAsFixed(2)}°, ${lng.toStringAsFixed(2)}°';
          _dateStr = _localizedDate(date);
          _fajr = timings['Fajr'] ?? '--:--';
          _sunrise = timings['Sunrise'] ?? '--:--';
          _dhuhr = timings['Dhuhr'] ?? '--:--';
          _asr = timings['Asr'] ?? '--:--';
          _maghrib = timings['Maghrib'] ?? '--:--';
          _isha = timings['Isha'] ?? '--:--';
          _nextPrayerIndex = _calcNextIndex();
          _loading = false;
        });
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  // Fallback: local adhan_dart calculation
  void _showTimesLocal(double lat, double lng, String city) {
    try {
      final coords = Coordinates(lat, lng);
      final params = CalculationMethodParameters.muslimWorldLeague();
      final now = DateTime.now();
      final prayerTimes = PrayerTimes(
        coordinates: coords,
        date: now,
        calculationParameters: params,
      );

      if (mounted) {
        setState(() {
          _city = city.isNotEmpty
              ? city
              : '${lat.toStringAsFixed(2)}°, ${lng.toStringAsFixed(2)}°';
          _dateStr = _buildDateStr(now);
          _fajr = _fmt(prayerTimes.fajr);
          _sunrise = _fmt(prayerTimes.sunrise);
          _dhuhr = _fmt(prayerTimes.dhuhr);
          _asr = _fmt(prayerTimes.asr);
          _maghrib = _fmt(prayerTimes.maghrib);
          _isha = _fmt(prayerTimes.isha);
          _nextPrayerIndex = _calcNextIndex();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _s('Hesaplama hatası', 'Calculation error', 'خطأ في الحساب');
          _loading = false;
        });
      }
    }
  }

  // "15 May 2026" → locale-aware
  String _localizedDate(String readable) {
    try {
      final parts = readable.split(' ');
      if (parts.length < 3) return readable;
      final day = parts[0];
      final monthEn = parts[1];
      final year = parts[2];
      const enMonths = [
        'January','February','March','April','May','June',
        'July','August','September','October','November','December'
      ];
      const trMonths = [
        'Ocak','Şubat','Mart','Nisan','Mayıs','Haziran',
        'Temmuz','Ağustos','Eylül','Ekim','Kasım','Aralık'
      ];
      const arMonths = [
        'يناير','فبراير','مارس','أبريل','مايو','يونيو',
        'يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'
      ];
      final idx = enMonths.indexWhere(
          (m) => m.toLowerCase() == monthEn.toLowerCase());
      if (idx == -1) return readable;
      final lang = LocaleService.instance.language;
      final months = lang == 'ar' ? arMonths : (lang == 'tr' ? trMonths : enMonths);
      return '$day ${months[idx]} $year';
    } catch (_) {
      return readable;
    }
  }

  String _buildDateStr(DateTime now) {
    final lang = LocaleService.instance.language;
    final months = lang == 'en'
        ? ['','January','February','March','April','May','June',
            'July','August','September','October','November','December']
        : lang == 'ar'
        ? ['','يناير','فبراير','مارس','أبريل','مايو','يونيو',
            'يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر']
        : ['','Ocak','Şubat','Mart','Nisan','Mayıs','Haziran',
            'Temmuz','Ağustos','Eylül','Ekim','Kasım','Aralık'];
    return '${now.day} ${months[now.month]} ${now.year}';
  }

  int _calcNextIndex() {
    final times = [_fajr, _sunrise, _dhuhr, _asr, _maghrib, _isha];
    final now = TimeOfDay.now();
    for (var i = 0; i < times.length; i++) {
      final t = _parseTime(times[i]);
      if (t == null) continue;
      if (t.hour > now.hour || (t.hour == now.hour && t.minute > now.minute)) {
        return i;
      }
    }
    return -1;
  }

  TimeOfDay? _parseTime(String s) {
    final parts = s.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String _fmt(DateTime? dt) {
    if (dt == null) return '--:--';
    final local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
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
