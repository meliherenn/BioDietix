import html
import hmac
import os
import re

import pandas as pd
import streamlit as st

from utils.biodietix_web import (
    BioDietixDataError,
    BioDietixPDFError,
    DEFAULT_DATA_PATH,
    DEFAULT_RECOMMENDATION_PATH,
    OUTPUT_COLUMNS,
    RISK_COLUMNS,
    analyze_dataframe,
    analyze_pdf_file,
    available_columns,
    dataframe_to_csv_bytes,
    ensure_recommendation_columns,
    read_csv_data,
)
from utils.biodietix_audit import (
    MLAuditError,
    build_data_audit,
    run_ml_profile_audit,
)
from utils.food_recommendation_guide import food_guide_dataframe
from utils.mobile_health_core import (
    ALLERGY_DISPLAY_NAMES,
    COMMON_ALLERGIES,
    build_profile_memory,
    evaluate_product_for_profile,
    extract_allergies_from_pdf_file,
    lookup_open_food_facts_product,
    normalize_allergies,
)

KEY_RESULT_COLUMNS = [
    "Health_Profile",
    "Nutrition_Recommendation",
    "Foods_To_Increase",
    "Foods_To_Limit",
]

KEY_RESULT_LABELS = {
    "en": {
        "Health_Profile": "Health Profile",
        "Nutrition_Recommendation": "Nutrition Recommendation",
        "Foods_To_Increase": "Foods to Increase",
        "Foods_To_Limit": "Foods to Limit",
    },
    "tr": {
        "Health_Profile": "Sağlık Profili",
        "Nutrition_Recommendation": "Beslenme Önerisi",
        "Foods_To_Increase": "Artırılması Önerilen Besinler",
        "Foods_To_Limit": "Sınırlandırılması Önerilen Besinler",
    },
}

TEXT = {
    "en": {
        "header_eyebrow": "Nutrition Intelligence Dashboard",
        "app_description": (
            "A simple web interface that turns nutrition and health profile data "
            "into readable risk analysis and nutrition recommendations using the "
            "existing BioDietix engine."
        ),
        "hero_note": "CSV and PDF inputs are analyzed with the original BioDietix risk and recommendation logic.",
        "chip_risk_engine": "Risk engine",
        "chip_pdf_ready": "PDF ready",
        "chip_csv_export": "CSV export",
        "chip_food_guide": "Food guide",
        "medical_note_title": "Important medical note",
        "medical_warning": (
            "This application is not intended for medical diagnosis or treatment. "
            "Results should only be considered educational/project-based support information."
        ),
        "language": "Language",
        "data_source": "Data Source",
        "analysis_type": "Analysis type",
        "default_csv": "Default CSV",
        "upload_csv": "Upload CSV",
        "upload_pdf": "Upload PDF report",
        "current_file": "Current file",
        "csv_file": "CSV file",
        "pdf_file": "PDF laboratory/report file",
        "allergy_profile": "Allergy profile",
        "common_allergies": "Known food allergies",
        "manual_allergies": "Other allergies",
        "manual_allergies_help": "Separate multiple allergies with commas.",
        "allergy_pdf_file": "Allergy test PDF (optional)",
        "allergy_pdf_note": "Allergy data is used for product suitability checks.",
        "health_upload_consent":
            "I am authorized to process this report and consent to transient server-side analysis.",
        "health_upload_consent_required":
            "Consent is required before a health report can be processed.",
        "gender": "Gender",
        "age": "Age",
        "anthropometrics": "Body measurements",
        "weight_kg": "Weight (kg)",
        "height_cm": "Height (cm)",
        "bmi": "BMI",
        "optional_zero": "Leave as 0 if unknown.",
        "female": "Female",
        "male": "Male",
        "run_analysis": "Run Analysis",
        "waiting": "Choose a data source and click Run Analysis.",
        "running": "Running analysis...",
        "completed": "Analysis completed.",
        "summary_tab": "Summary",
        "cards_tab": "Cards",
        "table_tab": "Results Table",
        "risk_tab": "Risk Details",
        "product_tab": "Product Check",
        "key_result": "Key Result",
        "profile_cards": "Result Cards",
        "card_count": "Number of cards to display",
        "card_limit_note": (
            "Card view is limited for performance. All records are available in the Results Table tab."
        ),
        "record_title": "Patient / Record",
        "records_analyzed": "Records analyzed",
        "unique_profiles": "Unique profiles",
        "low_risk_records": "Low Risk records",
        "pdf_values": "Values Extracted from PDF",
        "pdf_text_preview": "PDF text preview",
        "download_csv": "Download results as CSV",
        "upload_csv_required": "Please upload a CSV file for analysis.",
        "upload_pdf_required": "Please upload a PDF file for analysis.",
        "unexpected_error": "Unexpected error",
        "empty_recommendation": "A specific recommendation could not be generated for this profile.",
        "table_field": "Field",
        "table_value": "Value",
        "patient_id": "Patient ID",
        "idle_title": "Ready to analyze",
        "idle_description": (
            "Select the default dataset, upload a CSV, or analyze a PDF report. "
            "The key profile and nutrition guidance will appear here first."
        ),
        "result_section": "Results",
        "profile_distribution": "Profile distribution",
        "audit_tab": "Data & ML Audit",
        "audit_section": "Project audit",
        "data_readiness": "Data readiness",
        "ml_readiness": "ML model audit",
        "audit_rows": "ML audit sample size",
        "run_ml_audit": "Run ML audit",
        "run_ml_audit_help": "Trains Random Forest and Gradient Boosting baselines on Health_Profile pseudo-labels.",
        "rows": "Rows",
        "columns": "Columns",
        "duplicates": "Duplicate IDs",
        "missing_cells": "Missing cells",
        "model_features": "Model features",
        "target_classes": "Target classes",
        "age_range": "Age range",
        "missing_table": "Missing value check",
        "feature_coverage": "Feature coverage",
        "target_distribution": "Health profile distribution",
        "ml_audit_note": (
            "This audit uses the rule-engine Health_Profile as a supervised pseudo-label. "
            "Rare profile combinations are grouped as Other Profile so the baseline remains fast and readable. "
            "It proves the project workflow required in the brief: preprocessing, feature selection, model training, and evaluation."
        ),
        "ml_not_run": "ML audit was skipped for this analysis.",
        "ml_not_available": "ML audit could not be completed",
        "top_features": "Top Random Forest features",
        "training_rows": "Training rows",
        "food_guide": "Food recommendation guide",
        "guide_category": "Category",
        "guide_condition": "Condition / Risk",
        "guide_limit": "Foods to Limit",
        "guide_increase": "Foods to Increase",
        "guide_purpose": "Purpose",
        "profile_memory_saved": "Latest profile is kept in this session until a new analysis is run.",
        "product_check_title": "Scanned product suitability",
        "product_check_note": "Mobile will scan QR/barcode with the camera; this web prototype lets you enter a barcode or product data manually.",
        "barcode": "Barcode / QR value",
        "lookup_product": "Look up product",
        "lookup_success": "Product found.",
        "lookup_not_found": "Product could not be found. Enter product details manually.",
        "product_name": "Product name",
        "product_category": "Category",
        "ingredients": "Ingredients",
        "declared_allergens": "Declared allergens",
        "nutrition_per_100g": "Nutrition per 100 g",
        "energy_kcal": "Energy (kcal)",
        "sugar_g": "Sugar (g)",
        "saturated_fat_g": "Saturated fat (g)",
        "salt_g": "Salt (g)",
        "sodium_mg": "Sodium (mg)",
        "protein_g": "Protein (g)",
        "fiber_g": "Fiber (g)",
        "evaluate_product": "Evaluate Product",
        "product_decision": "Product decision",
        "product_reasons": "Reasons",
        "product_positives": "Positive signals",
        "product_alternatives": "Better alternatives",
        "recommended": "Recommended",
        "use_with_caution": "Use with caution",
        "not_recommended": "Not recommended",
        "no_profile_memory": "Run an analysis first so the product check can use the latest health profile.",
        "product_medical_note": "This is educational guidance, not a medical diagnosis.",
    },
    "tr": {
        "header_eyebrow": "Beslenme Zekası Paneli",
        "app_description": (
            "Mevcut BioDietix motorunu kullanarak beslenme ve sağlık profili "
            "verilerini okunabilir risk analizi ve beslenme önerilerine dönüştüren "
            "basit web arayüzü."
        ),
        "hero_note": "CSV ve PDF girdileri orijinal BioDietix risk ve öneri mantığıyla analiz edilir.",
        "chip_risk_engine": "Risk motoru",
        "chip_pdf_ready": "PDF hazır",
        "chip_csv_export": "CSV dışa aktarım",
        "chip_food_guide": "Gıda rehberi",
        "medical_note_title": "Önemli tıbbi not",
        "medical_warning": (
            "Bu uygulama tıbbi teşhis veya tedavi amacı taşımaz. Sonuçlar yalnızca "
            "eğitim/proje amaçlı destekleyici bilgi olarak değerlendirilmelidir."
        ),
        "language": "Dil",
        "data_source": "Veri Kaynağı",
        "analysis_type": "Analiz tipi",
        "default_csv": "Varsayılan CSV",
        "upload_csv": "CSV yükle",
        "upload_pdf": "PDF raporu yükle",
        "current_file": "Kullanılan dosya",
        "csv_file": "CSV dosyası",
        "pdf_file": "PDF laboratuvar/rapor dosyası",
        "allergy_profile": "Alerji profili",
        "common_allergies": "Bilinen gıda alerjileri",
        "manual_allergies": "Diğer alerjiler",
        "manual_allergies_help": "Birden fazla alerjiyi virgülle ayırın.",
        "allergy_pdf_file": "Alerji testi PDF'i (opsiyonel)",
        "allergy_pdf_note": "Alerji verisi ürün uygunluğu kontrolünde kullanılır.",
        "health_upload_consent":
            "Bu raporu işlemeye yetkiliyim ve sunucuda geçici olarak analiz edilmesini onaylıyorum.",
        "health_upload_consent_required":
            "Sağlık raporu işlenmeden önce onay gereklidir.",
        "gender": "Cinsiyet",
        "age": "Yaş",
        "anthropometrics": "Vücut ölçüleri",
        "weight_kg": "Kilo (kg)",
        "height_cm": "Boy (cm)",
        "bmi": "BMI",
        "optional_zero": "Bilinmiyorsa 0 bırakın.",
        "female": "Kadın",
        "male": "Erkek",
        "run_analysis": "Analizi Başlat",
        "waiting": "Veri kaynağını seçip Analizi Başlat düğmesine basın.",
        "running": "Analiz çalışıyor...",
        "completed": "Analiz tamamlandı.",
        "summary_tab": "Özet",
        "cards_tab": "Kartlar",
        "table_tab": "Sonuç Tablosu",
        "risk_tab": "Risk Detayları",
        "product_tab": "Ürün Kontrolü",
        "key_result": "Temel Sonuç",
        "profile_cards": "Sonuç Kartları",
        "card_count": "Gösterilecek kart sayısı",
        "card_limit_note": (
            "Kart görünümü performans için sınırlıdır. Tüm kayıtlar Sonuç Tablosu sekmesinde yer alır."
        ),
        "record_title": "Hasta / Kayıt",
        "records_analyzed": "Analiz edilen kayıt",
        "unique_profiles": "Farklı profil",
        "low_risk_records": "Düşük Risk kayıt",
        "pdf_values": "PDF'den Çıkarılan Değerler",
        "pdf_text_preview": "PDF metin ön izlemesi",
        "download_csv": "Sonuçları CSV indir",
        "upload_csv_required": "Lütfen analiz için bir CSV dosyası yükleyin.",
        "upload_pdf_required": "Lütfen analiz için bir PDF dosyası yükleyin.",
        "unexpected_error": "Beklenmeyen hata",
        "empty_recommendation": "Bu profil için özel öneri üretilemedi.",
        "table_field": "Alan",
        "table_value": "Değer",
        "patient_id": "Hasta ID",
        "idle_title": "Analize hazır",
        "idle_description": (
            "Varsayılan veri setini seçin, CSV yükleyin veya PDF raporu analiz edin. "
            "Temel profil ve beslenme önerisi önce burada görünecek."
        ),
        "result_section": "Sonuçlar",
        "profile_distribution": "Profil dağılımı",
        "audit_tab": "Veri ve ML Denetimi",
        "audit_section": "Proje denetimi",
        "data_readiness": "Veri hazırlığı",
        "ml_readiness": "ML model denetimi",
        "audit_rows": "ML denetimi örneklem boyutu",
        "run_ml_audit": "ML denetimini çalıştır",
        "run_ml_audit_help": "Health_Profile pseudo-label'ları üzerinde Random Forest ve Gradient Boosting temel modellerini eğitir.",
        "rows": "Satır",
        "columns": "Kolon",
        "duplicates": "Tekrarlı ID",
        "missing_cells": "Eksik hücre",
        "model_features": "Model özelliği",
        "target_classes": "Hedef sınıf",
        "age_range": "Yaş aralığı",
        "missing_table": "Eksik değer kontrolü",
        "feature_coverage": "Özellik kapsaması",
        "target_distribution": "Sağlık profili dağılımı",
        "ml_audit_note": (
            "Bu denetim, kural motorunun ürettiği Health_Profile alanını supervised pseudo-label olarak kullanır. "
            "Nadir profil kombinasyonları Other Profile olarak gruplanır; böylece baseline hızlı ve okunabilir kalır. "
            "PDF özetindeki preprocessing, feature selection, model training ve evaluation akışının projede gösterilebilir olduğunu kanıtlar."
        ),
        "ml_not_run": "Bu analiz için ML denetimi atlandı.",
        "ml_not_available": "ML denetimi tamamlanamadı",
        "top_features": "En önemli Random Forest özellikleri",
        "training_rows": "Eğitim satırı",
        "food_guide": "Gıda öneri rehberi",
        "guide_category": "Kategori",
        "guide_condition": "Koşul / Risk",
        "guide_limit": "Sınırlandırılacak Besinler",
        "guide_increase": "Artırılacak Besinler",
        "guide_purpose": "Amaç",
        "profile_memory_saved": "Son profil, yeni analiz yapılana kadar bu oturumda tutulur.",
        "product_check_title": "Taranan ürün uygunluğu",
        "product_check_note": "Mobil uygulama QR/barkodu kamerayla okuyacak; bu web prototipinde barkod veya ürün bilgisini elle girebilirsiniz.",
        "barcode": "Barkod / QR değeri",
        "lookup_product": "Ürünü bul",
        "lookup_success": "Ürün bulundu.",
        "lookup_not_found": "Ürün bulunamadı. Ürün bilgilerini elle girin.",
        "product_name": "Ürün adı",
        "product_category": "Kategori",
        "ingredients": "İçindekiler",
        "declared_allergens": "Beyan edilen alerjenler",
        "nutrition_per_100g": "100 g için besin değerleri",
        "energy_kcal": "Enerji (kcal)",
        "sugar_g": "Şeker (g)",
        "saturated_fat_g": "Doymuş yağ (g)",
        "salt_g": "Tuz (g)",
        "sodium_mg": "Sodyum (mg)",
        "protein_g": "Protein (g)",
        "fiber_g": "Lif (g)",
        "evaluate_product": "Ürünü Değerlendir",
        "product_decision": "Ürün kararı",
        "product_reasons": "Gerekçeler",
        "product_positives": "Olumlu sinyaller",
        "product_alternatives": "Daha iyi alternatifler",
        "recommended": "Önerilir",
        "use_with_caution": "Dikkatli tüketilmeli",
        "not_recommended": "Önerilmez",
        "no_profile_memory": "Ürün kontrolünün son sağlık profilini kullanabilmesi için önce analiz çalıştırın.",
        "product_medical_note": "Bu değerlendirme eğitim amaçlıdır, tıbbi teşhis değildir.",
    },
}

