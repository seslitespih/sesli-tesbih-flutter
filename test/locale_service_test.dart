import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sesli_tesbih/services/extra_translations.dart';
import 'package:sesli_tesbih/services/locale_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  final svc = LocaleService.instance;

  group('LocaleService extra languages (id/ur/fr)', () {
    test('core languages still return inline strings', () async {
      await svc.setLanguage('tr');
      expect(svc.tr('Merhaba', 'Hello', 'مرحبا'), 'Merhaba');
      await svc.setLanguage('en');
      expect(svc.tr('Merhaba', 'Hello', 'مرحبا'), 'Hello');
      await svc.setLanguage('ar');
      expect(svc.tr('Merhaba', 'Hello', 'مرحبا'), 'مرحبا');
    });

    test('extra language translates via English key', () async {
      await svc.setLanguage('id');
      expect(svc.tr('Dinleniyor...', 'Listening...', '...'), 'Mendengarkan...');
      await svc.setLanguage('fr');
      expect(svc.tr('Kaydet', 'Save', 'حفظ'), 'Enregistrer');
      await svc.setLanguage('ur');
      expect(svc.tr('Kıble', 'Qibla', 'القبلة'), 'قبلہ');
    });

    test('missing key falls back to English', () async {
      await svc.setLanguage('id');
      expect(svc.tr('X', 'Untranslated string', 'Y'), 'Untranslated string');
    });

    test('numeric template: Remaining / Round strings', () async {
      await svc.setLanguage('id');
      expect(svc.tr('Kalan: 12', 'Remaining: 12', 'x'), 'Sisa: 12');
      expect(svc.tr('3. tur tamamlandı! 🎉', 'Round 3 completed! 🎉', 'x'),
          'Putaran 3 selesai! 🎉');
      await svc.setLanguage('fr');
      expect(svc.tr('Kalan: 7', 'Remaining: 7', 'x'), 'Restant : 7');
    });

    test('quoted template: delete dialog title', () async {
      await svc.setLanguage('fr');
      expect(svc.tr('Sil?', 'Delete "Subhanallah"?', 'x'),
          'Supprimer « Subhanallah » ?');
    });

    test('every language table has identical key sets', () {
      final idKeys = kExtraTranslations['id']!.keys.toSet();
      final urKeys = kExtraTranslations['ur']!.keys.toSet();
      final frKeys = kExtraTranslations['fr']!.keys.toSet();
      expect(urKeys, idKeys);
      expect(frKeys, idKeys);
    });
  });
}
