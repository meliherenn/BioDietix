"""Mobile-ready profile memory and product suitability helpers.

The functions in this module do not depend on Streamlit. They are designed so
the current web app and a future mobile app can use the same BioDietix decision
logic for stored user profile data, allergy information, and scanned products.
"""

from __future__ import annotations

import json
import re
import threading
import time
import urllib.error
import urllib.parse
import urllib.request
from datetime import UTC, datetime
from pathlib import Path
from tempfile import NamedTemporaryFile

import pandas as pd

from biodietix import extract_pdf_text

_PRODUCT_CACHE = {}
_PRODUCT_CACHE_LOCK = threading.Lock()
_PRODUCT_CACHE_TTL_SECONDS = 15 * 60

COMMON_ALLERGIES = [
    "milk",
    "gluten",
    "peanut",
    "tree_nut",
    "egg",
    "soy",
    "fish",
    "shellfish",
    "sesame",
]

ALLERGY_DISPLAY_NAMES = {
    "milk": "Milk / dairy",
    "gluten": "Gluten / wheat",
    "peanut": "Peanut",
    "tree_nut": "Tree nuts",
    "egg": "Egg",
    "soy": "Soy",
    "fish": "Fish",
    "shellfish": "Shellfish",
    "sesame": "Sesame",
}

ALLERGEN_KEYWORDS = {
    "milk": (
        "milk",
        "dairy",
        "lactose",
        "casein",
        "whey",
        "sut",
        "süt",
        "laktoz",
        "kazein",
        "peynir",
        "yogurt",
        "yoğurt",
    ),
    "gluten": (
        "gluten",
        "wheat",
        "barley",
        "rye",
        "malt",
        "bugday",
        "buğday",
        "arpa",
        "cavdar",
        "çavdar",
    ),
    "peanut": ("peanut", "groundnut", "yer fistigi", "yer fıstığı"),
    "tree_nut": (
        "nut",
        "nuts",
        "almond",
        "hazelnut",
        "walnut",
        "cashew",
        "pistachio",
        "pecan",
        "badem",
        "findik",
        "fındık",
        "ceviz",
        "kaju",
        "antep fistigi",
        "antep fıstığı",
    ),
    "egg": ("egg", "albumin", "yumurta"),
    "soy": ("soy", "soya", "soybean", "soya lesitini", "soy lecithin"),
    "fish": ("fish", "balik", "balık", "salmon", "tuna", "anchovy"),
    "shellfish": (
        "shellfish",
        "shrimp",
        "crab",
        "lobster",
        "prawn",
        "karides",
        "yengec",
        "yengeç",
        "istakoz",
    ),
    "sesame": ("sesame", "tahini", "tahin", "susam"),
}

ALLERGY_SYNONYMS = {
    keyword: canonical
    for canonical, keywords in ALLERGEN_KEYWORDS.items()
    for keyword in keywords
}
ALLERGY_SYNONYMS.update({canonical: canonical for canonical in COMMON_ALLERGIES})

POSITIVE_ALLERGY_TERMS = (
    "positive",
    "pozitif",
    "class 1",
    "class 2",
    "class 3",
    "class 4",
    "class 5",
    "class 6",
    "high",
    "yuksek",
    "yüksek",
    "reactive",
    "sensitized",
    "duyarl",
)

NEGATIVE_ALLERGY_TERMS = (
    "negative",
    "negatif",
    "class 0",
    "normal",
)

PRODUCT_FIELD_DEFAULTS = {
    "barcode": "",
    "name": "",
    "category": "",
    "ingredients_text": "",
    "allergens_text": "",
    "brand": "",
    "quantity": "",
    "labels": "",
    "serving_size": "",
    "nutrition_grade": "",
    "nova_group": None,
    "energy_kcal_100g": None,
    "sugar_g_100g": None,
    "saturated_fat_g_100g": None,
    "salt_g_100g": None,
    "sodium_mg_100g": None,
    "protein_g_100g": None,
    "fiber_g_100g": None,
}

