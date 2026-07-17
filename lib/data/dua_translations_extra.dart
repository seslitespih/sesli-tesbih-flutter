/// Dua translations for the extra app languages (id / ur / fr).
/// Keyed by the exact `titleEn` of each dua in dua_data.dart.
/// Missing entries fall back to the English text.
library;

class DuaTr {
  final String title;
  final String text;
  final String info;
  const DuaTr(this.title, this.text, this.info);
}

const Map<String, Map<String, DuaTr>> kDuaTranslationsExtra = {
  'id': {
    "Verse on Dhikr — Ar-Ra'd 28": DuaTr(
      'Ayat tentang Dzikir — Ar-Ra\'d 28',
      'Orang-orang yang beriman dan hati mereka menjadi tenteram dengan mengingat Allah. Ingatlah, hanya dengan mengingat Allah hati menjadi tenteram.',
      'Sumber: Surah Ar-Ra\'d, ayat 28.',
    ),
    'Verse on Dhikr — Al-Baqarah 152': DuaTr(
      'Ayat tentang Dzikir — Al-Baqarah 152',
      'Maka ingatlah kepada-Ku, Aku pun akan ingat kepadamu. Bersyukurlah kepada-Ku dan janganlah kamu ingkar kepada-Ku.',
      'Sumber: Surah Al-Baqarah, ayat 152.',
    ),
    'Verse on Dhikr — Al-Ahzab 41-42': DuaTr(
      'Ayat tentang Dzikir — Al-Ahzab 41-42',
      'Wahai orang-orang yang beriman, ingatlah kepada Allah dengan dzikir yang sebanyak-banyaknya, dan bertasbihlah kepada-Nya pada waktu pagi dan petang.',
      'Sumber: Surah Al-Ahzab, ayat 41-42.',
    ),
    "Verse on Dhikr — Al-A'raf 205": DuaTr(
      'Ayat tentang Dzikir — Al-A\'raf 205',
      'Dan ingatlah Tuhanmu dalam hatimu dengan rendah hati dan rasa takut, tanpa mengeraskan suara, pada waktu pagi dan petang; dan janganlah kamu termasuk orang-orang yang lalai.',
      'Sumber: Surah Al-A\'raf, ayat 205.',
    ),
    'Verse on Dhikr — Al-Ankabut 45': DuaTr(
      'Ayat tentang Dzikir — Al-Ankabut 45',
      'Dan sungguh, mengingat Allah itu lebih besar (keutamaannya). Dan Allah mengetahui apa yang kamu kerjakan.',
      'Sumber: Surah Al-Ankabut, ayat 45.',
    ),
    'Ayat al-Kursi': DuaTr(
      'Ayat Kursi',
      'Allah — tidak ada tuhan selain Dia, Yang Maha Hidup, Yang terus-menerus mengurus makhluk-Nya. Dia tidak mengantuk dan tidak tidur. Milik-Nya apa yang ada di langit dan apa yang ada di bumi. Siapakah yang dapat memberi syafaat di sisi-Nya tanpa izin-Nya? Dia mengetahui apa yang di hadapan mereka dan apa yang di belakang mereka, dan mereka tidak mengetahui sesuatu pun dari ilmu-Nya kecuali apa yang Dia kehendaki. Kursi-Nya meliputi langit dan bumi, dan Dia tidak merasa berat memelihara keduanya. Dan Dia Maha Tinggi lagi Maha Besar.',
      'Sumber: Surah Al-Baqarah, ayat 255.',
    ),
    'Al-Fatiha': DuaTr(
      'Al-Fatihah',
      'Dengan nama Allah Yang Maha Pengasih lagi Maha Penyayang. Segala puji bagi Allah, Tuhan seluruh alam — Yang Maha Pengasih, Maha Penyayang — Pemilik hari pembalasan. Hanya kepada Engkaulah kami menyembah dan hanya kepada Engkaulah kami memohon pertolongan. Tunjukilah kami jalan yang lurus: jalan orang-orang yang telah Engkau beri nikmat, bukan jalan mereka yang dimurkai dan bukan pula jalan mereka yang sesat.',
      'Sumber: Al-Qur\'an, Surah 1 (Al-Fatihah).',
    ),
    'Al-Ikhlas': DuaTr(
      'Al-Ikhlas',
      'Katakanlah: Dialah Allah, Yang Maha Esa. Allah tempat meminta segala sesuatu. Dia tidak beranak dan tidak pula diperanakkan. Dan tidak ada sesuatu pun yang setara dengan Dia.',
      'Sumber: Al-Qur\'an, Surah 112 (Al-Ikhlas).',
    ),
    'Al-Falaq': DuaTr(
      'Al-Falaq',
      'Katakanlah: Aku berlindung kepada Tuhan yang menguasai subuh — dari kejahatan makhluk yang Dia ciptakan, dari kejahatan malam apabila telah gelap gulita, dari kejahatan perempuan-perempuan penyihir yang meniup pada buhul-buhul, dan dari kejahatan orang yang dengki apabila ia dengki.',
      'Sumber: Al-Qur\'an, Surah 113 (Al-Falaq).',
    ),
    'An-Nas': DuaTr(
      'An-Nas',
      'Katakanlah: Aku berlindung kepada Tuhan manusia, Raja manusia, Sembahan manusia — dari kejahatan bisikan setan yang bersembunyi, yang membisikkan ke dalam dada manusia — dari golongan jin dan manusia.',
      'Sumber: Al-Qur\'an, Surah 114 (An-Nas).',
    ),
    'Morning Prayer': DuaTr(
      'Doa Pagi',
      'Ya Allah, dengan-Mu kami memasuki waktu pagi dan dengan-Mu kami memasuki waktu petang. Dengan-Mu kami hidup, dengan-Mu kami mati, dan kepada-Mu kebangkitan.',
      'Sumber: Tirmidzi, Da\'awat 13; Abu Dawud, Adab 101.',
    ),
    'Evening Prayer': DuaTr(
      'Doa Petang',
      'Ya Allah, dengan-Mu kami memasuki waktu petang dan dengan-Mu kami memasuki waktu pagi. Dengan-Mu kami hidup, dengan-Mu kami mati, dan kepada-Mu tempat kembali.',
      'Sumber: Tirmidzi, Da\'awat 13; Abu Dawud, Adab 101.',
    ),
    'Qunut Prayer': DuaTr(
      'Doa Qunut',
      'Ya Allah, kami memohon pertolongan-Mu dan ampunan-Mu. Kami beriman kepada-Mu dan bertawakal kepada-Mu. Kami memuji-Mu dengan segala kebaikan dan bersyukur kepada-Mu. Kami tidak mengingkari-Mu. Kami melepaskan diri dan meninggalkan orang yang durhaka kepada-Mu.',
      'Sumber: Baihaqi, as-Sunan al-Kubra, II, 210.',
    ),
    'Subhanaka': DuaTr(
      'Subhanaka',
      'Maha Suci Engkau ya Allah, dan segala puji bagi-Mu. Maha berkah nama-Mu, Maha tinggi keagungan-Mu. Tidak ada tuhan selain Engkau.',
      'Sumber: Abu Dawud, Salat 121; Tirmidzi, Salat 179.',
    ),
    'At-Tahiyyat': DuaTr(
      'At-Tahiyyat',
      'Segala penghormatan, shalawat, dan kebaikan hanya milik Allah. Salam sejahtera atasmu wahai Nabi, beserta rahmat Allah dan berkah-Nya. Salam sejahtera atas kami dan atas hamba-hamba Allah yang saleh. Aku bersaksi bahwa tidak ada tuhan selain Allah, dan aku bersaksi bahwa Muhammad adalah hamba dan utusan-Nya.',
      'Sumber: Bukhari, Adzan 148; Muslim, Salat 56.',
    ),
    'Salawat': DuaTr(
      'Shalawat',
      'Ya Allah, limpahkanlah shalawat kepada Muhammad dan keluarga Muhammad, sebagaimana Engkau telah melimpahkan shalawat kepada Ibrahim dan keluarga Ibrahim. Sesungguhnya Engkau Maha Terpuji lagi Maha Mulia.',
      'Sumber: Bukhari, Anbiya 10; Muslim, Salat 65-66.',
    ),
    'Salawat (Barakah)': DuaTr(
      'Shalawat (Barakah)',
      'Ya Allah, berkahilah Muhammad dan keluarga Muhammad, sebagaimana Engkau telah memberkahi Ibrahim dan keluarga Ibrahim. Sesungguhnya Engkau Maha Terpuji lagi Maha Mulia.',
      'Sumber: Bukhari, Anbiya 10; Muslim, Salat 65-66.',
    ),
    'Rabbana Atina': DuaTr(
      'Rabbana Atina',
      'Ya Tuhan kami, berilah kami kebaikan di dunia dan kebaikan di akhirat, dan lindungilah kami dari azab neraka.',
      'Sumber: Surah Al-Baqarah, ayat 201.',
    ),
    'Before Meal Prayer': DuaTr(
      'Doa Sebelum Makan',
      'Dengan nama Allah dan dengan berkah Allah. Ya Allah, berkahilah kami pada apa yang telah Engkau rezekikan kepada kami dan peliharalah kami dari azab neraka.',
      'Sumber: Bukhari, At\'imah 2; Abu Dawud, At\'imah 15.',
    ),
    'After Meal Prayer': DuaTr(
      'Doa Setelah Makan',
      'Segala puji bagi Allah yang telah memberi kami makan, memberi kami minum, dan menjadikan kami orang-orang muslim.',
      'Sumber: Tirmidzi, Da\'awat 56; Abu Dawud, At\'imah 52.',
    ),
    'Before Sleep Prayer': DuaTr(
      'Doa Sebelum Tidur',
      'Dengan nama-Mu ya Allah aku mati (tidur) dan aku hidup (bangun).',
      'Sumber: Bukhari, Da\'awat 7.',
    ),
    'Waking Prayer': DuaTr(
      'Doa Bangun Tidur',
      'Segala puji bagi Allah yang telah menghidupkan kami setelah mematikan kami, dan kepada-Nya kebangkitan.',
      'Sumber: Bukhari, Da\'awat 8.',
    ),
    'Entering the Home': DuaTr(
      'Doa Masuk Rumah',
      'Dengan nama Allah kami masuk, dengan nama Allah kami keluar, dan kepada Allah Tuhan kami, kami bertawakal.',
      'Sumber: Abu Dawud, Adab 103.',
    ),
    'Leaving the Home': DuaTr(
      'Doa Keluar Rumah',
      'Dengan nama Allah, aku bertawakal kepada Allah. Tidak ada daya dan kekuatan kecuali dengan pertolongan Allah.',
      'Sumber: Abu Dawud, Adab 103; Tirmidzi, Da\'awat 34.',
    ),
    'Healing Prayer': DuaTr(
      'Doa Kesembuhan',
      'Ya Allah, Tuhan manusia, hilangkanlah penyakit dan berilah kesembuhan. Engkaulah Yang Maha Menyembuhkan. Tidak ada kesembuhan kecuali kesembuhan dari-Mu — kesembuhan yang tidak meninggalkan penyakit.',
      'Sumber: Bukhari, Marda 20; Muslim, Salam 46.',
    ),
    'Prayer of Yunus (Hardship)': DuaTr(
      'Doa Nabi Yunus (Kesulitan)',
      'Tidak ada tuhan selain Engkau; Maha Suci Engkau. Sesungguhnya aku termasuk orang-orang yang zalim.',
      'Sumber: Surah Al-Anbiya, ayat 87; Tirmidzi, Da\'awat 81.',
    ),
    'Blessing Prayer': DuaTr(
      'Doa Keberkahan',
      'Ya Allah, aku memohon kepada-Mu ilmu yang bermanfaat, rezeki yang baik, dan amal yang diterima.',
      'Sumber: Ibnu Majah, Iqamah 32.',
    ),
    'Prayer of Repentance': DuaTr(
      'Doa Taubat',
      'Ya Tuhanku, sesungguhnya aku telah menzalimi diriku sendiri, maka ampunilah aku.',
      'Sumber: Surah Al-Qasas, ayat 16.',
    ),
    'Prayer for Provision': DuaTr(
      'Doa Memohon Rezeki',
      'Ya Allah, cukupkanlah aku dengan rezeki-Mu yang halal dari yang haram, dan jadikanlah aku tidak bergantung kepada selain-Mu dengan karunia-Mu.',
      'Sumber: Tirmidzi, Da\'awat 110.',
    ),
    'Graveyard Visitation': DuaTr(
      'Doa Ziarah Kubur',
      'Salam sejahtera atas kalian wahai penghuni kubur. Semoga Allah mengampuni kami dan kalian. Kalian telah mendahului kami dan kami akan menyusul.',
      'Sumber: Tirmidzi, Jana\'iz 59.',
    ),
  },
  'ur': {
    "Verse on Dhikr — Ar-Ra'd 28": DuaTr(
      'ذکر کی آیت — الرعد 28',
      'جو لوگ ایمان لائے اور جن کے دل اللہ کے ذکر سے اطمینان پاتے ہیں۔ سن لو! اللہ کے ذکر ہی سے دل اطمینان پاتے ہیں۔',
      'ماخذ: سورہ الرعد، آیت 28۔',
    ),
    'Verse on Dhikr — Al-Baqarah 152': DuaTr(
      'ذکر کی آیت — البقرہ 152',
      'پس تم مجھے یاد کرو، میں تمہیں یاد رکھوں گا۔ اور میرا شکر ادا کرو اور میری ناشکری نہ کرو۔',
      'ماخذ: سورہ البقرہ، آیت 152۔',
    ),
    'Verse on Dhikr — Al-Ahzab 41-42': DuaTr(
      'ذکر کی آیت — الاحزاب 41-42',
      'اے ایمان والو! اللہ کو کثرت سے یاد کرو، اور صبح و شام اس کی تسبیح کرو۔',
      'ماخذ: سورہ الاحزاب، آیات 41-42۔',
    ),
    "Verse on Dhikr — Al-A'raf 205": DuaTr(
      'ذکر کی آیت — الاعراف 205',
      'اور اپنے رب کو اپنے دل میں عاجزی اور خوف کے ساتھ، بلند آواز کے بغیر، صبح اور شام یاد کرو؛ اور غافلوں میں سے نہ ہو جاؤ۔',
      'ماخذ: سورہ الاعراف، آیت 205۔',
    ),
    'Verse on Dhikr — Al-Ankabut 45': DuaTr(
      'ذکر کی آیت — العنکبوت 45',
      'اور اللہ کا ذکر سب سے بڑا ہے۔ اور اللہ جانتا ہے جو کچھ تم کرتے ہو۔',
      'ماخذ: سورہ العنکبوت، آیت 45۔',
    ),
    'Ayat al-Kursi': DuaTr(
      'آیت الکرسی',
      'اللہ — اس کے سوا کوئی معبود نہیں، وہ ہمیشہ زندہ اور سب کو قائم رکھنے والا ہے۔ نہ اسے اونگھ آتی ہے نہ نیند۔ آسمانوں اور زمین میں جو کچھ ہے سب اسی کا ہے۔ کون ہے جو اس کی اجازت کے بغیر اس کے حضور سفارش کر سکے؟ وہ جانتا ہے جو کچھ ان کے سامنے ہے اور جو کچھ ان کے پیچھے ہے، اور وہ اس کے علم میں سے کسی چیز کا احاطہ نہیں کر سکتے مگر جتنا وہ چاہے۔ اس کی کرسی آسمانوں اور زمین کو محیط ہے، اور ان کی حفاظت اسے نہیں تھکاتی۔ اور وہی سب سے بلند، سب سے عظیم ہے۔',
      'ماخذ: سورہ البقرہ، آیت 255۔',
    ),
    'Al-Fatiha': DuaTr(
      'سورہ فاتحہ',
      'اللہ کے نام سے جو نہایت مہربان، رحم کرنے والا ہے۔ سب تعریف اللہ کے لیے ہے جو تمام جہانوں کا رب ہے — نہایت مہربان، رحم کرنے والا — روزِ جزا کا مالک۔ ہم تیری ہی عبادت کرتے ہیں اور تجھ ہی سے مدد مانگتے ہیں۔ ہمیں سیدھا راستہ دکھا: ان لوگوں کا راستہ جن پر تو نے انعام کیا، نہ ان کا جن پر غضب ہوا اور نہ گمراہوں کا۔',
      'ماخذ: قرآن، سورہ 1 (الفاتحہ)۔',
    ),
    'Al-Ikhlas': DuaTr(
      'سورہ اخلاص',
      'کہو: وہ اللہ ایک ہے۔ اللہ بے نیاز ہے۔ نہ اس کی کوئی اولاد ہے اور نہ وہ کسی کی اولاد ہے۔ اور نہ کوئی اس کا ہمسر ہے۔',
      'ماخذ: قرآن، سورہ 112 (الاخلاص)۔',
    ),
    'Al-Falaq': DuaTr(
      'سورہ فلق',
      'کہو: میں صبح کے رب کی پناہ مانگتا ہوں — اس کی مخلوق کے شر سے، اور اندھیری رات کے شر سے جب وہ چھا جائے، اور گرہوں میں پھونکنے والیوں کے شر سے، اور حسد کرنے والے کے شر سے جب وہ حسد کرے۔',
      'ماخذ: قرآن، سورہ 113 (الفلق)۔',
    ),
    'An-Nas': DuaTr(
      'سورہ ناس',
      'کہو: میں انسانوں کے رب کی پناہ مانگتا ہوں، انسانوں کے بادشاہ کی، انسانوں کے معبود کی — اس وسوسہ ڈالنے والے کے شر سے جو پیچھے ہٹ جاتا ہے، جو لوگوں کے دلوں میں وسوسے ڈالتا ہے — جنوں میں سے ہو یا انسانوں میں سے۔',
      'ماخذ: قرآن، سورہ 114 (الناس)۔',
    ),
    'Morning Prayer': DuaTr(
      'صبح کی دعا',
      'اے اللہ! تیرے ہی حکم سے ہم نے صبح کی اور تیرے ہی حکم سے ہم نے شام کی۔ تیرے ہی حکم سے ہم جیتے ہیں، تیرے ہی حکم سے مرتے ہیں، اور تیری ہی طرف اٹھنا ہے۔',
      'ماخذ: ترمذی، دعوات 13؛ ابوداؤد، ادب 101۔',
    ),
    'Evening Prayer': DuaTr(
      'شام کی دعا',
      'اے اللہ! تیرے ہی حکم سے ہم نے شام کی اور تیرے ہی حکم سے ہم نے صبح کی۔ تیرے ہی حکم سے ہم جیتے ہیں، تیرے ہی حکم سے مرتے ہیں، اور تیری ہی طرف لوٹنا ہے۔',
      'ماخذ: ترمذی، دعوات 13؛ ابوداؤد، ادب 101۔',
    ),
    'Qunut Prayer': DuaTr(
      'دعائے قنوت',
      'اے اللہ! ہم تجھ سے مدد مانگتے ہیں اور تجھ سے مغفرت چاہتے ہیں۔ ہم تجھ پر ایمان رکھتے ہیں اور تجھ پر بھروسا کرتے ہیں۔ ہم تیری بہترین تعریف کرتے ہیں اور تیرا شکر ادا کرتے ہیں۔ ہم تیری ناشکری نہیں کرتے۔ جو تیری نافرمانی کرے، ہم اس سے الگ ہوتے اور اسے چھوڑتے ہیں۔',
      'ماخذ: بیہقی، السنن الکبریٰ، II، 210۔',
    ),
    'Subhanaka': DuaTr(
      'سبحانک',
      'اے اللہ! تو پاک ہے اور تیری ہی تعریف ہے۔ تیرا نام بابرکت ہے اور تیری شان بلند ہے۔ تیرے سوا کوئی معبود نہیں۔',
      'ماخذ: ابوداؤد، صلاۃ 121؛ ترمذی، صلاۃ 179۔',
    ),
    'At-Tahiyyat': DuaTr(
      'التحیات',
      'تمام قولی، فعلی اور مالی عبادتیں اللہ ہی کے لیے ہیں۔ اے نبی! آپ پر سلام ہو اور اللہ کی رحمت اور اس کی برکتیں۔ ہم پر اور اللہ کے نیک بندوں پر سلام ہو۔ میں گواہی دیتا ہوں کہ اللہ کے سوا کوئی معبود نہیں اور گواہی دیتا ہوں کہ محمد ﷺ اس کے بندے اور رسول ہیں۔',
      'ماخذ: بخاری، اذان 148؛ مسلم، صلاۃ 56۔',
    ),
    'Salawat': DuaTr(
      'درود شریف',
      'اے اللہ! محمد ﷺ پر اور آلِ محمد پر رحمت بھیج، جیسے تو نے ابراہیم اور آلِ ابراہیم پر رحمت بھیجی۔ بے شک تو تعریف کے لائق، بزرگی والا ہے۔',
      'ماخذ: بخاری، انبیاء 10؛ مسلم، صلاۃ 65-66۔',
    ),
    'Salawat (Barakah)': DuaTr(
      'درود (برکت)',
      'اے اللہ! محمد ﷺ پر اور آلِ محمد پر برکت نازل فرما، جیسے تو نے ابراہیم اور آلِ ابراہیم پر برکت نازل فرمائی۔ بے شک تو تعریف کے لائق، بزرگی والا ہے۔',
      'ماخذ: بخاری، انبیاء 10؛ مسلم، صلاۃ 65-66۔',
    ),
    'Rabbana Atina': DuaTr(
      'ربنا آتنا',
      'اے ہمارے رب! ہمیں دنیا میں بھلائی دے اور آخرت میں بھی بھلائی دے، اور ہمیں آگ کے عذاب سے بچا۔',
      'ماخذ: سورہ البقرہ، آیت 201۔',
    ),
    'Before Meal Prayer': DuaTr(
      'کھانے سے پہلے کی دعا',
      'اللہ کے نام سے اور اللہ کی برکت سے۔ اے اللہ! جو رزق تو نے ہمیں دیا ہے اس میں برکت دے اور ہمیں آگ کے عذاب سے بچا۔',
      'ماخذ: بخاری، اطعمہ 2؛ ابوداؤد، اطعمہ 15۔',
    ),
    'After Meal Prayer': DuaTr(
      'کھانے کے بعد کی دعا',
      'سب تعریف اللہ کے لیے ہے جس نے ہمیں کھلایا، پلایا اور ہمیں مسلمان بنایا۔',
      'ماخذ: ترمذی، دعوات 56؛ ابوداؤد، اطعمہ 52۔',
    ),
    'Before Sleep Prayer': DuaTr(
      'سونے سے پہلے کی دعا',
      'اے اللہ! تیرے ہی نام کے ساتھ میں مرتا (سوتا) ہوں اور جیتا (جاگتا) ہوں۔',
      'ماخذ: بخاری، دعوات 7۔',
    ),
    'Waking Prayer': DuaTr(
      'بیدار ہونے کی دعا',
      'سب تعریف اللہ کے لیے ہے جس نے ہمیں مارنے کے بعد زندہ کیا، اور اسی کی طرف اٹھنا ہے۔',
      'ماخذ: بخاری، دعوات 8۔',
    ),
    'Entering the Home': DuaTr(
      'گھر میں داخل ہونے کی دعا',
      'اللہ کے نام سے ہم داخل ہوتے ہیں، اللہ کے نام سے نکلتے ہیں، اور اپنے رب اللہ پر بھروسا کرتے ہیں۔',
      'ماخذ: ابوداؤد، ادب 103۔',
    ),
    'Leaving the Home': DuaTr(
      'گھر سے نکلنے کی دعا',
      'اللہ کے نام سے، میں نے اللہ پر بھروسا کیا۔ اللہ کے سوا نہ کوئی طاقت ہے نہ قوت۔',
      'ماخذ: ابوداؤد، ادب 103؛ ترمذی، دعوات 34۔',
    ),
    'Healing Prayer': DuaTr(
      'شفا کی دعا',
      'اے اللہ، لوگوں کے رب! تکلیف دور فرما اور شفا دے۔ تو ہی شفا دینے والا ہے۔ تیری شفا کے سوا کوئی شفا نہیں — ایسی شفا جو کوئی بیماری باقی نہ چھوڑے۔',
      'ماخذ: بخاری، مرضٰی 20؛ مسلم، سلام 46۔',
    ),
    'Prayer of Yunus (Hardship)': DuaTr(
      'دعائے یونس (مشکل میں)',
      'تیرے سوا کوئی معبود نہیں؛ تو پاک ہے۔ بے شک میں ظالموں میں سے تھا۔',
      'ماخذ: سورہ الانبیاء، آیت 87؛ ترمذی، دعوات 81۔',
    ),
    'Blessing Prayer': DuaTr(
      'برکت کی دعا',
      'اے اللہ! میں تجھ سے نفع دینے والا علم، پاکیزہ رزق اور قبول ہونے والا عمل مانگتا ہوں۔',
      'ماخذ: ابن ماجہ، اقامہ 32۔',
    ),
    'Prayer of Repentance': DuaTr(
      'توبہ کی دعا',
      'اے میرے رب! بے شک میں نے اپنی جان پر ظلم کیا، پس مجھے بخش دے۔',
      'ماخذ: سورہ القصص، آیت 16۔',
    ),
    'Prayer for Provision': DuaTr(
      'رزق کی دعا',
      'اے اللہ! مجھے اپنے حلال رزق کے ذریعے حرام سے بچا، اور اپنے فضل سے مجھے اپنے سوا ہر ایک سے بے نیاز کر دے۔',
      'ماخذ: ترمذی، دعوات 110۔',
    ),
    'Graveyard Visitation': DuaTr(
      'قبرستان کی زیارت کی دعا',
      'اے قبر والو! تم پر سلام ہو۔ اللہ ہمیں اور تمہیں بخشے۔ تم ہم سے پہلے چلے گئے اور ہم تمہارے پیچھے آنے والے ہیں۔',
      'ماخذ: ترمذی، جنائز 59۔',
    ),
  },
  'fr': {
    "Verse on Dhikr — Ar-Ra'd 28": DuaTr(
      "Verset sur le dhikr — Ar-Ra'd 28",
      "Ceux qui ont cru et dont les cœurs s'apaisent par l'évocation d'Allah. N'est-ce pas par l'évocation d'Allah que les cœurs s'apaisent ?",
      "Source : Sourate Ar-Ra'd, verset 28.",
    ),
    'Verse on Dhikr — Al-Baqarah 152': DuaTr(
      'Verset sur le dhikr — Al-Baqarah 152',
      "Souvenez-vous de Moi, Je Me souviendrai de vous. Soyez-Moi reconnaissants et ne soyez pas ingrats envers Moi.",
      'Source : Sourate Al-Baqarah, verset 152.',
    ),
    'Verse on Dhikr — Al-Ahzab 41-42': DuaTr(
      'Verset sur le dhikr — Al-Ahzab 41-42',
      "Ô vous qui croyez ! Évoquez Allah d'une évocation abondante, et glorifiez-Le matin et soir.",
      'Source : Sourate Al-Ahzab, versets 41-42.',
    ),
    "Verse on Dhikr — Al-A'raf 205": DuaTr(
      "Verset sur le dhikr — Al-A'raf 205",
      "Et invoque ton Seigneur en toi-même, avec humilité et crainte, à voix basse, le matin et le soir ; et ne sois pas du nombre des insouciants.",
      "Source : Sourate Al-A'raf, verset 205.",
    ),
    'Verse on Dhikr — Al-Ankabut 45': DuaTr(
      'Verset sur le dhikr — Al-Ankabut 45',
      "Et l'évocation d'Allah est certes ce qu'il y a de plus grand. Et Allah sait ce que vous faites.",
      'Source : Sourate Al-Ankabut, verset 45.',
    ),
    'Ayat al-Kursi': DuaTr(
      'Ayat al-Kursi',
      "Allah — point de divinité à part Lui, le Vivant, Celui qui subsiste par Lui-même. Ni somnolence ni sommeil ne Le saisissent. À Lui appartient tout ce qui est dans les cieux et sur la terre. Qui peut intercéder auprès de Lui sans Sa permission ? Il connaît leur passé et leur futur, et ils n'embrassent de Sa science que ce qu'Il veut. Son Trône déborde les cieux et la terre, et leur garde ne Lui coûte aucune peine. Et Il est le Très-Haut, le Très Grand.",
      'Source : Sourate Al-Baqarah, verset 255.',
    ),
    'Al-Fatiha': DuaTr(
      'Al-Fatiha',
      "Au nom d'Allah, le Tout Miséricordieux, le Très Miséricordieux. Louange à Allah, Seigneur des mondes — le Tout Miséricordieux, le Très Miséricordieux — Maître du Jour de la rétribution. C'est Toi que nous adorons et c'est Toi dont nous implorons le secours. Guide-nous dans le droit chemin : le chemin de ceux que Tu as comblés de faveurs, non pas de ceux qui ont encouru Ta colère, ni des égarés.",
      'Source : Le Coran, sourate 1 (Al-Fatiha).',
    ),
    'Al-Ikhlas': DuaTr(
      'Al-Ikhlas',
      "Dis : Il est Allah, Unique. Allah, le Seul à être imploré pour ce que nous désirons. Il n'a jamais engendré, n'a pas été engendré non plus. Et nul n'est égal à Lui.",
      'Source : Le Coran, sourate 112 (Al-Ikhlas).',
    ),
    'Al-Falaq': DuaTr(
      'Al-Falaq',
      "Dis : Je cherche protection auprès du Seigneur de l'aube naissante — contre le mal des êtres qu'Il a créés, contre le mal de l'obscurité quand elle s'approfondit, contre le mal de celles qui soufflent sur les nœuds, et contre le mal de l'envieux quand il envie.",
      'Source : Le Coran, sourate 113 (Al-Falaq).',
    ),
    'An-Nas': DuaTr(
      'An-Nas',
      "Dis : Je cherche protection auprès du Seigneur des hommes, le Souverain des hommes, le Dieu des hommes — contre le mal du mauvais conseiller furtif, qui souffle le mal dans les poitrines des hommes — qu'il soit djinn ou être humain.",
      'Source : Le Coran, sourate 114 (An-Nas).',
    ),
    'Morning Prayer': DuaTr(
      'Invocation du matin',
      "Ô Allah, par Toi nous entrons dans le matin et par Toi nous entrons dans le soir. Par Toi nous vivons, par Toi nous mourons, et vers Toi est la résurrection.",
      "Source : Tirmidhi, Da'awat 13 ; Abou Dawoud, Adab 101.",
    ),
    'Evening Prayer': DuaTr(
      'Invocation du soir',
      "Ô Allah, par Toi nous entrons dans le soir et par Toi nous entrons dans le matin. Par Toi nous vivons, par Toi nous mourons, et vers Toi est le retour.",
      "Source : Tirmidhi, Da'awat 13 ; Abou Dawoud, Adab 101.",
    ),
    'Qunut Prayer': DuaTr(
      'Invocation du Qounout',
      "Ô Allah, nous implorons Ton aide et Ton pardon. Nous croyons en Toi et nous plaçons notre confiance en Toi. Nous Te louons de tout bien et nous Te remercions. Nous ne Te renions pas. Nous nous désavouons de quiconque Te désobéit et nous l'abandonnons.",
      'Source : Bayhaqi, as-Sunan al-Kubra, II, 210.',
    ),
    'Subhanaka': DuaTr(
      'Subhanaka',
      "Gloire à Toi, ô Allah, et louange à Toi. Béni soit Ton nom et exaltée soit Ta majesté. Il n'y a de divinité que Toi.",
      'Source : Abou Dawoud, Salat 121 ; Tirmidhi, Salat 179.',
    ),
    'At-Tahiyyat': DuaTr(
      'At-Tahiyyat',
      "Les salutations, les prières et les bonnes œuvres sont pour Allah. Que la paix soit sur toi, ô Prophète, ainsi que la miséricorde d'Allah et Ses bénédictions. Que la paix soit sur nous et sur les serviteurs vertueux d'Allah. J'atteste qu'il n'y a de divinité qu'Allah et j'atteste que Muhammad est Son serviteur et Son messager.",
      'Source : Boukhari, Adhan 148 ; Mouslim, Salat 56.',
    ),
    'Salawat': DuaTr(
      'Salawat',
      "Ô Allah, prie sur Muhammad et sur la famille de Muhammad, comme Tu as prié sur Ibrahim et sur la famille d'Ibrahim. Tu es certes Digne de louange et de gloire.",
      'Source : Boukhari, Anbiya 10 ; Mouslim, Salat 65-66.',
    ),
    'Salawat (Barakah)': DuaTr(
      'Salawat (Barakah)',
      "Ô Allah, bénis Muhammad et la famille de Muhammad, comme Tu as béni Ibrahim et la famille d'Ibrahim. Tu es certes Digne de louange et de gloire.",
      'Source : Boukhari, Anbiya 10 ; Mouslim, Salat 65-66.',
    ),
    'Rabbana Atina': DuaTr(
      'Rabbana Atina',
      "Notre Seigneur, accorde-nous le bien dans ce monde et le bien dans l'au-delà, et protège-nous du châtiment du Feu.",
      'Source : Sourate Al-Baqarah, verset 201.',
    ),
    'Before Meal Prayer': DuaTr(
      'Invocation avant le repas',
      "Au nom d'Allah et avec la bénédiction d'Allah. Ô Allah, bénis ce que Tu nous as accordé et protège-nous du châtiment du Feu.",
      "Source : Boukhari, At'ima 2 ; Abou Dawoud, At'ima 15.",
    ),
    'After Meal Prayer': DuaTr(
      'Invocation après le repas',
      "Louange à Allah qui nous a nourris, nous a abreuvés et a fait de nous des musulmans.",
      "Source : Tirmidhi, Da'awat 56 ; Abou Dawoud, At'ima 52.",
    ),
    'Before Sleep Prayer': DuaTr(
      'Invocation avant de dormir',
      "En Ton nom, ô Allah, je meurs (je dors) et je vis (je me réveille).",
      "Source : Boukhari, Da'awat 7.",
    ),
    'Waking Prayer': DuaTr(
      'Invocation du réveil',
      "Louange à Allah qui nous a rendus à la vie après nous avoir fait mourir, et vers Lui est la résurrection.",
      "Source : Boukhari, Da'awat 8.",
    ),
    'Entering the Home': DuaTr(
      'En entrant chez soi',
      "Au nom d'Allah nous entrons, au nom d'Allah nous sortons, et en Allah notre Seigneur nous plaçons notre confiance.",
      'Source : Abou Dawoud, Adab 103.',
    ),
    'Leaving the Home': DuaTr(
      'En sortant de chez soi',
      "Au nom d'Allah, je place ma confiance en Allah. Il n'y a de force ni de puissance qu'en Allah.",
      "Source : Abou Dawoud, Adab 103 ; Tirmidhi, Da'awat 34.",
    ),
    'Healing Prayer': DuaTr(
      'Invocation de guérison',
      "Ô Allah, Seigneur des hommes, fais disparaître le mal et accorde la guérison. Tu es le Guérisseur. Il n'y a de guérison que la Tienne — une guérison qui ne laisse aucune maladie.",
      'Source : Boukhari, Marda 20 ; Mouslim, Salam 46.',
    ),
    'Prayer of Yunus (Hardship)': DuaTr(
      'Invocation de Yunus (épreuve)',
      "Il n'y a de divinité que Toi ; gloire à Toi. J'ai été certes du nombre des injustes.",
      "Source : Sourate Al-Anbiya, verset 87 ; Tirmidhi, Da'awat 81.",
    ),
    'Blessing Prayer': DuaTr(
      'Invocation de bénédiction',
      "Ô Allah, je Te demande une science utile, une subsistance pure et une œuvre acceptée.",
      'Source : Ibn Majah, Iqamah 32.',
    ),
    'Prayer of Repentance': DuaTr(
      'Invocation de repentir',
      "Seigneur, je me suis fait du tort à moi-même ; pardonne-moi.",
      'Source : Sourate Al-Qasas, verset 16.',
    ),
    'Prayer for Provision': DuaTr(
      'Invocation pour la subsistance',
      "Ô Allah, accorde-moi ce qui est licite pour me passer de ce qui est illicite, et par Ta grâce, rends-moi indépendant de tout autre que Toi.",
      "Source : Tirmidhi, Da'awat 110.",
    ),
    'Graveyard Visitation': DuaTr(
      'Visite du cimetière',
      "Que la paix soit sur vous, ô habitants des tombes. Qu'Allah nous pardonne, à nous et à vous. Vous nous avez précédés et nous vous suivrons.",
      "Source : Tirmidhi, Jana'iz 59.",
    ),
  },
};
