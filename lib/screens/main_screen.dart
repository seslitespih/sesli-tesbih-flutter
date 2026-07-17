import 'package:flutter/material.dart';
import '../main.dart';
import '../models/dhikr.dart';
import '../data/dhikr_data.dart';
import '../services/locale_service.dart';
import '../services/custom_dhikr_manager.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<Dhikr> _allDhikr = [];

  @override
  void initState() {
    super.initState();
    _loadDhikr();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadDhikr();
  }

  Future<void> _loadDhikr() async {
    final custom = await CustomDhikrManager.load();
    if (mounted) {
      setState(() {
        _allDhikr = [...kDhikrList, ...custom];
      });
    }
  }

  String get _lang => LocaleService.instance.language;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildLangBar(),
            _buildNavTabs(),
            Expanded(child: _buildGrid()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A1735), Color(0xFF16305F), Color(0xFF1E3A6E)],
        ),
      ),
      child: Row(
        children: [
          // İnce altın aksan çizgisi — sade ve şık
          Container(
            width: 3.5,
            height: 34,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.goldLight, AppColors.gold],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vocal Tasbeeh',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  _ls('Sesli İslami Zikir Sayacı', 'Islamic Voice Dhikr Counter',
                      'مسبحة صوتية إسلامية'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 11,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _showAddDhikrDialog,
            icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 26),
            tooltip: _ls('Özel Zikir Ekle', 'Add Custom Dhikr', 'إضافة ذكر مخصص'),
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/privacy'),
            icon: Icon(Icons.info_outline,
                color: Colors.white.withValues(alpha: 0.75), size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildLangBar() {
    return Container(
      color: const Color(0xFF14294F),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _LangButton(label: 'TR', lang: 'tr', current: _lang, onTap: _setLang),
          const SizedBox(width: 8),
          _LangButton(label: 'EN', lang: 'en', current: _lang, onTap: _setLang),
          const SizedBox(width: 8),
          _LangButton(label: 'AR', lang: 'ar', current: _lang, onTap: _setLang),
          const SizedBox(width: 8),
          _LangButton(label: 'ID', lang: 'id', current: _lang, onTap: _setLang),
          const SizedBox(width: 8),
          _LangButton(label: 'UR', lang: 'ur', current: _lang, onTap: _setLang),
          const SizedBox(width: 8),
          _LangButton(label: 'FR', lang: 'fr', current: _lang, onTap: _setLang),
        ],
      ),
    );
  }

  Widget _buildNavTabs() {
    return Container(
      color: const Color(0xFF14294F),
      padding: const EdgeInsets.only(bottom: 10, left: 12, right: 12),
      child: Row(
        children: [
          Expanded(
            child: _NavTab(
              label: _ls('Dualar', 'Prayers', 'الأدعية'),
              icon: Icons.menu_book_outlined,
              onTap: () => Navigator.pushNamed(context, '/dua'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _NavTab(
              label: _ls('Esmaül Hüsna', 'Asma ul-Husna', 'الأسماء الحسنى'),
              icon: Icons.auto_awesome_outlined,
              onTap: () => Navigator.pushNamed(context, '/esma'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _NavTab(
              label: _ls('Kıble', 'Qibla', 'القبلة'),
              icon: Icons.explore_outlined,
              onTap: () => Navigator.pushNamed(context, '/qibla'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    if (_allDhikr.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return GridView.builder(
      padding: const EdgeInsets.all(14),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.90,
      ),
      itemCount: _allDhikr.length,
      itemBuilder: (context, index) {
        final dhikr = _allDhikr[index];
        return _DhikrCard(
          dhikr: dhikr,
          lang: _lang,
          colorIndex: index % 5,
          isCustom: CustomDhikrManager.isCustom(dhikr.id),
          onTap: () {
            Navigator.pushNamed(context, '/counter', arguments: dhikr.id)
                .then((_) => _loadDhikr());
          },
          onDelete: () => _confirmDelete(dhikr),
        );
      },
    );
  }

  void _setLang(String lang) {
    LocaleService.instance.setLanguage(lang);
    setState(() {});
  }

  String _ls(String tr, String en, String ar) =>
      LocaleService.instance.tr(tr, en, ar);

  void _confirmDelete(Dhikr dhikr) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(_ls('Zikri Sil', 'Delete Dhikr', 'حذف الذكر')),
        content: Text(_ls(
          '"${dhikr.nameTr}" silinsin mi?',
          'Delete "${dhikr.nameTr}"?',
          'هل تريد حذف "${dhikr.nameTr}"؟',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_ls('İptal', 'Cancel', 'إلغاء')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await CustomDhikrManager.remove(dhikr.id);
              _loadDhikr();
            },
            child: Text(
              _ls('Sil', 'Delete', 'حذف'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDhikrDialog() {
    final nameCtrl = TextEditingController();
    final kwCtrl = TextEditingController();
    final countCtrl = TextEditingController(text: '100');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.add_circle, color: AppColors.greenMid, size: 22),
            const SizedBox(width: 8),
            Text(_ls('Özel Zikir Ekle', 'Add Custom Dhikr', 'إضافة ذكر مخصص')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogField(
              controller: nameCtrl,
              hint: _ls('Zikir adı', 'Dhikr name', 'اسم الذكر'),
              icon: Icons.edit_outlined,
            ),
            const SizedBox(height: 10),
            _buildDialogField(
              controller: kwCtrl,
              hint: _ls(
                'Anahtar kelime (virgülle ayır)',
                'Keyword (comma-separated)',
                'كلمة مفتاحية (مفصولة بفواصل)',
              ),
              icon: Icons.mic_outlined,
            ),
            const SizedBox(height: 10),
            _buildDialogField(
              controller: countCtrl,
              hint: _ls('Hedef sayı', 'Target count', 'العدد المستهدف'),
              icon: Icons.flag_outlined,
              isNumber: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_ls('İptal', 'Cancel', 'إلغاء')),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final kw = kwCtrl.text.trim();
              final target = int.tryParse(countCtrl.text) ?? 100;
              if (name.isEmpty || kw.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_ls(
                      'Tüm alanları doldurun',
                      'Please fill in all fields',
                      'يرجى ملء جميع الحقول',
                    )),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              await CustomDhikrManager.add(name, kw, target.clamp(1, 99999));
              _loadDhikr();
            },
            child: Text(_ls('Ekle', 'Add', 'إضافة')),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: AppColors.greenMid),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}

// ─── Card accent colors ───────────────────────────────────────────────────────

const _kAccentColors = [
  Color(0xFF16305F), // green
  Color(0xFF2C4A7C), // teal
  Color(0xFF16305F), // blue
  Color(0xFF8C6D1F), // purple
  Color(0xFF44608E), // brown
];

// ─── Language Button ──────────────────────────────────────────────────────────

class _LangButton extends StatelessWidget {
  final String label;
  final String lang;
  final String current;
  final ValueChanged<String> onTap;

  const _LangButton({
    required this.label,
    required this.lang,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = current == lang;
    return GestureDetector(
      onTap: () => onTap(lang),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        // 6 language chips must fit a 360 dp screen — keep padding tight
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFC9A227) : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFFC9A227) : Colors.white.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? const Color(0xFF10234C) : Colors.white,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ─── Nav Tab ──────────────────────────────────────────────────────────────────

class _NavTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _NavTab({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 17),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Dhikr Card ───────────────────────────────────────────────────────────────

class _DhikrCard extends StatelessWidget {
  final Dhikr dhikr;
  final String lang;
  final int colorIndex;
  final bool isCustom;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DhikrCard({
    required this.dhikr,
    required this.lang,
    required this.colorIndex,
    required this.isCustom,
    required this.onTap,
    required this.onDelete,
  });

  Color get _accent => _kAccentColors[colorIndex];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: isCustom ? onDelete : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _accent.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Coloured top strip with Arabic text
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(
                  top: BorderSide(color: _accent, width: 3),
                ),
              ),
              child: Text(
                dhikr.arabicText.isNotEmpty
                    ? (dhikr.arabicText.length > 22
                        ? '${dhikr.arabicText.substring(0, 22)}…'
                        : dhikr.arabicText)
                    : dhikr.localizedName(lang),
                style: TextStyle(
                  fontSize: 15,
                  color: _accent,
                  fontWeight: FontWeight.w600,
                  height: 1.6,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Name + target
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dhikr.localizedName(lang),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: _accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${dhikr.targetCount}×',
                            style: TextStyle(
                              color: _accent,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isCustom) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.person,
                              size: 13, color: AppColors.textSecondary),
                        ],
                      ],
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
