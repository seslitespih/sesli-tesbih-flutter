import 'package:flutter/material.dart';
import '../main.dart';
import '../services/locale_service.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = LocaleService.instance.language;
    final title =
        lang == 'en' ? 'Privacy Policy' : (lang == 'ar' ? 'سياسة الخصوصية' : 'Gizlilik Politikası');

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
                      'Veri Toplama',
                      'Bu uygulama kişisel veri toplamaz, sunucuya göndermez veya üçüncü taraflarla paylaşmaz.',
                    ),
                    _buildSection(
                      'Mikrofon İzni',
                      'Sesli zikir sayma özelliği için mikrofon izni gereklidir. Ses verisi yalnızca cihazınızda işlenir ve kesinlikle kayıt edilmez veya saklanmaz.',
                    ),
                    _buildSection(
                      'Konum İzni',
                      'Namaz vakitleri ve kıble yönü hesaplamak için konum izni kullanılır. Konum verisi sunucuya gönderilmez, yalnızca anlık hesaplama için kullanılır.',
                    ),
                    _buildSection(
                      'Yerel Depolama',
                      'Zikir sayıları ve uygulama ayarları yalnızca cihazınızda (SharedPreferences) saklanır.',
                    ),
                    _buildSection(
                      'Reklam & Analiz',
                      'Uygulama hiçbir reklam SDK\'sı veya analiz aracı içermez.',
                    ),
                    _buildSection(
                      'İletişim',
                      'Gizlilik politikasıyla ilgili sorularınız için: ssaglamess@gmail.com',
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Sesli Tesbih © 2025',
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
