import 'package:flutter_test/flutter_test.dart';
import 'package:sesli_tesbih/data/dua_data.dart';
import 'package:sesli_tesbih/data/dua_translations_extra.dart';
import 'package:sesli_tesbih/data/esma_data.dart';
import 'package:sesli_tesbih/data/esma_translations_extra.dart';

void main() {
  const extraLangs = ['id', 'ur', 'fr'];

  group('Content translations completeness', () {
    test('every dua has a translation in every extra language', () {
      for (final lang in extraLangs) {
        final table = kDuaTranslationsExtra[lang]!;
        for (final dua in kDuaList) {
          expect(table.containsKey(dua.titleEn), isTrue,
              reason: '$lang is missing dua "${dua.titleEn}"');
          final t = table[dua.titleEn]!;
          expect(t.title, isNotEmpty);
          expect(t.text, isNotEmpty);
          expect(t.info, isNotEmpty);
        }
      }
    });

    test('no orphan dua keys (typos in titleEn)', () {
      final titles = kDuaList.map((d) => d.titleEn).toSet();
      for (final lang in extraLangs) {
        for (final key in kDuaTranslationsExtra[lang]!.keys) {
          expect(titles.contains(key), isTrue,
              reason: '$lang has unknown dua key "$key"');
        }
      }
    });

    test('esma meanings: exactly 99 per language, none empty', () {
      expect(kEsmaList.length, 99);
      for (final lang in extraLangs) {
        final list = kEsmaMeaningsExtra[lang]!;
        expect(list.length, 99, reason: '$lang esma list length');
        for (final m in list) {
          expect(m.trim(), isNotEmpty);
        }
      }
    });

    test('localized dua accessors return the extra-language text', () {
      final fatiha = kDuaList.firstWhere((d) => d.titleEn == 'Al-Fatiha');
      expect(fatiha.localizedText('id'), contains('Dengan nama Allah'));
      expect(fatiha.localizedText('fr'), contains("Au nom d'Allah"));
      expect(fatiha.localizedText('ur'), contains('اللہ کے نام'));
      expect(fatiha.localizedText('ar'), isEmpty); // Arabic original shown
      expect(fatiha.localizedTitle('id'), 'Al-Fatihah');
    });
  });
}
