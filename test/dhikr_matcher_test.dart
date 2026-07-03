import 'package:flutter_test/flutter_test.dart';
import 'package:sesli_tesbih/services/dhikr_matcher.dart';
import 'package:sesli_tesbih/data/dhikr_data.dart';

void main() {
  List<String> kw(int id) =>
      kDhikrList.firstWhere((d) => d.id == id).keywords;

  group('normalizeDhikrText', () {
    test('collapses Turkish diacritics and strips non-letters', () {
      expect(normalizeDhikrText('Sübhânallah!'), 'subhanallah');
      expect(normalizeDhikrText('sub sub sub'), 'subsubsub');
      expect(normalizeDhikrText('ALLAH, Allah. allah'), 'allahallahallah');
    });
  });

  group('countDhikrOccurrences — fast/partial speech cases', () {
    test('"allah allah allah" counts 3 (Allah dhikr)', () {
      expect(countDhikrOccurrences('allah allah allah', kw(7)), 3);
    });

    test('run-together "allahallahallah" still counts 3', () {
      expect(countDhikrOccurrences('allahallahallah', kw(7)), 3);
    });

    test('"sub sub sub" counts 3 via fragment keyword (Sübhanallah)', () {
      expect(countDhikrOccurrences('sub sub sub', kw(1)), 3);
    });

    test('mixed STT transcriptions of Sübhanallah count together', () {
      expect(
        countDhikrOccurrences(
            'sübhanallah suphanallah süphanallah', kw(1)),
        3,
      );
    });

    test('single "sübhanallah" counts exactly 1 (no double count)', () {
      expect(countDhikrOccurrences('sübhanallah', kw(1)), 1);
    });

    test('"elhamdülillah elhamdülillah" counts 2', () {
      expect(
          countDhikrOccurrences('elhamdülillah elhamdülillah', kw(2)), 2);
    });

    test('unrelated speech counts 0', () {
      expect(countDhikrOccurrences('bugün hava çok güzel', kw(1)), 0);
      expect(countDhikrOccurrences('merhaba nasılsın', kw(7)), 0);
    });
  });
}
