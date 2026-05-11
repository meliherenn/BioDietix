import re
import numpy as np
import pandas as pd
import pdfplumber


# =========================================================
# CONFIG
# =========================================================

DATASET_PATH = "BioDietix_CLEAN.csv"
PDF_PATH = "29.01.2025.pdf"

RISK_OUTPUT = "BioDietix_Risk_Analysis.csv"
RECOMMENDATION_OUTPUT = "BioDietix_Recommendation_System.csv"
PDF_OUTPUT = "Patient_PDF_Recommendation_Result.csv"


# =========================================================
# HELPER FUNCTIONS
# =========================================================

def is_risk(value):
    return pd.notna(value) and value != "Normal"


def clean_value(value):
    value = str(value).replace("<", "").replace(">", "").replace(",", ".").strip()
    return float(value)


def extract_pdf_text(pdf_path):
    text = ""

    with pdfplumber.open(pdf_path) as pdf:
        for page in pdf.pages:
            page_text = page.extract_text()
            if page_text:
                text += page_text + "\n"

    return text


# =========================================================
# RISK FUNCTIONS
# =========================================================

def glucose_risk(glucose):
    if pd.isna(glucose):
        return np.nan
    elif glucose < 100:
        return "Normal"
    elif glucose < 126:
        return "Prediabetes Risk"
    else:
        return "High Diabetes Risk"


def hba1c_risk(hba1c):
    if pd.isna(hba1c):
        return np.nan
    elif hba1c < 5.7:
        return "Normal"
    elif hba1c < 6.5:
        return "Prediabetes Risk"
    else:
        return "High Diabetes Risk"


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


