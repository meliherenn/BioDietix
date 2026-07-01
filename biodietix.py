import os
import re
from datetime import datetime
from pathlib import Path

import numpy as np
import pandas as pd

from utils.food_recommendation_guide import add_food_guide_to_recommendations

# =========================================================
# CONFIG
# =========================================================

DATASET_PATH = os.getenv("BIODIETIX_DATASET_PATH", "BioDietix_CLEAN.csv")
PDF_PATH = os.getenv("BIODIETIX_PDF_PATH", "").strip()
ARTIFACT_DIR = Path(os.getenv("BIODIETIX_ARTIFACT_DIR", "artifacts"))

RISK_OUTPUT = ARTIFACT_DIR / "BioDietix_Risk_Analysis.csv"
RECOMMENDATION_OUTPUT = ARTIFACT_DIR / "BioDietix_Recommendation_System.csv"
PDF_OUTPUT = ARTIFACT_DIR / "PDF_Recommendation_Result.csv"


PDF_LAB_DOMAINS = {
    "glycemic": {"Glucose_mgdL", "HbA1c_Percent"},
    "lipids": {
        "Cholesterol_Total_mgdL",
        "Cholesterol_LDL_mgdL",
        "Cholesterol_HDL_mgdL",
        "Triglycerides_mgdL",
    },
    "kidney": {"Kidney_Creatinine_mgdL", "eGFR_ml_min_1_73m2", "Urea_mgdL"},
    "liver": {"Liver_AST_UL", "Liver_ALT_UL"},
    "blood_count": {
        "Hemoglobin_gdL",
        "Hematocrit_Percent",
        "Red_Blood_Cells_count",
        "White_Blood_Cells_count",
        "Platelet_count",
    },
    "inflammation": {"CRP_mg_L", "Sedimentation_mm_h"},
    "micronutrients": {
        "Ferritin_ng_mL",
        "Folate_ng_mL",
        "Vitamin_B12_pg_mL",
        "VitaminD_ng_mL",
        "Iron_ugdL",
        "Calcium_mg_dL",
        "Magnesium_mg_dL",
    },
    "thyroid": {"TSH_mIU_L", "Free_T3_pg_mL", "Free_T4_ng_dL"},
}


def is_risk(value):
    return pd.notna(value) and value != "Normal"


def clean_value(value):
    # A bound such as "<100" is not an exact measurement. Treating it as 100
    # could cross a decision threshold, so omit it until bounded values are
    # represented explicitly by the API schema.
    if re.match(r"\s*[<>]", str(value)):
        return np.nan
    match = re.search(r"[-+]?\d+(?:[.,]\d+)?", str(value))
    if not match:
        return np.nan
    value = match.group(0).replace(",", ".").strip()
    return float(value)


def parse_report_date(value):
    try:
        return datetime.strptime(value, "%d.%m.%Y").date()
    except (TypeError, ValueError):
        return None


def calculate_age(birth_date, report_date):
    if not birth_date or not report_date:
        return np.nan
    return (
        report_date.year
        - birth_date.year
        - ((report_date.month, report_date.day) < (birth_date.month, birth_date.day))
    )


def calculate_bmi(weight_kg, height_cm):
    if pd.isna(weight_kg) or pd.isna(height_cm) or height_cm <= 0:
        return np.nan
    height_m = height_cm / 100
    return round(weight_kg / (height_m**2), 1)


def enrich_anthropometrics(data):
    data = data.copy()
    if "BMI" not in data.columns:
        data["BMI"] = np.nan

    if "Weight_kg" in data.columns:
        data["Weight_kg"] = pd.to_numeric(data["Weight_kg"], errors="coerce")
    if "Height_cm" in data.columns:
        data["Height_cm"] = pd.to_numeric(data["Height_cm"], errors="coerce")

    if "Weight_kg" in data.columns and "Height_cm" in data.columns:
        calculated_bmi = data.apply(
            lambda row: calculate_bmi(row.get("Weight_kg"), row.get("Height_cm")),
            axis=1,
        )
        data["BMI"] = pd.to_numeric(data["BMI"], errors="coerce")
        data["BMI"] = data["BMI"].fillna(calculated_bmi)

    return data


def extract_pdf_text(pdf_path, max_pages=None, max_text_chars=None):
    try:
        import pdfplumber
    except ImportError as exc:
        raise ImportError(
            "PDF analysis requires pdfplumber. Install dependencies with: "
            "pip install -r requirements.txt"
        ) from exc

    max_pages = max_pages or int(os.getenv("BIODIETIX_MAX_PDF_PAGES", "50"))
    max_text_chars = max_text_chars or int(os.getenv("BIODIETIX_MAX_PDF_TEXT_CHARS", "200000"))
    text_parts = []
    text_length = 0

    with pdfplumber.open(pdf_path) as pdf:
        if len(pdf.pages) > max_pages:
            raise ValueError(f"PDF page count exceeds the {max_pages}-page limit.")
        for page in pdf.pages:
            page_text = page.extract_text()
            if page_text:
                text_length += len(page_text) + 1
                if text_length > max_text_chars:
                    raise ValueError("Extracted PDF text exceeds the processing limit.")
                text_parts.append(page_text)

    return "\n".join(text_parts)


# =========================================================
# RISK FUNCTIONS
# =========================================================


def glucose_risk(glucose):
    if pd.isna(glucose):
        return np.nan
    elif glucose < 100:
        return "Normal"
    elif glucose < 126:
        return "Prediabetes-Range Indicator"
    else:
        return "Diabetes-Range Indicator - Clinical Confirmation Needed"


def hba1c_risk(hba1c):
    if pd.isna(hba1c):
        return np.nan
    elif hba1c < 5.7:
        return "Normal"
    elif hba1c < 6.5:
        return "Prediabetes-Range Indicator"
    else:
        return "Diabetes-Range Indicator - Clinical Confirmation Needed"


def bmi_risk(bmi):
    if pd.isna(bmi):
        return np.nan
    elif bmi < 18.5:
        return "Underweight"
    elif bmi < 25:
        return "Normal"
    elif bmi < 30:
        return "Overweight Risk"
    else:
        return "Obesity Risk"


