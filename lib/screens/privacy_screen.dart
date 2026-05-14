import 'package:flutter/material.dart';
import '../main.dart';
import '../services/locale_service.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  String _ls(String lang, String tr, String en, String ar) {
    if (lang == 'en') return en;
    if (lang == 'ar') return ar;
    return tr;
  }

  @override
  Widget build(BuildContext context) {
    final lang = LocaleService.instance.language;
    final title = _ls(lang, 'Gizlilik Politikası', 'Privacy Policy', 'سياسة الخصوصية');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context, title),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.greenDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      _ls(lang, 'Veri Toplama', 'Data Collection', 'جمع البيانات'),
                      _ls(
                        lang,
                        'Bu uygulama kişisel veri toplamaz, sunucuya göndermez veya üçüncü taraflarla paylaşmaz.',
                        'This app does not collect, send to a server, or share any personal data with third parties.',
                        'لا يجمع هذا التطبيق أي بيانات شخصية ولا يرسلها إلى خادم أو يشاركها مع أطراف ثالثة.',
                      ),
                    ),
                    _buildSection(
                      _ls(lang, 'Mikrofon İzni', 'Microphone Permission', 'إذن الميكروفون'),
                      _ls(
                        lang,
                        'Sesli zikir sayma özelliği için mikrofon izni gereklidir. Ses verisi yalnızca cihazınızda işlenir ve kesinlikle kayıt edilmez veya saklanmaz.',
                        'Microphone permission is required for the voice dhikr counting feature. Audio data is processed only on your device and is never recorded or stored.',
                        'إذن الميكروفون مطلوب لميزة عد الذكر الصوتي. تتم معالجة بيانات الصوت على جهازك فقط ولا يتم تسجيلها أو تخزينها مطلقاً.',
                      ),
                    ),
                    _buildSection(
                      _ls(lang, 'Konum İzni', 'Location Permission', 'إذن الموقع'),
                      _ls(
                        lang,
                        'Namaz vakitleri ve kıble yönü hesaplamak için konum izni kullanılır. Konum verisi sunucuya gönderilmez, yalnızca anlık hesaplama için kullanılır.',
                        'Location permission is used to calculate prayer times and qibla direction. Location data is not sent to any server; it is used only for on-device calculations.',
                        'يُستخدم إذن الموقع لحساب أوقات الصلاة واتجاه القبلة. لا يُرسل الموقع إلى أي خادم؛ يُستخدم فقط للحسابات على الجهاز.',
                      ),
                    ),
                    _buildSection(
                      _ls(lang, 'Yerel Depolama', 'Local Storage', 'التخزين المحلي'),
                      _ls(
                        lang,
                        'Zikir sayıları ve uygulama ayarları yalnızca cihazınızda (SharedPreferences) saklanır.',
                        'Dhikr counts and app settings are stored only on your device (SharedPreferences).',
                        'يتم تخزين أعداد الذكر وإعدادات التطبيق على جهازك فقط (SharedPreferences).',
                      ),
                    ),
                    _buildSection(
                      _ls(lang, 'Reklam & Analiz', 'Ads & Analytics', 'الإعلانات والتحليلات'),
                      _ls(
                        lang,
                        'Uygulama hiçbir reklam SDK\'sı veya analiz aracı içermez.',
                        'The app contains no ad SDK or analytics tools.',
                        'لا يحتوي التطبيق على أي SDK للإعلانات أو أدوات تحليل.',
                      ),
                    ),
                    _buildSection(
                      _ls(lang, 'İletişim', 'Contact', 'التواصل'),
                      _ls(
                        lang,
                        'Gizlilik politikasıyla ilgili sorularınız için: ssaglamess@gmail.com',
                        'For questions about our privacy policy: ssaglamess@gmail.com',
                        'لأي استفسارات حول سياسة الخصوصية: ssaglamess@gmail.com',
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Vocal Tasbeeh © 2025',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, String title) {
    return Container(
      color: AppColors.greenDark,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.greenDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