PROFILE_TRANSLATIONS = {
    "Low Risk": "Düşük Risk",
    "Insufficient Data": "Yetersiz Veri",
    "No Flagged Risk in Available Data": "Mevcut Veride İşaretlenen Risk Yok",
    "Blood Sugar Risk": "Kan Şekeri Riski",
    "Weight Management Risk": "Kilo Yönetimi Riski",
    "Blood Pressure Risk": "Tansiyon Riski",
    "Cardiovascular Lipid Risk": "Kardiyovasküler Lipit Riski",
    "Kidney / Muscle Indicator": "Böbrek / Kas Göstergesi",
    "Hemoglobin Indicator": "Hemoglobin Göstergesi",
    "Immune / Inflammation Indicator": "Bağışıklık / Enflamasyon Göstergesi",
    "Blood Cell / Anemia Support Indicator": "Kan Hücresi / Anemi Destek Göstergesi",
    "Platelet Support Indicator": "Trombosit Destek Göstergesi",
    "Liver Enzyme Indicator": "Karaciğer Enzimi Göstergesi",
    "Thyroid / Metabolism Indicator": "Tiroid / Metabolizma Göstergesi",
    "Diet Quality Risk": "Beslenme Kalitesi Riski",
    "Abdominal Obesity Risk": "Abdominal Obezite Riski",
    "Age-Related Nutrition Focus": "Yaşa Bağlı Beslenme Odağı",
    "Vitamin D / Bone Health Indicator": "D Vitamini / Kemik Sağlığı Göstergesi",
    "Micronutrient Support Indicator": "Mikro Besin Destek Göstergesi",
}

