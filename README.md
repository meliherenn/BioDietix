# BioDietix ML

BioDietix ML, beslenme ve saglik profili verilerinden risk seviyeleri ve
beslenme onerileri ureten Python tabanli bir ogrenci projesidir. Proje; NHANES
benzeri CSV veri setlerini, temel laboratuvar degerlerini ve PDF raporlardan
cikarilabilen bazi test sonuclarini kullanarak `Health_Profile`,
`Nutrition_Recommendation`, `Foods_To_Increase` ve `Foods_To_Limit` alanlarini
olusturur. ENG4001 proje formundaki hedefe uygun olarak veri on isleme,
feature selection, Random Forest / Gradient Boosting tabanli model denetimi ve
performans metrikleri de web arayuzunde gosterilir.

Ek olarak `Biodietix-Food Recommendations.xlsx` icindeki gida bazli oneriler
tasınabilir `data/food_recommendations.csv` rehberine donusturulmustur. Bu
rehber mevcut kural tabanli motoru bozmadan onerileri zenginlestirir; ornegin
yuksek glukoz/HbA1c, dusuk lif, yuksek LDL/trigliserid, hipertansiyon,
karaciger enzimi ve obezite risklerinde artirilacak ve sinirlandirilacak
besinleri daha acik gosterir.

Son guncellemede yas bilgisi de modele dahil edilmistir. `Age_Group` ve
`Age_Risk_Level` alanlari uretilir; oneriler genc yetiskin, yetiskin, orta yas
ve ileri yas beslenme odaklarina gore zenginlestirilir. PDF raporlarinda
cinsiyet, dogum tarihi ve rapor tarihi bulunursa yas otomatik hesaplanir.

Kilo ve boy da modele entegre edilmistir. PDF analizinde arayuz kullanicidan
`Weight_kg` ve `Height_cm` alir, `BMI` otomatik hesaplanir ve kilo yonetimi
profili/onerileri buna gore uretilir. CSV analizinde `BMI` kolonu yoksa
`Weight_kg` + `Height_cm` kolonlari kullanilarak BMI tamamlanir.

Mobil uygulama hedefi icin proje cekirdegine kullanici profil hafizasi, alerji
bilgisi ve urun uygunluk kontrolu de eklenmistir. Kullanici kan testi/PDF
analizinden sonra uretilen son profil; saglik profili, oneriler, risk seviyeleri,
boy/kilo/BMI ve alerji bilgisini tek bir JSON uyumlu nesnede toplar. Bu nesne
mobil uygulamada Firebase Auth ile giris yapan kullanicinin telefonunda
saklanabilir. Market urunu QR/barkod ile okutuldugunda urunun icerik, alerjen
ve besin degerleri bu profile gore degerlendirilir.

## Proje Yapisi

- `biodietix.py`: Ana risk analizi, saglik profili ve beslenme onerisi
  fonksiyonlarini icerir. Komut satirindan calistirildiginda varsayilan CSV ve
  ornek PDF icin cikti dosyalari uretir.
- `app.py`: Streamlit web arayuzu. Varsayilan CSV, kullanici CSV yuklemesi ve
  PDF rapor yuklemesi ile analiz yapar.
- `utils/biodietix_web.py`: Web arayuzu icin veri okuma, kolon dogrulama, CSV
  analizi, PDF analizi ve CSV indirme yardimci fonksiyonlari.
- `utils/biodietix_audit.py`: Veri kalitesi, feature coverage ve
  `Health_Profile` pseudo-label'i uzerinde Random Forest / Gradient Boosting
  ML audit fonksiyonlari.
- `utils/food_recommendation_guide.py`: Excel'den turetilen gida bazli onerileri
  yukler ve mevcut onerilere uygular.
- `utils/mobile_health_core.py`: Mobil uygulamaya hazir profil hafizasi,
  alerji PDF metni okuma, Open Food Facts barkod bakisi ve urun uygunluk
  degerlendirme fonksiyonlari.
- `api.py`: Mobil uygulamanin kullandigi FastAPI servisi. Kan testi PDF analizi,
  alerji PDF analizi, barkod urun bakisi ve urun uygunluk degerlendirme
  endpointlerini sunar.
- `mobile/`: Flutter Android mobil uygulamasi. Firebase Auth ile giris,
  telefonda profil saklama, PDF yukleme, ayarlardan TR/EN dil ve acik/koyu tema
  secimi, QR/barkod urun tarama arayuzunu icerir.
