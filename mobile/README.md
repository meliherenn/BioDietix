# BioDietix Mobile

BioDietix Mobile, kan testi ve alerji bağlamını telefonda saklayan, ürün
barkodlarını tarayan ve kişisel profile göre ürün uygunluğu gösteren Flutter
Android uygulamasıdır.

## Ekran Görüntüleri

| Ana ekran | Raporlar | Ürün tarama |
| --- | --- | --- |
| ![BioDietix ana ekran](../docs/screenshots/biodietix-05-home.png) | ![BioDietix rapor ekranı](../docs/screenshots/biodietix-07-reports.png) | ![BioDietix ürün tarama](../docs/screenshots/biodietix-08-scan.png) |

| Ayarlar | Koyu tema | Türkçe arayüz |
| --- | --- | --- |
| ![BioDietix görünüm ve dil ayarları](../docs/screenshots/biodietix-09-settings-appearance.png) | ![BioDietix koyu tema](../docs/screenshots/biodietix-10-settings-dark.png) | ![BioDietix Türkçe dil](../docs/screenshots/biodietix-11-settings-turkish.png) |

## Özellikler

- Firebase Email/Password ve Google giriş.
- Telefon hafızasında profil, alerji, tema, dil ve son laboratuvar sonucu.
- Türkçe/İngilizce dil desteği.
- Sistem, açık ve koyu tema seçenekleri.
- FastAPI backend üzerinden kan testi PDF analizi.
- Aynı backend üzerinden alerji testi PDF analizi.
- Kamera ile QR/barkod tarama.
- Open Food Facts veya manuel ürün bilgisi ile uygunluk kararı.

## Kullanım Akışı

1. Kullanıcı Firebase hesabıyla giriş yapar.
2. Profil bilgileri, alerjiler ve son laboratuvar sonucu telefonda saklanır.
3. Raporlar ekranından kan testi veya alerji PDF'i yüklenir.
4. Ürün tarama ekranında barkod/QR okutulur veya ürün bilgisi manuel girilir.
5. Uygulama ürünü son sağlık profiline ve alerji bilgisine göre değerlendirir.
6. Ayarlar ekranından dil ve tema anında değiştirilebilir.

## Gereksinimler

- Flutter 3.44+.
- Android SDK ve bağlı cihaz/emülatör.
- Firebase projesinde Email/Password ve Google Authentication.
- Firebase App Check: dev için kayıtlı debug token, prod için Play Integrity.
- Android paket adı: `com.biodietix.biodietix_mobile`.
- `android/app/google-services.json` dosyası.

Firebase Google girişi için Android uygulamasına SHA-1 ve SHA-256 sertifika
parmak izleri eklenmelidir. Firebase ayarları değiştirildikten sonra
`google-services.json` yeniden indirilmelidir.

Geliştirme uygulamasının logunda gösterilen App Check debug token Firebase
Console'a kaydedilmelidir. Üretimde Play Integrity sağlayıcısını etkinleştirin;
backend prod ortamında `X-Firebase-AppCheck` tokenını zorunlu tutar.

## Backend

Uygulama prod build'de varsayılan olarak canlı BioDietix API adresine bağlanır:

```text
https://biodietix-ml.onrender.com
```

Uygulama `/v1` isteklerinde Firebase ID token gönderir. Üretim backend'i anonim
istekleri kabul etmez. Yerel emülatör için `http://10.0.2.2` desteklenir; diğer
uzak adreslerde HTTPS zorunludur.

Yerel backend çalıştırmak için repo kökünde:

```bash
source .venv/bin/activate
BIODIETIX_AUTH_REQUIRED=false uvicorn api:app --host 0.0.0.0 --port 8000
```

Geliştirme build'inde API adresi gerekirse dart define ile ezilebilir:

```bash
flutter run \
  --flavor dev \
  --dart-define=FLAVOR=dev \
  --dart-define=BIODIETIX_API_URL=http://10.0.2.2:8000
```

## Kurulum ve Çalıştırma

```bash
flutter pub get
flutter run --flavor dev --dart-define=FLAVOR=dev
```

Debug APK:

```bash
flutter build apk --debug --flavor dev --dart-define=FLAVOR=dev
```

Release APK:

```bash
flutter build apk --release --flavor prod \
  --dart-define=FLAVOR=prod \
  --dart-define=BIODIETIX_API_URL=https://YOUR_PRODUCTION_API_HOST \
  --dart-define=BIODIETIX_PRIVACY_POLICY_URL=https://YOUR_PUBLIC_PRIVACY_POLICY \
  --dart-define=BIODIETIX_ACCOUNT_DELETION_URL=https://YOUR_PUBLIC_DELETION_PAGE \
  --dart-define=BIODIETIX_SUPPORT_EMAIL=YOUR_MONITORED_SUPPORT_EMAIL \
  --dart-define=BIODIETIX_APP_CHECK_ENABLED=true
```

Prod flavor App Check kapalıyken veya gizlilik/silme/destek bilgileri eksikken
başlatılmaz. App Check kapalı kontrollü testler yalnız dev flavor ile yapılır.

Play Store app bundle:

```bash
flutter build appbundle --release --flavor prod \
  --dart-define=FLAVOR=prod \
  --dart-define=BIODIETIX_API_URL=https://YOUR_PRODUCTION_API_HOST \
  --dart-define=BIODIETIX_PRIVACY_POLICY_URL=https://YOUR_PUBLIC_PRIVACY_POLICY \
  --dart-define=BIODIETIX_ACCOUNT_DELETION_URL=https://YOUR_PUBLIC_DELETION_PAGE \
  --dart-define=BIODIETIX_SUPPORT_EMAIL=YOUR_MONITORED_SUPPORT_EMAIL \
  --dart-define=BIODIETIX_APP_CHECK_ENABLED=true
```

APK çıktıları:

```text
build/app/outputs/flutter-apk/app-dev-debug.apk
build/app/outputs/flutter-apk/app-prod-release.apk
```

Bağlı cihaza kurulum:

```bash
adb install -r build/app/outputs/flutter-apk/app-prod-release.apk
```

## Doğrulama

Bu sürümde aşağıdaki komutlar başarıyla çalıştırıldı:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug --flavor dev --dart-define=FLAVOR=dev
```

Release görevinin `android/key.properties` yokken debug anahtarıyla devam
etmediği doğrulandı. İmzalı release üretimi ve cihaz kurulumu için önce release
keystore'u güvenli biçimde sağlayın.

## Tıbbi Uyarı

BioDietix bir tıbbi cihaz değildir; herhangi bir durumu teşhis, tedavi veya
önleme amacı taşımaz. Çıktılar destekleyici beslenme bilgisidir ve profesyonel
sağlık görüşünün yerine geçmez.

Sağlık profili cihazda platform secure storage anahtarlı şifreli Hive kutusunda
önbelleğe alınır ve oturum açılmış kullanıcı için Firestore ile eşitlenir.
İsteğe bağlı profil fotoğrafı Storage'a yüklenir. Firestore ve Storage erişimi
repo kökündeki UID tabanlı kurallarla sınırlandırılmalı ve yayın öncesi gerçekten
deploy edildiği doğrulanmalıdır.
