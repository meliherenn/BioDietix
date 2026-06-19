# BioDietix

BioDietix; kan testi, beslenme profili, BMI ve alerji bilgilerini birlikte
değerlendirerek kişiye özel beslenme önerileri ve market ürünü uygunluk
kararları üreten Python + Flutter tabanlı bir öğrenci projesidir.

Proje; Streamlit web arayüzü, FastAPI mobil backend'i ve Firebase Auth kullanan
Flutter Android uygulamasından oluşur. Mobil uygulama kullanıcının son sağlık
profilini telefonda saklar, ürün barkodu/QR değeriyle market ürününü bulur ve
kan testi, BMI, alerji ve besin etiketi sinyallerine göre karar üretir.

> BioDietix tıbbi tanı veya tedavi aracı değildir. Çıktılar eğitim/proje amaçlı
> destekleyici bilgi olarak değerlendirilmelidir.

## İçindekiler

- [Ekran Görüntüleri](#ekran-görüntüleri)
- [Özellikler](#özellikler)
- [Teknoloji Yığını](#teknoloji-yığını)
- [Proje Yapısı](#proje-yapısı)
- [Hızlı Başlangıç](#hızlı-başlangıç)
- [Mobil Uygulama Kurulumu](#mobil-uygulama-kurulumu)
- [API Endpointleri](#api-endpointleri)
- [Kullanım Akışı](#kullanım-akışı)
- [Veri ve Model Notları](#veri-ve-model-notları)
- [Doğrulama](#doğrulama)

## Ekran Görüntüleri

### İlk Açılış ve Giriş

| Onboarding | Giriş |
| --- | --- |
| ![BioDietix onboarding başlangıcı](docs/screenshots/biodietix-01-start.png) | ![BioDietix Firebase giriş ekranı](docs/screenshots/biodietix-04-auth.png) |

### Uygulama İçi Ekranlar

| Ana ekran | Raporlar |
| --- | --- |
| ![BioDietix ana ekran](docs/screenshots/biodietix-05-home.png) | ![BioDietix rapor yükleme ekranı](docs/screenshots/biodietix-07-reports.png) |

| Ürün tarama | Ürün kontrol tanıtımı |
| --- | --- |
| ![BioDietix ürün tarama ekranı](docs/screenshots/biodietix-08-scan.png) | ![BioDietix ürün kontrolü onboarding ekranı](docs/screenshots/biodietix-03-product-check.png) |

### Tema ve Dil

| Ayarlar | Koyu tema | Türkçe arayüz |
| --- | --- | --- |
| ![BioDietix görünüm ve dil ayarları](docs/screenshots/biodietix-09-settings-appearance.png) | ![BioDietix koyu tema ayarı](docs/screenshots/biodietix-10-settings-dark.png) | ![BioDietix Türkçe dil ayarı](docs/screenshots/biodietix-11-settings-turkish.png) |

| Türkçe + koyu tema |
| --- |
| ![BioDietix Türkçe koyu tema ana ekranı](docs/screenshots/biodietix-12-home-turkish-dark.png) |

## Özellikler

- CSV veya PDF kan testi analizinden sağlık profili üretimi.
- Glukoz, HbA1c, lipid, tansiyon, böbrek, karaciğer, vitamin/mineral, yaş ve BMI
  sinyallerine göre risk değerlendirmesi.
- `Health_Profile`, `Nutrition_Recommendation`, `Foods_To_Increase` ve
  `Foods_To_Limit` çıktıları.
- e-Nabız benzeri PDF raporlarından desteklenen laboratuvar alanlarını çıkarma.
- Alerji PDF'i veya manuel alerji bilgisiyle ürün uygunluğu kontrolü.
- Open Food Facts barkod araması ve manuel ürün etiketi girişi.
- Ürün kararları: `recommended`, `use_with_caution`, `not_recommended`.
- Streamlit web arayüzünde CSV/PDF analizi ve ML audit görünümü.
- FastAPI ile mobil uygulamaya analiz ve ürün kontrol servisleri.
- Firebase Email/Password ve Google ile mobil giriş.
- Telefonda profil, alerji, tema, dil ve son test sonucu saklama.
- Türkçe/İngilizce arayüz.
- Sistem/açık/koyu tema seçenekleri.

## Teknoloji Yığını

| Katman | Teknoloji |
| --- | --- |
| Analiz çekirdeği | Python, pandas, scikit-learn |
| Web arayüzü | Streamlit |
| Mobil backend | FastAPI, Uvicorn |
| Mobil uygulama | Flutter, Dart, Material 3 |
| Kimlik doğrulama | Firebase Auth, Google Sign-In |
| Mobil veri saklama | Hive, Firebase servisleri |
| Ürün verisi | Open Food Facts |
| Test | Flutter test, Python unittest |

## Proje Yapısı

```text
.
├── app.py                         # Streamlit web arayüzü
├── api.py                         # FastAPI mobil backend
├── biodietix.py                   # Ana analiz ve öneri motoru
├── requirements.txt               # Python bağımlılıkları
├── utils/
│   ├── biodietix_web.py           # Web/PDF/CSV yardımcıları
│   ├── biodietix_audit.py         # Veri kalitesi ve ML audit
│   ├── food_recommendation_guide.py
│   └── mobile_health_core.py      # Mobil profil ve ürün kararı çekirdeği
├── data/food_recommendations.csv  # Gıda öneri rehberi
├── mobile/                        # Flutter Android uygulaması
├── docs/screenshots/              # README görselleri
└── tests/                         # Python ürün değerlendirme testleri
```

## Hızlı Başlangıç

Python ortamını hazırlayın:

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

Streamlit web arayüzünü başlatın:

```bash
streamlit run app.py
```

FastAPI backend'i başlatın:

```bash
uvicorn api:app --reload --host 0.0.0.0 --port 8000
```

Canlı mobil API varsayılanı:

```text
https://biodietix-ml.onrender.com
```

## Mobil Uygulama Kurulumu

Gereksinimler:

- Flutter 3.44+ ve Dart 3.12+.
- Android SDK.
- Çalışan Android cihaz veya emülatör.
- Firebase projesinde Email/Password ve Google Authentication.
- Android paket adı: `com.biodietix.biodietix_mobile`.
- Firebase dosyası: `mobile/android/app/google-services.json`.

Firebase Google girişi için Firebase Console'da Android uygulamasına SHA-1 ve
SHA-256 sertifika parmak izleri eklenmelidir. Provider veya sertifika değişirse
`google-services.json` yeniden indirilip `mobile/android/app/` altına
konulmalıdır.

Bağımlılıkları kurun:

```bash
cd mobile
flutter pub get
```

Geliştirme modunda çalıştırın:

```bash
flutter run --flavor dev --dart-define=FLAVOR=dev
```

Yerel backend kullanmak için Android emülatörde `10.0.2.2` adresini kullanın:

```bash
flutter run \
  --flavor dev \
  --dart-define=FLAVOR=dev \
  --dart-define=BIODIETIX_API_URL=http://10.0.2.2:8000
```

Release APK üretin:

```bash
flutter build apk --release --flavor prod --dart-define=FLAVOR=prod
```

APK çıktısı:

```text
mobile/build/app/outputs/flutter-apk/app-prod-release.apk
```

Bağlı cihaza kurulum:

```bash
adb install -r mobile/build/app/outputs/flutter-apk/app-prod-release.apk
```

Play Store için App Bundle:

```bash
flutter build appbundle --release --flavor prod --dart-define=FLAVOR=prod
```

## API Endpointleri

| Method | Endpoint | Açıklama |
| --- | --- | --- |
| `GET` | `/health` | API sağlık kontrolü |
| `POST` | `/analyze/blood-pdf` | Kan testi PDF analizinden profil üretir |
| `POST` | `/analyze/allergy-pdf` | Alerji PDF metninden alerji sinyalleri çıkarır |
| `GET` | `/product/lookup/{barcode}` | Barkodu Open Food Facts üzerinden arar |
| `POST` | `/product/evaluate` | Ürünü son profil ve alerji bilgisine göre değerlendirir |

## Kullanım Akışı

### Web

1. Streamlit arayüzü açılır.
2. Varsayılan CSV, kullanıcı CSV'i veya PDF raporu seçilir.
3. Gerekirse kilo ve boy girilerek BMI hesaplanır.
4. Analiz çalıştırılır.
5. Sağlık profili, öneriler, artırılacak/sınırlandırılacak besinler ve ML audit
   metrikleri incelenir.
6. Sonuçlar CSV olarak indirilebilir.

### Mobil

1. Kullanıcı Firebase hesabıyla giriş yapar.
2. Profil ekranında yaş, boy, kilo, BMI ve alerji bilgileri tutulur.
3. Kan testi PDF'i yüklendiğinde FastAPI servisi raporu analiz eder.
4. Son sağlık profili telefonda saklanır ve sonraki ürün kontrollerinde kullanılır.
5. Kullanıcı ürün barkodu/QR değeri tarar veya ürün bilgisini manuel girer.
6. BioDietix alerji, BMI, kan testi profili, şeker, doymuş yağ, tuz/sodyum, lif
   ve protein sinyallerine göre ürün kararını gösterir.
7. Ayarlar ekranından dil ve tema anında değiştirilebilir.

## Veri ve Model Notları

Temel CSV alanlarından bazıları:

```text
Gender, Glucose_mgdL, HbA1c_Percent, BMI veya Weight_kg + Height_cm,
Waist_Circumference_cm, BP_Systolic_mmHg, BP_Diastolic_mmHg,
Cholesterol_Total_mgdL, Cholesterol_LDL_mgdL, Triglycerides_mgdL,
Kidney_Creatinine_mgdL, Hemoglobin_gdL, Liver_AST_UL, Daily_Fiber_g,
Daily_Sugar_g, Daily_Fat_g, Daily_Cholesterol_mg
```

Desteklenen ek PDF alanlarından bazıları:

```text
Cholesterol_HDL_mgdL, Liver_ALT_UL, eGFR_ml_min_1_73m2, CRP_mg_L,
Ferritin_ng_mL, Folate_ng_mL, Vitamin_B12_pg_mL, VitaminD_ng_mL,
Iron_ugdL, Calcium_mg_dL, Magnesium_mg_dL, Free_T3_pg_mL, Free_T4_ng_dL
```

`Health_Profile` alanı, kural tabanlı risk motoru tarafından üretilen
denetlenebilir bir pseudo-label olarak kullanılır. ML audit bölümü bu etiket
üzerinden hızlı bir baseline eğitim akışı sunar:

- Ham biyokimyasal ve beslenme özellikleri seçilir.
- Eksik değerler pipeline içinde tamamlanır.
- Nadir profil kombinasyonları `Other Profile` altında gruplanır.
- Random Forest ve Gradient Boosting modelleri eğitilir.
- Accuracy, precision, recall, F1 ve RMSE-style label index metriği gösterilir.

## Ürün Kararı Mantığı

`utils/mobile_health_core.py` içindeki ürün değerlendirme akışı şu sinyalleri
birlikte kullanır:

- Alerjen eşleşmeleri.
- Kan şekeri riski ve ürün şekeri.
- Kilo/BMI ve enerji yoğunluğu.
- Tuz/sodyum ve tansiyon riski.
- Doymuş yağ, lif ve protein sinyalleri.
- Ürün veri kalitesi ve eksik etiket bilgisi.

Eksik ürün verisi doğrudan ağır cezalandırılmaz; veri kalitesi düşükse karar ve
gerekçeler kullanıcıya daha temkinli gösterilir.

## Doğrulama

Bu sürümde çalıştırılan kontroller:

```bash
cd mobile
flutter pub get
flutter analyze
flutter test
flutter build apk --debug --flavor dev --dart-define=FLAVOR=dev
flutter build apk --release --flavor prod --dart-define=FLAVOR=prod
adb install build/app/outputs/flutter-apk/app-prod-release.apk

cd ..
python -m unittest discover -s tests -v
```

Flutter build sırasında Android/Kotlin Gradle Plugin kullanımı için gelecek
Flutter sürümlerine yönelik uyarı alınmıştır. Uyarı mevcut build'i engellemez;
ileride Flutter'ın Built-in Kotlin geçiş rehberine göre güncelleme yapılmalıdır.

Yerel Python ortamında `pytest` paketi kurulu olmadığı için
`python -m pytest -q` çalıştırılamadı; Python testleri standart `unittest` ile
doğrulandı.

## Lisans ve Uyarı

Bu proje eğitim ve sunum amaçlıdır. Sağlıkla ilgili kararlar için yetkili sağlık
profesyonellerine danışılmalıdır.
