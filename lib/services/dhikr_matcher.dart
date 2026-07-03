/// Pure-Dart keyword matching for "Engine A" (speech-to-text results).
/// Extracted so it can be unit-tested (see test/dhikr_matcher_test.dart).
library;

/// Normalise a string: collapse Turkic/Arabic diacritics → ASCII letters
/// only (spaces and punctuation are removed too, so fragments match across
/// word boundaries: "sub sub sub" → "subsubsub").
String normalizeDhikrText(String s) {
  return s
      .toLowerCase()
      .replaceAll('â', 'a').replaceAll('î', 'i').replaceAll('û', 'u')
      .replaceAll('ê', 'e').replaceAll('ā', 'a').replaceAll('ī', 'i')
      .replaceAll('ū', 'u').replaceAll('ğ', 'g').replaceAll('ı', 'i')
      .replaceAll('ü', 'u').replaceAll('ö', 'o').replaceAll('ş', 's')
      .replaceAll('ç', 'c')
      .replaceAllMapped(RegExp(r'[^a-z]'), (_) => '');
}

/// Count occurrences: try all keywords, return the maximum found.
int countDhikrOccurrences(String rawText, List<String> keywords) {
  final text = normalizeDhikrText(rawText);
  int maxCount = 0;
  for (final keyword in keywords) {
    final kw = normalizeDhikrText(keyword);
    if (kw.isEmpty) continue;
    var n = 0, pos = 0;
    while (true) {
      final found = text.indexOf(kw, pos);
      if (found == -1) break;
      n++;
      pos = found + kw.length;
    }
    if (n > maxCount) maxCount = n;
  }
  return maxCount;
}