def age_group(age):
    if pd.isna(age):
        return np.nan
    if age < 18:
        return "Under 18"
    if age < 31:
        return "Young Adult"
    if age < 51:
        return "Adult"
    if age < 65:
        return "Midlife"
    return "Older Adult"


def age_risk(age):
    group = age_group(age)
    if pd.isna(group):
        return np.nan
    if group == "Under 18":
        return "Under 18 - Not Supported"
    if group in {"Young Adult", "Adult"}:
        return "Age-Appropriate Adult Focus"
    if group == "Midlife":
        return "Midlife Prevention Focus"
    return "Older Adult Nutrition Focus"


def bp_risk(sys_bp, dia_bp):
    if pd.isna(sys_bp) or pd.isna(dia_bp):
        return np.nan

    if sys_bp > 180 or dia_bp > 120:
        return "Severely Elevated BP Indicator - Prompt Clinical Review"
    if sys_bp < 120 and dia_bp < 80:
        return "Normal"
    elif 120 <= sys_bp < 130 and dia_bp < 80:
        return "Elevated"
    elif (130 <= sys_bp < 140) or (80 <= dia_bp < 90):
        return "Stage 1 Hypertension Risk"
    elif sys_bp >= 140 or dia_bp >= 90:
        return "Stage 2 Hypertension Risk"
    else:
        return np.nan


def cholesterol_risk(chol):
    if pd.isna(chol):
        return np.nan
    elif chol < 200:
        return "Desirable"
    elif chol < 240:
        return "Borderline High"
    else:
        return "High Risk"


def ldl_risk(ldl):
    if pd.isna(ldl):
        return np.nan
    elif ldl < 100:
        return "Optimal"
    elif ldl < 130:
        return "Near Optimal"
    elif ldl < 160:
        return "Borderline High"
    elif ldl < 190:
        return "High"
    else:
        return "Very High"


def triglyceride_risk(tg):
    if pd.isna(tg):
        return np.nan
    elif tg < 150:
        return "Normal"
    elif tg < 200:
        return "Borderline High"
    elif tg < 500:
        return "High"
    else:
        return "Very High"


def creatinine_risk(gender, creatinine):
    if pd.isna(creatinine):
        return np.nan

    if gender == "Male":
        if creatinine < 0.74:
            return "Low"
        elif creatinine <= 1.35:
            return "Normal"
        else:
            return "High Creatinine Indicator"

    elif gender == "Female":
        if creatinine < 0.59:
            return "Low"
        elif creatinine <= 1.04:
            return "Normal"
        else:
            return "High Creatinine Indicator"

    return np.nan


def hemoglobin_risk(gender, hgb):
    if pd.isna(hgb):
        return np.nan

    if gender == "Male":
        if hgb < 13.5:
            return "Low Hemoglobin Risk"
        elif hgb <= 17.5:
            return "Normal"
        else:
            return "High Hemoglobin"

    elif gender == "Female":
        if hgb < 12:
            return "Low Hemoglobin Risk"
        elif hgb <= 15.5:
            return "Normal"
        else:
            return "High Hemoglobin"

    return np.nan


def ast_risk(ast):
    if pd.isna(ast):
        return np.nan
    elif ast <= 40:
        return "Normal"
    else:
        return "Elevated AST Risk"


def alt_risk(gender, alt):
    if pd.isna(alt):
        return np.nan
    upper_limit = 41 if gender == "Male" else 35
    return "Normal" if alt <= upper_limit else "Elevated ALT Risk"


def hdl_risk(gender, hdl):
    if pd.isna(hdl):
        return np.nan
    lower_limit = 40 if gender == "Male" else 50
    return "Low HDL Risk" if hdl < lower_limit else "Normal"


def crp_risk(crp):
    if pd.isna(crp):
        return np.nan
    return "Elevated CRP Indicator" if crp > 5 else "Normal"


def vitamin_d_risk(vitamin_d):
    if pd.isna(vitamin_d):
        return np.nan
    if vitamin_d < 12:
        return "Low Vitamin D Indicator"
    if vitamin_d < 20:
        return "Vitamin D Inadequacy Indicator"
    return "Normal"


def b12_risk(vitamin_b12):
    if pd.isna(vitamin_b12):
        return np.nan
    if vitamin_b12 < 200:
        return "Low Vitamin B12 Indicator"
    if vitamin_b12 < 300:
        return "Borderline Vitamin B12 Indicator"
    return "Normal"


def folate_risk(folate):
    if pd.isna(folate):
        return np.nan
    return "Low Folate Indicator" if folate < 3 else "Normal"


def ferritin_risk(gender, ferritin):
    if pd.isna(ferritin):
        return np.nan
    if ferritin < 30:
        return "Low Ferritin Indicator"
    high_limit = 400 if gender == "Male" else 150
    return "High Ferritin Indicator" if ferritin > high_limit else "Normal"


def egfr_risk(egfr):
    if pd.isna(egfr):
        return np.nan
    return "Reduced eGFR Indicator" if egfr < 60 else "Normal"


def fiber_risk(fiber):
    if pd.isna(fiber):
        return np.nan
    elif fiber >= 25:
        return "Adequate"
    elif fiber >= 15:
        return "Low-Moderate"
    else:
        return "Low Fiber Intake Risk"


def sugar_risk(sugar):
    if pd.isna(sugar):
        return np.nan
    elif sugar <= 25:
        return "Low"
    elif sugar <= 50:
        return "Moderate"
    else:
        return "High Sugar Intake Risk"


def waist_risk(gender, waist):
    if pd.isna(waist):
        return np.nan

    if gender == "Male":
        return "Abdominal Obesity Risk" if waist > 102 else "Normal"

    elif gender == "Female":
        return "Abdominal Obesity Risk" if waist > 88 else "Normal"

    return np.nan


