/// Translations for the "extra" languages (Indonesian, Urdu, French).
///
/// Keyed by the exact English string used in the inline
/// `tr(trStr, enStr, arStr)` calls. Dynamic strings use `#` as a
/// placeholder — [LocaleService.tr] substitutes the runtime value back
/// (digits, or a quoted name) when an exact lookup misses.
/// Missing keys fall back to English.
library;

const Map<String, Map<String, String>> kExtraTranslations = {
  'id': {
    'Starting...': 'Memulai...',
    'Speech recognition not available': 'Pengenalan suara tidak tersedia',
    'Listening...': 'Mendengarkan...',
    'Round # completed! 🎉': 'Putaran # selesai! 🎉',
    'Paused': 'Dijeda',
    'Change Target': 'Ubah Target',
    'Cancel': 'Batal',
    'Save': 'Simpan',
    '✓ Target reached!': '✓ Target tercapai!',
    'Remaining: #': 'Sisa: #',
    'Tap': 'Ketuk',
    'Pause': 'Jeda',
    'Start': 'Mulai',
    'Reset': 'Atur Ulang',
    'Target': 'Target',
    'Prayers & Verses': 'Doa & Ayat',
    'Asma ul-Husna': 'Asmaul Husna',
    'Islamic Voice Dhikr Counter': 'Penghitung Dzikir Suara Islami',
    'Add Custom Dhikr': 'Tambah Dzikir Kustom',
    'Prayers': 'Doa',
    'Qibla': 'Kiblat',
    'Delete Dhikr': 'Hapus Dzikir',
    'Delete "#"?': 'Hapus "#"?',
    'Delete': 'Hapus',
    'Dhikr name': 'Nama dzikir',
    'Keyword (comma-separated)': 'Kata kunci (pisahkan dengan koma)',
    'Target count': 'Jumlah target',
    'Please fill in all fields': 'Harap isi semua kolom',
    'Add': 'Tambah',
    'Privacy Policy': 'Kebijakan Privasi',
    'Data Collection': 'Pengumpulan Data',
    'This app does not collect, send to a server, or share any personal data with third parties.':
        'Aplikasi ini tidak mengumpulkan, mengirim ke server, atau membagikan data pribadi apa pun kepada pihak ketiga.',
    'Microphone Permission': 'Izin Mikrofon',
    'Microphone permission is required for the voice dhikr counting feature. Audio data is processed only on your device and is never recorded or stored.':
        'Izin mikrofon diperlukan untuk fitur penghitungan dzikir dengan suara. Data audio hanya diproses di perangkatmu dan tidak pernah direkam atau disimpan.',
    'Location Permission': 'Izin Lokasi',
    'Location permission is used to calculate prayer times and qibla direction. Location data is not sent to any server; it is used only for on-device calculations.':
        'Izin lokasi digunakan untuk menghitung waktu shalat dan arah kiblat. Data lokasi tidak dikirim ke server mana pun; hanya digunakan untuk perhitungan di perangkat.',
    'Local Storage': 'Penyimpanan Lokal',
    'Dhikr counts and app settings are stored only on your device (SharedPreferences).':
        'Jumlah dzikir dan pengaturan aplikasi hanya disimpan di perangkatmu (SharedPreferences).',
    'Ads & Analytics': 'Iklan & Analitik',
    'The app contains no ad SDK or analytics tools.':
        'Aplikasi ini tidak berisi SDK iklan atau alat analitik.',
    'Contact': 'Kontak',
    'For questions about our privacy policy: ssaglamess@gmail.com':
        'Untuk pertanyaan tentang kebijakan privasi: ssaglamess@gmail.com',
    'Getting location...': 'Mengambil lokasi...',
    'Qibla Direction': 'Arah Kiblat',
    'Qibla calculated based on your GPS location.':
        'Kiblat dihitung berdasarkan lokasi GPS-mu.',
  },
  'ur': {
    'Starting...': 'شروع ہو رہا ہے...',
    'Speech recognition not available': 'آواز کی شناخت دستیاب نہیں',
    'Listening...': 'سن رہا ہے...',
    'Round # completed! 🎉': 'دور # مکمل ہوا! 🎉',
    'Paused': 'موقوف',
    'Change Target': 'ہدف تبدیل کریں',
    'Cancel': 'منسوخ',
    'Save': 'محفوظ کریں',
    '✓ Target reached!': '✓ ہدف مکمل!',
    'Remaining: #': 'باقی: #',
    'Tap': 'دبائیں',
    'Pause': 'روکیں',
    'Start': 'شروع کریں',
    'Reset': 'ری سیٹ',
    'Target': 'ہدف',
    'Prayers & Verses': 'دعائیں اور آیات',
    'Asma ul-Husna': 'اسمائے حسنیٰ',
    'Islamic Voice Dhikr Counter': 'اسلامی صوتی ذکر کاؤنٹر',
    'Add Custom Dhikr': 'اپنا ذکر شامل کریں',
    'Prayers': 'دعائیں',
    'Qibla': 'قبلہ',
    'Delete Dhikr': 'ذکر حذف کریں',
    'Delete "#"?': '"#" حذف کریں؟',
    'Delete': 'حذف کریں',
    'Dhikr name': 'ذکر کا نام',
    'Keyword (comma-separated)': 'الفاظ (کوما سے الگ کریں)',
    'Target count': 'ہدف کی تعداد',
    'Please fill in all fields': 'براہ کرم تمام خانے بھریں',
    'Add': 'شامل کریں',
    'Privacy Policy': 'پرائیویسی پالیسی',
    'Data Collection': 'ڈیٹا اکٹھا کرنا',
    'This app does not collect, send to a server, or share any personal data with third parties.':
        'یہ ایپ کوئی ذاتی ڈیٹا اکٹھا نہیں کرتی، کسی سرور کو نہیں بھیجتی اور نہ کسی تیسرے فریق سے شیئر کرتی ہے۔',
    'Microphone Permission': 'مائیکروفون کی اجازت',
    'Microphone permission is required for the voice dhikr counting feature. Audio data is processed only on your device and is never recorded or stored.':
        'آواز سے ذکر گننے کے لیے مائیکروفون کی اجازت ضروری ہے۔ آواز کا ڈیٹا صرف آپ کے فون پر پراسیس ہوتا ہے، کبھی ریکارڈ یا محفوظ نہیں ہوتا۔',
    'Location Permission': 'لوکیشن کی اجازت',
    'Location permission is used to calculate prayer times and qibla direction. Location data is not sent to any server; it is used only for on-device calculations.':
        'لوکیشن کی اجازت نماز کے اوقات اور قبلے کی سمت معلوم کرنے کے لیے استعمال ہوتی ہے۔ لوکیشن ڈیٹا کسی سرور کو نہیں بھیجا جاتا؛ صرف فون پر حساب کے لیے استعمال ہوتا ہے۔',
    'Local Storage': 'مقامی اسٹوریج',
    'Dhikr counts and app settings are stored only on your device (SharedPreferences).':
        'ذکر کی گنتی اور ایپ کی ترتیبات صرف آپ کے فون پر محفوظ ہوتی ہیں (SharedPreferences)۔',
    'Ads & Analytics': 'اشتہارات اور تجزیات',
    'The app contains no ad SDK or analytics tools.':
        'ایپ میں کوئی اشتہاری SDK یا تجزیاتی ٹول نہیں ہے۔',
    'Contact': 'رابطہ',
    'For questions about our privacy policy: ssaglamess@gmail.com':
        'پرائیویسی پالیسی سے متعلق سوالات کے لیے: ssaglamess@gmail.com',
    'Getting location...': 'لوکیشن حاصل کی جا رہی ہے...',
    'Qibla Direction': 'سمتِ قبلہ',
    'Qibla calculated based on your GPS location.':
        'قبلہ آپ کی GPS لوکیشن کی بنیاد پر معلوم کیا گیا ہے۔',
  },
  'fr': {
    'Starting...': 'Démarrage...',
    'Speech recognition not available': 'Reconnaissance vocale indisponible',
    'Listening...': 'Écoute...',
    'Round # completed! 🎉': 'Tour # terminé ! 🎉',
    'Paused': 'En pause',
    'Change Target': "Modifier l'objectif",
    'Cancel': 'Annuler',
    'Save': 'Enregistrer',
    '✓ Target reached!': '✓ Objectif atteint !',
    'Remaining: #': 'Restant : #',
    'Tap': 'Toucher',
    'Pause': 'Pause',
    'Start': 'Démarrer',
    'Reset': 'Réinitialiser',
    'Target': 'Objectif',
    'Prayers & Verses': 'Douas & Versets',
    'Asma ul-Husna': 'Asma ul-Husna',
    'Islamic Voice Dhikr Counter': 'Compteur de dhikr vocal islamique',
    'Add Custom Dhikr': 'Ajouter un dhikr personnalisé',
    'Prayers': 'Douas',
    'Qibla': 'Qibla',
    'Delete Dhikr': 'Supprimer le dhikr',
    'Delete "#"?': 'Supprimer « # » ?',
    'Delete': 'Supprimer',
    'Dhikr name': 'Nom du dhikr',
    'Keyword (comma-separated)': 'Mots-clés (séparés par des virgules)',
    'Target count': 'Nombre cible',
    'Please fill in all fields': 'Veuillez remplir tous les champs',
    'Add': 'Ajouter',
    'Privacy Policy': 'Politique de confidentialité',
    'Data Collection': 'Collecte de données',
    'This app does not collect, send to a server, or share any personal data with third parties.':
        "Cette application ne collecte, n'envoie à aucun serveur et ne partage aucune donnée personnelle avec des tiers.",
    'Microphone Permission': 'Autorisation micro',
    'Microphone permission is required for the voice dhikr counting feature. Audio data is processed only on your device and is never recorded or stored.':
        "L'autorisation du micro est requise pour le comptage vocal du dhikr. L'audio est traité uniquement sur votre appareil et n'est jamais enregistré ni stocké.",
    'Location Permission': 'Autorisation de localisation',
    'Location permission is used to calculate prayer times and qibla direction. Location data is not sent to any server; it is used only for on-device calculations.':
        "La localisation sert à calculer les horaires de prière et la direction de la qibla. Elle n'est envoyée à aucun serveur et n'est utilisée que sur l'appareil.",
    'Local Storage': 'Stockage local',
    'Dhikr counts and app settings are stored only on your device (SharedPreferences).':
        'Les comptes de dhikr et les réglages sont stockés uniquement sur votre appareil (SharedPreferences).',
    'Ads & Analytics': 'Publicité & Analyse',
    'The app contains no ad SDK or analytics tools.':
        "L'application ne contient aucun SDK publicitaire ni outil d'analyse.",
    'Contact': 'Contact',
    'For questions about our privacy policy: ssaglamess@gmail.com':
        'Pour toute question sur la confidentialité : ssaglamess@gmail.com',
    'Getting location...': 'Localisation en cours...',
    'Qibla Direction': 'Direction de la Qibla',
    'Qibla calculated based on your GPS location.':
        "Qibla calculée d'après votre position GPS.",
  },
};
