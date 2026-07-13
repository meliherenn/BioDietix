"""Canonical, locale-neutral display codes for generated profile summaries.

The analysis engine continues to expose its legacy English prose for backwards
compatibility.  New clients should render the stable codes in ``display_codes``
through their own locale catalog instead of translating those prose fields.
"""

from __future__ import annotations

from collections.abc import Iterable, Mapping

HEALTH_PROFILE_TEXT_BY_CODE: dict[str, str] = {
    "health.blood_sugar_risk": "Blood Sugar Risk",
    "health.weight_management_risk": "Weight Management Risk",
    "health.blood_pressure_risk": "Blood Pressure Risk",
    "health.cardiovascular_lipid_risk": "Cardiovascular Lipid Risk",
    "health.kidney_muscle_indicator": "Kidney / Muscle Indicator",
    "health.hemoglobin_indicator": "Hemoglobin Indicator",
    "health.immune_inflammation_indicator": "Immune / Inflammation Indicator",
    "health.blood_cell_anemia_support_indicator": ("Blood Cell / Anemia Support Indicator"),
    "health.platelet_support_indicator": "Platelet Support Indicator",
    "health.liver_enzyme_indicator": "Liver Enzyme Indicator",
    "health.fiber_intake_signal": "Fiber Intake Signal",
    "health.abdominal_obesity_risk": "Abdominal Obesity Risk",
    "health.thyroid_metabolism_indicator": "Thyroid / Metabolism Indicator",
    "health.vitamin_d_bone_health_indicator": "Vitamin D / Bone Health Indicator",
    "health.micronutrient_support_indicator": "Micronutrient Support Indicator",
    "health.age_related_nutrition_focus": "Age-Related Nutrition Focus",
    "health.no_flagged_risk_available_data": "No Flagged Risk in Available Data",
    "health.low_risk": "Low Risk",
    "health.insufficient_data": "Insufficient Data",
}


