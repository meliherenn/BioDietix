# BioDietix Mobile

BioDietix Mobile, kan testi ve alerji bağlamını telefonda saklayan, ürün
barkodlarını tarayan ve kişisel profile göre ürün uygunluğu gösteren Flutter
Android uygulamasıdır.

## Özellikler

- Firebase Email/Password ve Google giriş.
- Telefon hafızasında profil, alerji, tema, dil ve son laboratuvar sonucu.
- Türkçe/İngilizce dil desteği.
- Sistem, açık ve koyu tema seçenekleri.
- FastAPI backend üzerinden kan testi PDF analizi.
- Aynı backend üzerinden alerji testi PDF analizi.
- Kamera ile QR/barkod tarama.
- Open Food Facts veya manuel ürün bilgisi ile uygunluk kararı.

## Gereksinimler

- Flutter 3.44+.
- Android SDK ve bağlı cihaz/emülatör.
- Firebase projesinde Email/Password ve Google Authentication.
- Android paket adı: `com.biodietix.biodietix_mobile`.
- `android/app/google-services.json` dosyası.

Firebase Google girişi için Android uygulamasına SHA-1 ve SHA-256 sertifika
parmak izleri eklenmelidir. Firebase ayarları değiştirildikten sonra
`google-services.json` yeniden indirilmelidir.

## Backend

Uygulama prod build'de varsayılan olarak canlı BioDietix API adresine bağlanır:

```text
https://biodietix-ml.onrender.com
```

Yerel backend çalıştırmak için repo kökünde:

```bash
source .venv/bin/activate
uvicorn api:app --host 0.0.0.0 --port 8000
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
flutter build apk --release --flavor prod --dart-define=FLAVOR=prod
```

Play Store app bundle:

```bash
flutter build appbundle --release --flavor prod --dart-define=FLAVOR=prod
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
flutter build apk --release --flavor prod --dart-define=FLAVOR=prod
adb install build/app/outputs/flutter-apk/app-prod-release.apk
```

Flutter, mevcut Android/Kotlin Gradle plugin kullanımı için gelecek sürümlere
yönelik uyarı veriyor. Bu uyarı mevcut build'i engellemedi; ileride Flutter'ın
Built-in Kotlin geçiş rehberine göre güncelleme yapılmalıdır.

## Tıbbi Uyarı

BioDietix çıktıları eğitim/proje amaçlıdır. Tanı, tedavi veya profesyonel sağlık
görüşünün yerine geçmez.