def diet_quality_risk(row):
    """Return a limited fiber-intake signal, not an aggregate diet score.

    The legacy output column name is retained for API/data compatibility. Total
    sugar, total fat, and dietary cholesterol are deliberately not combined:
    those values do not establish overall diet quality without food-pattern,
    added-sugar, energy-intake, and other context.
    """
    diet_cols = ["Daily_Fiber_g", "Daily_Sugar_g", "Daily_Fat_g", "Daily_Cholesterol_mg"]

    if all(pd.isna(row.get(col, np.nan)) for col in diet_cols):
        return np.nan

    fiber_level = row.get("Fiber_Risk_Level")
    if fiber_level == "Low Fiber Intake Risk":
        return "Low Fiber Intake Signal"
    if fiber_level == "Low-Moderate":
        return "Lower Fiber Intake Signal"
    if fiber_level == "Adequate":
        return "No Low-Fiber Intake Signal"
    return "Fiber Intake Not Assessed"


def wbc_risk(wbc):
    if pd.isna(wbc):
        return np.nan
    elif wbc < 4:
        return "Low WBC Indicator"
    elif wbc <= 11:
        return "Normal"
    else:
        return "Elevated WBC Indicator"


def rbc_risk(gender, rbc):
    if pd.isna(rbc):
        return np.nan

    if gender == "Female":
        if rbc < 3.8:
            return "Low RBC Indicator"
        elif rbc <= 5.1:
            return "Normal"
        else:
            return "Elevated RBC Indicator"

    elif gender == "Male":
        if rbc < 4.5:
            return "Low RBC Indicator"
        elif rbc <= 5.9:
            return "Normal"
        else:
            return "Elevated RBC Indicator"

    return np.nan


def hct_risk(gender, hct):
    if pd.isna(hct):
        return np.nan

    if gender == "Female":
        if hct < 35:
            return "Low Hematocrit Indicator"
        elif hct <= 45:
            return "Normal"
        else:
            return "Elevated Hematocrit Indicator"

    elif gender == "Male":
        if hct < 41:
            return "Low Hematocrit Indicator"
        elif hct <= 53:
            return "Normal"
        else:
            return "Elevated Hematocrit Indicator"

    return np.nan


def platelet_risk(plt):
    if pd.isna(plt):
        return np.nan
    elif plt < 150:
        return "Low Platelet Indicator"
    elif plt <= 450:
        return "Normal"
    else:
        return "Elevated Platelet Indicator"


def tsh_risk(tsh):
    if pd.isna(tsh):
        return np.nan
    elif tsh < 0.4:
        return "Low TSH Indicator"
    elif tsh <= 4.5:
        return "Normal"
    else:
        return "Elevated TSH Indicator"


# =========================================================
# APPLY RISK ENGINE
# =========================================================


def apply_risk_engine(data):
    data = enrich_anthropometrics(data)

    if "Age" in data.columns:
        data["Age_Group"] = data["Age"].apply(age_group)
        data["Age_Risk_Level"] = data["Age"].apply(age_risk)

    data["Glucose_Risk_Level"] = data["Glucose_mgdL"].apply(glucose_risk)
    data["HbA1c_Risk_Level"] = data["HbA1c_Percent"].apply(hba1c_risk)
    data["BMI_Risk_Level"] = data["BMI"].apply(bmi_risk)

    data["Waist_Risk_Level"] = data.apply(
        lambda row: waist_risk(row["Gender"], row["Waist_Circumference_cm"]), axis=1
    )

    data["BP_Risk_Level"] = data.apply(
        lambda row: bp_risk(row["BP_Systolic_mmHg"], row["BP_Diastolic_mmHg"]), axis=1
    )

    data["Cholesterol_Risk_Level"] = data["Cholesterol_Total_mgdL"].apply(cholesterol_risk)
    data["LDL_Risk_Level"] = data["Cholesterol_LDL_mgdL"].apply(ldl_risk)
    data["Triglyceride_Risk_Level"] = data["Triglycerides_mgdL"].apply(triglyceride_risk)

    if "Cholesterol_HDL_mgdL" in data.columns:
        data["HDL_Risk_Level"] = data.apply(
            lambda row: hdl_risk(row["Gender"], row["Cholesterol_HDL_mgdL"]), axis=1
        )

    data["Creatinine_Risk_Level"] = data.apply(
        lambda row: creatinine_risk(row["Gender"], row["Kidney_Creatinine_mgdL"]), axis=1
    )

    if "eGFR_ml_min_1_73m2" in data.columns:
        data["eGFR_Risk_Level"] = data["eGFR_ml_min_1_73m2"].apply(egfr_risk)

    data["Hemoglobin_Risk_Level"] = data.apply(
        lambda row: hemoglobin_risk(row["Gender"], row["Hemoglobin_gdL"]), axis=1
    )

    data["AST_Risk_Level"] = data["Liver_AST_UL"].apply(ast_risk)

    if "Liver_ALT_UL" in data.columns:
        data["ALT_Risk_Level"] = data.apply(
            lambda row: alt_risk(row["Gender"], row["Liver_ALT_UL"]), axis=1
        )

    if "CRP_mg_L" in data.columns:
        data["CRP_Risk_Level"] = data["CRP_mg_L"].apply(crp_risk)

    if "VitaminD_ng_mL" in data.columns:
        data["VitaminD_Risk_Level"] = data["VitaminD_ng_mL"].apply(vitamin_d_risk)

    if "Vitamin_B12_pg_mL" in data.columns:
        data["B12_Risk_Level"] = data["Vitamin_B12_pg_mL"].apply(b12_risk)

    if "Folate_ng_mL" in data.columns:
        data["Folate_Risk_Level"] = data["Folate_ng_mL"].apply(folate_risk)

    if "Ferritin_ng_mL" in data.columns:
        data["Ferritin_Risk_Level"] = data.apply(
            lambda row: ferritin_risk(row["Gender"], row["Ferritin_ng_mL"]), axis=1
        )

    data["Fiber_Risk_Level"] = data["Daily_Fiber_g"].apply(fiber_risk)
    data["Sugar_Risk_Level"] = data["Daily_Sugar_g"].apply(sugar_risk)

    data["Diet_Quality_Risk_Level"] = data.apply(diet_quality_risk, axis=1)

    data["WBC_Risk_Level"] = data["White_Blood_Cells_count"].apply(wbc_risk)

    data["RBC_Risk_Level"] = data.apply(
        lambda row: rbc_risk(row["Gender"], row["Red_Blood_Cells_count"]), axis=1
    )

    data["Hematocrit_Risk_Level"] = data.apply(
        lambda row: hct_risk(row["Gender"], row["Hematocrit_Percent"]), axis=1
    )

    data["Platelet_Risk_Level"] = data["Platelet_count"].apply(platelet_risk)

    if "TSH_mIU_L" in data.columns:
        data["TSH_Risk_Level"] = data["TSH_mIU_L"].apply(tsh_risk)

    return data


