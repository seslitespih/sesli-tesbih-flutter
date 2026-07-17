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

  // tr keeps its own text; ar shows the Arabic original alone;
  // every other language falls back to English.
  String localizedTitle(String lang) =>
      lang == 'tr' ? title : titleEn;

  String localizedText(String lang) =>
      lang == 'tr' ? turkish : (lang == 'ar' ? '' : english);

  String localizedInfo(String lang) =>
      lang == 'tr' ? info : infoEn;
}
