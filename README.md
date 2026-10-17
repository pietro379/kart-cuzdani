# Kart Cüzdanı

[![CI](https://github.com/pietro379/kart-cuzdani/actions/workflows/ci.yml/badge.svg)](https://github.com/pietro379/kart-cuzdani/actions/workflows/ci.yml)
![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?logo=dart&logoColor=white)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS-3ddc84)
![Çevrimdışı](https://img.shields.io/badge/%C3%A7al%C4%B1%C5%9Fma-%C3%A7evrimd%C4%B1%C5%9F%C4%B1-10b981)

KVKK uyumlu, tamamen çevrimdışı çalışan ve tüm verileri cihazda şifreli saklayan
kredi/banka kartı cüzdanı. Flutter ile Android ve iOS için geliştirilmiştir.

> Uygulama hiçbir veriyi internete göndermez. Release sürümünde ağ erişim izni
> bulunmaz.

<!-- Ekran görüntüleri: docs/screenshots/ altına ekleyip burada tablo olarak göster (kart yığını, 3B çevirme, kart ekleme, ayarlar). -->

## Öne çıkanlar

- **Gizlilik tasarımın merkezinde:** Release manifest'te `INTERNET` izni yok, kart verisi PIN doğrulanmadan belleğe bile yüklenmez.
- **Gerçek güvenlik pratikleri:** Tuzlu PBKDF2 ile PIN türetme, Keystore/Keychain destekli şifreli depolama, kaba kuvvet kilidi, ekran görüntüsü koruması.
- **Zengin arayüz:** Üst üste binen kart yığını, 3B kart çevirme, canlı önizlemeli kart ekleme, açık/koyu tema.
- **Test edilebilir yapı:** PIN servisi, doğrulayıcılar, depolama, ayarlar ve ekran akışları için birim ve widget testleri; her push'ta CI'da çalışır.

## Özellikler

- **PIN ile kilit:** 6 haneli PIN; uygulama her açılışta ve arka plana
  alındığında kilitlenir. Kolay tahmin edilen PIN'ler (111111, 123456…) reddedilir.
- **Kaba kuvvet koruması:** Art arda 5 hatalı denemede giriş 30 saniye kilitlenir;
  kilit, uygulama kapatılıp açılsa da devam eder.
- **Kartlarım:** Üst üste binen, kaydırılarak gezilen kart yığını. Öndeki karta
  dokununca kart 3B olarak çevrilir; arka yüzde CVV ve (varsa) kart şifresi yer alır.
- **Basılı tut, göster:** Göz butonuna basılı tutulduğu sürece öndeki kartın
  gizlenmiş bilgileri görünür, bırakılınca tekrar gizlenir.
- **Kart Ekle:** Canlı önizleme, kart rengi ve desen rengi için ayrı paletler
  (gradyan + düz renkler), Luhn kontrolü, son kullanma tarihi ve CVV doğrulaması.
- **Ayarlar:** Profil adı, koyu/açık tema, kart bilgilerini gizleme ve
  tüm verileri kalıcı olarak silme.

## Güvenlik

| Konu | Uygulama |
| --- | --- |
| Veri saklama | `flutter_secure_storage` — Android'de Keystore + AES-GCM, iOS'ta Keychain (`unlocked_this_device`, iCloud'a senkronize edilmez) |
| PIN | Düz metin saklanmaz; rastgele tuzlu PBKDF2-HMAC-SHA256 (100.000 tur) |
| Bellek | Kart verileri PIN doğrulanmadan belleğe yüklenmez |
| Ekran | Android'de `FLAG_SECURE`; iOS'ta ekran görüntüsü/kayıt ve uygulama değiştirici koruması |
| Yedekleme | Android bulut yedeği ve cihazdan cihaza aktarım kapalı |
| Klavye | Kart alanlarında öneriler ve klavye öğrenmesi kapalı |
| Ağ | Release manifest'te `INTERNET` izni yok |

## Gereksinimler

- Flutter 3.47+ (Dart 3.13+)
- Android: Android Studio, Android SDK 36, NDK 28.2
- iOS: macOS + Xcode (iOS 15+)

## Çalıştırma

```bash
flutter pub get
flutter run
```

Release APK:

```bash
flutter build apk --release
```

## Testler

```bash
flutter analyze
flutter test
```

Birim ve widget testleri; PIN servisi, özetleme, doğrulayıcılar, kart modeli,
depolama, ayarlar ve tüm ekran akışlarını kapsar. GitHub Actions her push ve
pull request'te analiz ve testleri çalıştırır.

## Proje yapısı

```
lib/
  main.dart, app.dart     Uygulama girişi ve kilit akışı
  app_scope.dart          Servis ve durumların ekranlara aktarımı
  models/                 Kart modeli
  services/               Şifreli depolama, PIN, kart deposu
  state/                  Ayarlar ve kart listesi durumu
  theme/                  Renkler, temalar, kart renk paletleri
  utils/                  Biçimlendirme ve doğrulama yardımcıları
  widgets/                Kart görünümleri, kart yığını, PIN bileşenleri
  screens/                Kilit, PIN kurulumu ve ana sekmeler
tool/
  icon/                   Uygulama ikonu üreticisi
  dev_live.ps1            Emülatörde otomatik yeniden yüklemeli geliştirme
```

## Uygulama ikonu

İkonlar ek bir paket gerektirmeden Flutter'ın çizim motoruyla üretilir:

```bash
flutter test tool/icon/generate_icons_test.dart
```

Android (adaptif + temalı ikon dahil) ve iOS için tüm boyutlar yeniden oluşturulur.
