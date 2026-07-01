"""Food-based recommendation guide derived from the BioDietix XLSX notes."""

from pathlib import Path

import pandas as pd

PROJECT_ROOT = Path(__file__).resolve().parents[1]
FOOD_GUIDE_PATH = PROJECT_ROOT / "data" / "food_recommendations.csv"

FOOD_GUIDE_RULES = [
    {
        "category": "Carbohydrates",
        "condition_risk": "Higher HbA1c / glucose indicator",
        "recommendation": "Consider higher-fiber carbohydrate sources and smaller portions as general lower-glycemic food choices.",
        "foods_to_limit": "white bread, pastries, white rice, sugary cereals",
        "foods_to_increase": "whole wheat bread, oats, bulgur, brown rice, quinoa",
        "purpose": "Support lower-glycemic food choices",
        "profiles": ("Blood Sugar Risk",),
        "risk_triggers": (
            (
                "Glucose_Risk_Level",
                (
                    "Prediabetes-Range Indicator",
                    "Diabetes-Range Indicator - Clinical Confirmation Needed",
                ),
            ),
            (
                "HbA1c_Risk_Level",
                (
                    "Prediabetes-Range Indicator",
                    "Diabetes-Range Indicator - Clinical Confirmation Needed",
                ),
            ),
        ),
    },
    {
        "category": "Sugar",
        "condition_risk": "Higher recorded daily sugar intake",
        "recommendation": "Consider limiting added sugar and choosing whole fruit instead of sweet snacks when appropriate.",
        "foods_to_limit": "soft drinks, desserts, packaged snacks",
        "foods_to_increase": "fresh fruits, cinnamon",
        "purpose": "Support lower-added-sugar choices",
        "profiles": ("Blood Sugar Risk",),
        "risk_triggers": (),
    },
    {
        "category": "Fiber",
        "condition_risk": "Low fiber intake",
        "recommendation": "Consider varied fiber sources such as vegetables, legumes, seeds, and whole grains, increasing gradually if needed.",
        "foods_to_limit": "refined grains, processed foods",
        "foods_to_increase": "vegetables, legumes, chia seeds, flaxseed",
        "purpose": "Support adequate fiber intake",
        "profiles": ("Fiber Intake Signal", "Cardiovascular Lipid Risk"),
        "risk_triggers": (("Fiber_Risk_Level", ("Low Fiber Intake Risk", "Low-Moderate")),),
    },
    {
        "category": "Protein",
        "condition_risk": "Blood sugar indicator",
        "recommendation": "Include moderate portions of lean or plant protein as part of balanced meals.",
        "foods_to_limit": "processed meat, excessive red meat",
        "foods_to_increase": "fish, chicken breast, legumes",
        "purpose": "Support balanced meals",
        "profiles": ("Blood Sugar Risk",),
        "risk_triggers": (),
    },
    {
        "category": "Fat",
        "condition_risk": "High LDL / Triglycerides",
        "recommendation": "Replace saturated and fried fats with unsaturated fat sources in modest portions.",
        "foods_to_limit": "butter, margarine, fried foods",
        "foods_to_increase": "olive oil, avocado, nuts",
        "purpose": "Support heart-healthy fat choices",
        "profiles": ("Cardiovascular Lipid Risk",),
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
        "purpose": "Support lower-saturated-fat choices",
        "profiles": ("Cardiovascular Lipid Risk",),
        "risk_triggers": (("LDL_Risk_Level", ("Borderline High", "High", "Very High")),),
    },
    {
        "category": "Liver Health",
        "condition_risk": "Elevated ALT / AST",
        "recommendation": "Support liver health by avoiding alcohol, fried foods, and sugary foods.",
        "foods_to_limit": "alcohol, fried foods, sugary foods",
        "foods_to_increase": "vegetables, lean protein, olive oil",
        "purpose": "Support a general liver-conscious eating pattern",
        "profiles": ("Liver Enzyme Indicator",),
        "risk_triggers": (("AST_Risk_Level", ("Elevated AST Risk",)),),
    },
    {
        "category": "Blood Pressure",
        "condition_risk": "Blood pressure indicator",
        "recommendation": "Use herbs or lemon instead of extra salt and consider fewer salty processed foods; ask a clinician before changing potassium intake if kidney function is reduced.",
        "foods_to_limit": "processed foods, salty snacks, pickles",
        "foods_to_increase": "herbs, lemon",
        "purpose": "Support lower-sodium choices",
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
        "condition_risk": "Higher BMI range",
        "recommendation": "Prioritize vegetables and lean protein while reducing high-calorie fast food.",
        "foods_to_limit": "high-calorie fast food",
        "foods_to_increase": "vegetables, lean protein",
        "purpose": "Support nutrient-dense food choices",
        "profiles": ("Weight Management Risk", "Abdominal Obesity Risk"),
        "risk_triggers": (("BMI_Risk_Level", ("Overweight Risk", "Obesity Risk")),),
    },
    {
        "category": "Metabolic Health",
        "condition_risk": "Multiple metabolic indicators",
        "recommendation": "Use a Mediterranean-style pattern to support overall metabolic health.",
        "foods_to_limit": "sugary drinks, refined carbs",
        "foods_to_increase": "Mediterranean diet foods",
        "purpose": "Support a balanced Mediterranean-style pattern",
        "profiles": (
            "Blood Sugar Risk",
            "Weight Management Risk",
            "Blood Pressure Risk",
            "Cardiovascular Lipid Risk",
            "Fiber Intake Signal",
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
    return {part.strip() for part in _text(row.get("Health_Profile")).split(",") if part.strip()}


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