# =========================================================
# HEALTH PROFILE
# =========================================================


def create_health_profile(row):
    profiles = []

    if is_risk(row.get("Glucose_Risk_Level")) or is_risk(row.get("HbA1c_Risk_Level")):
        profiles.append("Blood Sugar Risk")

    if row.get("BMI_Risk_Level") in ["Overweight Risk", "Obesity Risk"]:
        profiles.append("Weight Management Risk")

    if row.get("BP_Risk_Level") in [
        "Stage 1 Hypertension Risk",
        "Stage 2 Hypertension Risk",
        "Severely Elevated BP Indicator - Prompt Clinical Review",
    ]:
        profiles.append("Blood Pressure Risk")

    if (
        row.get("Cholesterol_Risk_Level") in ["Borderline High", "High Risk"]
        or row.get("LDL_Risk_Level") in ["Borderline High", "High", "Very High"]
        or row.get("Triglyceride_Risk_Level") in ["Borderline High", "High", "Very High"]
    ):
        profiles.append("Cardiovascular Lipid Risk")

    if (
        row.get("Creatinine_Risk_Level") in ["Low", "High Creatinine Indicator"]
        or row.get("eGFR_Risk_Level") == "Reduced eGFR Indicator"
    ):
        profiles.append("Kidney / Muscle Indicator")

    if is_risk(row.get("Hemoglobin_Risk_Level")):
        profiles.append("Hemoglobin Indicator")

    if is_risk(row.get("WBC_Risk_Level")):
        profiles.append("Immune / Inflammation Indicator")

    if is_risk(row.get("RBC_Risk_Level")) or is_risk(row.get("Hematocrit_Risk_Level")):
        profiles.append("Blood Cell / Anemia Support Indicator")

    if is_risk(row.get("Platelet_Risk_Level")):
        profiles.append("Platelet Support Indicator")

    if (
        row.get("AST_Risk_Level") == "Elevated AST Risk"
        or row.get("ALT_Risk_Level") == "Elevated ALT Risk"
    ):
        profiles.append("Liver Enzyme Indicator")

    if row.get("Diet_Quality_Risk_Level") in {
        "Low Fiber Intake Signal",
        "Lower Fiber Intake Signal",
    }:
        profiles.append("Fiber Intake Signal")

    if row.get("Waist_Risk_Level") == "Abdominal Obesity Risk":
        profiles.append("Abdominal Obesity Risk")

    if is_risk(row.get("TSH_Risk_Level")):
        profiles.append("Thyroid / Metabolism Indicator")

    if row.get("HDL_Risk_Level") == "Low HDL Risk":
        profiles.append("Cardiovascular Lipid Risk")

    if is_risk(row.get("CRP_Risk_Level")):
        profiles.append("Immune / Inflammation Indicator")

    if is_risk(row.get("VitaminD_Risk_Level")):
        profiles.append("Vitamin D / Bone Health Indicator")

    if (
        is_risk(row.get("B12_Risk_Level"))
        or is_risk(row.get("Folate_Risk_Level"))
        or is_risk(row.get("Ferritin_Risk_Level"))
    ):
        profiles.append("Micronutrient Support Indicator")

    if row.get("Age_Risk_Level") in ["Midlife Prevention Focus", "Older Adult Nutrition Focus"]:
        profiles.append("Age-Related Nutrition Focus")

    if len(profiles) == 0:
        if row.get("Analysis_Source") == "pdf":
            return "No Flagged Risk in Available Data"
        return "Low Risk"

    return ", ".join(list(dict.fromkeys(profiles)))


# =========================================================
# RECOMMENDATION ENGINE
# =========================================================


