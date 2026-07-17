import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'extra_translations.dart';

class LocaleService extends ChangeNotifier {
  static final LocaleService instance = LocaleService._();
  LocaleService._();

  static const _keyLang = 'app_language';

  /// Core languages have inline strings everywhere; extra languages are
  /// translated via [kExtraTranslations], keyed by the English string.
  static const List<String> supported = ['tr', 'en', 'ar', 'id', 'ur', 'fr'];

  String _language = 'en';
  String get language => _language;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_keyLang);
    if (saved != null && supported.contains(saved)) {
      _language = saved;
    } else {
      // First launch: detect device language
      final deviceLang = ui.PlatformDispatcher.instance.locale.languageCode;
      _language = supported.contains(deviceLang) ? deviceLang : 'en';
    }
  }

  Future<void> setLanguage(String lang) async {
    if (_language == lang) return;
    _language = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLang, lang);
    notifyListeners();
  }

  // String helpers — use these throughout the app.
  // Extra languages (id/ur/fr) look the English string up in the
  // translation table and fall back to English when missing.
  String tr(String trStr, String enStr, String arStr) {
    switch (_language) {
      case 'en':
        return enStr;
      case 'ar':
        return arStr;
      case 'tr':
        return trStr;
      default:
        return _extra(enStr);
    }
  }

  /// Exact lookup first; then template lookup where the dynamic part
  /// (a number, or a quoted name) is replaced by `#` in the table key.
  String _extra(String enStr) {
    final table = kExtraTranslations[_language];
    if (table == null) return enStr;
    final direct = table[enStr];
    if (direct != null) return direct;

    final numMatch = RegExp(r'\d+').firstMatch(enStr);
    if (numMatch != null) {
      final tmpl = table[enStr.replaceFirst(numMatch.group(0)!, '#')];
      if (tmpl != null) return tmpl.replaceFirst('#', numMatch.group(0)!);
    }
    final quoted = RegExp(r'"([^"]*)"').firstMatch(enStr);
    if (quoted != null) {
      final tmpl = table[enStr.replaceFirst(quoted.group(0)!, '"#"')];
      if (tmpl != null) return tmpl.replaceFirst('#', quoted.group(1)!);
    }
    return enStr;
  }
}