RECOMMENDATION_TRANSLATIONS = {
    "Thyroid-related lab changes should be reviewed with a healthcare professional; this is not a medical diagnosis. Support thyroid-related metabolism with balanced meals, adequate protein, selenium, zinc, iodine, and regular meal patterns.": (
        "Tiroidle ilişkili laboratuvar değişiklikleri bir sağlık profesyoneli tarafından değerlendirilmelidir; bu tıbbi teşhis değildir. Dengeli öğünler, yeterli protein, selenyum, çinko, iyot ve düzenli öğün düzeniyle tiroidle ilişkili metabolizma desteklenebilir."
    ),
    "Maintain a balanced diet with regular meals, adequate fiber, lean protein, and healthy fats.": (
        "Düzenli öğünler, yeterli lif, yağsız protein ve sağlıklı yağlarla dengeli beslenmeyi sürdürün."
    ),
    "Reduce added sugar and refined carbohydrates, and prefer low-glycemic foods.": (
        "Eklenmiş şekeri ve rafine karbonhidratları azaltın; düşük glisemik indeksli besinleri tercih edin."
    ),
    "Control portion sizes and choose nutrient-dense, lower-calorie meals.": (
        "Porsiyon kontrolü yapın ve besin değeri yüksek, daha düşük kalorili öğünleri tercih edin."
    ),
    "Reduce sodium intake and follow a DASH-style eating pattern.": (
        "Sodyum alımını azaltın ve DASH tarzı bir beslenme düzenini tercih edin."
    ),
    "Reduce saturated fat and refined carbohydrates; prefer heart-healthy fats.": (
        "Doymuş yağı ve rafine karbonhidratları azaltın; kalp dostu yağları tercih edin."
    ),
    "Improve overall diet quality by increasing fiber and reducing added sugar, saturated fat, and dietary cholesterol.": (
        "Lifi artırıp eklenmiş şeker, doymuş yağ ve diyet kolesterolünü azaltarak genel beslenme kalitesini iyileştirin."
    ),
    "Limit excessive protein intake, reduce sodium, and avoid ultra-processed foods.": (
        "Aşırı protein alımını sınırlayın, sodyumu azaltın ve aşırı işlenmiş gıdalardan kaçının."
    ),
    "Support muscle mass with adequate calories, high-quality protein, and regular resistance exercise.": (
        "Yeterli kalori, kaliteli protein ve düzenli direnç egzersiziyle kas kütlesini destekleyin."
    ),
    "Increase iron-rich foods and pair them with vitamin C sources.": (
        "Demirden zengin besinleri artırın ve C vitamini kaynaklarıyla birlikte tüketin."
    ),
    "Support immune and inflammatory balance with antioxidant-rich foods, adequate protein, hydration, and omega-3 sources.": (
        "Antioksidandan zengin besinler, yeterli protein, sıvı alımı ve omega-3 kaynaklarıyla bağışıklık ve inflamasyon dengesini destekleyin."
    ),
    "Support blood cell health with iron, folate, vitamin B12, vitamin C, and adequate protein intake.": (
        "Demir, folat, B12 vitamini, C vitamini ve yeterli protein alımıyla kan hücresi sağlığını destekleyin."
    ),
    "Maintain balanced nutrition and hydration; platelet-related abnormalities should be interpreted with clinical context.": (
        "Dengeli beslenmeyi ve yeterli sıvı alımını sürdürün; trombosit ile ilgili anormallikler klinik bağlamda değerlendirilmelidir."
    ),
    "Reduce alcohol, fried foods, and excess sugar to support liver health.": (
        "Karaciğer sağlığını desteklemek için alkolü, kızartmaları ve aşırı şekeri azaltın."
    ),
    "Focus on weight management, fiber-rich meals, and regular physical activity.": (
        "Kilo yönetimine, liften zengin öğünlere ve düzenli fiziksel aktiviteye odaklanın."
    ),
    "For this age group, build long-term habits with regular meals, adequate protein, fiber, and physical activity.": (
        "Bu yaş grubu için düzenli öğünler, yeterli protein, lif ve fiziksel aktiviteyle uzun vadeli alışkanlıklar oluşturun."
    ),
    "For adult metabolic maintenance, prioritize portion control, fiber, lean protein, and consistent activity.": (
        "Yetişkin metabolik denge için porsiyon kontrolünü, lifi, yağsız proteini ve düzenli aktiviteyi önceliklendirin."
    ),
    "For midlife prevention, focus on cardiovascular health, muscle maintenance, fiber, vitamin D, calcium, and regular checkups.": (
        "Orta yaş koruması için kardiyovasküler sağlığa, kas korunmasına, lif alımına, D vitaminine, kalsiyuma ve düzenli kontrollere odaklanın."
    ),
    "For older adults, protect muscle and bone health with adequate protein, vitamin D, calcium, hydration, and clinically guided follow-up.": (
        "İleri yaşta yeterli protein, D vitamini, kalsiyum, sıvı alımı ve klinik takip ile kas ve kemik sağlığını koruyun."
    ),
    "Liver enzyme changes should be reviewed with a healthcare professional. Reduce alcohol, fried foods, and excess sugar to support liver health.": (
        "Karaciğer enzim değişiklikleri bir sağlık profesyoneli tarafından değerlendirilmelidir. Karaciğer sağlığını desteklemek için alkolü, kızartmaları ve aşırı şekeri azaltın."
    ),
    "Low vitamin D should be reviewed with a healthcare professional. Support bone health with vitamin D, calcium, protein, and safe sunlight exposure when appropriate.": (
        "Düşük D vitamini bir sağlık profesyoneli tarafından değerlendirilmelidir. Uygun olduğunda D vitamini, kalsiyum, protein ve güvenli güneş ışığıyla kemik sağlığını destekleyin."
    ),
    "Micronutrient abnormalities should be interpreted with clinical context. Support iron, folate, B12, vitamin C, and protein intake based on the specific deficiency pattern.": (
        "Mikro besin anormallikleri klinik bağlamda yorumlanmalıdır. Özgül eksiklik örüntüsüne göre demir, folat, B12, C vitamini ve protein alımını destekleyin."
    ),
    "Choose whole-grain, low-glycemic carbohydrate sources to improve glycemic control.": (
        "Glisemik kontrolü desteklemek için tam tahıllı ve düşük glisemik indeksli karbonhidrat kaynaklarını tercih edin."
    ),
    "Keep added sugar low and replace sweet snacks with whole fruit when appropriate.": (
        "Eklenmiş şekeri düşük tutun ve uygun olduğunda tatlı atıştırmalıklar yerine bütün meyveyi tercih edin."
    ),
    "Increase fiber from vegetables, legumes, chia seeds, flaxseed, and whole grains.": (
        "Sebzeler, baklagiller, chia tohumu, keten tohumu ve tam tahıllardan lif alımını artırın."
    ),
    "Prefer lean protein sources to support insulin sensitivity.": (
        "İnsülin duyarlılığını desteklemek için yağsız protein kaynaklarını tercih edin."
    ),
    "Replace saturated and fried fats with unsaturated fat sources in modest portions.": (
        "Doymuş ve kızartılmış yağlar yerine ölçülü porsiyonlarda doymamış yağ kaynaklarını tercih edin."
    ),
    "Prefer lower-fat dairy and fish while reducing fatty red meat and high-fat dairy.": (
        "Yağlı kırmızı et ve yüksek yağlı süt ürünlerini azaltırken daha az yağlı süt ürünleri ve balığı tercih edin."
    ),
    "Support liver health by avoiding alcohol, fried foods, and sugary foods.": (
        "Alkol, kızartmalar ve şekerli gıdalardan kaçınarak karaciğer sağlığını destekleyin."
    ),
    "Use herbs, garlic, lemon, and potassium-rich foods while reducing salty processed foods.": (
        "Tuzlu işlenmiş gıdaları azaltırken otlar, sarımsak, limon ve potasyumdan zengin besinleri kullanın."
    ),
    "Prioritize vegetables and lean protein while reducing high-calorie fast food.": (
        "Yüksek kalorili fast food tüketimini azaltırken sebzeler ve yağsız proteine öncelik verin."
    ),
    "Use a Mediterranean-style pattern to support overall metabolic health.": (
        "Genel metabolik sağlığı desteklemek için Akdeniz tarzı beslenme düzenini kullanın."
    ),
    "BMI indicates an underweight range. Increase nutrient-dense calories with protein-rich meals and healthy fats, and review unintentional weight loss with a healthcare professional.": (
        "BMI düşük kilo aralığını gösteriyor. Protein içeren öğünler ve sağlıklı yağlarla besin değeri yüksek kaloriyi artırın; istemsiz kilo kaybı varsa sağlık profesyoneliyle değerlendirin."
    ),
}

FOOD_TRANSLATIONS = {
    "eggs": "yumurta",
    "fish": "balık",
    "yogurt": "yoğurt",
    "dairy products": "süt ürünleri",
    "selenium-rich foods": "selenyumdan zengin besinler",
    "balanced meals": "dengeli öğünler",
    "regular meals": "düzenli öğünler",
    "legumes": "baklagiller",
    "oats": "yulaf",
    "fiber-rich foods": "liften zengin besinler",
    "high-fiber foods": "liften zengin besinler",
    "sugary drinks": "şekerli içecekler",
    "soft drinks": "gazlı/şekerli içecekler",
    "desserts": "tatlılar",
    "packaged snacks": "paketli atıştırmalıklar",
    "white bread": "beyaz ekmek",
    "white rice": "beyaz pirinç",
    "sugary cereals": "şekerli kahvaltılık gevrekler",
    "pastries": "hamur işleri",
    "whole wheat bread": "tam buğday ekmeği",
    "bulgur": "bulgur",
    "brown rice": "esmer pirinç",
    "quinoa": "kinoa",
    "fresh fruits": "taze meyveler",
    "cinnamon": "tarçın",
    "chia seeds": "chia tohumu",
    "flaxseed": "keten tohumu",
    "chicken breast": "tavuk göğsü",
    "olive oil": "zeytinyağı",
    "avocado": "avokado",
    "nuts": "kuruyemişler",
    "butter": "tereyağı",
    "margarine": "margarin",
    "low-fat dairy": "az yağlı süt ürünleri",
    "low-fat yogurt": "az yağlı yoğurt",
    "high-fat dairy": "yüksek yağlı süt ürünleri",
    "herbs": "otlar",
    "garlic": "sarımsak",
    "lemon": "limon",
    "potassium-rich foods": "potasyumdan zengin besinler",
    "Mediterranean diet foods": "Akdeniz tipi besinler",
    "very low-calorie diets": "çok düşük kalorili diyetler",
    "meal skipping": "öğün atlama",
    "ultra-processed foods": "aşırı işlenmiş gıdalar",
    "processed foods": "işlenmiş gıdalar",
    "processed snacks": "işlenmiş atıştırmalıklar",
    "processed meats": "işlenmiş etler",
    "processed meat": "işlenmiş et",
    "instant soups": "hazır çorbalar",
    "high-sodium packaged foods": "yüksek sodyumlu paketli gıdalar",
    "high-sodium foods": "yüksek sodyumlu gıdalar",
    "salty snacks": "tuzlu atıştırmalıklar",
    "pickles": "turşular",
    "excessive protein supplements": "aşırı protein takviyeleri",
    "excessive red meat": "aşırı kırmızı et",
    "fatty red meat": "yağlı kırmızı et",
    "lean meats": "yağsız etler",
    "lean red meat": "yağsız kırmızı et",
    "lentils": "mercimek",
    "beans": "fasulye",
    "spinach": "ıspanak",
    "citrus fruits": "narenciye",
    "berries": "orman meyveleri",
    "walnuts": "ceviz",
    "adequate protein": "yeterli protein",
    "water": "su",
    "coffee without sugar": "şekersiz kahve",
    "omega-3 rich foods": "omega-3'ten zengin besinler",
    "tea or coffee immediately with iron-rich meals": "demirden zengin öğünlerle birlikte hemen çay/kahve",
    "excess alcohol": "aşırı alkol",
    "alcohol": "alkol",
    "fried foods": "kızartmalar",
    "trans fats": "trans yağlar",
    "sugary foods": "şekerli gıdalar",
    "sweets": "şekerlemeler/tatlılar",
    "high-fat processed foods": "yüksek yağlı işlenmiş gıdalar",
    "high-calorie snacks": "yüksek kalorili atıştırmalıklar",
    "fast food": "fast food",
    "frequent fast food": "sık fast food tüketimi",
    "high-calorie fast food": "yüksek kalorili fast food",
    "fresh vegetables": "taze sebzeler",
    "high-fiber vegetables": "liften zengin sebzeler",
    "refined grains": "rafine tahıllar",
    "refined carbohydrates": "rafine karbonhidratlar",
    "refined carbs": "rafine karbonhidratlar",
    "large portions": "büyük porsiyonlar",
    "saturated fat": "doymuş yağ",
    "excess sodium": "aşırı sodyum",
    "vitamin D foods": "D vitamini içeren besinler",
    "calcium-rich foods": "kalsiyumdan zengin besinler",
    "protein-rich foods": "proteinden zengin besinler",
    "dehydration": "yetersiz sıvı alımı",
    "fatty fish": "yağlı balıklar",
    "fortified dairy": "D vitaminiyle zenginleştirilmiş süt ürünleri",
    "nutrient-poor processed foods": "besin değeri düşük işlenmiş gıdalar",
    "leafy greens": "yeşil yapraklı sebzeler",
    "very restrictive diets": "çok kısıtlayıcı diyetler",
    "excess sugar": "aşırı şeker",
    "vegetables": "sebzeler",
    "fruits": "meyveler",
    "whole grains": "tam tahıllar",
    "lean protein": "yağsız protein",
    "healthy fats": "sağlıklı yağlar",
}

FOOD_TRANSLATIONS_NORMALIZED = {
    " ".join(english.casefold().split()): turkish
    for english, turkish in FOOD_TRANSLATIONS.items()
}