def generate_recommendations(row):
    recommendations = []
    increase_foods = []
    limit_foods = []

    age_group_value = row.get("Age_Group")
    if age_group_value == "Young Adult":
        recommendations.append(
            "For this age group, build long-term habits with regular meals, adequate protein, fiber, and physical activity."
        )
        increase_foods.extend(
            ["balanced meals", "lean protein", "whole grains", "vegetables", "fruits"]
        )
        limit_foods.extend(["frequent fast food", "sugary drinks", "meal skipping"])
    elif age_group_value == "Adult":
        recommendations.append(
            "For adult metabolic maintenance, prioritize portion control, fiber, lean protein, and consistent activity."
        )
        increase_foods.extend(["fiber-rich foods", "lean protein", "vegetables", "healthy fats"])
        limit_foods.extend(["large portions", "processed foods", "excess sugar"])
    elif age_group_value == "Midlife":
        recommendations.append(
            "For midlife prevention, focus on cardiovascular health, muscle maintenance, fiber, vitamin D, calcium, and regular checkups."
        )
        increase_foods.extend(
            [
                "fish",
                "low-fat dairy",
                "legumes",
                "vegetables",
                "vitamin D foods",
                "calcium-rich foods",
            ]
        )
        limit_foods.extend(["saturated fat", "excess sodium", "ultra-processed foods"])
    elif age_group_value == "Older Adult":
        recommendations.append(
            "For older adults, protect muscle and bone health with adequate protein, vitamin D, calcium, hydration, and clinically guided follow-up."
        )
        increase_foods.extend(
            ["eggs", "fish", "yogurt", "low-fat dairy", "water", "protein-rich foods"]
        )
        limit_foods.extend(["very low-calorie diets", "dehydration", "high-sodium foods"])

    if "Blood Sugar Risk" in row["Health_Profile"]:
        recommendations.append(
            "Reduce added sugar and refined carbohydrates, and prefer low-glycemic foods."
        )
        increase_foods.extend(["vegetables", "legumes", "oats", "whole grains", "high-fiber foods"])
        limit_foods.extend(["sugary drinks", "desserts", "white bread", "white rice", "pastries"])

    if "Weight Management Risk" in row["Health_Profile"]:
        recommendations.append(
            "Control portion sizes and choose nutrient-dense, lower-calorie meals."
        )
        increase_foods.extend(["lean protein", "vegetables", "low-fat yogurt", "legumes"])
        limit_foods.extend(["fast food", "fried foods", "high-calorie snacks", "processed foods"])

    if row.get("BMI_Risk_Level") == "Underweight":
        recommendations.append(
            "BMI indicates an underweight range. Increase nutrient-dense calories with protein-rich meals and healthy fats, and review unintentional weight loss with a healthcare professional."
        )
        increase_foods.extend(
            [
                "protein-rich foods",
                "nuts",
                "olive oil",
                "yogurt",
                "eggs",
                "legumes",
                "balanced meals",
            ]
        )
        limit_foods.extend(["meal skipping", "very restrictive diets"])

    if "Blood Pressure Risk" in row["Health_Profile"]:
        if row.get("BP_Risk_Level") == "Severely Elevated BP Indicator - Prompt Clinical Review":
            recommendations.append(
                "This blood-pressure value is severely elevated. Recheck it correctly and seek prompt clinical advice; if there are symptoms such as chest pain, shortness of breath, weakness, vision change, or difficulty speaking, use local emergency services."
            )
        recommendations.append("Reduce sodium intake and follow a DASH-style eating pattern.")
        increase_foods.extend(["vegetables", "fruits", "low-fat dairy"])
        limit_foods.extend(
            ["salty snacks", "processed meats", "instant soups", "high-sodium packaged foods"]
        )

    if "Cardiovascular Lipid Risk" in row["Health_Profile"]:
        recommendations.append(
            "Reduce saturated fat and refined carbohydrates; prefer heart-healthy fats."
        )
        increase_foods.extend(["olive oil", "nuts", "fish", "avocado", "fiber-rich foods"])
        limit_foods.extend(
            ["processed meats", "butter", "fried foods", "trans fats", "sugary foods"]
        )

    if "Kidney / Muscle Indicator" in row["Health_Profile"]:
        if row.get("Creatinine_Risk_Level") == "High Creatinine Indicator":
            recommendations.append(
                "A creatinine result should be interpreted with eGFR, hydration, muscle mass, medicines, and the laboratory range. Do not change protein or fluid intake based on this result alone; discuss it with a healthcare professional."
            )
            increase_foods.extend(["fresh vegetables", "balanced meals", "water"])
            limit_foods.extend(
                ["high-dose protein supplements without clinical advice", "high-sodium foods"]
            )

        elif row.get("Creatinine_Risk_Level") == "Low":
            recommendations.append(
                "Support muscle mass with adequate calories, high-quality protein, and regular resistance exercise."
            )
            increase_foods.extend(["eggs", "fish", "yogurt", "legumes", "lean meats"])
            limit_foods.extend(["very low-calorie diets", "meal skipping"])

    if "Hemoglobin Indicator" in row["Health_Profile"]:
        if row.get("Hemoglobin_Risk_Level") == "Low Hemoglobin Risk":
            recommendations.append(
                "A low hemoglobin indicator has several possible causes and should be discussed with a healthcare professional. Iron-containing foods may be reasonable, but do not start iron supplements without clinical advice."
            )
            increase_foods.extend(["lean red meat", "lentils", "beans", "spinach", "citrus fruits"])
            limit_foods.extend(["tea or coffee immediately with iron-rich meals"])

    if "Immune / Inflammation Indicator" in row["Health_Profile"]:
        recommendations.append(
            "Inflammation or blood-cell indicators are nonspecific and should be interpreted with symptoms and other tests. A varied eating pattern with vegetables, fruit, adequate protein, and hydration is a general option."
        )
        increase_foods.extend(
            ["vegetables", "fruits", "berries", "fish", "walnuts", "yogurt", "adequate protein"]
        )
        limit_foods.extend(["ultra-processed foods", "excess sugar", "fried foods"])

    if "Blood Cell / Anemia Support Indicator" in row["Health_Profile"]:
        recommendations.append(
            "Support blood cell health with iron, folate, vitamin B12, vitamin C, and adequate protein intake."
        )
        increase_foods.extend(
            [
                "lean red meat",
                "eggs",
                "fish",
                "lentils",
                "beans",
                "spinach",
                "citrus fruits",
                "dairy products",
            ]
        )
        limit_foods.extend(
            ["tea or coffee immediately with iron-rich meals", "very low-calorie diets"]
        )

    if "Platelet Support Indicator" in row["Health_Profile"]:
        recommendations.append(
            "Maintain balanced nutrition and hydration; platelet-related abnormalities should be interpreted with clinical context."
        )
        increase_foods.extend(["balanced meals", "vegetables", "fruits", "water"])
        limit_foods.extend(["excess alcohol", "ultra-processed foods"])

    if "Liver Enzyme Indicator" in row["Health_Profile"]:
        recommendations.append(
            "Liver enzyme changes should be reviewed with a healthcare professional. Reduce alcohol, fried foods, and excess sugar to support liver health."
        )
        increase_foods.extend(
            ["vegetables", "whole grains", "coffee without sugar", "omega-3 rich foods"]
        )
        limit_foods.extend(["alcohol", "fried foods", "sugary drinks", "processed foods"])

    if "Thyroid / Metabolism Indicator" in row["Health_Profile"]:
        recommendations.append(
            "Thyroid-related lab changes should be reviewed with a healthcare professional and the reporting laboratory's reference range. Do not start iodine, selenium, or thyroid supplements based on this result."
        )
        increase_foods.extend(["balanced meals", "adequate protein", "vegetables"])
        limit_foods.extend(
            ["very low-calorie diets", "meal skipping", "ultra-processed foods", "excess sugar"]
        )

    if "Fiber Intake Signal" in row["Health_Profile"]:
        recommendations.append(
            "Recorded fiber intake appears below the general adult reference used by this app. If the entry reflects your usual intake, consider gradually adding varied fiber sources and discuss individual needs with a dietitian or healthcare professional."
        )
        increase_foods.extend(["vegetables", "fruits", "whole grains", "legumes"])
        limit_foods.extend(["low-fiber refined grains", "low-fiber processed snacks"])

    if "Abdominal Obesity Risk" in row["Health_Profile"]:
        recommendations.append(
            "Focus on weight management, fiber-rich meals, and regular physical activity."
        )
        increase_foods.extend(["high-fiber vegetables", "lean protein", "whole grains"])
        limit_foods.extend(["sugary foods", "refined carbohydrates", "large portions"])

    if "Vitamin D / Bone Health Indicator" in row["Health_Profile"]:
        recommendations.append(
            "A vitamin D indicator should be reviewed with a healthcare professional because thresholds and treatment decisions vary. Food sources of vitamin D, calcium, and protein can be part of a balanced diet; do not start high-dose supplements from this result alone."
        )
        increase_foods.extend(
            [
                "fatty fish",
                "eggs",
                "fortified dairy",
                "yogurt",
                "calcium-rich foods",
                "vitamin D foods",
            ]
        )
        limit_foods.extend(["very low-calorie diets", "nutrient-poor processed foods"])

    if "Micronutrient Support Indicator" in row["Health_Profile"]:
        recommendations.append(
            "Micronutrient indicators require the laboratory range and clinical context. Discuss abnormal results before starting or stopping any supplement."
        )
        if row.get("Ferritin_Risk_Level") == "Low Ferritin Indicator":
            increase_foods.extend(["lentils", "beans", "lean meat", "vitamin C foods"])
            limit_foods.append("tea or coffee immediately with iron-containing meals")
        elif row.get("Ferritin_Risk_Level") == "High Ferritin Indicator":
            recommendations.append(
                "High ferritin can occur for several reasons, including inflammation; do not increase iron intake or use iron supplements unless a clinician advises it."
            )
        if row.get("B12_Risk_Level") in {
            "Low Vitamin B12 Indicator",
            "Borderline Vitamin B12 Indicator",
        }:
            increase_foods.extend(["eggs", "fish", "dairy or fortified alternatives"])
        if row.get("Folate_Risk_Level") == "Low Folate Indicator":
            increase_foods.extend(["leafy greens", "beans", "lentils", "citrus fruits"])
        limit_foods.append("very restrictive diets")

    add_food_guide_to_recommendations(
        row,
        recommendations,
        increase_foods,
        limit_foods,
    )

    if len(recommendations) == 0:
        recommendations.append(
            "Maintain a balanced diet with regular meals, adequate fiber, lean protein, and healthy fats."
        )
        increase_foods.extend(
            ["vegetables", "fruits", "whole grains", "lean protein", "healthy fats"]
        )
        limit_foods.extend(["excess sugar", "processed foods", "trans fats"])

    recommendations = list(dict.fromkeys(recommendations))
    recommendations.append(
        "These are general food-choice suggestions, not medical advice. BioDietix is not a medical device and does not diagnose, treat, cure, or prevent any condition; discuss abnormal results and major diet changes with a qualified healthcare professional."
    )
    increase_foods = list(dict.fromkeys(increase_foods))
    limit_foods = list(dict.fromkeys(limit_foods))

    return pd.Series(
        {
            "Nutrition_Recommendation": " ".join(recommendations),
            "Foods_To_Increase": ", ".join(increase_foods),
            "Foods_To_Limit": ", ".join(limit_foods),
        }
    )