NUTRIENT_FIELD_LABELS = {
    "energy_kcal_100g": "energy_kcal_100g",
    "sugar_g_100g": "sugar_g_100g",
    "saturated_fat_g_100g": "saturated_fat_g_100g",
    "salt_g_100g": "salt_g_100g",
    "sodium_mg_100g": "sodium_mg_100g",
    "protein_g_100g": "protein_g_100g",
    "fiber_g_100g": "fiber_g_100g",
}


def _clean_text(value):
    if value is None:
        return ""
    if isinstance(value, float) and pd.isna(value):
        return ""
    return str(value).strip()


def _normalized(value):
    return " ".join(_clean_text(value).casefold().split())


def _split_values(value):
    if isinstance(value, (list, tuple, set)):
        raw_values = value
    else:
        raw_values = re.split(r"[,;\n|]+", _clean_text(value))
    return [_clean_text(item) for item in raw_values if _clean_text(item)]


def _first_text(*values):
    for value in values:
        text = _clean_text(value)
        if text:
            return text
    return ""


def _humanize_tag(value):
    text = _clean_text(value)
    if ":" in text:
        text = text.split(":", 1)[1]
    text = text.replace("_", " ").replace("-", " ").strip()
    replacements = {
        "nuts": "tree nuts",
        "peanuts": "peanut",
        "soybeans": "soy",
    }
    return replacements.get(text.casefold(), text)


def _humanize_tags(*values):
    items = []
    for value in values:
        if isinstance(value, (list, tuple, set)):
            raw_values = value
        else:
            raw_values = re.split(r"[,;\n|]+", _clean_text(value))
        for item in raw_values:
            text = _humanize_tag(item)
            if text and text not in items:
                items.append(text)
    return ", ".join(items)


def _to_number(value):
    text = _clean_text(value).replace(",", ".")
    if not text:
        return None
    try:
        return float(text)
    except ValueError:
        return None


def _json_safe(value):
    if value is None:
        return None
    if isinstance(value, float) and pd.isna(value):
        return None
    if hasattr(value, "item"):
        try:
            value = value.item()
        except Exception:
            pass
    if isinstance(value, float) and pd.isna(value):
        return None
    return value


def normalize_allergy_name(value):
    text = _normalized(value)
    if not text:
        return None

    if text in ALLERGY_SYNONYMS:
        return ALLERGY_SYNONYMS[text]

    for keyword, canonical in ALLERGY_SYNONYMS.items():
        if keyword and keyword in text:
            return canonical

    # Preserve unsupported user-entered allergens instead of silently dropping them.
    return text[:100]


def normalize_allergies(values):
    allergies = []
    raw_values = []
    if isinstance(values, (list, tuple, set)):
        for value in values:
            raw_values.extend(_split_values(value))
    else:
        raw_values = _split_values(values)

    for value in raw_values:
        normalized = normalize_allergy_name(value)
        if normalized and normalized not in allergies:
            allergies.append(normalized)
    return allergies


def extract_allergies_from_text(text):
    """Extract likely positive food allergies from an allergy-test PDF text."""

    detected = []
    for line in _clean_text(text).splitlines():
        normalized_line = _normalized(line)
        if not normalized_line:
            continue

        has_positive_word = any(term in normalized_line for term in POSITIVE_ALLERGY_TERMS)
        has_negative_word = any(term in normalized_line for term in NEGATIVE_ALLERGY_TERMS)
        numeric_values = [
            _to_number(match.group(1))
            for match in re.finditer(r"([0-9]+(?:[.,][0-9]+)?)\s*(?:kua/l|ku/l|iu/ml)?", normalized_line)
        ]
        has_positive_numeric = any(value is not None and value >= 0.35 for value in numeric_values)

        if has_negative_word and not has_positive_word and not has_positive_numeric:
            continue

        if not has_positive_word and not has_positive_numeric:
            continue

        for canonical, keywords in ALLERGEN_KEYWORDS.items():
            if any(keyword in normalized_line for keyword in keywords):
                if canonical not in detected:
                    detected.append(canonical)

    return detected