- `data/food_recommendations.csv`: `Biodietix-Food Recommendations.xlsx`
  dosyasindan cikarilan gida rehberi.
- `BioDietix_CLEAN.csv`: Web arayuzunun varsayilan ham veri dosyasi.
- `BioDietix_Recommendation_System.csv`: Daha once uretilmis risk ve onerileri
  iceren cikti dosyasi. Varsayilan web akisi bu dosya varsa hizli acilis icin
  bunu kullanir.
- `BioDietix_Risk_Analysis.csv`: Risk analizi cikti dosyasi.
- `Patient_PDF_Recommendation_Result.csv`: Ornek PDF raporu icin uretilmis tek
  hasta sonucu.
- `29.01.2025.pdf`: PDF analiz akisini denemek icin repoda bulunan ornek rapor.
- `1999/` - `2017-2018/`: Farkli yillara ait `.xpt` kaynak veri dosyalari.

## Kurulum

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Calistirma

Web arayuzu:

```bash
streamlit run app.py
```

Komut calistiktan sonra Streamlit yerel bir web adresi verir. Tarayicida bu
adresi acarak arayuzu kullanabilirsiniz.

Mobil API:

```bash
uvicorn api:app --reload --host 0.0.0.0 --port 8000
```

Mobil uygulama:

```bash
cd mobile
cp firebase_defines.example.json firebase_defines.json
flutter pub get
flutter run --dart-define-from-file=firebase_defines.json
```

Firebase Console'da Email/Password Authentication etkinlestirilmelidir.
Android Firebase dosyasi `mobile/android/app/google-services.json` konumunda
bulunmalidir ve paket adi `com.biodietix.biodietix_mobile` olmalidir.
Telefonlara kurulacak APK icin `BIODIETIX_API_URL` mutlaka internete acik HTTPS
BioDietix API adresi olmalidir. Gelistirici bilgisayari, emulator adresleri
veya ozel ag IP'leri baska kullanicilarin telefonunda calismaz. Uygulamada
preview/giris atlama modu yoktur.

APK uretmek icin:

```bash
cd mobile
flutter build apk --release --dart-define-from-file=firebase_defines.json
```

APK cikti yolu:

```text
mobile/build/app/outputs/flutter-apk/app-release.apk
```

## Kullanim

1. Sol panelden veri kaynagini secin:
   - `Varsayilan CSV`: Repodaki `BioDietix_CLEAN.csv` dosyasini analiz eder.
   - `CSV yukle`: Kendi CSV dosyanizi yukleyip analiz eder.
   - `PDF raporu yukle`: PDF laboratuvar/rapor dosyasindan desteklenen
     degerleri cikarir ve tek hasta onerisi uretir. e-Nabiz formatindaki
     raporlarda cinsiyet, dogum tarihi, rapor tarihi, yas, hemogram, lipid,
     karaciger, bobrek, tiroid, D vitamini, B12, folat, ferritin, CRP ve demir
     alanlari desteklenir. PDF'de kilo/boy olmadigi icin arayuzde kilo ve boy
     girildiginde BMI hesaplanir ve modele katilir.
2. Sol panelde alerji profilini secin, manuel alerji girin veya alerji testi
   PDF'i yukleyin. Bu bilgi beslenme profilinden bagimsiz olarak urun kontrolunde
   kullanilir.
3. `Analizi Baslat` dugmesine basin.
4. Ozet sekmesinde saglik profili, beslenme onerisi, artirilacak besinler ve
   sinirlandirilacak besinleri hemen inceleyin.
5. `Urun Kontrolu` / `Product Check` sekmesinde barkod/QR degerini girin,
   urunu Open Food Facts ile bulmayi deneyin veya icerik/besin degerlerini elle
   girerek urunun mevcut kan testi, BMI ve alerji profiline gore onerilip
   onerilmedigini kontrol edin.
6. `Veri ve ML Denetimi` / `Data & ML Audit` sekmesinde veri kalitesi,
   gida onerisi rehberi, hedef dagilimi, feature coverage, model metrikleri ve
   en etkili ozellikleri inceleyin.
7. Sonuclari kartlar, tablo ve risk detaylari sekmelerinde ayrintili inceleyin.
8. `Sonuclari CSV indir` dugmesiyle analiz sonucunu CSV olarak indirin.

CSV analizi icin beklenen temel kolonlardan bazilari sunlardir:

