import html

import pandas as pd
import streamlit as st

from utils.biodietix_web import (
    BioDietixDataError,
    BioDietixPDFError,
    DEFAULT_DATA_PATH,
    DEFAULT_PDF_PATH,
    DEFAULT_RECOMMENDATION_PATH,
    OUTPUT_COLUMNS,
    RISK_COLUMNS,
    analyze_dataframe,
    analyze_pdf_file,
    available_columns,
    dataframe_to_csv_bytes,
    read_csv_data,
)
from utils.biodietix_audit import (
    MLAuditError,
    build_data_audit,
    run_ml_profile_audit,
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
        "use_sample_pdf": "Use sample PDF from repository",
        "gender": "Gender",
        "age": "Age",
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
        "brief_alignment": "Graduation project alignment",
        "brief_alignment_text": (
            "The project now keeps the original nutrition recommendation engine and adds an auditable "
            "ML layer aligned with the PDF brief: real biochemical data, preprocessing, feature selection, "
            "Random Forest / Gradient Boosting baselines, and accuracy / precision / recall / RMSE-style evaluation."
        ),
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
        "use_sample_pdf": "Repodaki örnek PDF'i kullan",
        "gender": "Cinsiyet",
        "age": "Yaş",
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
        "brief_alignment": "Bitirme projesi uyumu",
        "brief_alignment_text": (
            "Proje artık orijinal beslenme öneri motorunu korurken PDF özetine uygun denetlenebilir "
            "bir ML katmanı da sunuyor: gerçek biyokimyasal veri, preprocessing, feature selection, "
            "Random Forest / Gradient Boosting temel modelleri ve accuracy / precision / recall / RMSE tarzı değerlendirme."
        ),
    },
}

PROFILE_TRANSLATIONS = {
    "Low Risk": "Düşük Risk",
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
}

FOOD_TRANSLATIONS = {
    "eggs": "yumurta",
    "fish": "balık",
    "yogurt": "yoğurt",
    "dairy products": "süt ürünleri",
    "selenium-rich foods": "selenyumdan zengin besinler",
    "balanced meals": "dengeli öğünler",
    "very low-calorie diets": "çok düşük kalorili diyetler",
    "meal skipping": "öğün atlama",
    "ultra-processed foods": "aşırı işlenmiş gıdalar",
    "excess sugar": "aşırı şeker",
    "vegetables": "sebzeler",
    "fruits": "meyveler",
    "whole grains": "tam tahıllar",
    "lean protein": "yağsız protein",
    "healthy fats": "sağlıklı yağlar",
}


st.set_page_config(
    page_title="BioDietix ML",
    layout="wide",
)


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


def translate_recommendation(value):
    translated = str(value)
    for english, turkish in RECOMMENDATION_TRANSLATIONS.items():
        translated = translated.replace(english, turkish)
    return translated


def translate_food_list(value):
    foods = [food.strip() for food in str(value).split(",") if food.strip()]
    translated = [FOOD_TRANSLATIONS.get(food, food) for food in foods]
    return ", ".join(translated)


def localize_value(column, value):
    if language != "tr" or pd.isna(value) or str(value).strip() == "":
        return value

    if column == "Health_Profile":
        return translate_profile(value)
    if column == "Nutrition_Recommendation":
        return translate_recommendation(value)
    if column in {"Foods_To_Increase", "Foods_To_Limit"}:
        return translate_food_list(value)
    return value


def display_label(column):
    base_labels = {
        "Patient_ID": t("patient_id"),
        "Gender": t("gender"),
        "Age": t("age"),
    }
    return KEY_RESULT_LABELS[language].get(column, base_labels.get(column, column))


@st.cache_data(show_spinner=False)
def cached_data_audit(dataframe):
    return build_data_audit(dataframe)