# =========================================================
# PDF PARSER
# =========================================================

test_patterns = {
    "TSH_mIU_L": r"(?im)^\s*TSH\s+([<>]?\s*\d+(?:[.,]\d+)?)",
    "Hemoglobin_gdL": r"(?im)^\s*HGB\s+([<>]?\s*\d+(?:[.,]\d+)?)",
    "Hematocrit_Percent": r"(?im)^\s*HCT\s+([<>]?\s*\d+(?:[.,]\d+)?)",
    "Red_Blood_Cells_count": r"(?im)^\s*RBC\s+([<>]?\s*\d+(?:[.,]\d+)?)",
    "White_Blood_Cells_count": r"(?im)^\s*WBC\s+([<>]?\s*\d+(?:[.,]\d+)?)",
    "Platelet_count": r"(?im)^\s*PLT\s+([<>]?\s*\d+(?:[.,]\d+)?)",
    "Glucose_mgdL": r"(?im)^\s*(?:GLUCOSE|Glucose|GLUKOZ|Glukoz|Açlık Kan Şekeri|Aclik Kan Sekeri)\s+([<>]?\s*\d+(?:[.,]\d+)?)",
    "HbA1c_Percent": r"(?im)^\s*(?:HbA1c|HBA1C|Hemoglobin A1c)\s+([<>]?\s*\d+(?:[.,]\d+)?)",
    "Cholesterol_Total_mgdL": r"(?im)^\s*(?:Total Cholesterol|TOTAL CHOLESTEROL|Kolesterol|Total Kolesterol)\s+([<>]?\s*\d+(?:[.,]\d+)?)",
    "Cholesterol_LDL_mgdL": r"(?im)^\s*(?:LDL kolesterol|LDL cholesterol|LDL Kolesterol|LDL)\s+([<>]?\s*\d+(?:[.,]\d+)?)",
    "Cholesterol_HDL_mgdL": r"(?im)^\s*(?:HDL kolesterol|HDL cholesterol|HDL Kolesterol|HDL)\s+([<>]?\s*\d+(?:[.,]\d+)?)",
    "Triglycerides_mgdL": r"(?im)^\s*(?:Triglyceride|TRIGLYCERIDE|Trigliserid|TG)\s+([<>]?\s*\d+(?:[.,]\d+)?)",
    "Kidney_Creatinine_mgdL": r"(?im)^\s*(?:Creatinine|CREATININE|Kreatinin|KREATININ)\s+([<>]?\s*\d+(?:[.,]\d+)?)",
    "eGFR_ml_min_1_73m2": r"(?im)^\s*eGFR\s+([<>]?\s*\d+(?:[.,]\d+)?)",
    "Liver_AST_UL": r"(?im)^\s*(?:AST|SGOT|Aspartat transaminaz(?:\s*\(AST\))?)\s+([<>]?\s*\d+(?:[.,]\d+)?)",
    "Liver_ALT_UL": r"(?im)^\s*(?:ALT|SGPT|Alanin aminotransferaz(?:\s*\(ALT\))?)\s+([<>]?\s*\d+(?:[.,]\d+)?)",
    "CRP_mg_L": r"(?im)^\s*(?:CRP[, ]*türbidimetrik|CRP)\s+([<>]?\s*\d+(?:[.,]\d+)?)",
    "Ferritin_ng_mL": r"(?im)^\s*Ferritin\s+([<>]?\s*\d+(?:[.,]\d+)?)",
    "Folate_ng_mL": r"(?im)^\s*(?:Folik Asit|Folate|Folat)\s+([<>]?\s*\d+(?:[.,]\d+)?)",
    "Calcium_mg_dL": r"(?im)^\s*(?:Kalsiyum\s*\(Ca\)|Calcium)\s+([<>]?\s*\d+(?:[.,]\d+)?)",
    "Magnesium_mg_dL": r"(?im)^\s*(?:Magnezyum|Magnesium)\s+([<>]?\s*\d+(?:[.,]\d+)?)",
    "Urea_mgdL": r"(?im)^\s*(?:Üre|Ure|Urea)(?:\s*\(Serum/Plazma\))?\s+([<>]?\s*\d+(?:[.,]\d+)?)",
    "Vitamin_B12_pg_mL": r"(?im)^\s*(?:Vitamin B12|B12)\s+([<>]?\s*\d+(?:[.,]\d+)?)",
    "VitaminD_ng_mL": r"(?im)^\s*(?:25-Hidroksi Vitamin D|25 Hydroxy Vitamin D|Vitamin D)\s+([<>]?\s*\d+(?:[.,]\d+)?)",
    "Iron_ugdL": r"(?im)^\s*(?:Demir \(Serum\)|Iron)\s+([<>]?\s*\d+(?:[.,]\d+)?)",
    "Iron_Binding_Capacity_ugdL": r"(?im)^\s*(?:Demir bağlama kapasitesi|Total Iron Binding Capacity|TIBC)\s+([<>]?\s*\d+(?:[.,]\d+)?)",
    "Sedimentation_mm_h": r"(?im)^\s*(?:Sedimentasyon|ESR)\s+([<>]?\s*\d+(?:[.,]\d+)?)",
    "Free_T3_pg_mL": r"(?im)^\s*(?:Serbest T3|Free T3|FT3)\s+([<>]?\s*\d+(?:[.,]\d+)?)",
    "Free_T4_ng_dL": r"(?im)^\s*(?:Serbest T4|Free T4|FT4)\s+([<>]?\s*\d+(?:[.,]\d+)?)",
}