def extract_allergies_from_pdf_file(file_or_path):
    temporary_path = None

    try:
        if isinstance(file_or_path, (str, Path)):
            pdf_path = Path(file_or_path)
        else:
            suffix = Path(getattr(file_or_path, "name", "allergy_report.pdf")).suffix or ".pdf"
            with NamedTemporaryFile(delete=False, suffix=suffix) as temporary_file:
                temporary_file.write(file_or_path.getbuffer())
                temporary_path = Path(temporary_file.name)
            pdf_path = temporary_path

        text = extract_pdf_text(pdf_path)
        return extract_allergies_from_text(text), text
    finally:
        if temporary_path and temporary_path.exists():
            temporary_path.unlink()


def _list_from_csv_text(value):
    return [_clean_text(item) for item in _split_values(value)]


def build_profile_memory(results, allergies=None, extracted_values=None):
    """Build a single-user profile snapshot for local mobile storage."""

    if results is None or len(results) == 0:
        raise ValueError("At least one analyzed result row is required.")

    row = results.iloc[0]
    risk_levels = {}
    for column in results.columns:
        if column.endswith("_Risk_Level") or column in {"Age_Group", "Age_Risk_Level"}:
            value = _json_safe(row.get(column))
            if value not in (None, ""):
                risk_levels[column] = value

    personal_info = {}
    for column in ["Patient_ID", "Gender", "Age", "Weight_kg", "Height_cm", "BMI"]:
        if column in results.columns:
            value = _json_safe(row.get(column))
            if value not in (None, ""):
                personal_info[column] = value

    lab_values = {}
    for key, value in (extracted_values or {}).items():
        safe_value = _json_safe(value)
        if safe_value not in (None, ""):
            lab_values[key] = safe_value

    profile_memory = {
        "schema_version": 1,
        "updated_at": datetime.now(UTC).isoformat(),
        "personal_info": personal_info,
        "bmi": personal_info.get("BMI"),
        "health_profile": _clean_text(row.get("Health_Profile")),
        "nutrition_recommendation": _clean_text(row.get("Nutrition_Recommendation")),
        "foods_to_increase": _list_from_csv_text(row.get("Foods_To_Increase")),
        "foods_to_limit": _list_from_csv_text(row.get("Foods_To_Limit")),
        "risk_levels": risk_levels,
        "data_quality": {
            "status": _json_safe(row.get("Data_Quality_Status")),
            "observed_lab_count": _json_safe(row.get("Observed_Lab_Count")),
            "observed_lab_domains": _json_safe(row.get("Observed_Lab_Domains")),
        },
        "lab_values": lab_values,
        "allergies": normalize_allergies(allergies or []),
    }
    return profile_memory


def profile_memory_to_json(profile_memory):
    return json.dumps(profile_memory, ensure_ascii=False, indent=2)


def profile_memory_from_json(value):
    loaded = json.loads(value)
    loaded["allergies"] = normalize_allergies(loaded.get("allergies", []))
    return loaded


def product_from_open_food_facts(raw_product):
    nutriments = raw_product.get("nutriments", {}) or {}
    sodium_g = _to_number(nutriments.get("sodium_100g"))
    product = {
        **PRODUCT_FIELD_DEFAULTS,
        "barcode": _clean_text(raw_product.get("code")),
        "name": _first_text(
            raw_product.get("product_name_tr"),
            raw_product.get("product_name"),
            raw_product.get("generic_name_tr"),
            raw_product.get("generic_name"),
        ),
        "brand": _clean_text(raw_product.get("brands")),
        "quantity": _clean_text(raw_product.get("quantity")),
        "category": _humanize_tags(raw_product.get("categories_tags"))
        or _clean_text(raw_product.get("categories")),
        "ingredients_text": _first_text(
            raw_product.get("ingredients_text_tr"),
            raw_product.get("ingredients_text"),
        ),
        "allergens_text": _humanize_tags(
            raw_product.get("allergens"),
            raw_product.get("allergens_tags"),
        ),
        "labels": _humanize_tags(raw_product.get("labels"), raw_product.get("labels_tags")),
        "serving_size": _clean_text(raw_product.get("serving_size")),
        "nutrition_grade": _clean_text(
            raw_product.get("nutriscore_grade") or raw_product.get("nutrition_grade_fr")
        ),
        "nova_group": _to_number(raw_product.get("nova_group")),
        "energy_kcal_100g": _to_number(nutriments.get("energy-kcal_100g")),
        "sugar_g_100g": _to_number(nutriments.get("sugars_100g")),
        "saturated_fat_g_100g": _to_number(nutriments.get("saturated-fat_100g")),
        "salt_g_100g": _to_number(nutriments.get("salt_100g")),
        "sodium_mg_100g": sodium_g * 1000 if sodium_g is not None else None,
        "protein_g_100g": _to_number(nutriments.get("proteins_100g")),
        "fiber_g_100g": _to_number(nutriments.get("fiber_100g")),
    }
    return product