@st.cache_data(show_spinner=False)
def cached_ml_audit(dataframe, max_rows):
    return run_ml_profile_audit(dataframe, max_rows=max_rows)


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
    columns = available_columns(results, ["Patient_ID", "Gender", "Age"] + KEY_RESULT_COLUMNS)
    display_data = results[columns].copy()
    for column in KEY_RESULT_COLUMNS:
        if column in display_data.columns:
            display_data[column] = display_data[column].apply(
                lambda value, selected_column=column: localize_value(selected_column, value)
            )
    return display_data.rename(columns={column: display_label(column) for column in columns})


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
        .fillna("Low Risk")
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
    st.markdown(
        f"""
        <div class="bd-idle">
            <div class="bd-idle-title">{t("brief_alignment")}</div>
            <div class="bd-idle-text">{t("brief_alignment_text")}</div>
        </div>
        """,
        unsafe_allow_html=True,
    )

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


def render_results(results, extracted_values=None, extracted_text=None, run_ml_audit_enabled=True, audit_rows=1000):
    st.markdown(f'<div class="bd-section-kicker">{t("result_section")}</div>', unsafe_allow_html=True)
    st.markdown(f'<div class="bd-status">{t("completed")}</div>', unsafe_allow_html=True)

    tabs = st.tabs([
        t("summary_tab"),
        t("cards_tab"),
        t("table_tab"),
        t("risk_tab"),
        t("audit_tab"),
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
        base_columns = available_columns(results, ["Patient_ID", "Gender", "Age"])
        st.dataframe(
            results[base_columns + risk_columns],
            width="stretch",
            hide_index=True,
        )
        if extracted_text:
            with st.expander(t("pdf_text_preview")):
                st.text(extracted_text[:4000])

    with tabs[4]:
        render_project_audit(results, run_ml_audit_enabled, audit_rows)

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
    use_sample_pdf = False
    gender = "Female"
    age = 22
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
        use_sample_pdf = st.checkbox(
            f"{t('use_sample_pdf')} ({DEFAULT_PDF_PATH.name})",
            value=False,
        )
        gender = st.selectbox(
            t("gender"),
            ["Female", "Male"],
            format_func=lambda value: t("female") if value == "Female" else t("male"),
        )
        age = st.number_input(t("age"), min_value=18, max_value=120, value=22, step=1)

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


if analyze_clicked:
    try:
        with st.spinner(t("running")):
            if source_type == "default_csv":
                if DEFAULT_RECOMMENDATION_PATH.exists():
                    results_df = read_csv_data(DEFAULT_RECOMMENDATION_PATH)
                else:
                    input_df = read_csv_data(DEFAULT_DATA_PATH)
                    results_df = analyze_dataframe(input_df)
                render_results(
                    results_df,
                    run_ml_audit_enabled=run_ml_audit_enabled,
                    audit_rows=audit_rows,
                )

            elif source_type == "upload_csv":
                if uploaded_csv is None:
                    raise BioDietixDataError(t("upload_csv_required"))
                input_df = read_csv_data(uploaded_csv)
                results_df = analyze_dataframe(input_df)
                render_results(
                    results_df,
                    run_ml_audit_enabled=run_ml_audit_enabled,
                    audit_rows=audit_rows,
                )

            else:
                if use_sample_pdf:
                    pdf_source = DEFAULT_PDF_PATH
                elif uploaded_pdf is not None:
                    pdf_source = uploaded_pdf
                else:
                    raise BioDietixPDFError(t("upload_pdf_required"))

                results_df, extracted_values, extracted_text = analyze_pdf_file(
                    pdf_source,
                    gender=gender,
                    age=int(age),
                )
                render_results(
                    results_df,
                    extracted_values=extracted_values,
                    extracted_text=extracted_text,
                    run_ml_audit_enabled=False,
                    audit_rows=audit_rows,
                )

    except BioDietixDataError as exc:
        st.error(str(exc))
    except BioDietixPDFError as exc:
        st.error(str(exc))
    except Exception as exc:
        st.error(f"{t('unexpected_error')}: {exc}")
else:
    render_idle_state()