# The standardized field names encode their expected units. Values carrying a
# different unit must not be silently interpreted on the wrong scale.
incompatible_unit_patterns = {
    "Glucose_mgdL": r"\bmmol\s*/?\s*l\b",
    "Cholesterol_Total_mgdL": r"\bmmol\s*/?\s*l\b",
    "Cholesterol_LDL_mgdL": r"\bmmol\s*/?\s*l\b",
    "Cholesterol_HDL_mgdL": r"\bmmol\s*/?\s*l\b",
    "Triglycerides_mgdL": r"\bmmol\s*/?\s*l\b",
    "Kidney_Creatinine_mgdL": r"(?:µ|μ|u)mol\s*/?\s*l\b",
    "VitaminD_ng_mL": r"\bnmol\s*/?\s*l\b",
    "Vitamin_B12_pg_mL": r"\bpmol\s*/?\s*l\b",
    "Folate_ng_mL": r"\bnmol\s*/?\s*l\b",
    "Iron_ugdL": r"(?:µ|μ|u)mol\s*/?\s*l\b",
    "Calcium_mg_dL": r"\bmmol\s*/?\s*l\b",
    "Magnesium_mg_dL": r"\bmmol\s*/?\s*l\b",
    "Urea_mgdL": r"\bmmol\s*/?\s*l\b",
}


def extract_patient_metadata(text):
    metadata = {}

    gender_match = re.search(r"Cinsiyet:\s*(Erkek|Kadın|Kadin|Male|Female)", text, re.IGNORECASE)
    if gender_match:
        gender_text = gender_match.group(1).strip().casefold()
        metadata["Gender"] = "Male" if gender_text in {"erkek", "male"} else "Female"

    report_date_match = re.search(r"\bTarih:\s*(\d{2}\.\d{2}\.\d{4})", text)
    birth_date_match = re.search(r"Doğum Tarihi:\s*(\d{2}\.\d{2}\.\d{4})", text)
    report_date = parse_report_date(report_date_match.group(1)) if report_date_match else None
    birth_date = parse_report_date(birth_date_match.group(1)) if birth_date_match else None

    if report_date:
        metadata["Report_Date"] = report_date.isoformat()
    if birth_date:
        metadata["Birth_Date"] = birth_date.isoformat()

    age = calculate_age(birth_date, report_date)
    if pd.notna(age):
        metadata["Age"] = int(age)

    return metadata


def extract_lab_values(text):
    results = {}

    for standard_name, pattern in test_patterns.items():
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            line_end = text.find("\n", match.end())
            if line_end == -1:
                line_end = len(text)
            matched_line = text[match.start() : line_end]
            incompatible_pattern = incompatible_unit_patterns.get(standard_name)
            if incompatible_pattern and re.search(
                incompatible_pattern,
                matched_line,
                re.IGNORECASE,
            ):
                results[standard_name] = np.nan
            else:
                results[standard_name] = clean_value(match.group(1))
        else:
            results[standard_name] = np.nan

    return results


def summarize_pdf_lab_coverage(lab_values):
    observed = {
        key for key, value in lab_values.items() if key in test_patterns and pd.notna(value)
    }
    observed_domains = sorted(
        domain for domain, columns in PDF_LAB_DOMAINS.items() if observed.intersection(columns)
    )
    if not observed:
        status = "insufficient"
    elif len(observed) >= 5 and len(observed_domains) >= 3:
        status = "sufficient_for_screening"
    else:
        status = "limited"
    return {
        "Observed_Lab_Count": len(observed),
        "Observed_Lab_Domains": ", ".join(observed_domains),
        "Data_Quality_Status": status,
    }