RECOMMENDATION_TEXT_BY_CODE: dict[str, str] = {
    "recommendation.medical_disclaimer": (
        "These are general food-choice suggestions, not medical advice. BioDietix is not "
        "a medical device and does not diagnose, treat, cure, or prevent any condition; "
        "discuss abnormal results and major diet changes with a qualified healthcare "
        "professional."
    ),
    "recommendation.age_young_adult": (
        "For this age group, build long-term habits with regular meals, adequate protein, "
        "fiber, and physical activity."
    ),
    "recommendation.age_adult": (
        "For adult metabolic maintenance, prioritize portion control, fiber, lean protein, "
        "and consistent activity."
    ),
    "recommendation.age_midlife": (
        "For midlife prevention, focus on cardiovascular health, muscle maintenance, "
        "fiber, vitamin D, calcium, and regular checkups."
    ),
    "recommendation.age_older_adult": (
        "For older adults, protect muscle and bone health with adequate protein, vitamin D, "
        "calcium, hydration, and clinically guided follow-up."
    ),
    "recommendation.reduce_added_sugar_refined_carbs": (
        "Reduce added sugar and refined carbohydrates, and prefer low-glycemic foods."
    ),
    "recommendation.portion_control_nutrient_dense_meals": (
        "Control portion sizes and choose nutrient-dense, lower-calorie meals."
    ),
    "recommendation.underweight_nutrient_dense_support": (
        "BMI indicates an underweight range. Increase nutrient-dense calories with "
        "protein-rich meals and healthy fats, and review unintentional weight loss with a "
        "healthcare professional."
    ),
    "recommendation.severely_elevated_blood_pressure": (
        "This blood-pressure value is severely elevated. Recheck it correctly and seek "
        "prompt clinical advice; if there are symptoms such as chest pain, shortness of "
        "breath, weakness, vision change, or difficulty speaking, use local emergency "
        "services."
    ),
    "recommendation.reduce_sodium_dash_pattern": (
        "Reduce sodium intake and follow a DASH-style eating pattern."
    ),
    "recommendation.heart_healthy_fats": (
        "Reduce saturated fat and refined carbohydrates; prefer heart-healthy fats."
    ),
    "recommendation.creatinine_clinical_review": (
        "A creatinine result should be interpreted with eGFR, hydration, muscle mass, "
        "medicines, and the laboratory range. Do not change protein or fluid intake based "
        "on this result alone; discuss it with a healthcare professional."
    ),
    "recommendation.low_creatinine_muscle_support": (
        "Support muscle mass with adequate calories, high-quality protein, and regular "
        "resistance exercise."
    ),
    "recommendation.low_hemoglobin_clinical_review": (
        "A low hemoglobin indicator has several possible causes and should be discussed "
        "with a healthcare professional. Iron-containing foods may be reasonable, but do "
        "not start iron supplements without clinical advice."
    ),
    "recommendation.inflammation_varied_diet": (
        "Inflammation or blood-cell indicators are nonspecific and should be interpreted "
        "with symptoms and other tests. A varied eating pattern with vegetables, fruit, "
        "adequate protein, and hydration is a general option."
    ),
    "recommendation.blood_cell_nutrient_support": (
        "Support blood cell health with iron, folate, vitamin B12, vitamin C, and adequate "
        "protein intake."
    ),
    "recommendation.platelet_balanced_nutrition": (
        "Maintain balanced nutrition and hydration; platelet-related abnormalities should "
        "be interpreted with clinical context."
    ),
    "recommendation.liver_health_support": (
        "Liver enzyme changes should be reviewed with a healthcare professional. Reduce "
        "alcohol, fried foods, and excess sugar to support liver health."
    ),
    "recommendation.thyroid_clinical_review": (
        "Thyroid-related lab changes should be reviewed with a healthcare professional and "
        "the reporting laboratory's reference range. Do not start iodine, selenium, or "
        "thyroid supplements based on this result."
    ),
    "recommendation.low_fiber_gradual_increase": (
        "Recorded fiber intake appears below the general adult reference used by this app. "
        "If the entry reflects your usual intake, consider gradually adding varied fiber "
        "sources and discuss individual needs with a dietitian or healthcare professional."
    ),
    "recommendation.weight_management_focus": (
        "Focus on weight management, fiber-rich meals, and regular physical activity."
    ),
    "recommendation.vitamin_d_clinical_review": (
        "A vitamin D indicator should be reviewed with a healthcare professional because "
        "thresholds and treatment decisions vary. Food sources of vitamin D, calcium, and "
        "protein can be part of a balanced diet; do not start high-dose supplements from "
        "this result alone."
    ),
    "recommendation.micronutrient_clinical_review": (
        "Micronutrient indicators require the laboratory range and clinical context. "
        "Discuss abnormal results before starting or stopping any supplement."
    ),
    "recommendation.high_ferritin_clinical_review": (
        "High ferritin can occur for several reasons, including inflammation; do not "
        "increase iron intake or use iron supplements unless a clinician advises it."
    ),
    "recommendation.balanced_diet_general": (
        "Maintain a balanced diet with regular meals, adequate fiber, lean protein, and "
        "healthy fats."
    ),
    "recommendation.guide_higher_fiber_carbohydrates": (
        "Consider higher-fiber carbohydrate sources and smaller portions as general "
        "lower-glycemic food choices."
    ),
    "recommendation.guide_limit_added_sugar": (
        "Consider limiting added sugar and choosing whole fruit instead of sweet snacks "
        "when appropriate."
    ),
    "recommendation.guide_varied_fiber_sources": (
        "Consider varied fiber sources such as vegetables, legumes, seeds, and whole "
        "grains, increasing gradually if needed."
    ),
    "recommendation.guide_balanced_protein": (
        "Include moderate portions of lean or plant protein as part of balanced meals."
    ),
    "recommendation.guide_unsaturated_fats": (
        "Replace saturated and fried fats with unsaturated fat sources in modest portions."
    ),
    "recommendation.guide_lower_fat_dairy_fish": (
        "Prefer lower-fat dairy and fish while reducing fatty red meat and high-fat dairy."
    ),
    "recommendation.guide_liver_health": (
        "Support liver health by avoiding alcohol, fried foods, and sugary foods."
    ),
    "recommendation.guide_lower_sodium": (
        "Use herbs or lemon instead of extra salt and consider fewer salty processed foods; "
        "ask a clinician before changing potassium intake if kidney function is reduced."
    ),
    "recommendation.guide_weight_control": (
        "Prioritize vegetables and lean protein while reducing high-calorie fast food."
    ),
    "recommendation.guide_mediterranean_pattern": (
        "Use a Mediterranean-style pattern to support overall metabolic health."
    ),
}