def lookup_open_food_facts_product(barcode, timeout=8):
    """Return a normalized product dict from Open Food Facts, or None."""

    clean_barcode = re.sub(r"\D+", "", _clean_text(barcode))
    if not clean_barcode:
        return None

    now = time.monotonic()
    with _PRODUCT_CACHE_LOCK:
        cached = _PRODUCT_CACHE.get(clean_barcode)
        if cached and cached[0] > now:
            return cached[1]

    fields = ",".join(
        [
            "code",
            "brands",
            "quantity",
            "product_name",
            "product_name_tr",
            "generic_name",
            "generic_name_tr",
            "categories",
            "categories_tags",
            "ingredients_text",
            "ingredients_text_tr",
            "allergens",
            "allergens_tags",
            "labels",
            "labels_tags",
            "serving_size",
            "nutriscore_grade",
            "nutrition_grade_fr",
            "nova_group",
            "nutriments",
        ]
    )
    encoded_fields = urllib.parse.quote(fields, safe=",")
    urls = [
        f"https://world.openfoodfacts.org/api/v2/product/{clean_barcode}.json?fields={encoded_fields}&lc=tr",
        f"https://world.openfoodfacts.org/api/v0/product/{clean_barcode}.json",
    ]

    for url in urls:
        request = urllib.request.Request(
            url,
            headers={"User-Agent": "BioDietixML/1.0 (student nutrition project)"},
        )
        try:
            with urllib.request.urlopen(request, timeout=timeout) as response:
                response_body = response.read(2_000_001)
                if len(response_body) > 2_000_000:
                    raise ValueError("Product lookup response exceeded 2 MB.")
                payload = json.loads(response_body.decode("utf-8"))
        except urllib.error.HTTPError as exc:
            if exc.code == 404:
                continue
            raise

        if payload.get("status") == 1 and payload.get("product"):
            product = product_from_open_food_facts(payload["product"])
            with _PRODUCT_CACHE_LOCK:
                if len(_PRODUCT_CACHE) >= 1024:
                    expired = [key for key, value in _PRODUCT_CACHE.items() if value[0] <= now]
                    for key in expired or list(_PRODUCT_CACHE)[:256]:
                        _PRODUCT_CACHE.pop(key, None)
                _PRODUCT_CACHE[clean_barcode] = (
                    now + _PRODUCT_CACHE_TTL_SECONDS,
                    product,
                )
            return product

    with _PRODUCT_CACHE_LOCK:
        _PRODUCT_CACHE[clean_barcode] = (now + 60, None)
    return None


def _combined_product_text(product):
    return _normalized(
        " ".join(
            [
                product.get("name", ""),
                product.get("brand", ""),
                product.get("category", ""),
                product.get("ingredients_text", ""),
                product.get("allergens_text", ""),
                product.get("labels", ""),
            ]
        )
    )


def _find_allergy_conflicts(product, allergies):
    product_text = _combined_product_text(product)
    conflicts = []
    for allergy in normalize_allergies(allergies):
        keywords = ALLERGEN_KEYWORDS.get(allergy, (allergy,))
        if any(keyword in product_text for keyword in keywords):
            conflicts.append(allergy)
    return conflicts


def _profile_contains(profile_memory, *keywords):
    profile_text = _clean_text(profile_memory.get("health_profile")).casefold()
    return any(keyword.casefold() in profile_text for keyword in keywords)


def _has_limited_food(profile_memory, *keywords):
    limited_text = _normalized(", ".join(profile_memory.get("foods_to_limit", [])))
    product_text = _normalized(" ".join(keywords))
    return any(keyword in limited_text for keyword in product_text.split())


