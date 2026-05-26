# Codemagic Kurulum Adımları

## 1. GitHub'a Push Et

```bash
cd D:\sesli_tesbih   # flutter create sonrası oluşacak klasör
git init
git add .
git commit -m "Initial Flutter project"
git remote add origin https://github.com/KULLANICI_ADIN/sesli-tesbih-flutter.git
git push -u origin main
```

---

## 2. Codemagic'e Bağlan

1. https://codemagic.io adresine git
2. "Add application" → GitHub repo'nu seç
3. "sesli_tesbih" reposunu seç
4. Build config: **"Flutter App"** → **"codemagic.yaml"** seç

---

## 3. App Store Connect API Key Oluştur

Apple Developer hesabında:
1. https://appstoreconnect.apple.com/access/integrations/api
2. "Generate API Key" tıkla
3. Name: Codemagic, Role: **App Manager**
4. `.p8` dosyasını indir (sadece bir kez indirilir!)
5. **Key ID** ve **Issuer ID**'yi not al

---

## 4. Codemagic'te Environment Variables Ayarla

Codemagic dashboard → Proje → Environment variables → **"app_store_credentials"** adında grup oluştur:

| Variable Adı | Değer | Secure |
|---|---|---|
| `APP_STORE_CONNECT_PRIVATE_KEY` | `.p8` dosyasının tüm içeriği | ✅ Yes |
| `APP_STORE_CONNECT_KEY_IDENTIFIER` | Key ID (örn: ABC123DEFG) | ✅ Yes |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID (UUID formatı) | ✅ Yes |

---

## 5. iOS Signing (Codemagic Otomatik)

Codemagic dashboard → Proje → **iOS code signing**:
1. **Distribution certificate** oluştur veya mevcut olanı yükle
2. **Provisioning profile**: Codemagic API key ile otomatik oluşturabilir
3. Bundle ID: `com.sesliTesbih.app`

Veya **Automatic signing** seçeneğini kullanabilirsin — Codemagic API key yeterlidir.

---

## 6. App Store Connect'te Uygulama Oluştur (Önceden yapılmalı)

1. https://appstoreconnect.apple.com → "My Apps" → "+"
2. Platform: iOS
3. Name: **Sesli Tesbih**
4. Primary Language: **Turkish**
5. Bundle ID: **com.sesliTesbih.app** (register edilmemiş ise önce developer.apple.com'da kaydet)
6. SKU: sesli-tesbih-001
7. Create

---

## 7. Build Başlat

Codemagic dashboard'da **"Start new build"** → branch: `main` → **Build**

İlk build ~15-20 dakika sürer (CocoaPods + Xcode).

---

## 8. TestFlight → App Store

Build başarılı olunca:
- `codemagic.yaml`'da `submit_to_testflight: true` olduğu için TestFlight'a otomatik yüklenir
- App Store Connect → TestFlight → Testi yap
- Hazır olunca: App Store → Submit for Review

---

## App Store Listing (dolduracakların)

**App Information:**
- Name: Sesli Tesbih
- Subtitle: Sesli İslami Zikir Sayacı  
- Category: Reference
- Age Rating: 4+
- Privacy Policy URL: Bir gizlilik politikası web sayfası gerekli (Google Sites, Notion vs. kullanabilirsin)

**Açıklama:**
```
Sesli Tesbih, sesinizi tanıyarak otomatik zikir sayan İslami bir uygulamadır.

ÖZELLİKLER:
• Sesli Zikir Sayma — Mikrofonla otomatik sayar
• 21 Zikir — Sübhanallah, Elhamdülillah, Allahu Ekber ve daha fazlası
• Özel Zikir — Kendi zikirlerinizi ekleyin
• Namaz Vakitleri — GPS ile konum bazlı hesaplama
• Kıble Yönü — Pusula ile anlık yön gösterimi
• Dualar & Sureler — 23 dua ve sure
• 3 Dil — Türkçe, İngilizce, Arapça
• Gizlilik Odaklı — Ses kaydedilmez, sunucuya veri gönderilmez
```

**Keywords (100 karakter):**
```
tesbih,zikir,namaz,kıble,dua,allah,islam,sesli,sayaç,subhanallah
```

**Screenshots:**
- iPhone 6.7": 1290×2796 (gerekli)
- iPhone 6.5": 1242×2688 (gerekli)
- Simulator'da çalıştırıp al: `flutter run` → Simulator → File → Save Screen
