class Dua {
  final String title;
  final String titleEn;
  final String arabicText;
  final String turkish;
  final String english;
  final String info;
  final String infoEn;

  const Dua({
    required this.title,
    required this.titleEn,
    required this.arabicText,
    required this.turkish,
    required this.english,
    required this.info,
    required this.infoEn,
  });

  String localizedTitle(String lang) =>
      lang == 'en' ? titleEn : title;

  String localizedText(String lang) =>
      lang == 'en' ? english : (lang == 'ar' ? '' : turkish);

  String localizedInfo(String lang) =>
      lang == 'en' ? infoEn : info;
}
