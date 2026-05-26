# Sesli Tesbih Flutter Proje Kurulum Scripti
# flutter create sonrasında bu scripti çalıştır

param(
    [string]$ProjectDir = "D:\sesli_tesbih"
)

Write-Host "=== Sesli Tesbih Flutter Kurulum ===" -ForegroundColor Green

# 1. lib/ klasörünü kopyala
Write-Host "lib/ klasörü kopyalanıyor..."
Copy-Item "D:\SesliTesbihFlutter\lib" -Destination "$ProjectDir\" -Recurse -Force

# 2. pubspec.yaml'ı değiştir
Write-Host "pubspec.yaml kopyalanıyor..."
Copy-Item "D:\SesliTesbihFlutter\pubspec.yaml" -Destination "$ProjectDir\pubspec.yaml" -Force

# 3. codemagic.yaml kopyala
Write-Host "codemagic.yaml kopyalanıyor..."
Copy-Item "D:\SesliTesbihFlutter\codemagic.yaml" -Destination "$ProjectDir\codemagic.yaml" -Force

# 4. .gitignore kopyala
Write-Host ".gitignore kopyalanıyor..."
Copy-Item "D:\SesliTesbihFlutter\.gitignore" -Destination "$ProjectDir\.gitignore" -Force

# 5. iOS Info.plist izinleri ekle
Write-Host "iOS Info.plist izinleri ekleniyor..."
$plistPath = "$ProjectDir\ios\Runner\Info.plist"
if (Test-Path $plistPath) {
    $plist = Get-Content $plistPath -Raw

    $permissionsToAdd = @"
	<key>NSMicrophoneUsageDescription</key>
	<string>Sesli tesbih sayımı için mikrofon gereklidir. Ses verisi kaydedilmez.</string>
	<key>NSSpeechRecognitionUsageDescription</key>
	<string>Zikir kelimelerini tanımak için ses tanıma kullanılır.</string>
	<key>NSLocationWhenInUseUsageDescription</key>
	<string>Namaz vakitleri ve kıble yönü hesaplamak için konum gereklidir.</string>
	<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
	<string>Namaz vakitleri ve kıble yönü hesaplamak için konum gereklidir.</string>
"@

    # Insert before </dict> closing tag
    $plist = $plist -replace '</dict>\s*</plist>', "$permissionsToAdd`n</dict>`n</plist>"
    Set-Content $plistPath $plist -Encoding UTF8
    Write-Host "Info.plist güncellendi." -ForegroundColor Green
} else {
    Write-Host "UYARI: Info.plist bulunamadı: $plistPath" -ForegroundColor Yellow
}

# 6. flutter pub get
Write-Host "flutter pub get çalıştırılıyor..."
Set-Location $ProjectDir
& flutter pub get

# 7. git init
Write-Host "Git repo başlatılıyor..."
git init
git add .
git commit -m "Initial commit: Sesli Tesbih Flutter iOS"

Write-Host ""
Write-Host "=== KURULUM TAMAMLANDI ===" -ForegroundColor Green
Write-Host ""
Write-Host "Sıradaki adımlar:" -ForegroundColor Cyan
Write-Host "1. GitHub'da yeni repo oluştur: sesli-tesbih-flutter"
Write-Host "2. git remote add origin https://github.com/KULLANICI_ADIN/sesli-tesbih-flutter.git"
Write-Host "3. git push -u origin main"
Write-Host "4. codemagic.io → Add Application → GitHub reposunu seç"
Write-Host "5. CODEMAGIC_KURULUM.md dosyasını takip et"
