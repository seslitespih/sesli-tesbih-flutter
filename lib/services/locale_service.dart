import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService extends ChangeNotifier {
  static final LocaleService instance = LocaleService._();
  LocaleService._();

  static const _keyLang = 'app_language';

  String _language = 'tr';
  String get language => _language;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _language = prefs.getString(_keyLang) ?? 'tr';
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
