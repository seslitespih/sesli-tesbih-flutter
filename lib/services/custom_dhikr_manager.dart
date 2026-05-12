import 'package:shared_preferences/shared_preferences.dart';
import '../models/dhikr.dart';

class CustomDhikrManager {
  static const _prefsKey = 'custom_dhikr_list';
  static const _customIdStart = 1000;

  static Future<List<Dhikr>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey) ?? '';
    if (raw.trim().isEmpty) return [];

    return raw
        .split('\n')
        .where((line) => line.isNotEmpty)
        .map((line) {
          final parts = line.split('|');
          if (parts.length < 4) return null;
          final id = int.tryParse(parts[0]);
          if (id == null) return null;
          final name = parts[1];
          final keywords = parts[2]
              .split(',')
              .where((k) => k.isNotEmpty)
              .toList();
          final target = int.tryParse(parts[3]) ?? 100;
          return Dhikr(
            id: id,
            nameTr: name,
            nameEn: name,
            nameAr: name,
            arabicText: '',
            meaningTr: '',
            meaningEn: '',
            targetCount: target,
            keywords: keywords,
          );
        })
        .whereType<Dhikr>()
        .toList();
  }

  static Future<Dhikr> add(
      String name, String keyword, int targetCount) async {
    final existing = await load();
    final newId = existing.isEmpty
        ? _customIdStart
        : (existing.map((d) => d.id).reduce((a, b) => a > b ? a : b) + 1)
            .clamp(_customIdStart, double.maxFinite.toInt());
    final keywords = keyword
        .toLowerCase()
        .split(RegExp(r'[,،]'))
        .map((k) => k.trim())
        .where((k) => k.isNotEmpty)
        .toList();
    final dhikr = Dhikr(
      id: newId,
      nameTr: name,
      nameEn: name,
      nameAr: name,
      arabicText: '',
      meaningTr: '',
      meaningEn: '',
      targetCount: targetCount,
      keywords: keywords,
    );
    await _save([...existing, dhikr]);
    return dhikr;
  }

  static Future<void> remove(int id) async {
    final existing = await load();
    await _save(existing.where((d) => d.id != id).toList());
  }

  static Future<void> _save(List<Dhikr> list) async {
    final raw = list
        .map((d) =>
            '${d.id}|${d.nameTr}|${d.keywords.join(',')}|${d.targetCount}')
        .join('\n');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, raw);
  }

  static bool isCustom(int id) => id >= _customIdStart;
}
