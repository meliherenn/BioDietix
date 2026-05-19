"""Food-based recommendation guide derived from the BioDietix XLSX notes."""

from pathlib import Path

import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
FOOD_GUIDE_PATH = PROJECT_ROOT / "data" / "food_recommendations.csv"

FOOD_GUIDE_RULES = [
    {
        "category": "Carbohydrates",
        "condition_risk": "High HbA1c / High Glucose",
        "recommendation": "Choose whole-grain, low-glycemic carbohydrate sources to improve glycemic control.",
        "foods_to_limit": "white bread, pastries, white rice, sugary cereals",
        "foods_to_increase": "whole wheat bread, oats, bulgur, brown rice, quinoa",
        "purpose": "Improve glycemic control",
        "profiles": ("Blood Sugar Risk",),
        "risk_triggers": (
            ("Glucose_Risk_Level", ("Prediabetes Risk", "High Diabetes Risk")),
            ("HbA1c_Risk_Level", ("Prediabetes Risk", "High Diabetes Risk")),
        ),
    },
    {
        "category": "Sugar",
        "condition_risk": "High daily sugar intake",
        "recommendation": "Keep added sugar low and replace sweet snacks with whole fruit when appropriate.",
        "foods_to_limit": "soft drinks, desserts, packaged snacks",
        "foods_to_increase": "fresh fruits, cinnamon",
        "purpose": "Reduce blood sugar spikes",
        "profiles": ("Blood Sugar Risk", "Diet Quality Risk"),
        "risk_triggers": (("Sugar_Risk_Level", ("High Sugar Intake Risk",)),),
    },
    {
        "category": "Fiber",
        "condition_risk": "Low fiber intake",
        "recommendation": "Increase fiber from vegetables, legumes, chia seeds, flaxseed, and whole grains.",
        "foods_to_limit": "refined grains, processed foods",
        "foods_to_increase": "vegetables, legumes, chia seeds, flaxseed",
        "purpose": "Improve digestion and lower LDL",
        "profiles": ("Diet Quality Risk", "Cardiovascular Lipid Risk"),
        "risk_triggers": (("Fiber_Risk_Level", ("Low Fiber Intake Risk", "Low-Moderate")),),
    },
    {
        "category": "Protein",
        "condition_risk": "Insulin resistance",
        "recommendation": "Prefer lean protein sources to support insulin sensitivity.",
        "foods_to_limit": "processed meat, excessive red meat",
        "foods_to_increase": "fish, chicken breast, legumes",
        "purpose": "Improve insulin sensitivity",
        "profiles": ("Blood Sugar Risk",),
        "risk_triggers": (),
    },
    {
        "category": "Fat",
        "condition_risk": "High LDL / Triglycerides",
        "recommendation": "Replace saturated and fried fats with unsaturated fat sources in modest portions.",
        "foods_to_limit": "butter, margarine, fried foods",
        "foods_to_increase": "olive oil, avocado, nuts",
        "purpose": "Improve lipid profile",
        "profiles": ("Cardiovascular Lipid Risk", "Diet Quality Risk"),
        "risk_triggers": (
            ("LDL_Risk_Level", ("Borderline High", "High", "Very High")),
            ("Triglyceride_Risk_Level", ("Borderline High", "High", "Very High")),
        ),
    },
    {
        "category": "Cholesterol",
        "condition_risk": "High LDL cholesterol",
        "recommendation": "Prefer lower-fat dairy and fish while reducing fatty red meat and high-fat dairy.",
        "foods_to_limit": "high-fat dairy, fatty red meat",
        "foods_to_increase": "low-fat dairy, fish",
        "purpose": "Reduce cardiovascular risk",
        "profiles": ("Cardiovascular Lipid Risk",),
        "risk_triggers": (("LDL_Risk_Level", ("Borderline High", "High", "Very High")),),
    },
    {
        "category": "Liver Health",
        "condition_risk": "Elevated ALT / AST",
        "recommendation": "Support liver health by avoiding alcohol, fried foods, and sugary foods.",
        "foods_to_limit": "alcohol, fried foods, sugary foods",
        "foods_to_increase": "vegetables, lean protein, olive oil",
        "purpose": "Support liver function",
        "profiles": ("Liver Enzyme Indicator",),
        "risk_triggers": (("AST_Risk_Level", ("Elevated AST Risk",)),),
    },
    {
        "category": "Blood Pressure",
        "condition_risk": "Hypertension",
        "recommendation": "Use herbs, garlic, lemon, and potassium-rich foods while reducing salty processed foods.",
        "foods_to_limit": "processed foods, salty snacks, pickles",
        "foods_to_increase": "herbs, garlic, lemon, potassium-rich foods",
        "purpose": "Reduce blood pressure",
        "profiles": ("Blood Pressure Risk",),
        "risk_triggers": (
            (
                "BP_Risk_Level",
                ("Stage 1 Hypertension Risk", "Stage 2 Hypertension Risk"),
            ),
        ),
    },
    {
        "category": "Weight Control",
        "condition_risk": "Obesity",
        "recommendation": "Prioritize vegetables and lean protein while reducing high-calorie fast food.",
        "foods_to_limit": "high-calorie fast food",
        "foods_to_increase": "vegetables, lean protein",
        "purpose": "Promote weight loss",
        "profiles": ("Weight Management Risk", "Abdominal Obesity Risk"),
        "risk_triggers": (("BMI_Risk_Level", ("Overweight Risk", "Obesity Risk")),),
    },
    {
        "category": "Metabolic Health",
        "condition_risk": "Metabolic syndrome",
        "recommendation": "Use a Mediterranean-style pattern to support overall metabolic health.",
        "foods_to_limit": "sugary drinks, refined carbs",
        "foods_to_increase": "Mediterranean diet foods",
        "purpose": "Improve overall metabolic health",
        "profiles": (
            "Blood Sugar Risk",
            "Weight Management Risk",
            "Blood Pressure Risk",
            "Cardiovascular Lipid Risk",
            "Diet Quality Risk",
            "Abdominal Obesity Risk",
        ),
        "min_profile_matches": 2,
        "risk_triggers": (),
    },
]


