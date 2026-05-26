# Sesli Tesbih — Flutter → App Store Kurulum Talimatları

## Ön Koşullar
- Mac bilgisayar (iOS build için zorunlu)
- Xcode 15+ kurulu
- Apple Developer hesabı (aktif — $99/yıl)
- Flutter SDK kurulu

---

## ADIM 1: Flutter SDK Kurulumu (Windows'ta geliştirme)

1. https://flutter.dev/docs/get-started/install/windows adresine git
2. Flutter SDK'yı indir ve `C:\flutter` klasörüne çıkart
3. `C:\flutter\bin` klasörünü PATH'e ekle
4. PowerShell'de: `flutter doctor` çalıştır — tüm checkmark yeşil olana kadar düzelt

## ADIM 2: Flutter Projesi Oluştur

PowerShell'de bu komutları çalıştır:

```powershell
cd D:\
flutter create sesli_tesbih --org com.sesliTesbih --project-name sesli_tesbih
```

Sonra D:\SesliTesbihFlutter'daki tüm dosyaları kopyala:
```powershell
# lib/ klasörünü komple kopyala
Copy-Item "D:\SesliTesbihFlutter\lib" -Destination "D:\sesli_tesbih\" -Recurse -Force
# pubspec.yaml'ı değiştir
Copy-Item "D:\SesliTesbihFlutter\pubspec.yaml" -Destination "D:\sesli_tesbih\" -Force
```

## ADIM 3: Bağımlılıkları Yükle

```powershell
cd D:\sesli_tesbih
flutter pub get
```

Eğer `adhan_dart` bulunamazsa pubspec.yaml'da şu satırı değiştir:
```yaml
# adhan_dart: ^1.0.1   # bunu yorum yap
adhan: ^1.0.0           # bunu dene
```
Ve `prayer_times_screen.dart` dosyasındaki import satırını güncelle.

---

## ADIM 4: iOS Info.plist İzinleri (Mac'te Xcode ile)

Projeyi Mac'e kopyala ve terminalde:
```bash
cd sesli_tesbih
flutter pub get
open ios/Runner.xcworkspace   # Xcode açılır
```

Xcode'da `ios/Runner/Info.plist` dosyasını aç ve `<dict>` içine ekle:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Sesli tesbih sayımı için mikrofon gereklidir. Ses verisi kaydedilmez.</string>

<key>NSSpeechRecognitionUsageDescription</key>
<string>Zikir kelimelerini tanımak için ses tanıma kullanılır.</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>Namaz vakitleri ve kıble yönü hesaplamak için konum gereklidir.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Namaz vakitleri ve kıble yönü hesaplamak için konum gereklidir.</string>
```

---

## ADIM 5: Bundle ID ve Signing Ayarları (Xcode)

1. Xcode'da sol panelde `Runner` projesine tıkla
2. `Signing & Capabilities` sekmesine geç
3. **Team**: Apple Developer hesabını seç
4. **Bundle Identifier**: `com.sesliTesbih.app` yaz
5. Automatically manage signing: ✅ açık

---

## ADIM 6: App Icon Hazırla

1. 1024×1024 PNG app ikonu hazırla (şeffaf arkaplan olmamalı)
2. https://appicon.co adresine yükle → iOS set'ini indir
3. `Assets.xcassets/AppIcon.appiconset/` klasörüne kopyala

Veya Flutter ile:
```bash
flutter pub add flutter_launcher_icons --dev
```
pubspec.yaml'a ekle:
```yaml
flutter_launcher_icons:
  ios: true
  image_path: "assets/icon.png"
```

---

## ADIM 7: Release Build Al

Mac terminalde:
```bash
flutter build ipa --release
```

Veya Xcode'da: Product → Archive → Distribute App → App Store Connect

---

## ADIM 8: App Store Connect'te Uygulama Oluştur

1. https://appstoreconnect.apple.com adresine git
2. "My Apps" → "+" → "New App"
3. Şunları doldur:
   - **Name**: Sesli Tesbih
   - **Primary Language**: Turkish
   - **Bundle ID**: com.sesliTesbih.app (önceden oluşturulmuş olmalı)
   - **SKU**: sesli-tesbih-001
4. "Create" tıkla

---

## ADIM 9: App Store Listing Bilgileri

**App Information:**
- Name: Sesli Tesbih
- Subtitle: Sesli İslami Zikir Sayacı
- Category: Reference (veya Lifestyle)
- Content Rating: 4+
- Privacy Policy URL: Gizlilik metni için bir web sayfası gerekli

**Açıklama (TR):**
```
Sesli Tesbih, sesinizi tanıyarak otomatik zikir sayan İslami bir uygulamadır.

ÖZELLİKLER:
• Sesli Zikir Sayma — Mikrofonla otomatik sayar
• 21 Zikir — Sübhanallah, Elhamdülillah, Allahu Ekber ve daha fazlası
• Özel Zikir — Kendi zikirlerinizi ekleyin
• Namaz Vakitleri — GPS ile konum bazlı
• Kıble Yönü — Pusula ile anlık gösterim
• Dualar & Sureler — Ayetel Kürsi, Fatiha ve daha fazlası
• 3 Dil — Türkçe, İngilizce, Arapça
• Gizlilik Odaklı — Ses kaydedilmez, sunucuya veri gönderilmez
```

**Keywords (100 karakter):**
```
tesbih,zikir,namaz,kıble,dua,allah,islam,sesli,sayaç,subhanallah
```

---

## ADIM 10: Screenshots (Ekran Görüntüleri)

Gerekli boyutlar:
- iPhone 6.7" (iPhone 14 Pro Max): 1290×2796
- iPhone 6.5" (iPhone 11 Pro Max): 1242×2688
- iPhone 5.5" (iPhone 8 Plus): 1242×2208

Simulator'da çalıştırıp screenshot al:
```bash
flutter run --release   # Simulator'da çalıştır
# Xcode Simulator → File → Save Screen
```

---

## ADIM 11: Build'i Yükle

```bash
xcrun altool --upload-app -f build/ios/ipa/*.ipa -t ios \
  -u apple@email.com -p @keychain:app-specific-password
```

Veya Xcode Organizer'dan: Window → Organizer → Distribute App

---

## ADIM 12: İncelemeye Gönder

App Store Connect'te:
1. "App Store" sekmesi
2. Yüklenen build'i seç
3. Tüm bilgileri tamamla (rating, pricing: Free)
4. "Submit for Review" tıkla
5. İnceleme süresi: 1-3 gün

---

## NOTLAR

### adhan_dart Paketi Sorunu
Eğer `adhan_dart` bulunamazsa `prayer_times_screen.dart` dosyasında şu değişikliği yap:
```dart
// Şu satırı değiştir:
import 'package:adhan_dart/adhan_dart.dart';
// Buna:
import 'package:adhan/adhan.dart';
```
Ve pubspec.yaml'da paketi güncelle.

### speech_to_text Türkçe Desteği
İlk çalıştırmada iOS Türkçe dil paketini indirecektir. 
Kullanıcıya şunu bildirmeniz gerekebilir: Settings → General → Keyboard → Türkçe ekle.

### flutter_compass Sensör
iOS'ta compass için "Always" konum iznine gerek yoktur; "When In Use" yeterlidir.