def _add_unique(items, item):
    if item not in items:
        items.append(item)


def _record_signal(reasons, alternatives, reason, alternative, severity, points, level):
    reasons.append(reason)
    if alternative:
        _add_unique(alternatives, {"code": alternative})
    return max(severity, level), points + level


def _product_data_quality(normalized_product, nutrient_map, nova_group, nutrition_grade):
    measured_nutrients = [
        label
        for key, label in NUTRIENT_FIELD_LABELS.items()
        if nutrient_map.get(key) is not None
    ]
    missing_nutrients = [
        label
        for key, label in NUTRIENT_FIELD_LABELS.items()
        if nutrient_map.get(key) is None
    ]
    summary_signals = []
    if nova_group is not None:
        summary_signals.append("nova_group")
    if nutrition_grade:
        summary_signals.append("nutrition_grade")

    has_ingredient_text = bool(_clean_text(normalized_product.get("ingredients_text")))
    has_identity_text = any(
        _clean_text(normalized_product.get(key))
        for key in ("name", "brand", "category", "labels", "allergens_text")
    )

    measured_count = len(measured_nutrients)
    if measured_count >= 4:
        level = "high"
    elif measured_count >= 2 or (measured_count >= 1 and summary_signals):
        level = "medium"
    elif measured_count >= 1 or summary_signals or has_ingredient_text or has_identity_text:
        level = "low"
    else:
        level = "missing"

    return {
        "level": level,
        "measured_nutrients": measured_nutrients,
        "missing_nutrients": missing_nutrients,
        "summary_signals": summary_signals,
        "has_ingredient_text": has_ingredient_text,
    }


