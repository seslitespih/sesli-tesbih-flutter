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

  /// Source citation (Quran verse / hadith reference) shown instead of
  /// the meaning text.
  final String source;

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
    this.source = '',
  });

  String localizedName(String lang) {
    if (lang == 'ar') return nameAr;
    if (lang == 'tr') return nameTr;
    return nameEn;
  }

  String localizedMeaning(String lang) {
    if (lang == 'tr') return meaningTr;
    return meaningEn;
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
    String? source,
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
      source: source ?? this.source,
    );
  }
}