FOOD_TEXT_BY_CODE: dict[str, str] = {
    "food.mediterranean_diet_foods": "Mediterranean diet foods",
    "food.adequate_protein": "adequate protein",
    "food.alcohol": "alcohol",
    "food.avocado": "avocado",
    "food.balanced_meals": "balanced meals",
    "food.beans": "beans",
    "food.berries": "berries",
    "food.brown_rice": "brown rice",
    "food.bulgur": "bulgur",
    "food.butter": "butter",
    "food.calcium_rich_foods": "calcium-rich foods",
    "food.chia_seeds": "chia seeds",
    "food.chicken_breast": "chicken breast",
    "food.cinnamon": "cinnamon",
    "food.citrus_fruits": "citrus fruits",
    "food.coffee_without_sugar": "coffee without sugar",
    "food.dairy_or_fortified_alternatives": "dairy or fortified alternatives",
    "food.dairy_products": "dairy products",
    "food.dehydration": "dehydration",
    "food.desserts": "desserts",
    "food.eggs": "eggs",
    "food.excess_alcohol": "excess alcohol",
    "food.excess_sodium": "excess sodium",
    "food.excess_sugar": "excess sugar",
    "food.excessive_red_meat": "excessive red meat",
    "food.fast_food": "fast food",
    "food.fatty_fish": "fatty fish",
    "food.fatty_red_meat": "fatty red meat",
    "food.fiber_rich_foods": "fiber-rich foods",
    "food.fish": "fish",
    "food.flaxseed": "flaxseed",
    "food.fortified_dairy": "fortified dairy",
    "food.frequent_fast_food": "frequent fast food",
    "food.fresh_fruits": "fresh fruits",
    "food.fresh_vegetables": "fresh vegetables",
    "food.fried_foods": "fried foods",
    "food.fruits": "fruits",
    "food.healthy_fats": "healthy fats",
    "food.herbs": "herbs",
    "food.high_calorie_fast_food": "high-calorie fast food",
    "food.high_calorie_snacks": "high-calorie snacks",
    "food.high_dose_protein_supplements_without_clinical_advice": (
        "high-dose protein supplements without clinical advice"
    ),
    "food.high_fat_dairy": "high-fat dairy",
    "food.high_fiber_foods": "high-fiber foods",
    "food.high_fiber_vegetables": "high-fiber vegetables",
    "food.high_sodium_foods": "high-sodium foods",
    "food.high_sodium_packaged_foods": "high-sodium packaged foods",
    "food.instant_soups": "instant soups",
    "food.large_portions": "large portions",
    "food.leafy_greens": "leafy greens",
    "food.lean_meat": "lean meat",
    "food.lean_meats": "lean meats",
    "food.lean_protein": "lean protein",
    "food.lean_red_meat": "lean red meat",
    "food.legumes": "legumes",
    "food.lemon": "lemon",
    "food.lentils": "lentils",
    "food.low_fat_dairy": "low-fat dairy",
    "food.low_fat_yogurt": "low-fat yogurt",
    "food.low_fiber_processed_snacks": "low-fiber processed snacks",
    "food.low_fiber_refined_grains": "low-fiber refined grains",
    "food.margarine": "margarine",
    "food.meal_skipping": "meal skipping",
    "food.nutrient_poor_processed_foods": "nutrient-poor processed foods",
    "food.nuts": "nuts",
    "food.oats": "oats",
    "food.olive_oil": "olive oil",
    "food.omega_3_rich_foods": "omega-3 rich foods",
    "food.packaged_snacks": "packaged snacks",
    "food.pastries": "pastries",
    "food.pickles": "pickles",
    "food.processed_foods": "processed foods",
    "food.processed_meat": "processed meat",
    "food.processed_meats": "processed meats",
    "food.protein_rich_foods": "protein-rich foods",
    "food.quinoa": "quinoa",
    "food.refined_carbohydrates": "refined carbohydrates",
    "food.refined_carbs": "refined carbs",
    "food.refined_grains": "refined grains",
    "food.salty_snacks": "salty snacks",
    "food.saturated_fat": "saturated fat",
    "food.soft_drinks": "soft drinks",
    "food.spinach": "spinach",
    "food.sugary_cereals": "sugary cereals",
    "food.sugary_drinks": "sugary drinks",
    "food.sugary_foods": "sugary foods",
    "food.tea_or_coffee_immediately_with_iron_containing_meals": (
        "tea or coffee immediately with iron-containing meals"
    ),
    "food.tea_or_coffee_immediately_with_iron_rich_meals": (
        "tea or coffee immediately with iron-rich meals"
    ),
    "food.trans_fats": "trans fats",
    "food.ultra_processed_foods": "ultra-processed foods",
    "food.vegetables": "vegetables",
    "food.very_low_calorie_diets": "very low-calorie diets",
    "food.very_restrictive_diets": "very restrictive diets",
    "food.vitamin_c_foods": "vitamin C foods",
    "food.vitamin_d_foods": "vitamin D foods",
    "food.walnuts": "walnuts",
    "food.water": "water",
    "food.white_bread": "white bread",
    "food.white_rice": "white rice",
    "food.whole_grains": "whole grains",
    "food.whole_wheat_bread": "whole wheat bread",
    "food.yogurt": "yogurt",
}