GENERAL_VALUE_TRANSLATIONS = {
    "Male": "Erkek",
    "Female": "Kadın",
    "Young Adult": "Genç Yetişkin",
    "Adult": "Yetişkin",
    "Midlife": "Orta Yaş",
    "Older Adult": "İleri Yaş",
    "Under 18": "18 Yaş Altı",
    "Age-Appropriate Adult Focus": "Yaşa Uygun Yetişkin Odağı",
    "Midlife Prevention Focus": "Orta Yaş Koruma Odağı",
    "Older Adult Nutrition Focus": "İleri Yaş Beslenme Odağı",
    "Under 18 - Not Supported": "18 Yaş Altı - Desteklenmiyor",
    "Normal": "Normal",
    "Desirable": "İstenen Düzey",
    "Optimal": "Optimal",
    "Near Optimal": "Optimale Yakın",
    "Borderline High": "Sınırda Yüksek",
    "High": "Yüksek",
    "Very High": "Çok Yüksek",
    "High Risk": "Yüksek Risk",
    "Low": "Düşük",
    "Adequate": "Yeterli",
    "Low-Moderate": "Düşük-Orta",
    "Prediabetes Risk": "Prediyabet Riski",
    "High Diabetes Risk": "Yüksek Diyabet Riski",
    "Overweight Risk": "Fazla Kilo Riski",
    "Obesity Risk": "Obezite Riski",
    "Underweight": "Düşük Kilo",
    "Abdominal Obesity Risk": "Abdominal Obezite Riski",
    "Elevated": "Yükselmiş",
    "Stage 1 Hypertension Risk": "Evre 1 Hipertansiyon Riski",
    "Stage 2 Hypertension Risk": "Evre 2 Hipertansiyon Riski",
    "Low HDL Risk": "Düşük HDL Riski",
    "Reduced eGFR Indicator": "Azalmış eGFR Göstergesi",
    "Low Hemoglobin Risk": "Düşük Hemoglobin Riski",
    "High Hemoglobin": "Yüksek Hemoglobin",
    "Elevated AST Risk": "Yüksek AST Riski",
    "Elevated ALT Risk": "Yüksek ALT Riski",
    "Elevated CRP Indicator": "Yüksek CRP Göstergesi",
    "Low Vitamin D Indicator": "Düşük D Vitamini Göstergesi",
    "Vitamin D Insufficiency Indicator": "D Vitamini Yetersizliği Göstergesi",
    "Low Vitamin B12 Indicator": "Düşük B12 Vitamini Göstergesi",
    "Borderline Vitamin B12 Indicator": "Sınırda B12 Vitamini Göstergesi",
    "Low Folate Indicator": "Düşük Folat Göstergesi",
    "Low Ferritin Indicator": "Düşük Ferritin Göstergesi",
    "High Ferritin Indicator": "Yüksek Ferritin Göstergesi",
    "Low Fiber Intake Risk": "Düşük Lif Alımı Riski",
    "High Sugar Intake Risk": "Yüksek Şeker Alımı Riski",
    "Good Diet Quality": "İyi Beslenme Kalitesi",
    "Moderate Diet Quality Risk": "Orta Beslenme Kalitesi Riski",
    "Poor Diet Quality Risk": "Düşük Beslenme Kalitesi Riski",
    "Low WBC Indicator": "Düşük WBC Göstergesi",
    "Elevated WBC Indicator": "Yüksek WBC Göstergesi",
    "Low RBC Indicator": "Düşük RBC Göstergesi",
    "Elevated RBC Indicator": "Yüksek RBC Göstergesi",
    "Low Hematocrit Indicator": "Düşük Hematokrit Göstergesi",
    "Elevated Hematocrit Indicator": "Yüksek Hematokrit Göstergesi",
    "Low Platelet Indicator": "Düşük Trombosit Göstergesi",
    "Elevated Platelet Indicator": "Yüksek Trombosit Göstergesi",
    "Low TSH Indicator": "Düşük TSH Göstergesi",
    "Elevated TSH Indicator": "Yüksek TSH Göstergesi",
}

GENERAL_VALUE_TRANSLATIONS_NORMALIZED = {
    " ".join(english.casefold().split()): turkish
    for english, turkish in GENERAL_VALUE_TRANSLATIONS.items()
}

COLUMN_LABEL_TRANSLATIONS = {
    "Age_Group": {"en": "Age Group", "tr": "Yaş Grubu"},
    "Age_Risk_Level": {"en": "Age Focus", "tr": "Yaş Odağı"},
    "Weight_kg": {"en": "Weight (kg)", "tr": "Kilo (kg)"},
    "Height_cm": {"en": "Height (cm)", "tr": "Boy (cm)"},
    "BMI": {"en": "BMI", "tr": "BMI"},
    "Glucose_Risk_Level": {"en": "Glucose Risk", "tr": "Glukoz Riski"},
    "HbA1c_Risk_Level": {"en": "HbA1c Risk", "tr": "HbA1c Riski"},
    "BMI_Risk_Level": {"en": "BMI Risk", "tr": "BMI Riski"},
    "Waist_Risk_Level": {"en": "Waist Risk", "tr": "Bel Çevresi Riski"},
    "BP_Risk_Level": {"en": "Blood Pressure Risk", "tr": "Tansiyon Riski"},
    "Cholesterol_Risk_Level": {"en": "Cholesterol Risk", "tr": "Kolesterol Riski"},
    "LDL_Risk_Level": {"en": "LDL Risk", "tr": "LDL Riski"},
    "HDL_Risk_Level": {"en": "HDL Risk", "tr": "HDL Riski"},
    "Triglyceride_Risk_Level": {"en": "Triglyceride Risk", "tr": "Trigliserid Riski"},
    "Creatinine_Risk_Level": {"en": "Creatinine Risk", "tr": "Kreatinin Riski"},
    "eGFR_Risk_Level": {"en": "eGFR Risk", "tr": "eGFR Riski"},
    "Hemoglobin_Risk_Level": {"en": "Hemoglobin Risk", "tr": "Hemoglobin Riski"},
    "ALT_Risk_Level": {"en": "ALT Risk", "tr": "ALT Riski"},
    "AST_Risk_Level": {"en": "AST Risk", "tr": "AST Riski"},
    "CRP_Risk_Level": {"en": "CRP Risk", "tr": "CRP Riski"},
    "VitaminD_Risk_Level": {"en": "Vitamin D Risk", "tr": "D Vitamini Riski"},
    "B12_Risk_Level": {"en": "B12 Risk", "tr": "B12 Riski"},
    "Folate_Risk_Level": {"en": "Folate Risk", "tr": "Folat Riski"},
    "Ferritin_Risk_Level": {"en": "Ferritin Risk", "tr": "Ferritin Riski"},
    "Fiber_Risk_Level": {"en": "Fiber Risk", "tr": "Lif Riski"},
    "Sugar_Risk_Level": {"en": "Sugar Risk", "tr": "Şeker Riski"},
    "Diet_Quality_Risk_Level": {"en": "Diet Quality Risk", "tr": "Beslenme Kalitesi Riski"},
    "WBC_Risk_Level": {"en": "WBC Risk", "tr": "WBC Riski"},
    "RBC_Risk_Level": {"en": "RBC Risk", "tr": "RBC Riski"},
    "Hematocrit_Risk_Level": {"en": "Hematocrit Risk", "tr": "Hematokrit Riski"},
    "Platelet_Risk_Level": {"en": "Platelet Risk", "tr": "Trombosit Riski"},
    "TSH_Risk_Level": {"en": "TSH Risk", "tr": "TSH Riski"},
}

GUIDE_VALUE_TRANSLATIONS = {
    "Carbohydrates": "Karbonhidratlar",
    "Sugar": "Şeker",
    "Fiber": "Lif",
    "Protein": "Protein",
    "Fat": "Yağ",
    "Cholesterol": "Kolesterol",
    "Liver Health": "Karaciğer Sağlığı",
    "Blood Pressure": "Tansiyon",
    "Weight Control": "Kilo Kontrolü",
    "Metabolic Health": "Metabolik Sağlık",
    "High HbA1c / High Glucose": "Yüksek HbA1c / Yüksek Glukoz",
    "High daily sugar intake": "Yüksek günlük şeker alımı",
    "Low fiber intake": "Düşük lif alımı",
    "Insulin resistance": "İnsülin direnci",
    "High LDL / Triglycerides": "Yüksek LDL / Trigliserid",
    "High LDL cholesterol": "Yüksek LDL kolesterol",
    "Elevated ALT / AST": "Yüksek ALT / AST",
    "Hypertension": "Hipertansiyon",
    "Obesity": "Obezite",
    "Metabolic syndrome": "Metabolik sendrom",
    "Improve glycemic control": "Glisemik kontrolü iyileştirme",
    "Reduce blood sugar spikes": "Kan şekeri dalgalanmalarını azaltma",
    "Improve digestion and lower LDL": "Sindirimi iyileştirme ve LDL'yi düşürme",
    "Improve insulin sensitivity": "İnsülin duyarlılığını iyileştirme",
    "Improve lipid profile": "Lipit profilini iyileştirme",
    "Reduce cardiovascular risk": "Kardiyovasküler riski azaltma",
    "Support liver function": "Karaciğer fonksiyonunu destekleme",
    "Reduce blood pressure": "Tansiyonu azaltma",
    "Promote weight loss": "Kilo kaybını destekleme",
    "Improve overall metabolic health": "Genel metabolik sağlığı iyileştirme",
}

ALLERGY_LABEL_TRANSLATIONS = {
    "milk": {"en": "Milk / dairy", "tr": "Süt / süt ürünleri"},
    "gluten": {"en": "Gluten / wheat", "tr": "Gluten / buğday"},
    "peanut": {"en": "Peanut", "tr": "Yer fıstığı"},
    "tree_nut": {"en": "Tree nuts", "tr": "Sert kabuklu yemişler"},
    "egg": {"en": "Egg", "tr": "Yumurta"},
    "soy": {"en": "Soy", "tr": "Soya"},
    "fish": {"en": "Fish", "tr": "Balık"},
    "shellfish": {"en": "Shellfish", "tr": "Kabuklu deniz ürünleri"},
    "sesame": {"en": "Sesame", "tr": "Susam"},
}