def bp_risk(sys_bp, dia_bp):
    if pd.isna(sys_bp) or pd.isna(dia_bp):
        return np.nan

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
            return "High Risk"

    elif gender == "Female":
        if creatinine < 0.59:
            return "Low"
        elif creatinine <= 1.04:
            return "Normal"
        else:
            return "High Risk"

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
    diet_cols = [
        "Daily_Fiber_g",
        "Daily_Sugar_g",
        "Daily_Fat_g",
        "Daily_Cholesterol_mg"
    ]

    if all(pd.isna(row.get(col, np.nan)) for col in diet_cols):
        return np.nan

    risks = 0

    if row.get("Fiber_Risk_Level") == "Low Fiber Intake Risk":
        risks += 1
    if row.get("Sugar_Risk_Level") == "High Sugar Intake Risk":
        risks += 1
    if row.get("Daily_Fat_g", np.nan) > 100:
        risks += 1
    if row.get("Daily_Cholesterol_mg", np.nan) > 300:
        risks += 1

    if risks == 0:
        return "Good Diet Quality"
    elif risks == 1:
        return "Moderate Diet Quality Risk"
    else:
        return "Poor Diet Quality Risk"


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
    data = data.copy()

    data["Glucose_Risk_Level"] = data["Glucose_mgdL"].apply(glucose_risk)
    data["HbA1c_Risk_Level"] = data["HbA1c_Percent"].apply(hba1c_risk)
    data["BMI_Risk_Level"] = data["BMI"].apply(bmi_risk)

    data["Waist_Risk_Level"] = data.apply(
        lambda row: waist_risk(row["Gender"], row["Waist_Circumference_cm"]),
        axis=1
    )

    data["BP_Risk_Level"] = data.apply(
        lambda row: bp_risk(row["BP_Systolic_mmHg"], row["BP_Diastolic_mmHg"]),
        axis=1
    )

    data["Cholesterol_Risk_Level"] = data["Cholesterol_Total_mgdL"].apply(cholesterol_risk)
    data["LDL_Risk_Level"] = data["Cholesterol_LDL_mgdL"].apply(ldl_risk)
    data["Triglyceride_Risk_Level"] = data["Triglycerides_mgdL"].apply(triglyceride_risk)

    data["Creatinine_Risk_Level"] = data.apply(
        lambda row: creatinine_risk(row["Gender"], row["Kidney_Creatinine_mgdL"]),
        axis=1
    )

    data["Hemoglobin_Risk_Level"] = data.apply(
        lambda row: hemoglobin_risk(row["Gender"], row["Hemoglobin_gdL"]),
        axis=1
    )

    data["AST_Risk_Level"] = data["Liver_AST_UL"].apply(ast_risk)

    data["Fiber_Risk_Level"] = data["Daily_Fiber_g"].apply(fiber_risk)
    data["Sugar_Risk_Level"] = data["Daily_Sugar_g"].apply(sugar_risk)

    data["Diet_Quality_Risk_Level"] = data.apply(diet_quality_risk, axis=1)

    data["WBC_Risk_Level"] = data["White_Blood_Cells_count"].apply(wbc_risk)

    data["RBC_Risk_Level"] = data.apply(
        lambda row: rbc_risk(row["Gender"], row["Red_Blood_Cells_count"]),
        axis=1
    )

    data["Hematocrit_Risk_Level"] = data.apply(
        lambda row: hct_risk(row["Gender"], row["Hematocrit_Percent"]),
        axis=1
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

    if row.get("BP_Risk_Level") in ["Stage 1 Hypertension Risk", "Stage 2 Hypertension Risk"]:
        profiles.append("Blood Pressure Risk")

    if row.get("Cholesterol_Risk_Level") in ["Borderline High", "High Risk"] or \
       row.get("LDL_Risk_Level") in ["Borderline High", "High", "Very High"] or \
       row.get("Triglyceride_Risk_Level") in ["Borderline High", "High", "Very High"]:
        profiles.append("Cardiovascular Lipid Risk")

    if row.get("Creatinine_Risk_Level") in ["Low", "High Risk"]:
        profiles.append("Kidney / Muscle Indicator")

    if is_risk(row.get("Hemoglobin_Risk_Level")):
        profiles.append("Hemoglobin Indicator")

    if is_risk(row.get("WBC_Risk_Level")):
        profiles.append("Immune / Inflammation Indicator")

    if is_risk(row.get("RBC_Risk_Level")) or is_risk(row.get("Hematocrit_Risk_Level")):
        profiles.append("Blood Cell / Anemia Support Indicator")

    if is_risk(row.get("Platelet_Risk_Level")):
        profiles.append("Platelet Support Indicator")

    if row.get("AST_Risk_Level") == "Elevated AST Risk":
        profiles.append("Liver Enzyme Indicator")

    if pd.notna(row.get("Diet_Quality_Risk_Level")) and row.get("Diet_Quality_Risk_Level") != "Good Diet Quality":
        profiles.append("Diet Quality Risk")

    if row.get("Waist_Risk_Level") == "Abdominal Obesity Risk":
        profiles.append("Abdominal Obesity Risk")

    if is_risk(row.get("TSH_Risk_Level")):
        profiles.append("Thyroid / Metabolism Indicator")

    if len(profiles) == 0:
        return "Low Risk"

    return ", ".join(list(dict.fromkeys(profiles)))


# =========================================================
# RECOMMENDATION ENGINE
# =========================================================

def generate_recommendations(row):
    recommendations = []
    increase_foods = []
    limit_foods = []

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

    if "Blood Pressure Risk" in row["Health_Profile"]:
        recommendations.append(
            "Reduce sodium intake and follow a DASH-style eating pattern."
        )
        increase_foods.extend(["vegetables", "fruits", "low-fat dairy", "potassium-rich foods"])
        limit_foods.extend(["salty snacks", "processed meats", "instant soups", "high-sodium packaged foods"])

    if "Cardiovascular Lipid Risk" in row["Health_Profile"]:
        recommendations.append(
            "Reduce saturated fat and refined carbohydrates; prefer heart-healthy fats."
        )
        increase_foods.extend(["olive oil", "nuts", "fish", "avocado", "fiber-rich foods"])
        limit_foods.extend(["processed meats", "butter", "fried foods", "trans fats", "sugary foods"])

    if "Kidney / Muscle Indicator" in row["Health_Profile"]:
        if row.get("Creatinine_Risk_Level") == "High Risk":
            recommendations.append(
                "Limit excessive protein intake, reduce sodium, and avoid ultra-processed foods."
            )
            increase_foods.extend(["fresh vegetables", "balanced meals", "water"])
            limit_foods.extend(["excessive protein supplements", "processed foods", "high-sodium foods"])

        elif row.get("Creatinine_Risk_Level") == "Low":
            recommendations.append(
                "Support muscle mass with adequate calories, high-quality protein, and regular resistance exercise."
            )
            increase_foods.extend(["eggs", "fish", "yogurt", "legumes", "lean meats"])
            limit_foods.extend(["very low-calorie diets", "meal skipping"])

    if "Hemoglobin Indicator" in row["Health_Profile"]:
        if row.get("Hemoglobin_Risk_Level") == "Low Hemoglobin Risk":
            recommendations.append(
                "Increase iron-rich foods and pair them with vitamin C sources."
            )
            increase_foods.extend(["lean red meat", "lentils", "beans", "spinach", "citrus fruits"])
            limit_foods.extend(["tea or coffee immediately with iron-rich meals"])

    if "Immune / Inflammation Indicator" in row["Health_Profile"]:
        recommendations.append(
            "Support immune and inflammatory balance with antioxidant-rich foods, adequate protein, hydration, and omega-3 sources."
        )
        increase_foods.extend(["vegetables", "fruits", "berries", "fish", "walnuts", "yogurt", "adequate protein"])
        limit_foods.extend(["ultra-processed foods", "excess sugar", "fried foods"])

    if "Blood Cell / Anemia Support Indicator" in row["Health_Profile"]:
        recommendations.append(
            "Support blood cell health with iron, folate, vitamin B12, vitamin C, and adequate protein intake."
        )
        increase_foods.extend(["lean red meat", "eggs", "fish", "lentils", "beans", "spinach", "citrus fruits", "dairy products"])
        limit_foods.extend(["tea or coffee immediately with iron-rich meals", "very low-calorie diets"])

    if "Platelet Support Indicator" in row["Health_Profile"]:
        recommendations.append(
            "Maintain balanced nutrition and hydration; platelet-related abnormalities should be interpreted with clinical context."
        )
        increase_foods.extend(["balanced meals", "vegetables", "fruits", "water"])
        limit_foods.extend(["excess alcohol", "ultra-processed foods"])

    if "Liver Enzyme Indicator" in row["Health_Profile"]:
        recommendations.append(
            "Reduce alcohol, fried foods, and excess sugar to support liver health."
        )
        increase_foods.extend(["vegetables", "whole grains", "coffee without sugar", "omega-3 rich foods"])
        limit_foods.extend(["alcohol", "fried foods", "sugary drinks", "processed foods"])

    if "Thyroid / Metabolism Indicator" in row["Health_Profile"]:
        recommendations.append(
            "Support thyroid-related metabolism with balanced meals, adequate protein, selenium, zinc, iodine, and regular meal patterns."
        )
        increase_foods.extend(["eggs", "fish", "yogurt", "dairy products", "selenium-rich foods", "balanced meals"])
        limit_foods.extend(["very low-calorie diets", "meal skipping", "ultra-processed foods"])

    if "Diet Quality Risk" in row["Health_Profile"]:
        recommendations.append(
            "Improve overall diet quality by increasing fiber and reducing added sugar, saturated fat, and dietary cholesterol."
        )
        increase_foods.extend(["vegetables", "fruits", "whole grains", "legumes"])
        limit_foods.extend(["sweets", "processed snacks", "high-fat processed foods"])

    if "Abdominal Obesity Risk" in row["Health_Profile"]:
        recommendations.append(
            "Focus on weight management, fiber-rich meals, and regular physical activity."
        )
        increase_foods.extend(["high-fiber vegetables", "lean protein", "whole grains"])
        limit_foods.extend(["sugary foods", "refined carbohydrates", "large portions"])

    if len(recommendations) == 0:
        recommendations.append(
            "Maintain a balanced diet with regular meals, adequate fiber, lean protein, and healthy fats."
        )
        increase_foods.extend(["vegetables", "fruits", "whole grains", "lean protein", "healthy fats"])
        limit_foods.extend(["excess sugar", "processed foods", "trans fats"])

    recommendations = list(dict.fromkeys(recommendations))
    increase_foods = list(dict.fromkeys(increase_foods))
    limit_foods = list(dict.fromkeys(limit_foods))

    return pd.Series({
        "Nutrition_Recommendation": " ".join(recommendations),
        "Foods_To_Increase": ", ".join(increase_foods),
        "Foods_To_Limit": ", ".join(limit_foods)
    })


# =========================================================
# PDF PARSER
# =========================================================

test_patterns = {
    "TSH_mIU_L": r"\bTSH\s+([<>]?\s*\d+\.?\d*)",
    "Hemoglobin_gdL": r"\bHGB\s+([<>]?\s*\d+\.?\d*)",
    "Hematocrit_Percent": r"\bHCT\s+([<>]?\s*\d+\.?\d*)",
    "Red_Blood_Cells_count": r"\bRBC\s+([<>]?\s*\d+\.?\d*)",
    "White_Blood_Cells_count": r"\bWBC\s+([<>]?\s*\d+\.?\d*)",
    "Platelet_count": r"\bPLT\s+([<>]?\s*\d+\.?\d*)",

    "Glucose_mgdL": r"\b(?:GLUCOSE|Glucose|GLUKOZ|Glukoz|Açlık Kan Şekeri|Aclik Kan Sekeri)\s+([<>]?\s*\d+\.?\d*)",
    "HbA1c_Percent": r"\b(?:HbA1c|HBA1C|Hemoglobin A1c)\s+([<>]?\s*\d+\.?\d*)",
    "Cholesterol_Total_mgdL": r"\b(?:Total Cholesterol|TOTAL CHOLESTEROL|Kolesterol|Total Kolesterol)\s+([<>]?\s*\d+\.?\d*)",
    "Cholesterol_LDL_mgdL": r"\b(?:LDL|LDL Cholesterol|LDL Kolesterol)\s+([<>]?\s*\d+\.?\d*)",
    "Triglycerides_mgdL": r"\b(?:Triglyceride|TRIGLYCERIDE|Trigliserid|TG)\s+([<>]?\s*\d+\.?\d*)",
    "Kidney_Creatinine_mgdL": r"\b(?:Creatinine|CREATININE|Kreatinin|KREATININ)\s+([<>]?\s*\d+\.?\d*)",
    "Liver_AST_UL": r"\b(?:AST|SGOT)\s+([<>]?\s*\d+\.?\d*)"
}


def extract_lab_values(text):
    results = {}

    for standard_name, pattern in test_patterns.items():
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            results[standard_name] = clean_value(match.group(1))
        else:
            results[standard_name] = np.nan

    return results


def build_patient_dataframe(lab_values, gender="Female", age=22):
    patient = {
        "Gender": gender,
        "Age": age,

        "BMI": np.nan,
        "Waist_Circumference_cm": np.nan,
        "BP_Systolic_mmHg": np.nan,
        "BP_Diastolic_mmHg": np.nan,

        "Glucose_mgdL": np.nan,
        "HbA1c_Percent": np.nan,
        "Cholesterol_Total_mgdL": np.nan,
        "Cholesterol_LDL_mgdL": np.nan,
        "Triglycerides_mgdL": np.nan,
        "Kidney_Creatinine_mgdL": np.nan,
        "Liver_AST_UL": np.nan,

        "Daily_Fiber_g": np.nan,
        "Daily_Sugar_g": np.nan,
        "Daily_Fat_g": np.nan,
        "Daily_Cholesterol_mg": np.nan,

        "White_Blood_Cells_count": np.nan,
        "Hemoglobin_gdL": np.nan,
        "Hematocrit_Percent": np.nan,
        "Red_Blood_Cells_count": np.nan,
        "Platelet_count": np.nan,

        "TSH_mIU_L": np.nan
    }

    patient.update(lab_values)

    # HGB can come as g/L in Turkish reports. Convert if suspiciously high.
    if pd.notna(patient["Hemoglobin_gdL"]) and patient["Hemoglobin_gdL"] > 30:
        patient["Hemoglobin_gdL"] = patient["Hemoglobin_gdL"] / 10

    return pd.DataFrame([patient])


def analyze_pdf_report(pdf_path, gender="Female", age=22):
    text = extract_pdf_text(pdf_path)
    lab_values = extract_lab_values(text)

    patient_df = build_patient_dataframe(lab_values, gender=gender, age=age)

    patient_df = apply_risk_engine(patient_df)

    patient_df["Health_Profile"] = patient_df.apply(create_health_profile, axis=1)

    patient_df[[
        "Nutrition_Recommendation",
        "Foods_To_Increase",
        "Foods_To_Limit"
    ]] = patient_df.apply(generate_recommendations, axis=1)

    return patient_df, lab_values, text


# =========================================================
# MAIN
# =========================================================

def main():
    print("Loading dataset...")
    df = pd.read_csv(DATASET_PATH)

    df = df[df["Age"] >= 18].copy()

    print("Applying risk engine...")
    df = apply_risk_engine(df)

    df["Health_Profile"] = df.apply(create_health_profile, axis=1)

    df[[
        "Nutrition_Recommendation",
        "Foods_To_Increase",
        "Foods_To_Limit"
    ]] = df.apply(generate_recommendations, axis=1)

    df.to_csv(RECOMMENDATION_OUTPUT, index=False)
    df.to_csv(RISK_OUTPUT, index=False)

    print("Saved:", RECOMMENDATION_OUTPUT)
    print("Saved:", RISK_OUTPUT)
    print("Dataset shape:", df.shape)

    try:
        print("\nAnalyzing PDF report...")
        patient_df, lab_values, text = analyze_pdf_report(
            PDF_PATH,
            gender="Female",
            age=22
        )

        patient_df.to_csv(PDF_OUTPUT, index=False)

        print("Extracted values:")
        print(lab_values)

        print("\nPDF Recommendation Result:")
        print(patient_df[[
            "Health_Profile",
            "Nutrition_Recommendation",
            "Foods_To_Increase",
            "Foods_To_Limit"
        ]])

        print("Saved:", PDF_OUTPUT)

    except FileNotFoundError:
        print("\nPDF file not found. Dataset recommendation files were created only.")

result = pd.read_csv("Patient_PDF_Recommendation_Result.csv")
print(result[["Hemoglobin_gdL", "Hemoglobin_Risk_Level", "TSH_mIU_L", "TSH_Risk_Level"]])


if __name__ == "__main__":
    main()