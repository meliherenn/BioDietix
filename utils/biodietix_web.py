from pathlib import Path
from tempfile import NamedTemporaryFile

import pandas as pd

from biodietix import (
    analyze_pdf_report,
    apply_risk_engine,
    create_health_profile,
    enrich_anthropometrics,
    generate_recommendations,
)
from utils.food_recommendation_guide import FOOD_GUIDE_PATH


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_DATA_PATH = PROJECT_ROOT / "BioDietix_CLEAN.csv"
DEFAULT_RECOMMENDATION_PATH = PROJECT_ROOT / "BioDietix_Recommendation_System.csv"
DEFAULT_PDF_PATH = PROJECT_ROOT / "29.01.2025.pdf"
DEFAULT_FOOD_GUIDE_PATH = FOOD_GUIDE_PATH

REQUIRED_ANALYSIS_COLUMNS = [
    "Gender",
    "Glucose_mgdL",
    "HbA1c_Percent",
    "Waist_Circumference_cm",
    "BP_Systolic_mmHg",
    "BP_Diastolic_mmHg",
    "Cholesterol_Total_mgdL",
    "Cholesterol_LDL_mgdL",
    "Triglycerides_mgdL",
    "Kidney_Creatinine_mgdL",
    "Hemoglobin_gdL",
    "Liver_AST_UL",
    "Daily_Fiber_g",
    "Daily_Sugar_g",
    "Daily_Fat_g",
    "Daily_Cholesterol_mg",
    "White_Blood_Cells_count",
    "Red_Blood_Cells_count",
    "Hematocrit_Percent",
    "Platelet_count",
]

ANTHROPOMETRIC_COLUMNS = [
    "BMI",
    "Weight_kg",
    "Height_cm",
]

NUMERIC_ANALYSIS_COLUMNS = [
    column for column in REQUIRED_ANALYSIS_COLUMNS if column != "Gender"
] + ANTHROPOMETRIC_COLUMNS

OUTPUT_COLUMNS = [
    "Patient_ID",
    "Gender",
    "Age",
    "Weight_kg",
    "Height_cm",
    "BMI",
    "Health_Profile",
    "Nutrition_Recommendation",
    "Foods_To_Increase",
    "Foods_To_Limit",
]

RECOMMENDATION_COLUMNS = [
    "Nutrition_Recommendation",
    "Foods_To_Increase",
    "Foods_To_Limit",
]

RISK_COLUMNS = [
    "Age_Group",
    "Age_Risk_Level",
    "Glucose_Risk_Level",
    "HbA1c_Risk_Level",
    "BMI_Risk_Level",
    "Waist_Risk_Level",
    "BP_Risk_Level",
    "Cholesterol_Risk_Level",
    "LDL_Risk_Level",
    "HDL_Risk_Level",
    "Triglyceride_Risk_Level",
    "Creatinine_Risk_Level",
    "eGFR_Risk_Level",
    "Hemoglobin_Risk_Level",
    "ALT_Risk_Level",
    "AST_Risk_Level",
    "CRP_Risk_Level",
    "VitaminD_Risk_Level",
    "B12_Risk_Level",
    "Folate_Risk_Level",
    "Ferritin_Risk_Level",
    "Fiber_Risk_Level",
    "Sugar_Risk_Level",
    "Diet_Quality_Risk_Level",
    "WBC_Risk_Level",
    "RBC_Risk_Level",
    "Hematocrit_Risk_Level",
    "Platelet_Risk_Level",
    "TSH_Risk_Level",
]

FALLBACK_RECOMMENDATION = (
    "Bu profil için özel öneri üretilemedi. Dengeli öğünler, yeterli protein, "
    "sebze, meyve ve tam tahıl ağırlıklı beslenme tercih edin; kişisel sağlık "
    "kararları için bir sağlık profesyoneline danışın. Bu uygulama tıbbi "
    "teşhis yapmaz."
)

FALLBACK_INCREASE_FOODS = (
    "vegetables, fruits, whole grains, lean protein, healthy fats"
)

FALLBACK_LIMIT_FOODS = (
    "ultra-processed foods, excess sugar, trans fats, large portions"
)


class BioDietixDataError(ValueError):
    """Raised when input data cannot be analyzed."""


class BioDietixPDFError(ValueError):
    """Raised when a PDF report cannot be read or parsed."""


def available_columns(dataframe, columns):
    return [column for column in columns if column in dataframe.columns]


def is_blank(value):
    return pd.isna(value) or str(value).strip() == ""