PRODUCT_REASON_TEXT = {
    "allergy_conflict": {
        "en": "The product appears to contain an allergen in the user's allergy profile: {allergens}.",
        "tr": "Ürün, kullanıcının alerji profilindeki şu alerjenleri içeriyor olabilir: {allergens}.",
    },
    "high_sugar_blood_sugar": {
        "en": "Sugar is high for a blood sugar sensitive profile ({value:.1f} g / 100 g).",
        "tr": "Şeker miktarı kan şekeri hassasiyeti için yüksek ({value:.1f} g / 100 g).",
    },
    "moderate_sugar_blood_sugar": {
        "en": "Sugar should be limited for this blood sugar profile ({value:.1f} g / 100 g).",
        "tr": "Bu kan şekeri profili için şeker sınırlandırılmalı ({value:.1f} g / 100 g).",
    },
    "very_high_saturated_fat_lipid": {
        "en": "Saturated fat is very high for a cardiovascular lipid risk profile ({value:.1f} g / 100 g).",
        "tr": "Doymuş yağ kardiyovasküler lipit riski için çok yüksek ({value:.1f} g / 100 g).",
    },
    "high_saturated_fat_lipid": {
        "en": "Saturated fat should be limited for this lipid profile ({value:.1f} g / 100 g).",
        "tr": "Bu lipit profili için doymuş yağ sınırlandırılmalı ({value:.1f} g / 100 g).",
    },
    "high_salt_bp_kidney": {
        "en": "Salt/sodium is high for blood pressure or kidney-related risk.",
        "tr": "Tuz/sodyum miktarı tansiyon veya böbrek ilişkili risk için yüksek.",
    },
    "moderate_salt_bp_kidney": {
        "en": "Salt/sodium should be limited for this blood pressure or kidney-related profile.",
        "tr": "Bu tansiyon veya böbrek ilişkili profil için tuz/sodyum sınırlandırılmalı.",
    },
    "high_energy_weight": {
        "en": "Energy density is high for weight management ({value:.0f} kcal / 100 g).",
        "tr": "Enerji yoğunluğu kilo yönetimi için yüksek ({value:.0f} kcal / 100 g).",
    },
    "ultra_processed_diet": {
        "en": "The ingredient list suggests an ultra-processed product, which conflicts with the current diet-quality guidance.",
        "tr": "İçindekiler listesi aşırı işlenmiş ürün sinyali veriyor; bu mevcut beslenme kalitesi önerisiyle uyumlu değil.",
    },
    "low_fiber_diet": {
        "en": "Fiber is low for a diet-quality risk profile ({value:.1f} g / 100 g).",
        "tr": "Lif miktarı beslenme kalitesi riski için düşük ({value:.1f} g / 100 g).",
    },
    "high_protein_kidney": {
        "en": "Protein is high; kidney or creatinine-related findings should be considered ({value:.1f} g / 100 g).",
        "tr": "Protein miktarı yüksek; böbrek veya kreatinin ilişkili bulgular dikkate alınmalı ({value:.1f} g / 100 g).",
    },
}

PRODUCT_POSITIVE_TEXT = {
    "good_fiber": {
        "en": "Fiber content is supportive ({value:.1f} g / 100 g).",
        "tr": "Lif içeriği destekleyici düzeyde ({value:.1f} g / 100 g).",
    },
    "good_protein": {
        "en": "Protein content is useful in a balanced portion ({value:.1f} g / 100 g).",
        "tr": "Protein içeriği dengeli porsiyonda faydalı olabilir ({value:.1f} g / 100 g).",
    },
}

PRODUCT_ALTERNATIVE_TEXT = {
    "allergy_safe_same_category": {
        "en": "Choose an allergen-free product in the same category with a clear allergen label.",
        "tr": "Aynı kategoride, alerjen içermediği açıkça belirtilen bir ürün seçin.",
    },
    "low_sugar_snack": {
        "en": "Prefer unsweetened yogurt, whole fruit, nuts/seeds if allergy-safe, or a low-sugar whole-grain option.",
        "tr": "Alerjiye uygunsa şekersiz yoğurt, bütün meyve, kuruyemiş/tohum veya düşük şekerli tam tahıllı seçenek tercih edin.",
    },
    "unsalted_option": {
        "en": "Prefer an unsalted or low-sodium version, fresh vegetables, plain yogurt, or home-prepared alternatives.",
        "tr": "Tuzsuz veya düşük sodyumlu versiyon, taze sebze, sade yoğurt veya evde hazırlanmış alternatifleri tercih edin.",
    },
    "unsaturated_fat_option": {
        "en": "Prefer products based on olive oil, avocado, fish, or unsalted nuts if allergy-safe.",
        "tr": "Alerjiye uygunsa zeytinyağı, avokado, balık veya tuzsuz kuruyemiş temelli seçenekleri tercih edin.",
    },
    "high_fiber_option": {
        "en": "Choose a higher-fiber option such as legumes, vegetables, oats, whole grains, or fruit.",
        "tr": "Baklagiller, sebzeler, yulaf, tam tahıllar veya meyve gibi daha lifli bir seçenek seçin.",
    },
    "balanced_protein_option": {
        "en": "Prefer moderate protein portions and avoid concentrated protein supplements unless clinically advised.",
        "tr": "Orta düzey protein porsiyonlarını tercih edin; klinik öneri yoksa yoğun protein takviyelerinden kaçının.",
    },
    "fresh_whole_food": {
        "en": "Prefer a simpler whole-food alternative with a short ingredient list.",
        "tr": "İçindekiler listesi kısa olan daha sade, bütün gıda temelli bir alternatif tercih edin.",
    },
}


st.set_page_config(
    page_title="BioDietix",
    layout="wide",
)


def require_web_access():
    environment = os.getenv("BIODIETIX_ENV", "development").lower()
    expected_password = os.getenv("BIODIETIX_WEB_PASSWORD", "")
    if not expected_password and environment != "production":
        return
    if not expected_password:
        st.error("Production web access is disabled until BIODIETIX_WEB_PASSWORD is configured.")
        st.stop()
    if st.session_state.get("web_authenticated"):
        return

    st.title("BioDietix")
    st.warning("Protected health-data workspace / Korumalı sağlık verisi çalışma alanı")
    password = st.text_input("Access password / Erişim parolası", type="password")
    if st.button("Continue / Devam et"):
        if hmac.compare_digest(password, expected_password):
            st.session_state["web_authenticated"] = True
            st.rerun()
        st.error("Access denied / Erişim reddedildi")
    st.stop()


require_web_access()


st.markdown(
    """
    <style>
        :root {
            --bd-bg: #f5f7f2;
            --bd-panel: #ffffff;
            --bd-ink: #13201b;
            --bd-muted: #66736d;
            --bd-line: #dbe3db;
            --bd-green: #0f766e;
            --bd-green-dark: #12352f;
            --bd-sage: #dbead8;
            --bd-gold: #a16f2b;
            --bd-coral: #c95f45;
        }
        .stApp {
            background:
                linear-gradient(180deg, rgba(219, 234, 216, .52), rgba(245, 247, 242, .86) 270px),
                var(--bd-bg);
            color: var(--bd-ink);
        }
        header[data-testid="stHeader"] {
            background: transparent;
        }
        .main .block-container {
            padding-top: 1.4rem;
            max-width: 1240px;
        }
        [data-testid="stSidebar"] {
            background: #11231f;
            border-right: 1px solid rgba(255,255,255,.08);
        }
        [data-testid="stSidebar"] h2,
        [data-testid="stSidebar"] h3,
        [data-testid="stSidebar"] p,
        [data-testid="stSidebar"] label,
        [data-testid="stSidebar"] span {
            color: #eef7f1;
        }
        [data-testid="stSidebar"] [data-baseweb="radio"] label,
        [data-testid="stSidebar"] [data-baseweb="checkbox"] label {
            color: #eef7f1;
        }
        [data-testid="stSidebar"] [data-testid="stCaptionContainer"] {
            color: #b7c9c1;
        }
        div.stButton > button:first-child,
        div.stDownloadButton > button:first-child {
            border: 0;
            border-radius: 8px;
            background: #0f766e;
            color: #ffffff;
            font-weight: 750;
            box-shadow: 0 14px 30px rgba(15, 118, 110, .24);
        }
        div.stButton > button:first-child:hover,
        div.stDownloadButton > button:first-child:hover {
            background: #0c625c;
            color: #ffffff;
            border: 0;
        }
        .bd-hero {
            display: grid;
            grid-template-columns: minmax(0, 1.5fr) minmax(280px, .75fr);
            gap: 1.1rem;
            align-items: stretch;
            border: 1px solid rgba(19, 32, 27, .08);
            border-radius: 8px;
            padding: 1.35rem;
            background:
                linear-gradient(135deg, #12352f 0%, #235143 61%, #7a5a2b 100%);
            box-shadow: 0 24px 70px rgba(18, 53, 47, .2);
            color: #ffffff;
            margin-bottom: 1rem;
            overflow: hidden;
            position: relative;
        }
        .bd-hero h1 {
            margin: .1rem 0 .45rem 0;
            font-size: clamp(2rem, 4vw, 3.35rem);
            line-height: .96;
            letter-spacing: 0;
            color: #ffffff;
        }
        .bd-eyebrow {
            width: fit-content;
            border: 1px solid rgba(255,255,255,.28);
            border-radius: 999px;
            padding: .3rem .65rem;
            color: #d9f2e7;
            font-size: .78rem;
            font-weight: 750;
            text-transform: uppercase;
            background: rgba(255,255,255,.09);
        }
        .bd-hero p {
            color: #e8f3ed;
            margin: 0;
            max-width: 720px;
            line-height: 1.55;
            font-size: 1.02rem;
        }
        .bd-chip-row {
            display: flex;
            flex-wrap: wrap;
            gap: .5rem;
            margin-top: .95rem;
        }
        .bd-chip {
            border-radius: 999px;
            padding: .42rem .7rem;
            background: rgba(255,255,255,.12);
            border: 1px solid rgba(255,255,255,.2);
            color: #ffffff;
            font-size: .86rem;
            font-weight: 700;
        }
        .bd-signal-card {
            background: rgba(255,255,255,.1);
            border: 1px solid rgba(255,255,255,.18);
            border-radius: 8px;
            padding: 1rem;
            display: grid;
            align-content: center;
            gap: .7rem;
        }
        .bd-signal-row {
            display: grid;
            grid-template-columns: 1fr 2.4fr;
            gap: .55rem;
            align-items: center;
        }
        .bd-signal-label {
            font-size: .74rem;
            color: #cfe6dc;
            font-weight: 750;
        }
        .bd-signal-track {
            height: 8px;
            border-radius: 999px;
            background: rgba(255,255,255,.16);
            overflow: hidden;
        }
        .bd-signal-fill {
            height: 100%;
            border-radius: inherit;
            background: #d2b26e;
        }
        .bd-alert {
            border: 1px solid rgba(161,111,43,.22);
            border-left: 4px solid var(--bd-gold);
            border-radius: 8px;
            padding: .95rem 1rem;
            background: #fff8e8;
            color: #3b2b14;
            margin: .9rem 0 1rem 0;
        }
        .bd-alert-title {
            font-size: .82rem;
            font-weight: 850;
            text-transform: uppercase;
            margin-bottom: .25rem;
        }
        .bd-status {
            border: 1px solid rgba(15,118,110,.22);
            border-left: 4px solid var(--bd-green);
            border-radius: 8px;
            padding: .85rem 1rem;
            background: #ecf8f2;
            color: #11392f;
            font-weight: 750;
            margin: .2rem 0 1rem 0;
        }
        .bd-idle {
            border: 1px dashed #bac8bd;
            border-radius: 8px;
            padding: 1.35rem;
            background: rgba(255,255,255,.72);
            box-shadow: 0 12px 40px rgba(19,32,27,.06);
        }
        .bd-idle-title {
            font-size: 1.2rem;
            color: var(--bd-ink);
            font-weight: 850;
            margin-bottom: .3rem;
        }
        .bd-idle-text {
            color: var(--bd-muted);
            line-height: 1.55;
        }
        .bd-section-kicker {
            color: var(--bd-green);
            font-size: .78rem;
            font-weight: 850;
            text-transform: uppercase;
            margin: .8rem 0 .15rem 0;
        }
        .bd-metric-grid {
            display: grid;
            grid-template-columns: repeat(3, minmax(0, 1fr));
            gap: .85rem;
            margin: .75rem 0 1rem 0;
        }
        .bd-metric-card {
            border: 1px solid var(--bd-line);
            border-radius: 8px;
            background: rgba(255,255,255,.9);
            padding: 1rem;
            box-shadow: 0 14px 42px rgba(19,32,27,.07);
        }
        .bd-metric-label {
            color: var(--bd-muted);
            font-size: .76rem;
            font-weight: 850;
            text-transform: uppercase;
        }
        .bd-metric-value {
            color: var(--bd-ink);
            font-size: 2rem;
            font-weight: 850;
            line-height: 1.1;
            margin-top: .2rem;
        }
        .bd-card {
            border: 1px solid var(--bd-line);
            border-radius: 8px;
            padding: 1.05rem;
            margin-bottom: .85rem;
            background: rgba(255,255,255,.92);
            box-shadow: 0 12px 38px rgba(19,32,27,.07);
        }
        .bd-card-title {
            color: var(--bd-green);
            font-size: .9rem;
            font-weight: 850;
            margin-bottom: .35rem;
        }
        .bd-label {
            color: #52615a;
            font-size: .78rem;
            font-weight: 850;
            text-transform: uppercase;
            margin-top: .55rem;
            margin-bottom: .1rem;
        }
        .bd-text {
            color: #111827;
            font-size: .95rem;
            line-height: 1.45;
        }
        .bd-summary-grid {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: .85rem;
            margin: .5rem 0 1rem 0;
        }
        .bd-summary-card {
            border: 1px solid var(--bd-line);
            border-radius: 8px;
            padding: 1rem 1.05rem;
            background: rgba(255,255,255,.94);
            min-height: 130px;
            box-shadow: 0 14px 45px rgba(19,32,27,.07);
            position: relative;
            overflow: hidden;
        }
        .bd-summary-card:before {
            content: "";
            position: absolute;
            inset: 0 auto 0 0;
            width: 4px;
            background: var(--bd-green);
        }
        .bd-summary-label {
            color: var(--bd-green);
            font-size: .82rem;
            font-weight: 800;
            text-transform: uppercase;
            margin-bottom: .45rem;
        }
        .bd-summary-text {
            color: #111827;
            font-size: 1rem;
            line-height: 1.5;
            font-weight: 500;
        }
        div[data-testid="stTabs"] button {
            border-radius: 8px 8px 0 0;
        }
        div[data-testid="stTabs"] button[role="tab"] {
            opacity: 1;
            color: #52615a;
            font-weight: 750;
        }
        div[data-testid="stTabs"] button[role="tab"] p {
            color: #52615a;
            font-weight: 750;
        }
        div[data-testid="stTabs"] button[role="tab"][aria-selected="true"] p {
            color: var(--bd-green);
            font-weight: 850;
        }
        div[data-testid="stDataFrame"] {
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 12px 35px rgba(19,32,27,.06);
        }
        @media (max-width: 820px) {
            .main .block-container {
                padding-left: 1rem;
                padding-right: 1rem;
            }
            .bd-hero {
                grid-template-columns: 1fr;
            }
            .bd-summary-grid,
            .bd-metric-grid {
                grid-template-columns: 1fr;
            }
        }
    </style>
    """,
    unsafe_allow_html=True,
)