```text
Gender, Glucose_mgdL, HbA1c_Percent, BMI veya Weight_kg + Height_cm,
Waist_Circumference_cm,
BP_Systolic_mmHg, BP_Diastolic_mmHg, Cholesterol_Total_mgdL,
Cholesterol_LDL_mgdL, Triglycerides_mgdL, Kidney_Creatinine_mgdL,
Hemoglobin_gdL, Liver_AST_UL, Daily_Fiber_g, Daily_Sugar_g,
Daily_Fat_g, Daily_Cholesterol_mg, White_Blood_Cells_count,
Red_Blood_Cells_count, Hematocrit_Percent, Platelet_count
```

Desteklenen ek PDF alanlarindan bazilari:

```text
Cholesterol_HDL_mgdL, Liver_ALT_UL, eGFR_ml_min_1_73m2,
CRP_mg_L, Ferritin_ng_mL, Folate_ng_mL, Vitamin_B12_pg_mL,
VitaminD_ng_mL, Iron_ugdL, Calcium_mg_dL, Magnesium_mg_dL,
Free_T3_pg_mL, Free_T4_ng_dL
```

## ML Audit Notu

Bu projede `Health_Profile` alani mevcut kural tabanli risk motoru tarafindan
uretilen denetlenebilir bir pseudo-label olarak kullanilir. ML audit bolumu bu
etiket uzerinden hizli ve okunabilir bir baseline egitimi yapar:

- Ham biyokimyasal ve beslenme ozellikleri secilir.
- Eksik degerler model pipeline'i icinde doldurulur.
- Nadir profil kombinasyonlari `Other Profile` altinda gruplanir.
- Random Forest ve Gradient Boosting modelleri egitilir.
- Accuracy, precision, recall, F1 ve RMSE-style label index metriği gosterilir.

Bu bolum tıbbi karar modeli iddiasi tasimaz; proje formundaki preprocessing,
feature selection, model training ve evaluation adimlarini gosterilebilir hale
getirmek icindir.

## Gida Oneri Rehberi

`data/food_recommendations.csv` dosyasi Excel notlarindaki gida bazli
onerilerin sade, version control dostu kopyasidir. Uygulama bu rehberi su
alanlarda kullanir:

- `Nutrition_Recommendation`: Risk profiline uygun ek oneriler ekler.
- `Foods_To_Increase`: Artirilmasi onerilen besinleri zenginlestirir.
- `Foods_To_Limit`: Sinirlandirilmasi onerilen besinleri zenginlestirir.
- Web arayuzundeki `Data & ML Audit`: Kullanilan gida rehberini tablo olarak
  gosterir.

## Mobil Uygulama Hazirligi

Eklenen mobil mimari:

- Flutter Android uygulamasi: `mobile/` klasoru altinda APK uretebilen mobil
  istemci.
- Firebase Auth: Kullanici girisi ve oturum yonetimi. Android Firebase
  yapilandirmasi `mobile/android/app/google-services.json` ile verilir.
- Telefon hafizasi: Boy, kilo, alerjiler, tema/dil tercihi ve son kan testi
  sonucu burada tutulur. Yeni PDF yuklenene kadar son profil kullanilir.
- Ayarlar: Mobil uygulamada `Settings/Ayarlar` sekmesinden Ingilizce/Turkce dil
  ve sistem/acik/koyu tema secilebilir.
- PDF okuma: Kan testi ve alerji testi PDF'leri BioDietix cekirdegine
  FastAPI uzerinden aktarilir.
- QR/barkod tarama: Mobil kamera barkod/QR degerini okur. Urun bilgisi
  Open Food Facts barkod bakisindan veya manuel giristen alinir.
- Urun karari: `utils/mobile_health_core.py` icindeki
  `evaluate_product_for_profile()` fonksiyonu alerji, kan testi profili, BMI,
  seker, doymus yag, tuz/sodyum, lif ve protein sinyallerine gore
  `recommended`, `use_with_caution` veya `not_recommended` karari uretir.
- Alternatif onerisi: Urun uygun degilse alerjiye ve saglik profiline daha
  uygun alternatif gida gruplari onerilir.

Mobil API endpointleri:

- `GET /health`
- `POST /analyze/blood-pdf`
- `POST /analyze/allergy-pdf`
- `GET /product/lookup/{barcode}`
- `POST /product/evaluate`

## Tibbi Uyari

Bu uygulama tibbi teshis veya tedavi amaci tasimaz. Uretilen risk profilleri ve
beslenme onerileri yalnizca egitim/proje amacli destekleyici bilgi olarak
degerlendirilmelidir. Saglik kararlarinda mutlaka yetkili saglik
profesyonellerine danisilmalidir.
