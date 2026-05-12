class Dhikr {
  final int id;
  final String nameTr;
  final String nameEn;
  final String nameAr;
  final String arabicText;
  final String meaningTr;
  final String meaningEn;
  final int targetCount;
  final List<String> keywords;

  const Dhikr({
    required this.id,
    required this.nameTr,
    required this.nameEn,
    required this.nameAr,
    required this.arabicText,
    required this.meaningTr,
    required this.meaningEn,
    required this.targetCount,
    required this.keywords,
  });

  String localizedName(String lang) {
    if (lang == 'ar') return nameAr;
    if (lang == 'en') return nameEn;
    return nameTr;
  }

  String localizedMeaning(String lang) {
    if (lang == 'en' || lang == 'ar') return meaningEn;
    return meaningTr;
  }

  Dhikr copyWith({
    int? id,
    String? nameTr,
    String? nameEn,
    String? nameAr,
    String? arabicText,
    String? meaningTr,
    String? meaningEn,
    int? targetCount,
    List<String>? keywords,
  }) {
    return Dhikr(
      id: id ?? this.id,
      nameTr: nameTr ?? this.nameTr,
      nameEn: nameEn ?? this.nameEn,
      nameAr: nameAr ?? this.nameAr,
      arabicText: arabicText ?? this.arabicText,
      meaningTr: meaningTr ?? this.meaningTr,
      meaningEn: meaningEn ?? this.meaningEn,
      targetCount: targetCount ?? this.targetCount,
      keywords: keywords ?? this.keywords,
    );
  }
}
