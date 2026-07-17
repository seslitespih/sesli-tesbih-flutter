import '../data/dua_translations_extra.dart';

class Dua {
  final String title;
  final String titleEn;
  final String arabicText;
  final String transliteration;
  final String turkish;
  final String english;
  final String info;
  final String infoEn;

  const Dua({
    required this.title,
    required this.titleEn,
    required this.arabicText,
    required this.transliteration,
    required this.turkish,
    required this.english,
    required this.info,
    required this.infoEn,
  });

  // tr keeps its own text; ar shows the Arabic original alone; id/ur/fr
  // use kDuaTranslationsExtra; anything else falls back to English.
  DuaTr? _extra(String lang) => kDuaTranslationsExtra[lang]?[titleEn];

  String localizedTitle(String lang) {
    if (lang == 'tr') return title;
    return _extra(lang)?.title ?? titleEn;
  }

  String localizedText(String lang) {
    if (lang == 'tr') return turkish;
    if (lang == 'ar') return '';
    return _extra(lang)?.text ?? english;
  }

  String localizedInfo(String lang) {
    if (lang == 'tr') return info;
    return _extra(lang)?.info ?? infoEn;
  }
}
