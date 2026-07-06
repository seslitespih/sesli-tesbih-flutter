import '../models/dua.dart';

const List<Dua> kDuaList = [
  // ── Zikirle ilgili ayetler ────────────────────────────────────────────────
  Dua(
    title: 'Zikir Ayeti — Ra\'d 28',
    titleEn: 'Verse on Dhikr — Ar-Ra\'d 28',
    arabicText:
        'اَلَّذِينَ اٰمَنُوا وَتَطْمَئِنُّ قُلُوبُهُمْ بِذِكْرِ اللّٰهِ اَلَا بِذِكْرِ اللّٰهِ تَطْمَئِنُّ الْقُلُوبُ',
    transliteration:
        "Ellezîne âmenû ve tatmainnu kulûbuhum bi-zikrillâh. E lâ bi-zikrillâhi tatmainnu'l-kulûb.",
    turkish:
        "Onlar, inananlar ve kalpleri Allah'ı anmakla huzura kavuşanlardır. Biliniz ki, kalpler ancak Allah'ı anmakla huzur bulur.",
    english:
        "Those who have believed and whose hearts find rest in the remembrance of Allah. Verily, in the remembrance of Allah do hearts find rest.",
    info: "Kaynak: Ra'd Suresi, 28. ayet · Meal: Diyanet İşleri Başkanlığı.",
    infoEn: "Source: Surah Ar-Ra'd, verse 28.",
  ),
  Dua(
    title: 'Zikir Ayeti — Bakara 152',
    titleEn: 'Verse on Dhikr — Al-Baqarah 152',
    arabicText: 'فَاذْكُرُونِٓي اَذْكُرْكُمْ وَاشْكُرُوا لِي وَلَا تَكْفُرُونِ',
    transliteration: "Fezkurûnî ezkurkum, veşkurû lî ve lâ tekfurûn.",
    turkish:
        "Öyleyse yalnız beni anın ki ben de sizi anayım. Bana şükredin, sakın nankörlük etmeyin.",
    english:
        "So remember Me; I will remember you. And be grateful to Me and do not deny Me.",
    info: 'Kaynak: Bakara Suresi, 152. ayet · Meal: Diyanet İşleri Başkanlığı.',
    infoEn: 'Source: Surah Al-Baqarah, verse 152.',
  ),
  Dua(
    title: 'Zikir Ayeti — Ahzâb 41-42',
    titleEn: 'Verse on Dhikr — Al-Ahzab 41-42',
    arabicText:
        'يَٓا اَيُّهَا الَّذِينَ اٰمَنُوا اذْكُرُوا اللّٰهَ ذِكْرًا كَثِيرًا۝ وَسَبِّحُوهُ بُكْرَةً وَاَصِيلًا',
    transliteration:
        "Yâ eyyuhellezîne âmenüzkürullâhe zikran kesîrâ. Ve sebbihûhu bukraten ve asîlâ.",
    turkish:
        "Ey iman edenler! Allah'ı çokça zikredin. O'nu sabah akşam tespih edin.",
    english:
        "O you who have believed, remember Allah with much remembrance, and exalt Him morning and afternoon.",
    info: 'Kaynak: Ahzâb Suresi, 41-42. ayetler · Meal: Diyanet İşleri Başkanlığı.',
    infoEn: 'Source: Surah Al-Ahzab, verses 41-42.',
  ),
  Dua(
    title: "Zikir Ayeti — A'râf 205",
    titleEn: "Verse on Dhikr — Al-A'raf 205",
    arabicText:
        'وَاذْكُرْ رَبَّكَ فِي نَفْسِكَ تَضَرُّعًا وَخِيفَةً وَدُونَ الْجَهْرِ مِنَ الْقَوْلِ بِالْغُدُوِّ وَالْاٰصَالِ وَلَا تَكُنْ مِنَ الْغَافِلِينَ',
    transliteration:
        "Vezkur rabbeke fî nefsike tedarruan ve hîfeten ve dûne'l-cehri mine'l-kavli bi'l-guduvvi ve'l-âsâli ve lâ tekun mine'l-gâfilîn.",
    turkish:
        "Rabbini, içinden yalvararak ve korkarak, yüksek olmayan bir sesle sabah-akşam zikret ve gafillerden olma.",
    english:
        "And remember your Lord within yourself in humility and in fear, without being loud in speech, in the mornings and the evenings; and do not be among the heedless.",
    info: "Kaynak: A'râf Suresi, 205. ayet · Meal: Diyanet İşleri Başkanlığı.",
    infoEn: "Source: Surah Al-A'raf, verse 205.",
  ),
  Dua(
    title: 'Zikir Ayeti — Ankebût 45',
    titleEn: 'Verse on Dhikr — Al-Ankabut 45',
    arabicText: 'وَلَذِكْرُ اللّٰهِ اَكْبَرُ وَاللّٰهُ يَعْلَمُ مَا تَصْنَعُونَ',
    transliteration:
        "Ve lezikrullâhi ekber. Vallâhu ya'lemu mâ tasneûn.",
    turkish:
        "Allah'ı anmak (olan namaz) elbette en büyük ibadettir. Allah, yaptıklarınızı biliyor.",
    english:
        "And the remembrance of Allah is greater. And Allah knows that which you do.",
    info: 'Kaynak: Ankebût Suresi, 45. ayet · Meal: Diyanet İşleri Başkanlığı.',
    infoEn: 'Source: Surah Al-Ankabut, verse 45.',
  ),
  // ── Dualar ve sureler ─────────────────────────────────────────────────────
  Dua(
    title: 'Ayetel Kürsi',
    titleEn: 'Ayat al-Kursi',
    arabicText:
        'اَللّٰهُ لَٓا اِلٰهَ اِلَّا هُوَ اَلْحَيُّ الْقَيُّومُۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌۚ لَهُ مَا فِي السَّمٰوَاتِ وَمَا فِي الْاَرْضِۚ مَنْ ذَا الَّذِي يَشْفَعُ عِنْدَهُٓ اِلَّا بِاِذْنِهِۚ يَعْلَمُ مَا بَيْنَ اَيْدِيهِمْ وَمَا خَلْفَهُمْۚ وَلَا يُحِيطُونَ بِشَيْءٍ مِنْ عِلْمِهِٓ اِلَّا بِمَا شَٓاءَۚ وَسِعَ كُرْسِيُّهُ السَّمٰوَاتِ وَالْاَرْضَۚ وَلَا يَؤُدُهُ حِفْظُهُمَاۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ',
    transliteration:
        "Allahu laa ilaaha illaa huw-al-Hayyul-Qayyuum. Laa ta'khudhuhu sinatuw-wa laa nawm. Lahuu maa fis-samaawaati wa maa fil-ard. Man dhal-ladhii yashfa'u 'indahuu illaa bi-idhnih. Ya'lamu maa bayna aydiihim wa maa khalfahum. Wa laa yuhiituuna bi-shay'im-min 'ilmihii illaa bimaa shaa'. Wasi'a kursiyyuhus-samaawaati wal-ard. Wa laa ya'uduhu hifzuhumaa. Wa huwal-'Aliyyul-'Aziim.",
    turkish:
        "Allah, kendisinden başka hiçbir ilah olmayandır. Diridir, kayyumdur. O'nu ne bir uyuklama tutabilir, ne de bir uyku. Göklerdeki her şey, yerdeki her şey O'nundur. İzni olmaksızın O'nun katında şefaatte bulunacak kimdir? O, kulların önlerindekileri ve arkalarındakileri (yaptıklarını ve yapacaklarını) bilir. Onlar O'nun ilminden, kendisinin dilediği kadarından başka bir şey kavrayamazlar. O'nun kürsüsü, bütün gökleri ve yeri kaplayıp kuşatmıştır. (O, göklere, yere, bütün evrene hükmetmektedir.) Gökleri ve yeri koruyup gözetmek O'na güç gelmez. O, yücedir, büyüktür.",
    english:
        "Allah — there is no deity except Him, the Ever-Living, the Sustainer of existence. Neither drowsiness overtakes Him nor sleep. To Him belongs whatever is in the heavens and whatever is on the earth. Who is it that can intercede with Him except by His permission? He knows what is before them and what will be after them, and they encompass not a thing of His knowledge except for what He wills. His Kursi extends over the heavens and the earth, and their preservation tires Him not. And He is the Most High, the Most Great.",
    info: 'Kaynak: Bakara Suresi, 255. ayet · Meal: Diyanet İşleri Başkanlığı.',
    infoEn: 'Source: Surah Al-Baqarah, verse 255.',
  ),
  Dua(
    title: 'Fatiha Suresi',
    titleEn: 'Al-Fatiha',
    arabicText:
        'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيمِ۝ اَلْحَمْدُ لِلّٰهِ رَبِّ الْعَالَمِينَ۝ اَلرَّحْمٰنِ الرَّحِيمِ۝ مَالِكِ يَوْمِ الدِّينِ۝ اِيَّاكَ نَعْبُدُ وَاِيَّاكَ نَسْتَعِينُ۝ اِهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ۝ صِرَاطَ الَّذِينَ اَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّٓالِّينَ',
    transliteration:
        "Bismillaahir-Rahmaanir-Rahiim. Alhamdulillaahi Rabbil-'aalamiin. Ar-Rahmaanir-Rahiim. Maaliki Yawmid-Diin. Iyyaaka na'budu wa iyyaaka nasta'iin. Ihdinas-Siraatal-Mustaqiim. Siraatalladhiina an'amta 'alayhim, ghayril-maghdhuubi 'alayhim wa lad-daalliin.",
    turkish:
        "Bismillahirrahmanirrahim. Hamd, âlemlerin Rabbi, Rahmân, Rahîm, hesap ve ceza gününün (ahiret gününün) mâliki Allah'a mahsustur. (Allah'ım!) Yalnız sana ibadet ederiz ve yalnız senden yardım dileriz. Bizi doğru yola, kendilerine nimet verdiklerinin yoluna ilet; gazaba uğrayanlarınkine ve sapıklarınkine değil.",
    english:
        "In the name of Allah, the Entirely Merciful, the Especially Merciful. Praise be to Allah, Lord of the worlds — the Entirely Merciful, the Especially Merciful — Sovereign of the Day of Recompense. It is You we worship and You we ask for help. Guide us to the straight path: the path of those upon whom You have bestowed favor, not of those who have earned anger or of those who are astray.",
    info: "Kaynak: Kur'an-ı Kerim, 1. sure (Fâtiha) · Meal: Diyanet İşleri Başkanlığı.",
    infoEn: 'Source: The Quran, Surah 1 (Al-Fatiha).',
  ),
  Dua(
    title: 'İhlas Suresi',
    titleEn: 'Al-Ikhlas',
    arabicText:
        'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيمِ۝ قُلْ هُوَ اللّٰهُ اَحَدٌ۝ اَللّٰهُ الصَّمَدُ۝ لَمْ يَلِدْ وَلَمْ يُولَدْ۝ وَلَمْ يَكُنْ لَهُ كُفُوًا اَحَدٌ',
    transliteration:
        "Bismillaahir-Rahmaanir-Rahiim. Qul Huwallahu Ahad. Allahus-Samad. Lam yalid wa lam yuulad. Wa lam yakul-lahuu kufuwan ahad.",
    turkish:
        "De ki: \"O, Allah'tır, bir tektir. Allah Samed'dir. (Her şey O'na muhtaçtır; O, hiçbir şeye muhtaç değildir.) O'ndan çocuk olmamıştır, kendisi de doğmamıştır. Hiçbir şey O'na denk ve benzer değildir.\"",
    english:
        "Say: He is Allah, the One. Allah, the Eternal Refuge. He neither begets nor is born. Nor is there to Him any equivalent.",
    info: "Kaynak: Kur'an-ı Kerim, 112. sure (İhlâs) · Meal: Diyanet İşleri Başkanlığı.",
    infoEn: 'Source: The Quran, Surah 112 (Al-Ikhlas).',
  ),
  Dua(
    title: 'Felak Suresi',
    titleEn: 'Al-Falaq',
    arabicText:
        'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيمِ۝ قُلْ اَعُوذُ بِرَبِّ الْفَلَقِ۝ مِنْ شَرِّ مَا خَلَقَ۝ وَمِنْ شَرِّ غَاسِقٍ اِذَا وَقَبَ۝ وَمِنْ شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ۝ وَمِنْ شَرِّ حَاسِدٍ اِذَا حَسَدَ',
    transliteration:
        "Bismillaahir-Rahmaanir-Rahiim. Qul a'uudhu bi-Rabbil-falaq. Min sharri maa khalaq. Wa min sharri ghaasiqin idhaa waqab. Wa min sharrin-naffaathaati fil-'uqad. Wa min sharri haasidin idhaa hasad.",
    turkish:
        "De ki: \"Yarattığı şeylerin kötülüğünden, karanlığı çöktüğü zaman gecenin kötülüğünden, düğümlere üfleyenlerin kötülüğünden, haset ettiği zaman hasetçinin kötülüğünden, sabah aydınlığının Rabbine sığınırım.\"",
    english:
        "Say: I seek refuge in the Lord of daybreak — from the evil of that which He created, from the evil of darkness when it settles, from the evil of those who blow on knots, and from the evil of an envier when he envies.",
    info: "Kaynak: Kur'an-ı Kerim, 113. sure (Felak) · Meal: Diyanet İşleri Başkanlığı.",
    infoEn: 'Source: The Quran, Surah 113 (Al-Falaq).',
  ),
  Dua(
    title: 'Nas Suresi',
    titleEn: 'An-Nas',
    arabicText:
        'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيمِ۝ قُلْ اَعُوذُ بِرَبِّ النَّاسِ۝ مَلِكِ النَّاسِ۝ اِلٰهِ النَّاسِ۝ مِنْ شَرِّ الْوَسْوَاسِ الْخَنَّاسِ۝ اَلَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ۝ مِنَ الْجِنَّةِ وَالنَّاسِ',
    transliteration:
        "Bismillaahir-Rahmaanir-Rahiim. Qul a'uudhu bi-Rabbin-naas. Malikin-naas. Ilaahin-naas. Min sharril-waswaasil-khannaas. Alladhii yuwaswisu fii suduurin-naas. Minal-jinnati wan-naas.",
    turkish:
        "De ki: \"Cinlerden ve insanlardan; insanların kalplerine vesvese veren sinsi vesvesecinin kötülüğünden, insanların Rabbine, insanların Melik'ine, insanların İlah'ına sığınırım.\"",
    english:
        "Say: I seek refuge in the Lord of mankind, the Sovereign of mankind, the God of mankind — from the evil of the retreating whisperer who whispers into the breasts of mankind — from among the jinn and mankind.",
    info: "Kaynak: Kur'an-ı Kerim, 114. sure (Nâs) · Meal: Diyanet İşleri Başkanlığı.",
    infoEn: 'Source: The Quran, Surah 114 (An-Nas).',
  ),
  Dua(
    title: 'Sabah Duası',
    titleEn: 'Morning Prayer',
    arabicText:
        'اَللّٰهُمَّ بِكَ اَصْبَحْنَا وَبِكَ اَمْسَيْنَا وَبِكَ نَحْيَا وَبِكَ نَمُوتُ وَاِلَيْكَ النُّشُورُ',
    transliteration:
        "Allaahummaa bika asbahna wa bika amsaynaa, wa bika nahyaa wa bika namuutu wa ilaykan-nushuur.",
    turkish:
        "Allah'ım! Senin adınla sabahladık, senin adınla akşamladık. Senin adınla yaşar, senin adınla ölürüz. Dönüş yalnız sanadır.",
    english:
        "O Allah, by You we have entered upon the morning and by You we have entered upon the evening. By You we live, by You we die, and to You is the resurrection.",
    info: 'Kaynak: Tirmizî, Deavât 13; Ebû Dâvûd, Edeb 101.',
    infoEn: "Source: Tirmidhi, Da'awat 13; Abu Dawud, Adab 101.",
  ),
  Dua(
    title: 'Akşam Duası',
    titleEn: 'Evening Prayer',
    arabicText:
        'اَللّٰهُمَّ بِكَ اَمْسَيْنَا وَبِكَ اَصْبَحْنَا وَبِكَ نَحْيَا وَبِكَ نَمُوتُ وَاِلَيْكَ الْمَصِيرُ',
    transliteration:
        "Allaahummaa bika amsaynaa wa bika asbahna, wa bika nahyaa wa bika namuutu wa ilaykal-masiir.",
    turkish:
        "Allah'ım! Senin adınla akşamladık, senin adınla sabahladık. Senin adınla yaşar, senin adınla ölürüz. Dönüş yalnız sanadır.",
    english:
        "O Allah, by You we have entered upon the evening and by You we have entered upon the morning. By You we live, by You we die, and to You is the return.",
    info: 'Kaynak: Tirmizî, Deavât 13; Ebû Dâvûd, Edeb 101.',
    infoEn: "Source: Tirmidhi, Da'awat 13; Abu Dawud, Adab 101.",
  ),
  Dua(
    title: 'Kunut Duası',
    titleEn: 'Qunut Prayer',
    arabicText:
        'اَللّٰهُمَّ اِنَّا نَسْتَعِينُكَ وَنَسْتَغْفِرُكَ وَنُؤْمِنُ بِكَ وَنَتَوَكَّلُ عَلَيْكَ وَنُثْنِي عَلَيْكَ الْخَيْرَ وَنَشْكُرُكَ وَلَا نَكْفُرُكَ وَنَخْلَعُ وَنَتْرُكُ مَنْ يَفْجُرُكَ',
    transliteration:
        "Allaahummaa innaa nasta'iinuka wa nastaghfiruk. Wa nu'minu bika wa natawakkalu 'alayk. Wa nuthnii 'alaykal-khayr. Wa nashkuruka wa laa nakfuruk. Wa nakhla'u wa natruku man yafjuruk.",
    turkish:
        "Allah'ım! Senden yardım ister, senden bağışlanma diler, sana inanır, sana dayanır, seni hayırla över, sana şükrederiz. Seni inkâr etmez, sana karşı geleni terk eder ve bırakırız.",
    english:
        "O Allah, we seek Your help and Your forgiveness. We believe in You and rely on You. We praise You with all goodness and give thanks to You. We do not deny You. We disown and forsake those who disobey You.",
    info: "Kaynak: Beyhakî, es-Sünenü'l-Kübrâ, II, 210.",
    infoEn: 'Source: Bayhaqi, al-Sunan al-Kubra, II, 210.',
  ),
  Dua(
    title: 'Sübhaneke',
    titleEn: 'Subhanaka',
    arabicText:
        'سُبْحَانَكَ اللّٰهُمَّ وَبِحَمْدِكَ وَتَبَارَكَ اسْمُكَ وَتَعَالَى جَدُّكَ وَلَا اِلٰهَ غَيْرُكَ',
    transliteration:
        "Subhaanakallaahumma wa bihamdik. Wa tabaarakasmuk. Wa ta'aalaa jadduk. Wa laa ilaaha ghayruk.",
    turkish:
        "Allah'ım! Seni her türlü noksanlıktan tenzih eder, seni hamd ile yâd ederim. İsmin mübarektir, şanın yücedir. Senden başka ilah yoktur.",
    english:
        "Glory be to You, O Allah, and praise. Blessed is Your name and exalted is Your majesty. There is no god but You.",
    info: 'Kaynak: Ebû Dâvûd, Salât 121; Tirmizî, Salât 179.',
    infoEn: 'Source: Abu Dawud, Salat 121; Tirmidhi, Salat 179.',
  ),
  Dua(
    title: 'Ettehiyyatü',
    titleEn: 'At-Tahiyyat',
    arabicText:
        'اَلتَّحِيَّاتُ لِلّٰهِ وَالصَّلَوَاتُ وَالطَّيِّبَاتُ اَلسَّلَامُ عَلَيْكَ اَيُّهَا النَّبِيُّ وَرَحْمَةُ اللّٰهِ وَبَرَكَاتُهُ اَلسَّلَامُ عَلَيْنَا وَعَلَى عِبَادِ اللّٰهِ الصَّالِحِينَ اَشْهَدُ اَنْ لَا اِلٰهَ اِلَّا اللّٰهُ وَاَشْهَدُ اَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ',
    transliteration:
        "At-tahiyyaatu lillaahi was-salawaatu wat-tayyibaat. As-salaamu 'alayka ayyuhan-nabiyyu wa rahmatullaahi wa barakaatuh. As-salaamu 'alaynaa wa 'alaa 'ibaadillaahis-saalihiin. Ash-hadu al-laa ilaaha illallaah, wa ash-hadu anna Muhammadan 'abduhu wa rasuuluh.",
    turkish:
        "Her türlü tazim, dua ve iyilik Allah'adır. Ey Peygamber! Allah'ın selamı, rahmeti ve bereketi üzerine olsun. Selam bizim üzerimize ve Allah'ın salih kulları üzerine olsun. Şehadet ederim ki Allah'tan başka ilah yoktur; yine şehadet ederim ki Muhammed O'nun kulu ve elçisidir.",
    english:
        "All greetings, prayers, and good things are for Allah. Peace be upon you, O Prophet, and the mercy and blessings of Allah. Peace be upon us and upon the righteous servants of Allah. I bear witness that there is no god but Allah, and I bear witness that Muhammad is His servant and messenger.",
    info: 'Kaynak: Buhârî, Ezân 148; Müslim, Salât 56.',
    infoEn: 'Source: Bukhari, Adhan 148; Muslim, Salat 56.',
  ),
  Dua(
    title: 'Allahümme Salli',
    titleEn: 'Salawat',
    arabicText:
        'اَللّٰهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ كَمَا صَلَّيْتَ عَلَى اِبْرَاهِيمَ وَعَلَى آلِ اِبْرَاهِيمَ اِنَّكَ حَمِيدٌ مَجِيدٌ',
    transliteration:
        "Allaahumma salli 'alaa Muhammadin wa 'alaa aali Muhammad. Kamaa sallayta 'alaa Ibraaheema wa 'alaa aali Ibraaheem. Innaka Hamiidun Majiid.",
    turkish:
        "Allah'ım! İbrahim'e ve İbrahim'in ailesine rahmet ettiğin gibi Muhammed'e ve Muhammed'in ailesine de rahmet et. Şüphesiz sen Hamid ve Mecid'sin.",
    english:
        "O Allah, send prayers upon Muhammad and upon the family of Muhammad, as You sent prayers upon Ibrahim and upon the family of Ibrahim. Indeed, You are Praiseworthy and Glorious.",
    info: 'Kaynak: Buhârî, Enbiyâ 10; Müslim, Salât 65-66.',
    infoEn: 'Source: Bukhari, Anbiya 10; Muslim, Salat 65-66.',
  ),
  Dua(
    title: 'Allahümme Barik',
    titleEn: 'Salawat (Barakah)',
    arabicText:
        'اَللّٰهُمَّ بَارِكْ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ كَمَا بَارَكْتَ عَلَى اِبْرَاهِيمَ وَعَلَى آلِ اِبْرَاهِيمَ اِنَّكَ حَمِيدٌ مَجِيدٌ',
    transliteration:
        "Allaahumma baarik 'alaa Muhammadin wa 'alaa aali Muhammad. Kamaa baarakta 'alaa Ibraaheema wa 'alaa aali Ibraaheem. Innaka Hamiidun Majiid.",
    turkish:
        "Allah'ım! İbrahim'e ve İbrahim'in ailesine bereket verdiğin gibi Muhammed'e ve Muhammed'in ailesine de bereket ver. Şüphesiz sen Hamid ve Mecid'sin.",
    english:
        "O Allah, send blessings upon Muhammad and upon the family of Muhammad, as You sent blessings upon Ibrahim and upon the family of Ibrahim. Indeed, You are Praiseworthy and Glorious.",
    info: 'Kaynak: Buhârî, Enbiyâ 10; Müslim, Salât 65-66.',
    infoEn: 'Source: Bukhari, Anbiya 10; Muslim, Salat 65-66.',
  ),
  Dua(
    title: 'Rabbena Atina',
    titleEn: 'Rabbana Atina',
    arabicText:
        'رَبَّنَٓا اٰتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْاٰخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
    transliteration:
        "Rabbanaa aatinaa fid-dunyaa hasanatan wa fil-aakhirati hasanatan wa qinaa 'adhaaban-naar.",
    turkish:
        "Rabbimiz! Bize dünyada da iyilik ver, ahirette de iyilik ver ve bizi ateş azabından koru.",
    english:
        "Our Lord, give us good in this world and good in the Hereafter, and protect us from the punishment of the Fire.",
    info: 'Kaynak: Bakara Suresi, 201. ayet · Meal: Diyanet İşleri Başkanlığı.',
    infoEn: 'Source: Surah Al-Baqarah, verse 201.',
  ),
  Dua(
    title: 'Yemek Duası',
    titleEn: 'Before Meal Prayer',
    arabicText:
        'بِسْمِ اللّٰهِ وَعَلَى بَرَكَةِ اللّٰهِ۝ اَللّٰهُمَّ بَارِكْ لَنَا فِيمَا رَزَقْتَنَا وَقِنَا عَذَابَ النَّارِ',
    transliteration:
        "Bismillaahi wa 'alaa barakatillaah. Allaahummaa baarik lanaa fiimaa razaqtanaa wa qinaa 'adhaaban-naar.",
    turkish:
        "Allah'ın adıyla ve Allah'ın bereketine sığınarak. Allah'ım! Bize verdiğin rızıkta bereket ver ve bizi ateş azabından koru.",
    english:
        "In the name of Allah and with the blessing of Allah. O Allah, bless us in what You have provided for us and protect us from the punishment of the Fire.",
    info: "Kaynak: Buhârî, Et'ime 2; Ebû Dâvûd, Et'ime 15.",
    infoEn: "Source: Bukhari, At'ima 2; Abu Dawud, At'ima 15.",
  ),
  Dua(
    title: 'Yemek Sonrası',
    titleEn: 'After Meal Prayer',
    arabicText:
        'اَلْحَمْدُ لِلّٰهِ الَّذِٓي اَطْعَمَنَا وَسَقَانَا وَجَعَلَنَا مِنَ الْمُسْلِمِينَ',
    transliteration:
        "Alhamdulillaahilladhii at'amanaa wa saqaanaa wa ja'alanaa minal-muslimiin.",
    turkish:
        "Bizi doyuran, içiren ve Müslümanlardan kılan Allah'a hamdolsun.",
    english:
        "Praise be to Allah Who has fed us, given us drink, and made us Muslims.",
    info: "Kaynak: Tirmizî, Deavât 56; Ebû Dâvûd, Et'ime 52.",
    infoEn: "Source: Tirmidhi, Da'awat 56; Abu Dawud, At'ima 52.",
  ),
  Dua(
    title: 'Uyku Duası',
    titleEn: 'Before Sleep Prayer',
    arabicText: 'بِاسْمِكَ اللّٰهُمَّ اَمُوتُ وَاَحْيَا',
    transliteration: "Bismikallaahumma amuutu wa ahyaa.",
    turkish:
        "Allah'ım, senin adınla ölür (uyur) ve dirilrim (uyanırım).",
    english:
        "In Your name, O Allah, I die (sleep) and I live (wake).",
    info: 'Kaynak: Buhârî, Deavât 7.',
    infoEn: "Source: Bukhari, Da'awat 7.",
  ),
  Dua(
    title: 'Uyanış Duası',
    titleEn: 'Waking Prayer',
    arabicText:
        'اَلْحَمْدُ لِلّٰهِ الَّذِٓي اَحْيَانَا بَعْدَمَٓا اَمَاتَنَا وَاِلَيْهِ النُّشُورُ',
    transliteration:
        "Alhamdulillaahilladhii ahyaanaa ba'damaa amaatanaa wa ilayhin-nushuur.",
    turkish:
        "Bizi öldürdükten (uyuttuktan) sonra dirilten (uyandıran) Allah'a hamdolsun. Diriliş O'nadır.",
    english:
        "Praise be to Allah Who gave us life after He had caused us to die, and to Him is the resurrection.",
    info: 'Kaynak: Buhârî, Deavât 8.',
    infoEn: "Source: Bukhari, Da'awat 8.",
  ),
  Dua(
    title: 'Eve Girerken',
    titleEn: 'Entering the Home',
    arabicText:
        'بِسْمِ اللّٰهِ وَلَجْنَا وَبِسْمِ اللّٰهِ خَرَجْنَا وَعَلَى اللّٰهِ رَبِّنَا تَوَكَّلْنَا',
    transliteration:
        "Bismillaahi walajanaa wa bismillaahi kharajnaa, wa 'alallaahi Rabbinaa tawakkalnaa.",
    turkish:
        "Allah'ın adıyla girdik, Allah'ın adıyla çıkarız. Rabbimiz olan Allah'a tevekkül ettik.",
    english:
        "In the name of Allah we enter, in the name of Allah we leave, and upon Allah our Lord we rely.",
    info: 'Kaynak: Ebû Dâvûd, Edeb 103.',
    infoEn: 'Source: Abu Dawud, Adab 103.',
  ),
  Dua(
    title: 'Evden Çıkarken',
    titleEn: 'Leaving the Home',
    arabicText:
        'بِسْمِ اللّٰهِ تَوَكَّلْتُ عَلَى اللّٰهِ وَلَا حَوْلَ وَلَا قُوَّةَ اِلَّا بِاللّٰهِ',
    transliteration:
        "Bismillaahi tawakkaltu 'alallaahi wa laa hawla wa laa quwwata illaa billaah.",
    turkish:
        "Allah'ın adıyla çıkıyorum. Allah'a tevekkül ettim. Güç ve kuvvet ancak Allah'a aittir.",
    english:
        "In the name of Allah, I put my trust in Allah. There is no might nor power except with Allah.",
    info: 'Kaynak: Ebû Dâvûd, Edeb 103; Tirmizî, Deavât 34.',
    infoEn: "Source: Abu Dawud, Adab 103; Tirmidhi, Da'awat 34.",
  ),
  Dua(
    title: 'Şifa Duası',
    titleEn: 'Healing Prayer',
    arabicText:
        'اَللّٰهُمَّ رَبَّ النَّاسِ اَذْهِبِ الْبَاسَ اِشْفِ اَنْتَ الشَّافِٓي لَا شِفَاءَ اِلَّا شِفَاؤُكَ شِفَاءً لَا يُغَادِرُ سَقَمًا',
    transliteration:
        "Allaahummaa Rabban-naasi adhhib il-ba's. Ishfi Antash-shaafii, laa shifaa'a illaa shifaa'uk. Shifaa'al-laa yughaadiru saqamaa.",
    turkish:
        "Ey insanların Rabbi Allah'ım! Şu hastalığı gider, şifa ver. Şifa veren yalnız sensin. Senin şifandan başka şifa yoktur. Hiçbir hastalık bırakmayan bir şifa ver.",
    english:
        "O Allah, Lord of mankind, remove the harm and grant healing. You are the Healer. There is no healing except Your healing — a healing that leaves no illness behind.",
    info: 'Kaynak: Buhârî, Merdâ 20; Müslim, Selâm 46.',
    infoEn: 'Source: Bukhari, Marda 20; Muslim, Salam 46.',
  ),
  Dua(
    title: 'Sıkıntı Duası (Yunus)',
    titleEn: 'Prayer of Yunus (Hardship)',
    arabicText:
        'لَٓا اِلٰهَ اِلَّٓا اَنْتَ سُبْحَانَكَ اِنِّي كُنْتُ مِنَ الظَّالِمِينَ',
    transliteration:
        "Laa ilaaha illaa Anta subhaanaka innii kuntu minaz-zaalimiin.",
    turkish:
        "Senden başka hiçbir ilah yoktur. Seni eksikliklerden uzak tutarım. Ben gerçekten (nefsine) zulmedenlerden oldum.",
    english:
        "There is no deity except You; exalted are You. Indeed, I have been of the wrongdoers.",
    info: 'Kaynak: Enbiyâ Suresi, 87. ayet; Tirmizî, Deavât 81 · Meal: Diyanet İşleri Başkanlığı.',
    infoEn: "Source: Surah Al-Anbiya, verse 87; Tirmidhi, Da'awat 81.",
  ),
  Dua(
    title: 'Bereket Duası',
    titleEn: 'Blessing Prayer',
    arabicText:
        'اَللّٰهُمَّ اِنِّٓي اَسْئَلُكَ عِلْمًا نَافِعًا وَرِزْقًا طَيِّبًا وَعَمَلًا مُتَقَبَّلًا',
    transliteration:
        "Allaahummaa innii as'aluka 'ilman naafi'an wa rizqan tayyiban wa 'amalan mutaqabbalaa.",
    turkish:
        "Allah'ım! Senden faydalı ilim, temiz rızık ve makbul amel istiyorum.",
    english:
        "O Allah, I ask You for beneficial knowledge, good provision, and accepted deeds.",
    info: 'Kaynak: İbn Mâce, İkâmet 32.',
    infoEn: 'Source: Ibn Majah, Iqamah 32.',
  ),
  Dua(
    title: 'Tövbe Duası',
    titleEn: 'Prayer of Repentance',
    arabicText: 'رَبِّ اِنِّي ظَلَمْتُ نَفْسِي فَاغْفِرْ لِي',
    transliteration: "Rabbi innii zalamtu nafsii faghfir lii.",
    turkish:
        "Rabbim! Şüphesiz ben nefsime zulmettim. Beni affet.",
    english:
        "My Lord, indeed I have wronged myself, so forgive me.",
    info: 'Kaynak: Kasas Suresi, 16. ayet · Meal: Diyanet İşleri Başkanlığı.',
    infoEn: 'Source: Surah Al-Qasas, verse 16.',
  ),
  Dua(
    title: 'Rızık Duası',
    titleEn: 'Prayer for Provision',
    arabicText:
        'اَللّٰهُمَّ اكْفِنِي بِحَلَالِكَ عَنْ حَرَامِكَ وَاَغْنِنِي بِفَضْلِكَ عَمَّنْ سِوَاكَ',
    transliteration:
        "Allaahummakfinii bihalaalika 'an haraamik, wa aghninii bifadlika 'amman siwaak.",
    turkish:
        "Allah'ım! Helalinle beni haramından koru. Lütuf ve ihsanınla beni senden başkasına muhtaç etme.",
    english:
        "O Allah, suffice me with Your lawful provision against Your prohibited, and make me independent of all besides You through Your bounty.",
    info: 'Kaynak: Tirmizî, Deavât 110.',
    infoEn: "Source: Tirmidhi, Da'awat 110.",
  ),
  Dua(
    title: 'Kabir Ziyareti',
    titleEn: 'Graveyard Visitation',
    arabicText:
        'اَلسَّلَامُ عَلَيْكُمْ يَا اَهْلَ الْقُبُورِ يَغْفِرُ اللّٰهُ لَنَا وَلَكُمْ اَنْتُمْ سَلَفُنَا وَنَحْنُ بِالْاَثَرِ',
    transliteration:
        "As-salaamu 'alaykum yaa ahlal-qubuur. Yaghfirul-laahu lanaa wa lakum. Antum salafunaa wa nahnu bil-athar.",
    turkish:
        "Ey kabir ehli! Allah'ın selamı üzerinize olsun. Allah bizi de sizi de bağışlasın. Siz bizden önce geçtiniz, biz de arkanızdan geliyoruz.",
    english:
        "Peace be upon you, O people of the graves. May Allah forgive us and you. You have gone before us and we shall follow.",
    info: 'Kaynak: Tirmizî, Cenâiz 59.',
    infoEn: "Source: Tirmidhi, Jana'iz 59.",
  ),
];