def build_patient_dataframe(
    lab_values, gender="Female", age=22, weight_kg=np.nan, height_cm=np.nan
):
    patient = {
        "Gender": gender,
        "Age": age,
        "Weight_kg": weight_kg,
        "Height_cm": height_cm,
        "BMI": np.nan,
        "Waist_Circumference_cm": np.nan,
        "BP_Systolic_mmHg": np.nan,
        "BP_Diastolic_mmHg": np.nan,
        "Glucose_mgdL": np.nan,
        "HbA1c_Percent": np.nan,
        "Cholesterol_Total_mgdL": np.nan,
        "Cholesterol_LDL_mgdL": np.nan,
        "Cholesterol_HDL_mgdL": np.nan,
        "Triglycerides_mgdL": np.nan,
        "Kidney_Creatinine_mgdL": np.nan,
        "eGFR_ml_min_1_73m2": np.nan,
        "Liver_ALT_UL": np.nan,
        "Liver_AST_UL": np.nan,
        "CRP_mg_L": np.nan,
        "Ferritin_ng_mL": np.nan,
        "Folate_ng_mL": np.nan,
        "Calcium_mg_dL": np.nan,
        "Magnesium_mg_dL": np.nan,
        "Urea_mgdL": np.nan,
        "Vitamin_B12_pg_mL": np.nan,
        "VitaminD_ng_mL": np.nan,
        "Iron_ugdL": np.nan,
        "Iron_Binding_Capacity_ugdL": np.nan,
        "Sedimentation_mm_h": np.nan,
        "Free_T3_pg_mL": np.nan,
        "Free_T4_ng_dL": np.nan,
        "Daily_Fiber_g": np.nan,
        "Daily_Sugar_g": np.nan,
        "Daily_Fat_g": np.nan,
        "Daily_Cholesterol_mg": np.nan,
        "White_Blood_Cells_count": np.nan,
        "Hemoglobin_gdL": np.nan,
        "Hematocrit_Percent": np.nan,
        "Red_Blood_Cells_count": np.nan,
        "Platelet_count": np.nan,
        "TSH_mIU_L": np.nan,
    }

    patient.update(lab_values)

    # HGB can come as g/L in Turkish reports. Convert if suspiciously high.
    if pd.notna(patient["Hemoglobin_gdL"]) and patient["Hemoglobin_gdL"] > 30:
        patient["Hemoglobin_gdL"] = patient["Hemoglobin_gdL"] / 10

    return enrich_anthropometrics(pd.DataFrame([patient]))


def analyze_pdf_report(pdf_path, gender="Female", age=22, weight_kg=np.nan, height_cm=np.nan):
    text = extract_pdf_text(pdf_path)
    metadata = extract_patient_metadata(text)
    lab_values = extract_lab_values(text)

    gender = metadata.get("Gender", gender)
    age = metadata.get("Age", age)
    patient_df = build_patient_dataframe(
        lab_values,
        gender=gender,
        age=age,
        weight_kg=weight_kg,
        height_cm=height_cm,
    )
    patient_df["Analysis_Source"] = "pdf"
    coverage = summarize_pdf_lab_coverage(lab_values)
    for key, value in coverage.items():
        patient_df[key] = value
    for key in ["Report_Date", "Birth_Date"]:
        if key in metadata:
            patient_df[key] = metadata[key]

    patient_df = apply_risk_engine(patient_df)

    patient_df["Health_Profile"] = patient_df.apply(create_health_profile, axis=1)

    patient_df[["Nutrition_Recommendation", "Foods_To_Increase", "Foods_To_Limit"]] = (
        patient_df.apply(generate_recommendations, axis=1)
    )

    extracted_values = {**metadata, **lab_values, **coverage}
    for column in ["Weight_kg", "Height_cm", "BMI"]:
        value = patient_df.loc[0, column] if column in patient_df.columns else np.nan
        if pd.notna(value):
            extracted_values[column] = value
    return patient_df, extracted_values, text


# =========================================================
# MAIN
# =========================================================


def main():
    ARTIFACT_DIR.mkdir(parents=True, exist_ok=True)
    print("Loading dataset...")
    df = pd.read_csv(DATASET_PATH)

    df = df[df["Age"] >= 18].copy()

    print("Applying risk engine...")
    df = apply_risk_engine(df)

    df["Health_Profile"] = df.apply(create_health_profile, axis=1)

    df[["Nutrition_Recommendation", "Foods_To_Increase", "Foods_To_Limit"]] = df.apply(
        generate_recommendations, axis=1
    )

    df.to_csv(RECOMMENDATION_OUTPUT, index=False)
    df.to_csv(RISK_OUTPUT, index=False)

    print("Saved:", RECOMMENDATION_OUTPUT)
    print("Saved:", RISK_OUTPUT)
    print("Dataset shape:", df.shape)

    if not PDF_PATH:
        print("\nPDF analysis skipped. Set BIODIETIX_PDF_PATH to analyze a local report.")
        return

    try:
        print("\nAnalyzing PDF report...")
        patient_df, lab_values, text = analyze_pdf_report(PDF_PATH, gender="Female", age=22)

        patient_df.to_csv(PDF_OUTPUT, index=False)

        print("Extracted values:")
        print(lab_values)

        print("\nPDF Recommendation Result:")
        print(
            patient_df[
                [
                    "Health_Profile",
                    "Nutrition_Recommendation",
                    "Foods_To_Increase",
                    "Foods_To_Limit",
                ]
            ]
        )

        print("Saved:", PDF_OUTPUT)

    except FileNotFoundError:
        print("\nPDF file not found. Dataset recommendation files were created only.")


def print_saved_pdf_summary(path=PDF_OUTPUT):
    try:
        result = pd.read_csv(path)
    except FileNotFoundError:
        return

    columns = [
        "Hemoglobin_gdL",
        "Hemoglobin_Risk_Level",
        "TSH_mIU_L",
        "TSH_Risk_Level",
    ]
    available_columns = [column for column in columns if column in result.columns]
    if available_columns:
        print(result[available_columns])


if __name__ == "__main__":
    main()
    print_saved_pdf_summary()