def t(key):
    return TEXT[language][key]


def translate_profile(value):
    parts = [part.strip() for part in str(value).split(",") if part.strip()]
    translated = [PROFILE_TRANSLATIONS.get(part, part) for part in parts]
    return ", ".join(translated)


def normalized_lookup_key(value):
    return " ".join(str(value).strip().casefold().split())


def translate_food_item(value):
    item = " ".join(str(value).strip().split())
    return FOOD_TRANSLATIONS_NORMALIZED.get(normalized_lookup_key(item), item)


def translate_general_value(value):
    if pd.isna(value):
        return value
    text = str(value)
    return GENERAL_VALUE_TRANSLATIONS_NORMALIZED.get(normalized_lookup_key(text), text)


def replace_known_food_terms(value):
    translated = str(value)
    for english in sorted(FOOD_TRANSLATIONS, key=len, reverse=True):
        pattern = re.compile(
            rf"(?<![\w-]){re.escape(english)}(?![\w-])",
            flags=re.IGNORECASE,
        )
        translated = pattern.sub(FOOD_TRANSLATIONS[english], translated)
    return translated


def translate_recommendation(value):
    translated = str(value)
    for english, turkish in RECOMMENDATION_TRANSLATIONS.items():
        translated = translated.replace(english, turkish)
    return replace_known_food_terms(translated)


def translate_food_list(value):
    foods = [food.strip() for food in str(value).split(",") if food.strip()]
    translated = [translate_food_item(food) for food in foods]
    return ", ".join(translated)


def translate_guide_value(value):
    return GUIDE_VALUE_TRANSLATIONS.get(str(value), value)


def allergy_label(allergy):
    fallback = ALLERGY_DISPLAY_NAMES.get(allergy, allergy)
    labels = ALLERGY_LABEL_TRANSLATIONS.get(allergy, {"en": fallback, "tr": fallback})
    return labels[language]


def format_product_message(item, messages):
    code = item.get("code")
    template = messages.get(code, {}).get(language, code)
    context = dict(item)
    if "allergens" in context:
        context["allergens"] = ", ".join(allergy_label(allergy) for allergy in context["allergens"])
    try:
        return template.format(**context)
    except Exception:
        return template


def format_product_messages(items, messages):
    return [format_product_message(item, messages) for item in items]


def collect_allergies(selected_allergies, manual_allergies, allergy_pdf):
    detected_from_pdf = []
    allergy_pdf_text = ""
    if allergy_pdf is not None:
        try:
            detected_from_pdf, allergy_pdf_text = extract_allergies_from_pdf_file(allergy_pdf)
        except Exception as exc:
            raise BioDietixPDFError(f"{t('allergy_pdf_file')}: {exc}") from exc

    allergies = normalize_allergies(
        list(selected_allergies or []) + [manual_allergies] + detected_from_pdf
    )
    return allergies, detected_from_pdf, allergy_pdf_text


def render_product_message_list(title, messages):
    if not messages:
        return
    st.markdown(f"**{title}**")
    for message in messages:
        st.write(f"- {message}")


def localize_value(column, value):
    if language != "tr" or pd.isna(value) or str(value).strip() == "":
        return value

    if column == "Health_Profile":
        return translate_profile(value)
    if column == "Nutrition_Recommendation":
        return translate_recommendation(value)
    if column in {"Foods_To_Increase", "Foods_To_Limit"}:
        return translate_food_list(value)
    return translate_general_value(value)


def display_label(column):
    base_labels = {
        "Patient_ID": t("patient_id"),
        "Gender": t("gender"),
        "Age": t("age"),
    }
    if column in COLUMN_LABEL_TRANSLATIONS:
        return COLUMN_LABEL_TRANSLATIONS[column][language]
    return KEY_RESULT_LABELS[language].get(column, base_labels.get(column, column))


@st.cache_data(show_spinner=False)
def cached_data_audit(dataframe):
    return build_data_audit(dataframe)


@st.cache_data(show_spinner=False)
def cached_ml_audit(dataframe, max_rows):
    return run_ml_profile_audit(dataframe, max_rows=max_rows)


@st.cache_data(show_spinner=False)
def cached_food_guide():
    return food_guide_dataframe()


@st.cache_data(show_spinner=False)
def cached_default_results(path_string, modified_ns):
    del modified_ns  # Cache invalidation key; the file content is read below.
    dataframe = read_csv_data(path_string)
    return ensure_recommendation_columns(
        dataframe,
        refresh_existing=True,
        refresh_profiles=True,
    )


def clean_text(value, column=None):
    value = localize_value(column, value) if column else value
    if pd.isna(value) or str(value).strip() == "":
        return t("empty_recommendation")
    return html.escape(str(value).strip())


def render_app_header():
    profile_signal_label = html.escape(KEY_RESULT_LABELS[language]["Health_Profile"].upper())
    st.markdown(
        f"""
        <section class="bd-hero">
            <div>
                <div class="bd-eyebrow">{t("header_eyebrow")}</div>
                <h1>BioDietix ML</h1>
                <p>{t("app_description")}</p>
                <div class="bd-chip-row">
                    <span class="bd-chip">{t("chip_risk_engine")}</span>
                    <span class="bd-chip">{t("chip_pdf_ready")}</span>
                    <span class="bd-chip">{t("chip_food_guide")}</span>
                    <span class="bd-chip">{t("chip_csv_export")}</span>
                </div>
            </div>
            <div class="bd-signal-card">
                <div class="bd-signal-row">
                    <div class="bd-signal-label">CSV</div>
                    <div class="bd-signal-track"><div class="bd-signal-fill" style="width: 92%"></div></div>
                </div>
                <div class="bd-signal-row">
                    <div class="bd-signal-label">PDF</div>
                    <div class="bd-signal-track"><div class="bd-signal-fill" style="width: 78%"></div></div>
                </div>
                <div class="bd-signal-row">
                    <div class="bd-signal-label">{profile_signal_label}</div>
                    <div class="bd-signal-track"><div class="bd-signal-fill" style="width: 86%"></div></div>
                </div>
                <p>{t("hero_note")}</p>
            </div>
        </section>
        """,
        unsafe_allow_html=True,
    )


def render_medical_notice():
    st.markdown(
        f"""
        <div class="bd-alert">
            <div class="bd-alert-title">{t("medical_note_title")}</div>
            <div>{t("medical_warning")}</div>
        </div>
        """,
        unsafe_allow_html=True,
    )


def render_idle_state():
    st.markdown(
        f"""
        <div class="bd-idle">
            <div class="bd-idle-title">{t("idle_title")}</div>
            <div class="bd-idle-text">{t("idle_description")}</div>
        </div>
        """,
        unsafe_allow_html=True,
    )