def ensure_recommendation_columns(dataframe, refresh_existing=False, refresh_profiles=False):
    prepared = dataframe.copy()

    if refresh_profiles:
        prepared = apply_risk_engine(prepared)
        prepared["Health_Profile"] = prepared.apply(create_health_profile, axis=1)
    elif "Health_Profile" not in prepared.columns:
        prepared["Health_Profile"] = "Low Risk"

    generated = prepared.apply(generate_recommendations, axis=1)
    for column in RECOMMENDATION_COLUMNS:
        if refresh_existing or column not in prepared.columns:
            prepared[column] = generated[column]
        else:
            blank_rows = prepared[column].apply(is_blank)
            if blank_rows.any():
                prepared.loc[blank_rows, column] = generated.loc[blank_rows, column]

    fallback_values = {
        "Nutrition_Recommendation": FALLBACK_RECOMMENDATION,
        "Foods_To_Increase": FALLBACK_INCREASE_FOODS,
        "Foods_To_Limit": FALLBACK_LIMIT_FOODS,
    }
    for column, fallback in fallback_values.items():
        prepared[column] = prepared[column].apply(
            lambda value: fallback if is_blank(value) else value
        )

    return prepared


def read_csv_data(source):
    try:
        dataframe = pd.read_csv(source)
    except Exception as exc:
        raise BioDietixDataError(f"CSV okunamadi: {exc}") from exc

    if dataframe.empty:
        raise BioDietixDataError("Veri bos. Analiz icin en az bir satir gerekli.")

    return dataframe


def validate_analysis_columns(dataframe):
    missing_columns = [
        column for column in REQUIRED_ANALYSIS_COLUMNS if column not in dataframe.columns
    ]
    if missing_columns:
        missing = ", ".join(missing_columns)
        raise BioDietixDataError(f"Beklenen kolonlar eksik: {missing}")

    has_bmi = "BMI" in dataframe.columns
    has_weight_height = {"Weight_kg", "Height_cm"}.issubset(dataframe.columns)
    if not has_bmi and not has_weight_height:
        raise BioDietixDataError(
            "BMI kolonu yoksa Weight_kg ve Height_cm kolonlari birlikte gerekli."
        )


def normalize_gender(value):
    text = str(value).strip().lower()
    if text in {"male", "m", "erkek"}:
        return "Male"
    if text in {"female", "f", "kadin", "kadın"}:
        return "Female"
    return value


def prepare_analysis_input(dataframe, adults_only=True):
    validate_analysis_columns(dataframe)
    prepared = dataframe.copy()

    prepared["Gender"] = prepared["Gender"].apply(normalize_gender)

    for column in NUMERIC_ANALYSIS_COLUMNS:
        if column in prepared.columns:
            prepared[column] = pd.to_numeric(prepared[column], errors="coerce")

    prepared = enrich_anthropometrics(prepared)

    if "Age" in prepared.columns:
        prepared["Age"] = pd.to_numeric(prepared["Age"], errors="coerce")
        if adults_only:
            prepared = prepared[prepared["Age"].isna() | (prepared["Age"] >= 18)].copy()

    if prepared.empty:
        raise BioDietixDataError(
            "Filtreleme sonrasi veri bos kaldi. Yetiskin hasta satiri bulunamadi."
        )

    return prepared


def analyze_dataframe(dataframe, adults_only=True):
    prepared = prepare_analysis_input(dataframe, adults_only=adults_only)
    analyzed = apply_risk_engine(prepared)
    analyzed["Health_Profile"] = analyzed.apply(create_health_profile, axis=1)
    analyzed[
        [
            "Nutrition_Recommendation",
            "Foods_To_Increase",
            "Foods_To_Limit",
        ]
    ] = analyzed.apply(generate_recommendations, axis=1)
    return ensure_recommendation_columns(analyzed)


def analyze_pdf_file(file_or_path, gender="Female", age=22, weight_kg=None, height_cm=None):
    temporary_path = None

    try:
        if isinstance(file_or_path, (str, Path)):
            pdf_path = Path(file_or_path)
        else:
            suffix = Path(getattr(file_or_path, "name", "report.pdf")).suffix or ".pdf"
            with NamedTemporaryFile(delete=False, suffix=suffix) as temporary_file:
                temporary_file.write(file_or_path.getbuffer())
                temporary_path = Path(temporary_file.name)
            pdf_path = temporary_path

        patient_df, lab_values, text = analyze_pdf_report(
            str(pdf_path),
            gender=gender,
            age=age,
            weight_kg=weight_kg,
            height_cm=height_cm,
        )
    except ImportError as exc:
        raise BioDietixPDFError(str(exc)) from exc
    except FileNotFoundError as exc:
        raise BioDietixPDFError("PDF dosyasi bulunamadi.") from exc
    except Exception as exc:
        raise BioDietixPDFError(f"PDF okunamadi: {exc}") from exc
    finally:
        if temporary_path and temporary_path.exists():
            temporary_path.unlink()

    extracted_values = {}
    for key, value in lab_values.items():
        if key in patient_df.columns and pd.notna(patient_df.loc[0, key]):
            extracted_values[key] = patient_df.loc[0, key]
        elif pd.notna(value):
            extracted_values[key] = value

    if not extracted_values:
        raise BioDietixPDFError(
            "PDF okundu ancak desteklenen laboratuvar degeri bulunamadi."
        )

    return ensure_recommendation_columns(patient_df), extracted_values, text


def dataframe_to_csv_bytes(dataframe):
    return dataframe.to_csv(index=False).encode("utf-8")