def evaluate_product_for_profile(product, profile_memory):
    """Evaluate whether a scanned product fits the stored BioDietix profile."""

    normalized_product = {**PRODUCT_FIELD_DEFAULTS, **(product or {})}
    allergies = normalize_allergies(profile_memory.get("allergies", []))
    conflicts = _find_allergy_conflicts(normalized_product, allergies)

    reasons = []
    positives = []
    alternatives = []
    severity = 0

    if conflicts:
        reasons.append({"code": "allergy_conflict", "allergens": conflicts})
        _add_unique(alternatives, {"code": "allergy_safe_same_category"})
        severity = max(severity, 3)

    sugar = _to_number(normalized_product.get("sugar_g_100g"))
    saturated_fat = _to_number(normalized_product.get("saturated_fat_g_100g"))
    salt = _to_number(normalized_product.get("salt_g_100g"))
    sodium = _to_number(normalized_product.get("sodium_mg_100g"))
    energy = _to_number(normalized_product.get("energy_kcal_100g"))
    protein = _to_number(normalized_product.get("protein_g_100g"))
    fiber = _to_number(normalized_product.get("fiber_g_100g"))
    nova_group = _to_number(normalized_product.get("nova_group"))
    nutrition_grade = _normalized(normalized_product.get("nutrition_grade"))
    product_text = _combined_product_text(normalized_product)
    nutrient_map = {
        "energy_kcal_100g": energy,
        "sugar_g_100g": sugar,
        "saturated_fat_g_100g": saturated_fat,
        "salt_g_100g": salt,
        "sodium_mg_100g": sodium,
        "protein_g_100g": protein,
        "fiber_g_100g": fiber,
    }
    data_quality = _product_data_quality(
        normalized_product,
        nutrient_map,
        nova_group,
        nutrition_grade,
    )
    measured_nutrient_count = len(data_quality["measured_nutrients"])

    personal_info = profile_memory.get("personal_info") or {}
    bmi = _to_number(
        profile_memory.get("bmi")
        or profile_memory.get("BMI")
        or personal_info.get("BMI")
        or personal_info.get("bmi")
    )
    blood_sugar_sensitive = _profile_contains(
        profile_memory,
        "Blood Sugar",
        "Insulin Resistance",
        "Glucose",
    )
    lipid_sensitive = _profile_contains(
        profile_memory,
        "Cardiovascular Lipid",
        "Lipid",
        "Cholesterol",
    )
    bp_or_kidney_sensitive = _profile_contains(
        profile_memory,
        "Blood Pressure",
        "Kidney",
        "Muscle",
    )
    weight_sensitive = (
        bmi >= 25
        if bmi is not None
        else _profile_contains(
            profile_memory,
            "Weight Management",
            "Obesity",
            "BMI",
        )
    )
    diet_quality_sensitive = _profile_contains(profile_memory, "Diet Quality")
    thyroid_sensitive = _profile_contains(profile_memory, "Thyroid", "Metabolism")
    risk_points = 0

    if measured_nutrient_count == 0:
        reasons.append({"code": "nutrition_data_missing"})
        _add_unique(alternatives, {"code": "fresh_whole_food"})
        severity = max(severity, 1)

    if sugar is not None:
        if sugar >= 35:
            severity, risk_points = _record_signal(
                reasons,
                alternatives,
                {"code": "very_high_sugar_product", "value": sugar},
                "low_sugar_snack",
                severity,
                risk_points,
                3,
            )
        elif sugar >= 22.5:
            severity, risk_points = _record_signal(
                reasons,
                alternatives,
                {"code": "high_sugar_product", "value": sugar},
                "low_sugar_snack",
                severity,
                risk_points,
                2,
            )
        elif sugar >= 10:
            severity, risk_points = _record_signal(
                reasons,
                alternatives,
                {"code": "moderate_sugar_product", "value": sugar},
                "low_sugar_snack",
                severity,
                risk_points,
                1,
            )

    if saturated_fat is not None:
        if saturated_fat >= 15:
            severity, risk_points = _record_signal(
                reasons,
                alternatives,
                {"code": "very_high_saturated_fat_product", "value": saturated_fat},
                "unsaturated_fat_option",
                severity,
                risk_points,
                3,
            )
        elif saturated_fat >= 5:
            severity, risk_points = _record_signal(
                reasons,
                alternatives,
                {"code": "high_saturated_fat_product", "value": saturated_fat},
                "unsaturated_fat_option",
                severity,
                risk_points,
                2,
            )

    high_sodium = (salt is not None and salt >= 1.5) or (sodium is not None and sodium >= 600)
    moderate_sodium = (salt is not None and salt >= 0.75) or (sodium is not None and sodium >= 300)
    if high_sodium:
        severity, risk_points = _record_signal(
            reasons,
            alternatives,
            {"code": "high_salt_product", "salt": salt, "sodium": sodium},
            "unsalted_option",
            severity,
            risk_points,
            2,
        )
    elif moderate_sodium:
        severity, risk_points = _record_signal(
            reasons,
            alternatives,
            {"code": "moderate_salt_product", "salt": salt, "sodium": sodium},
            "unsalted_option",
            severity,
            risk_points,
            1,
        )

    if energy is not None:
        if energy >= 550:
            severity, risk_points = _record_signal(
                reasons,
                alternatives,
                {"code": "very_high_energy_product", "value": energy},
                "high_fiber_option",
                severity,
                risk_points,
                2,
            )
        elif energy >= 400:
            severity, risk_points = _record_signal(
                reasons,
                alternatives,
                {"code": "high_energy_product", "value": energy},
                "high_fiber_option",
                severity,
                risk_points,
                1,
            )

    if nova_group is not None and nova_group >= 4:
        severity, risk_points = _record_signal(
            reasons,
            alternatives,
            {"code": "ultra_processed_product", "value": nova_group},
            "fresh_whole_food",
            severity,
            risk_points,
            2,
        )

    if nutrition_grade in {"d", "e"}:
        severity, risk_points = _record_signal(
            reasons,
            alternatives,
            {"code": "poor_nutrition_grade", "value": nutrition_grade.upper()},
            "fresh_whole_food",
            severity,
            risk_points,
            2 if nutrition_grade == "e" else 1,
        )

    if fiber is not None and fiber < 3 and (
        (sugar is not None and sugar >= 10) or (energy is not None and energy >= 400)
    ):
        severity, risk_points = _record_signal(
            reasons,
            alternatives,
            {"code": "low_fiber_product", "value": fiber},
            "high_fiber_option",
            severity,
            risk_points,
            1,
        )

    if blood_sugar_sensitive and sugar is not None:
        if sugar >= 22.5:
            reasons.append({"code": "high_sugar_blood_sugar", "value": sugar})
            _add_unique(alternatives, {"code": "low_sugar_snack"})
            severity = max(severity, 3)
        elif sugar >= 10:
            reasons.append({"code": "moderate_sugar_blood_sugar", "value": sugar})
            _add_unique(alternatives, {"code": "low_sugar_snack"})
            severity = max(severity, 2)

    if lipid_sensitive and saturated_fat is not None:
        if saturated_fat >= 10:
            reasons.append({"code": "very_high_saturated_fat_lipid", "value": saturated_fat})
            _add_unique(alternatives, {"code": "unsaturated_fat_option"})
            severity = max(severity, 3)
        elif saturated_fat >= 5:
            reasons.append({"code": "high_saturated_fat_lipid", "value": saturated_fat})
            _add_unique(alternatives, {"code": "unsaturated_fat_option"})
            severity = max(severity, 2)

    high_sodium = (salt is not None and salt >= 1.5) or (sodium is not None and sodium >= 600)
    moderate_sodium = (salt is not None and salt >= 0.75) or (sodium is not None and sodium >= 300)
    if bp_or_kidney_sensitive and high_sodium:
        reasons.append({"code": "high_salt_bp_kidney", "salt": salt, "sodium": sodium})
        _add_unique(alternatives, {"code": "unsalted_option"})
        severity = max(severity, 3)
    elif bp_or_kidney_sensitive and moderate_sodium:
        reasons.append({"code": "moderate_salt_bp_kidney", "salt": salt, "sodium": sodium})
        _add_unique(alternatives, {"code": "unsalted_option"})
        severity = max(severity, 2)

    if weight_sensitive and energy is not None and energy >= 400:
        reasons.append({"code": "high_energy_weight", "value": energy})
        _add_unique(alternatives, {"code": "high_fiber_option"})
        severity = max(severity, 2)

    ultra_processed_terms = (
        "glucose syrup",
        "corn syrup",
        "hydrogenated",
        "palm oil",
        "maltodextrin",
        "emulsifier",
        "preservative",
        "renklendirici",
        "koruyucu",
    )
    if (diet_quality_sensitive or thyroid_sensitive) and any(term in product_text for term in ultra_processed_terms):
        reasons.append({"code": "ultra_processed_diet"})
        _add_unique(alternatives, {"code": "fresh_whole_food"})
        severity = max(severity, 2)

    if diet_quality_sensitive and fiber is not None and fiber < 3:
        reasons.append({"code": "low_fiber_diet", "value": fiber})
        _add_unique(alternatives, {"code": "high_fiber_option"})
        severity = max(severity, 1)

    if bp_or_kidney_sensitive and protein is not None and protein >= 25:
        reasons.append({"code": "high_protein_kidney", "value": protein})
        _add_unique(alternatives, {"code": "balanced_protein_option"})
        severity = max(severity, 2)

    if fiber is not None and fiber >= 6:
        positives.append({"code": "good_fiber", "value": fiber})
    if protein is not None and 8 <= protein < 25:
        positives.append({"code": "good_protein", "value": protein})
    if sugar is not None and sugar <= 5:
        positives.append({"code": "low_sugar", "value": sugar})
    if salt is not None and salt <= 0.3:
        positives.append({"code": "low_salt", "value": salt})

    if reasons and not alternatives:
        _add_unique(alternatives, {"code": "fresh_whole_food"})

    if severity >= 3 or risk_points >= 5:
        decision = "not_recommended"
    elif severity >= 1 or risk_points >= 2:
        decision = "use_with_caution"
    else:
        decision = "recommended"

    if (
        decision == "not_recommended"
        and measured_nutrient_count == 0
        and not conflicts
    ):
        decision = "use_with_caution"

    return {
        "decision": decision,
        "allergy_conflicts": conflicts,
        "reasons": reasons,
        "positives": positives,
        "alternatives": alternatives,
        "data_quality": data_quality,
        "medical_note": "This is educational guidance, not a medical diagnosis.",
    }
