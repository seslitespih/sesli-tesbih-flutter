import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService extends ChangeNotifier {
  static final LocaleService instance = LocaleService._();
  LocaleService._();

  static const _keyLang = 'app_language';

  String _language = 'en';
  String get language => _language;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_keyLang);
    if (saved != null) {
      _language = saved;
    } else {
      // First launch: detect device language
      final deviceLang = ui.PlatformDispatcher.instance.locale.languageCode;
      if (deviceLang == 'tr') {
        _language = 'tr';
      } else if (deviceLang == 'ar') {
        _language = 'ar';
      } else {
        _language = 'en';
      }
    }
  }

  Future<void> setLanguage(String lang) async {
    if (_language == lang) return;
    _language = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLang, lang);
    notifyListeners();
  }

  // String helpers — use these throughout the app
  String tr(String trStr, String enStr, String arStr) {
    if (_language == 'en') return enStr;
    if (_language == 'ar') return arStr;
    return trStr;
  }
}
