import 'package:flutter/material.dart';
import '../main.dart';
import '../data/esma_data.dart';
import '../services/locale_service.dart';

/// Esmaül Hüsna — Allah'ın 99 güzel ismi listesi.
class EsmaScreen extends StatelessWidget {
  const EsmaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = LocaleService.instance.language;
    final title = LocaleService.instance
        .tr('Esmaül Hüsna', 'Asma ul-Husna', 'الأسماء الحسنى');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context, title),
            _buildSourceBanner(lang),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
                itemCount: kEsmaList.length,
                itemBuilder: (context, index) =>
                    _EsmaCard(esma: kEsmaList[index], lang: lang),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, String title) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A1735), Color(0xFF16305F), Color(0xFF1E3A6E)],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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

  Widget _buildSourceBanner(String lang) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.menu_book_outlined,
              size: 14, color: Colors.orange.shade700),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              lang == 'tr' ? kEsmaSourceTr : kEsmaSourceEn,
              style: TextStyle(
                fontSize: 11,
                color: Colors.orange.shade800,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EsmaCard extends StatelessWidget {
  final EsmaName esma;
  final String lang;
  const _EsmaCard({required this.esma, required this.lang});

  static const _accents = [
    Color(0xFF16305F),
    Color(0xFF2C4A7C),
    Color(0xFF8C6D1F),
    Color(0xFF16305F),
    Color(0xFF44608E),
  ];

  Color get _accent => _accents[(esma.number - 1) % _accents.length];

  @override
  Widget build(BuildContext context) {
    final meaning = lang == 'tr' ? esma.meaningTr : esma.meaningEn;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/counter',
          arguments: 2000 + esma.number),
      child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: _accent, width: 4)),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${esma.number}',
                style: TextStyle(
                  color: _accent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  esma.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  meaning,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            esma.arabic,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontSize: 18,
              color: _accent,
              fontWeight: FontWeight.w600,
              height: 1.6,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.mic_none_rounded,
              size: 16, color: _accent.withValues(alpha: 0.55)),
        ],
      ),
      ),
    );
  }
}
