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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.greenDark,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Vocal Tasbeeh',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: _showAddDhikrDialog,
                icon: const Icon(Icons.add, color: Colors.white),
                tooltip: _ls('Özel Zikir Ekle', 'Add Custom Dhikr', 'إضافة ذكر مخصص'),
              ),
              IconButton(
                onPressed: () => Navigator.pushNamed(context, '/privacy'),
                icon: const Icon(Icons.info_outline, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLangBar() {
    return Container(
      color: AppColors.greenMid,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _LangButton(label: 'TR', lang: 'tr', current: _lang, onTap: _setLang),
          const SizedBox(width: 8),
          _LangButton(label: 'EN', lang: 'en', current: _lang, onTap: _setLang),
          const SizedBox(width: 8),
          _LangButton(label: 'AR', lang: 'ar', current: _lang, onTap: _setLang),
        ],
      ),
    );
  }

  Widget _buildNavTabs() {
    return Container(
      color: AppColors.greenMid,
      padding: const EdgeInsets.only(bottom: 6, left: 8, right: 8),
      child: Row(
        children: [
          Expanded(
            child: _NavTab(
              label: _lang == 'en' ? 'Prayers' : (_lang == 'ar' ? 'الأدعية' : 'Dualar'),
              icon: Icons.menu_book_outlined,
              onTap: () => Navigator.pushNamed(context, '/dua'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _NavTab(
              label: _lang == 'en' ? 'Prayer Times' : (_lang == 'ar' ? 'أوقات الصلاة' : 'Namaz'),
              icon: Icons.access_time,
              onTap: () => Navigator.pushNamed(context, '/prayer'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _NavTab(
              label: _lang == 'en' ? 'Qibla' : (_lang == 'ar' ? 'القبلة' : 'Kıble'),
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
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.95,
      ),
      itemCount: _allDhikr.length,
      itemBuilder: (context, index) {
        final dhikr = _allDhikr[index];
        return _DhikrCard(
          dhikr: dhikr,
          lang: _lang,
          isCustom: CustomDhikrManager.isCustom(dhikr.id),
          onTap: () {
            Navigator.pushNamed(
              context,
              '/counter',
              arguments: dhikr.id,
            ).then((_) => _loadDhikr());
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

  String _ls(String tr, String en, String ar) {
    if (_lang == 'en') return en;
    if (_lang == 'ar') return ar;
    return tr;
  }

  void _confirmDelete(Dhikr dhikr) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
            child: Text(_ls('Sil', 'Delete', 'حذف'), style: const TextStyle(color: Colors.red)),
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
        title: Text(_ls('Özel Zikir Ekle', 'Add Custom Dhikr', 'إضافة ذكر مخصص')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                hintText: _ls('Zikir adı', 'Dhikr name', 'اسم الذكر'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: kwCtrl,
              decoration: InputDecoration(
                hintText: _ls(
                  'Anahtar kelime (sesle söylenecek)',
                  'Keyword (spoken aloud)',
                  'كلمة مفتاحية (تُقال بصوت)',
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: countCtrl,
              decoration: InputDecoration(
                hintText: _ls('Hedef sayı', 'Target count', 'العدد المستهدف'),
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
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
}

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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? AppColors.greenDark : Colors.white24,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.greenDark : Colors.white54,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white70,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

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
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DhikrCard extends StatelessWidget {
  final Dhikr dhikr;
  final String lang;
  final bool isCustom;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DhikrCard({
    required this.dhikr,
    required this.lang,
    required this.isCustom,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: isCustom ? onDelete : null,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (dhikr.arabicText.isNotEmpty)
                Text(
                  dhikr.arabicText.length > 20
                      ? dhikr.arabicText.substring(0, 20)
                      : dhikr.arabicText,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.greenDark,
                    fontWeight: FontWeight.w500,
                  ),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              if (dhikr.arabicText.isNotEmpty) const SizedBox(height: 6),
              Text(
                dhikr.localizedName(lang),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.greenLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${dhikr.targetCount}×',
                  style: const TextStyle(
                    color: AppColors.greenDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isCustom)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Icon(Icons.person, size: 14, color: AppColors.textSecondary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
