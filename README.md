# BioDietix ML

BioDietix ML, beslenme ve saglik profili verilerinden risk seviyeleri ve
beslenme onerileri ureten Python tabanli bir ogrenci projesidir. Proje; NHANES
benzeri CSV veri setlerini, temel laboratuvar degerlerini ve PDF raporlardan
cikarilabilen bazi test sonuclarini kullanarak `Health_Profile`,
`Nutrition_Recommendation`, `Foods_To_Increase` ve `Foods_To_Limit` alanlarini
olusturur. ENG4001 proje formundaki hedefe uygun olarak veri on isleme,
feature selection, Random Forest / Gradient Boosting tabanli model denetimi ve
performans metrikleri de web arayuzunde gosterilir.

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

```bash
streamlit run app.py
```

Komut calistiktan sonra Streamlit yerel bir web adresi verir. Tarayicida bu
adresi acarak arayuzu kullanabilirsiniz.

## Kullanim

1. Sol panelden veri kaynagini secin:
   - `Varsayilan CSV`: Repodaki `BioDietix_CLEAN.csv` dosyasini analiz eder.
   - `CSV yukle`: Kendi CSV dosyanizi yukleyip analiz eder.
   - `PDF raporu yukle`: PDF laboratuvar/rapor dosyasindan desteklenen
     degerleri cikarir ve tek hasta onerisi uretir.
2. `Analizi Baslat` dugmesine basin.
3. Ozet sekmesinde saglik profili, beslenme onerisi, artirilacak besinler ve
   sinirlandirilacak besinleri hemen inceleyin.
4. `Veri ve ML Denetimi` / `Data & ML Audit` sekmesinde veri kalitesi,
   hedef dagilimi, feature coverage, model metrikleri ve en etkili ozellikleri
   inceleyin.
5. Sonuclari kartlar, tablo ve risk detaylari sekmelerinde ayrintili inceleyin.
6. `Sonuclari CSV indir` dugmesiyle analiz sonucunu CSV olarak indirin.

CSV analizi icin beklenen temel kolonlardan bazilari sunlardir:

```text
Gender, Glucose_mgdL, HbA1c_Percent, BMI, Waist_Circumference_cm,
BP_Systolic_mmHg, BP_Diastolic_mmHg, Cholesterol_Total_mgdL,
Cholesterol_LDL_mgdL, Triglycerides_mgdL, Kidney_Creatinine_mgdL,
Hemoglobin_gdL, Liver_AST_UL, Daily_Fiber_g, Daily_Sugar_g,
Daily_Fat_g, Daily_Cholesterol_mg, White_Blood_Cells_count,
Red_Blood_Cells_count, Hematocrit_Percent, Platelet_count
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

## Tibbi Uyari

Bu uygulama tibbi teshis veya tedavi amaci tasimaz. Uretilen risk profilleri ve
beslenme onerileri yalnizca egitim/proje amacli destekleyici bilgi olarak
degerlendirilmelidir. Saglik kararlarinda mutlaka yetkili saglik
profesyonellerine danisilmalidir.