INTERPRETATION_WARNING_TEXT_BY_CODE: dict[str, str] = {
    "warning.reference_intervals_vary": (
        "Reference intervals vary by laboratory, method, age, sex, pregnancy status, and "
        "clinical context."
    ),
    "warning.glucose_fasting_status_unknown": (
        "The glucose threshold assumes a fasting sample; fasting status cannot be reliably "
        "inferred from every PDF."
    ),
    "warning.hba1c_clinical_factors": (
        "HbA1c can be affected by anemia, kidney or liver disease, blood disorders, "
        "pregnancy, blood loss, or transfusion."
    ),
    "warning.egfr_single_result_not_diagnostic": (
        "A single eGFR below 60 does not establish chronic kidney disease; persistence and "
        "urine markers matter."
    ),
}


class UnknownProfileSummaryText(ValueError):
    """Raised when generated prose has no canonical display code."""


def _reverse(catalog: Mapping[str, str]) -> dict[str, str]:
    reverse = {text: code for code, text in catalog.items()}
    if len(reverse) != len(catalog):
        raise RuntimeError("Profile summary catalog contains duplicate English text.")
    return reverse


_HEALTH_CODE_BY_TEXT = _reverse(HEALTH_PROFILE_TEXT_BY_CODE)
_RECOMMENDATION_CODE_BY_TEXT = _reverse(RECOMMENDATION_TEXT_BY_CODE)
_FOOD_CODE_BY_TEXT = _reverse(FOOD_TEXT_BY_CODE)
_WARNING_CODE_BY_TEXT = _reverse(INTERPRETATION_WARNING_TEXT_BY_CODE)
_RECOMMENDATIONS_LONGEST_FIRST = sorted(
    _RECOMMENDATION_CODE_BY_TEXT,
    key=len,
    reverse=True,
)


def _code_for_text(text: str, reverse: Mapping[str, str], category: str) -> str:
    try:
        return reverse[text]
    except KeyError as exc:
        raise UnknownProfileSummaryText(
            f"Unmapped generated {category} text; add it to profile_summary_catalog."
        ) from exc


def health_profile_codes(value: object) -> list[str]:
    """Map a comma-separated generated health profile to stable codes."""

    parts = [part.strip() for part in str(value or "").split(",") if part.strip()]
    return [_code_for_text(part, _HEALTH_CODE_BY_TEXT, "health profile") for part in parts]


def recommendation_codes_from_items(values: Iterable[object]) -> list[str]:
    """Map individual recommendation strings before they are joined for legacy output."""

    return [
        _code_for_text(str(value).strip(), _RECOMMENDATION_CODE_BY_TEXT, "recommendation")
        for value in values
        if str(value).strip()
    ]


def recommendation_codes(value: object) -> list[str]:
    """Decode the legacy space-joined recommendation prose without fuzzy matching."""

    remaining = str(value or "").strip()
    codes: list[str] = []
    while remaining:
        matched_text = next(
            (text for text in _RECOMMENDATIONS_LONGEST_FIRST if remaining.startswith(text)),
            None,
        )
        if matched_text is None:
            raise UnknownProfileSummaryText(
                "Unmapped generated recommendation text; add it to profile_summary_catalog."
            )
        codes.append(_RECOMMENDATION_CODE_BY_TEXT[matched_text])
        remaining = remaining[len(matched_text) :].lstrip()
    return codes


def food_codes(values: Iterable[object]) -> list[str]:
    """Map generated food labels by exact value, never by substring replacement."""

    return [
        _code_for_text(str(value).strip(), _FOOD_CODE_BY_TEXT, "food")
        for value in values
        if str(value).strip()
    ]


def interpretation_warning_text(code: str) -> str:
    return INTERPRETATION_WARNING_TEXT_BY_CODE[code]


def interpretation_warning_codes(values: Iterable[object]) -> list[str]:
    return [
        _code_for_text(str(value).strip(), _WARNING_CODE_BY_TEXT, "interpretation warning")
        for value in values
        if str(value).strip()
    ]


def build_display_codes(
    *,
    health_profile: object,
    nutrition_recommendation: object,
    foods_to_increase: Iterable[object],
    foods_to_limit: Iterable[object],
    interpretation_warnings: Iterable[object],
) -> dict[str, list[str]]:
    """Build the schema-v2 localization contract from legacy generated fields."""

    return {
        "health_profiles": health_profile_codes(health_profile),
        "recommendations": recommendation_codes(nutrition_recommendation),
        "foods_to_increase": food_codes(foods_to_increase),
        "foods_to_limit": food_codes(foods_to_limit),
        "interpretation_warnings": interpretation_warning_codes(interpretation_warnings),
    }
