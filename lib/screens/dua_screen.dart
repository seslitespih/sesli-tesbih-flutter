import 'package:flutter/material.dart';
import '../main.dart';
import '../data/dua_data.dart';
import '../models/dua.dart';
import '../services/locale_service.dart';

class DuaScreen extends StatelessWidget {
  const DuaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = LocaleService.instance.language;
    final title = lang == 'en'
        ? 'Prayers & Verses'
        : (lang == 'ar' ? 'الأدعية والآيات' : 'Dualar ve Ayetler');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context, title),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: kDuaList.length,
                itemBuilder: (context, index) =>
                    _DuaCard(dua: kDuaList[index], lang: lang, index: index),
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
          colors: [Color(0xFF1A5C1E), Color(0xFF2E7D32), Color(0xFF43A047)],
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
}

// ─── Category accent colors ───────────────────────────────────────────────────

const _kDuaAccents = [
  Color(0xFF2E7D32),
  Color(0xFF00838F),
  Color(0xFF6A1B9A),
  Color(0xFF1565C0),
  Color(0xFF4E342E),
];

class _DuaCard extends StatefulWidget {
  final Dua dua;
  final String lang;
  final int index;
  const _DuaCard({required this.dua, required this.lang, required this.index});

  @override
  State<_DuaCard> createState() => _DuaCardState();
}

class _DuaCardState extends State<_DuaCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _expandCtrl;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _expandCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _expandAnim = CurvedAnimation(
      parent: _expandCtrl,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _expandCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _expandCtrl.forward();
    } else {
      _expandCtrl.reverse();
    }
  }

  Color get _accent => _kDuaAccents[widget.index % _kDuaAccents.length];

  @override
  Widget build(BuildContext context) {
    final title = widget.dua.localizedTitle(widget.lang);
    final translationText = widget.dua.localizedText(widget.lang);
    final infoText = widget.dua.localizedInfo(widget.lang);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            // Header row
            InkWell(
              onTap: _toggle,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: _accent, width: 4),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                child: Row(
                  children: [
                    // Number badge
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${widget.index + 1}',
                          style: TextStyle(
                            color: _accent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 280),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _accent,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Expandable content
            SizeTransition(
              sizeFactor: _expandAnim,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: _accent, width: 4),
                    top: BorderSide(
                        color: _accent.withValues(alpha: 0.15), width: 1),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Arabic text
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _accent.withValues(alpha: 0.06),
                            _accent.withValues(alpha: 0.02),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _accent.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        widget.dua.arabicText,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontSize: 16,
                          color: _accent,
                          height: 2.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    // Transliteration
                    if (widget.dua.transliteration.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        widget.dua.transliteration,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                          height: 1.7,
                        ),
                      ),
                    ],
                    // Translation
                    if (translationText.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        translationText,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          height: 1.65,
                        ),
                      ),
                    ],
                    // Info box
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 14, color: Colors.orange.shade700),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              infoText,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade800,
                                fontStyle: FontStyle.italic,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
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
}