def _text(value):
    if value is None:
        return ""
    text = str(value).strip()
    if text.lower() in {"", "nan", "none"}:
        return ""
    return text


def _split_foods(value):
    return [item.strip() for item in _text(value).split(",") if item.strip()]


def _profile_parts(row):
    return {
        part.strip()
        for part in _text(row.get("Health_Profile")).split(",")
        if part.strip()
    }


def _risk_matches(row, rule):
    for column, expected_values in rule.get("risk_triggers", ()):
        if _text(row.get(column)) in expected_values:
            return True
    return False


def matched_food_guide_rules(row):
    profiles = _profile_parts(row)
    matches = []

    for rule in FOOD_GUIDE_RULES:
        rule_profiles = set(rule.get("profiles", ()))
        profile_match_count = len(profiles.intersection(rule_profiles))
        minimum_matches = rule.get("min_profile_matches", 1)

        if profile_match_count >= minimum_matches or _risk_matches(row, rule):
            matches.append(rule)

    return matches


def add_food_guide_to_recommendations(row, recommendations, increase_foods, limit_foods):
    for rule in matched_food_guide_rules(row):
        recommendations.append(rule["recommendation"])
        increase_foods.extend(_split_foods(rule["foods_to_increase"]))
        limit_foods.extend(_split_foods(rule["foods_to_limit"]))


def food_guide_dataframe():
    if FOOD_GUIDE_PATH.exists():
        return pd.read_csv(FOOD_GUIDE_PATH)

    return pd.DataFrame(
        [
            {
                "Category": rule["category"],
                "Condition_Risk": rule["condition_risk"],
                "Foods_To_Limit": rule["foods_to_limit"],
                "Foods_To_Increase": rule["foods_to_increase"],
                "Purpose": rule["purpose"],
            }
            for rule in FOOD_GUIDE_RULES
        ]
    )
