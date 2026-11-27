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

  // Real iOS recogniser output (iOS 26 simulator, synthetic Turkish speech):
  // some reps come back as just "allah" — the "subhan" is lost — so counting
  // only full "subhanallah" under-counted by ~2 of 10.
  group('Sübhanallah — reps the recogniser shortened to "allah"', () {
    test('real transcript tail: 3 full + 3 "allah" + 1 full = 7 reps', () {
      expect(
        countDhikrOccurrences(
            'subhanallah subhanallah subhanallah allah allah allah suphanallah',
            kw(1)),
        7,
      );
    });

    test('run-together form, as the screen sees it after normalising', () {
      expect(
          countDhikrOccurrences(
              'subhanallahsubhanallahallahallahallahsuphanallah', kw(1)),
          6);
    });

    test('a full "subhanallah" is still exactly one rep, not two', () {
      expect(countDhikrOccurrences('subhanallah', kw(1)), 1);
      expect(countDhikrOccurrences('subhanallah subhanallah', kw(1)), 2);
    });

    test('Elhamdülillah / Bismillah never look like Sübhanallah reps', () {
      expect(countDhikrOccurrences('elhamdülillah elhamdülillah', kw(1)), 0);
      expect(countDhikrOccurrences('bismillahirrahmanirrahim', kw(1)), 0);
    });

    test('ordinary talk still counts 0', () {
      expect(
          countDhikrOccurrences(
              'merhaba bugün hava çok güzel yarın akşam toplantıya gelecek misin',
              kw(1)),
          0);
    });
  });
}