def key_result_dataframe(results):
    columns = available_columns(
        results,
        ["Patient_ID", "Gender", "Age", "Weight_kg", "Height_cm", "BMI"] + KEY_RESULT_COLUMNS,
    )
    display_data = results[columns].copy()
    for column in columns:
        display_data[column] = display_data[column].apply(
            lambda value, selected_column=column: localize_value(selected_column, value)
        )
    return display_data.rename(columns={column: display_label(column) for column in columns})


def localized_dataframe(dataframe):
    display_data = dataframe.copy()
    if language == "tr":
        for column in display_data.columns:
            display_data[column] = display_data[column].apply(
                lambda value, selected_column=column: localize_value(selected_column, value)
            )
    return display_data.rename(columns={column: display_label(column) for column in display_data.columns})


def render_body_measurement_cards(row):
    columns = available_columns(
        row.to_frame().T,
        ["Age", "Weight_kg", "Height_cm", "BMI", "BMI_Risk_Level"],
    )
    if not columns:
        return

    metrics = []
    for column in columns:
        value = row.get(column)
        if pd.isna(value) or str(value).strip() == "":
            continue
        if column in {"Weight_kg", "Height_cm", "BMI"}:
            value = f"{float(value):.1f}"
        metrics.append((display_label(column), localize_value(column, value)))

    if metrics:
        render_simple_metric_grid(metrics)


def render_key_result_cards(row):
    cards = []
    for column in KEY_RESULT_COLUMNS:
        label = KEY_RESULT_LABELS[language][column]
        value = clean_text(row.get(column, t("empty_recommendation")), column=column)
        cards.append(
            '<div class="bd-summary-card">'
            f'<div class="bd-summary-label">{label}</div>'
            f'<div class="bd-summary-text">{value}</div>'
            "</div>"
        )

    st.markdown(
        f'<div class="bd-summary-grid">{"".join(cards)}</div>',
        unsafe_allow_html=True,
    )


def render_key_results_summary(results):
    st.subheader(t("key_result"))

    if len(results) == 1:
        render_body_measurement_cards(results.iloc[0])
        render_key_result_cards(results.iloc[0])
        return

    st.dataframe(
        key_result_dataframe(results),
        width="stretch",
        hide_index=True,
    )


def render_profile_cards(results):
    display_columns = available_columns(results, OUTPUT_COLUMNS)

    if len(results) > 25:
        card_limit = st.number_input(
            t("card_count"),
            min_value=1,
            max_value=len(results),
            value=10,
            step=5,
        )
    else:
        card_limit = len(results)

    card_data = results[display_columns].head(int(card_limit))

    st.subheader(t("profile_cards"))
    for index, row in card_data.iterrows():
        patient_id = row.get("Patient_ID", index + 1)
        title = f"{t('record_title')} {clean_text(patient_id)}"
        body_values = []
        for column in ["Age", "Weight_kg", "Height_cm", "BMI"]:
            value = row.get(column)
            if pd.notna(value) and str(value).strip() != "":
                if column in {"Weight_kg", "Height_cm", "BMI"}:
                    value = f"{float(value):.1f}"
                body_values.append(f"{display_label(column)}: {clean_text(value, column=column)}")
        body_summary = " | ".join(body_values)
        profile = clean_text(row.get("Health_Profile", "-"), column="Health_Profile")
        recommendation = clean_text(
            row.get("Nutrition_Recommendation", "-"),
            column="Nutrition_Recommendation",
        )
        increase = clean_text(row.get("Foods_To_Increase", "-"), column="Foods_To_Increase")
        limit = clean_text(row.get("Foods_To_Limit", "-"), column="Foods_To_Limit")

        st.markdown(
            '<div class="bd-card">'
            f'<div class="bd-card-title">{title}</div>'
            f'<div class="bd-text">{html.escape(body_summary)}</div>'
            f'<div class="bd-label">{KEY_RESULT_LABELS[language]["Health_Profile"]}</div>'
            f'<div class="bd-text">{profile}</div>'
            f'<div class="bd-label">{KEY_RESULT_LABELS[language]["Nutrition_Recommendation"]}</div>'
            f'<div class="bd-text">{recommendation}</div>'
            f'<div class="bd-label">{KEY_RESULT_LABELS[language]["Foods_To_Increase"]}</div>'
            f'<div class="bd-text">{increase}</div>'
            f'<div class="bd-label">{KEY_RESULT_LABELS[language]["Foods_To_Limit"]}</div>'
            f'<div class="bd-text">{limit}</div>'
            "</div>",
            unsafe_allow_html=True,
        )

    if len(results) > len(card_data):
        st.caption(t("card_limit_note"))


def render_metric_cards(results, profiles):
    low_risk_count = int((results["Health_Profile"] == "Low Risk").sum())
    metrics = [
        (t("records_analyzed"), f"{len(results):,}"),
        (t("unique_profiles"), f"{len(profiles):,}"),
        (t("low_risk_records"), f"{low_risk_count:,}"),
    ]
    cards = "".join(
        '<div class="bd-metric-card">'
        f'<div class="bd-metric-label">{html.escape(label)}</div>'
        f'<div class="bd-metric-value">{html.escape(value)}</div>'
        "</div>"
        for label, value in metrics
    )
    st.markdown(f'<div class="bd-metric-grid">{cards}</div>', unsafe_allow_html=True)


def render_simple_metric_grid(metrics):
    cards = "".join(
        '<div class="bd-metric-card">'
        f'<div class="bd-metric-label">{html.escape(str(label))}</div>'
        f'<div class="bd-metric-value">{html.escape(str(value))}</div>'
        "</div>"
        for label, value in metrics
    )
    st.markdown(f'<div class="bd-metric-grid">{cards}</div>', unsafe_allow_html=True)


def render_summary(results):
    profiles = (
        results["Health_Profile"]
        .fillna("Insufficient Data")
        .astype(str)
        .str.split(", ")
        .explode()
        .value_counts()
        .rename_axis("Health_Profile")
        .reset_index(name="Count")
    )
    if language == "tr":
        profiles["Health_Profile"] = profiles["Health_Profile"].apply(translate_profile)
    profiles = profiles.rename(
        columns={
            "Health_Profile": KEY_RESULT_LABELS[language]["Health_Profile"],
            "Count": "Count" if language == "en" else "Sayı",
        }
    )

    render_metric_cards(results, profiles)

    st.markdown(f'<div class="bd-section-kicker">{t("profile_distribution")}</div>', unsafe_allow_html=True)
    st.dataframe(profiles, width="stretch", hide_index=True)


def render_project_audit(results, run_ml_audit_enabled, audit_rows):
    st.markdown(f'<div class="bd-section-kicker">{t("audit_section")}</div>', unsafe_allow_html=True)

    audit = cached_data_audit(results)
    summary = audit["summary"]
    render_simple_metric_grid(
        [
            (t("rows"), f'{summary["Rows"]:,}'),
            (t("columns"), f'{summary["Columns"]:,}'),
            (t("duplicates"), f'{summary["Duplicate_Patient_IDs"]:,}'),
            (t("missing_cells"), f'{summary["Missing_Cells_Percent"]}%'),
            (t("model_features"), f'{summary["Model_Features_Available"]:,}'),
            (t("target_classes"), f'{summary["Target_Classes"]:,}'),
        ]
    )
    st.caption(f'{t("age_range")}: {summary["Age_Min"]:.0f} - {summary["Age_Max"]:.0f}')

    data_tab, ml_tab = st.tabs([t("data_readiness"), t("ml_readiness")])
    with data_tab:
        guide = cached_food_guide().rename(
            columns={
                "Category": t("guide_category"),
                "Condition_Risk": t("guide_condition"),
                "Foods_To_Limit": t("guide_limit"),
                "Foods_To_Increase": t("guide_increase"),
                "Purpose": t("guide_purpose"),
            }
        )
        if language == "tr":
            for column in [t("guide_category"), t("guide_condition"), t("guide_purpose")]:
                guide[column] = guide[column].apply(translate_guide_value)
            for column in [t("guide_limit"), t("guide_increase")]:
                guide[column] = guide[column].apply(translate_food_list)
        st.subheader(t("food_guide"))
        st.dataframe(guide, width="stretch", hide_index=True)
        st.subheader(t("target_distribution"))
        st.dataframe(
            audit["target_distribution"].head(20),
            width="stretch",
            hide_index=True,
        )
        st.subheader(t("feature_coverage"))
        st.dataframe(
            audit["feature_coverage"],
            width="stretch",
            hide_index=True,
        )
        st.subheader(t("missing_table"))
        st.dataframe(
            audit["missing_table"].head(20),
            width="stretch",
            hide_index=True,
        )

    with ml_tab:
        st.info(t("ml_audit_note"))
        if not run_ml_audit_enabled:
            st.warning(t("ml_not_run"))
            return
        try:
            ml_audit = cached_ml_audit(results, audit_rows)
        except MLAuditError as exc:
            st.warning(f"{t('ml_not_available')}: {exc}")
            return

        render_simple_metric_grid(
            [
                (t("training_rows"), f'{ml_audit["sample_rows"]:,}'),
                (t("target_classes"), f'{ml_audit["target_classes"]:,}'),
                (t("model_features"), f'{ml_audit["feature_count"]:,}'),
            ]
        )
        st.subheader(t("ml_readiness"))
        st.dataframe(ml_audit["metrics"], width="stretch", hide_index=True)
        st.subheader(t("top_features"))
        st.dataframe(ml_audit["feature_importance"], width="stretch", hide_index=True)


def render_product_checker(profile_memory):
    st.subheader(t("product_check_title"))
    st.caption(t("product_check_note"))

    if not profile_memory:
        st.info(t("no_profile_memory"))
        return

    st.caption(t("profile_memory_saved"))
    allergies = profile_memory.get("allergies", [])
    if allergies:
        st.write(f"{t('allergy_profile')}: {', '.join(allergy_label(allergy) for allergy in allergies)}")

    barcode = st.text_input(t("barcode"), key="product_barcode")
    if st.button(t("lookup_product")):
        try:
            looked_up = lookup_open_food_facts_product(barcode)
        except Exception:
            looked_up = None

        if looked_up:
            for field, value in looked_up.items():
                st.session_state[f"product_{field}"] = "" if value is None else value
            st.success(t("lookup_success"))
        else:
            st.warning(t("lookup_not_found"))

    product_name = st.text_input(t("product_name"), key="product_name")
    product_category = st.text_input(t("product_category"), key="product_category")
    ingredients_text = st.text_area(t("ingredients"), key="product_ingredients_text", height=90)
    allergens_text = st.text_area(t("declared_allergens"), key="product_allergens_text", height=70)

    st.markdown(f"**{t('nutrition_per_100g')}**")
    col1, col2, col3, col4 = st.columns(4)
    with col1:
        energy_kcal = st.number_input(t("energy_kcal"), min_value=0.0, value=0.0, step=1.0, key="product_energy_kcal_100g")
        sugar_g = st.number_input(t("sugar_g"), min_value=0.0, value=0.0, step=0.1, key="product_sugar_g_100g")
    with col2:
        saturated_fat_g = st.number_input(t("saturated_fat_g"), min_value=0.0, value=0.0, step=0.1, key="product_saturated_fat_g_100g")
        salt_g = st.number_input(t("salt_g"), min_value=0.0, value=0.0, step=0.1, key="product_salt_g_100g")
    with col3:
        sodium_mg = st.number_input(t("sodium_mg"), min_value=0.0, value=0.0, step=10.0, key="product_sodium_mg_100g")
        protein_g = st.number_input(t("protein_g"), min_value=0.0, value=0.0, step=0.1, key="product_protein_g_100g")
    with col4:
        fiber_g = st.number_input(t("fiber_g"), min_value=0.0, value=0.0, step=0.1, key="product_fiber_g_100g")

    if st.button(t("evaluate_product"), type="primary"):
        product = {
            "barcode": barcode,
            "name": product_name,
            "category": product_category,
            "ingredients_text": ingredients_text,
            "allergens_text": allergens_text,
            "energy_kcal_100g": energy_kcal or None,
            "sugar_g_100g": sugar_g or None,
            "saturated_fat_g_100g": saturated_fat_g or None,
            "salt_g_100g": salt_g or None,
            "sodium_mg_100g": sodium_mg or None,
            "protein_g_100g": protein_g or None,
            "fiber_g_100g": fiber_g or None,
        }
        evaluation = evaluate_product_for_profile(product, profile_memory)
        decision_key = evaluation["decision"]
        st.markdown(f"**{t('product_decision')}: {t(decision_key)}**")
        render_product_message_list(
            t("product_reasons"),
            format_product_messages(evaluation.get("reasons", []), PRODUCT_REASON_TEXT),
        )
        render_product_message_list(
            t("product_positives"),
            format_product_messages(evaluation.get("positives", []), PRODUCT_POSITIVE_TEXT),
        )
        render_product_message_list(
            t("product_alternatives"),
            format_product_messages(evaluation.get("alternatives", []), PRODUCT_ALTERNATIVE_TEXT),
        )
        st.caption(t("product_medical_note"))


def render_results(
    results,
    extracted_values=None,
    extracted_text=None,
    run_ml_audit_enabled=True,
    audit_rows=1000,
    profile_memory=None,
):
    st.markdown(f'<div class="bd-section-kicker">{t("result_section")}</div>', unsafe_allow_html=True)
    st.markdown(f'<div class="bd-status">{t("completed")}</div>', unsafe_allow_html=True)

    tabs = st.tabs([
        t("summary_tab"),
        t("cards_tab"),
        t("table_tab"),
        t("risk_tab"),
        t("audit_tab"),
        t("product_tab"),
    ])

    with tabs[0]:
        render_key_results_summary(results)
        render_summary(results)
        if extracted_values:
            st.subheader(t("pdf_values"))
            values_df = pd.DataFrame(
                extracted_values.items(),
                columns=[t("table_field"), t("table_value")],
            )
            st.dataframe(values_df, width="stretch", hide_index=True)

    with tabs[1]:
        render_profile_cards(results)

    with tabs[2]:
        st.dataframe(
            key_result_dataframe(results),
            width="stretch",
            hide_index=True,
        )

    with tabs[3]:
        risk_columns = available_columns(results, RISK_COLUMNS)
        base_columns = available_columns(results, ["Patient_ID", "Gender", "Age", "Weight_kg", "Height_cm", "BMI"])
        st.dataframe(
            localized_dataframe(results[base_columns + risk_columns]),
            width="stretch",
            hide_index=True,
        )
        if extracted_text:
            with st.expander(t("pdf_text_preview")):
                st.text(extracted_text[:4000])

    with tabs[4]:
        render_project_audit(results, run_ml_audit_enabled, audit_rows)

    with tabs[5]:
        render_product_checker(profile_memory)

    st.download_button(
        t("download_csv"),
        data=dataframe_to_csv_bytes(results),
        file_name="biodietix_web_results.csv",
        mime="text/csv",
    )


language_options = ["English", "Türkçe"]
language_codes = {"English": "en", "Türkçe": "tr"}
stored_language_name = st.session_state.get("language_name", "English")
stored_language = language_codes.get(stored_language_name, "en")

with st.sidebar:
    language_name = st.selectbox(
        TEXT[stored_language]["language"],
        language_options,
        index=language_options.index(stored_language_name),
        key="language_name",
    )

language = language_codes[language_name]

render_app_header()
render_medical_notice()

with st.sidebar:
    st.header(t("data_source"))
    source_labels = {
        t("default_csv"): "default_csv",
        t("upload_csv"): "upload_csv",
        t("upload_pdf"): "upload_pdf",
    }
    source_label = st.radio(
        t("analysis_type"),
        list(source_labels.keys()),
    )
    source_type = source_labels[source_label]

    uploaded_csv = None
    uploaded_pdf = None
    uploaded_allergy_pdf = None
    gender = "Female"
    age = 22
    weight_kg = None
    height_cm = None
    run_ml_audit_enabled = source_type != "upload_pdf"
    audit_rows = 1000

    if source_type == "default_csv":
        default_file_name = (
            DEFAULT_RECOMMENDATION_PATH.name
            if DEFAULT_RECOMMENDATION_PATH.exists()
            else DEFAULT_DATA_PATH.name
        )
        st.caption(f"{t('current_file')}: {default_file_name}")
    elif source_type == "upload_csv":
        uploaded_csv = st.file_uploader(t("csv_file"), type=["csv"])
    else:
        uploaded_pdf = st.file_uploader(t("pdf_file"), type=["pdf"])
        gender = st.selectbox(
            t("gender"),
            ["Female", "Male"],
            format_func=lambda value: t("female") if value == "Female" else t("male"),
        )
        age = st.number_input(t("age"), min_value=18, max_value=120, value=22, step=1)
        st.markdown(f"**{t('anthropometrics')}**")
        st.caption(t("optional_zero"))
        weight_input = st.number_input(
            t("weight_kg"),
            min_value=0.0,
            max_value=350.0,
            value=0.0,
            step=0.5,
        )
        height_input = st.number_input(
            t("height_cm"),
            min_value=0.0,
            max_value=250.0,
            value=0.0,
            step=0.5,
        )
        weight_kg = weight_input if weight_input > 0 else None
        height_cm = height_input if height_input > 0 else None

    st.markdown(f"**{t('allergy_profile')}**")
    selected_allergies = st.multiselect(
        t("common_allergies"),
        COMMON_ALLERGIES,
        format_func=allergy_label,
    )
    manual_allergies = st.text_input(
        t("manual_allergies"),
        help=t("manual_allergies_help"),
    )
    uploaded_allergy_pdf = st.file_uploader(
        t("allergy_pdf_file"),
        type=["pdf"],
        key="allergy_pdf_upload",
    )
    st.caption(t("allergy_pdf_note"))
    health_upload_consent = st.checkbox(t("health_upload_consent"), value=False)

    if source_type != "upload_pdf":
        run_ml_audit_enabled = st.checkbox(
            t("run_ml_audit"),
            value=True,
            help=t("run_ml_audit_help"),
        )
        audit_rows = st.slider(
            t("audit_rows"),
            min_value=500,
            max_value=3000,
            value=1000,
            step=500,
        )

    analyze_clicked = st.button(t("run_analysis"), type="primary")


analysis_failed = False

if analyze_clicked:
    try:
        with st.spinner(t("running")):
            if (uploaded_pdf is not None or uploaded_allergy_pdf is not None) and not health_upload_consent:
                raise BioDietixPDFError(t("health_upload_consent_required"))
            allergies, detected_allergies, allergy_pdf_text = collect_allergies(
                selected_allergies,
                manual_allergies,
                uploaded_allergy_pdf,
            )
            extracted_values = {}
            extracted_text = None

            if source_type == "default_csv":
                if DEFAULT_RECOMMENDATION_PATH.exists():
                    results_df = cached_default_results(
                        str(DEFAULT_RECOMMENDATION_PATH),
                        DEFAULT_RECOMMENDATION_PATH.stat().st_mtime_ns,
                    )
                else:
                    input_df = read_csv_data(DEFAULT_DATA_PATH)
                    results_df = analyze_dataframe(input_df)

            elif source_type == "upload_csv":
                if uploaded_csv is None:
                    raise BioDietixDataError(t("upload_csv_required"))
                input_df = read_csv_data(uploaded_csv)
                results_df = analyze_dataframe(input_df)

            else:
                if uploaded_pdf is not None:
                    pdf_source = uploaded_pdf
                else:
                    raise BioDietixPDFError(t("upload_pdf_required"))

                results_df, extracted_values, extracted_text = analyze_pdf_file(
                    pdf_source,
                    gender=gender,
                    age=int(age),
                    weight_kg=weight_kg,
                    height_cm=height_cm,
                )

            if detected_allergies:
                extracted_values["Detected_Allergies"] = ", ".join(
                    allergy_label(allergy) for allergy in detected_allergies
                )

            profile_memory = build_profile_memory(
                results_df,
                allergies=allergies,
                extracted_values=extracted_values,
            )
            if allergy_pdf_text:
                profile_memory["allergy_pdf_text_preview"] = allergy_pdf_text[:4000]

            st.session_state["last_results"] = results_df
            st.session_state["last_extracted_values"] = extracted_values
            st.session_state["last_extracted_text"] = extracted_text
            st.session_state["last_run_ml_audit_enabled"] = run_ml_audit_enabled if source_type != "upload_pdf" else False
            st.session_state["last_audit_rows"] = audit_rows
            st.session_state["latest_profile_memory"] = profile_memory

    except BioDietixDataError as exc:
        analysis_failed = True
        st.error(str(exc))
    except BioDietixPDFError as exc:
        analysis_failed = True
        st.error(str(exc))
    except Exception as exc:
        analysis_failed = True
        st.error(f"{t('unexpected_error')}: {exc}")

if not analysis_failed and "last_results" in st.session_state:
    render_results(
        st.session_state["last_results"],
        extracted_values=st.session_state.get("last_extracted_values"),
        extracted_text=st.session_state.get("last_extracted_text"),
        run_ml_audit_enabled=st.session_state.get("last_run_ml_audit_enabled", True),
        audit_rows=st.session_state.get("last_audit_rows", 1000),
        profile_memory=st.session_state.get("latest_profile_memory"),
    )
elif not analyze_clicked:
    render_idle_state()
