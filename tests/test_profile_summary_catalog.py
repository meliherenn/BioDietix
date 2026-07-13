import ast
import inspect
import textwrap
import unittest

import pandas as pd

from biodietix import create_health_profile, generate_recommendations
from utils.food_recommendation_guide import FOOD_GUIDE_RULES
from utils.mobile_health_core import build_profile_memory
from utils.profile_summary_catalog import (
    FOOD_TEXT_BY_CODE,
    HEALTH_PROFILE_TEXT_BY_CODE,
    INTERPRETATION_WARNING_TEXT_BY_CODE,
    RECOMMENDATION_TEXT_BY_CODE,
    UnknownProfileSummaryText,
    build_display_codes,
)


def _literal_mutation_values(function, variable_names):
    tree = ast.parse(textwrap.dedent(inspect.getsource(function)))
    values = []
    for node in ast.walk(tree):
        if not isinstance(node, ast.Call) or not isinstance(node.func, ast.Attribute):
            continue
        if not isinstance(node.func.value, ast.Name):
            continue
        if node.func.value.id not in variable_names:
            continue
        if node.func.attr not in {"append", "extend"}:
            continue
        for argument in node.args:
            if isinstance(argument, ast.Constant) and isinstance(argument.value, str):
                values.append(argument.value)
            elif isinstance(argument, (ast.List, ast.Tuple)):
                values.extend(
                    item.value
                    for item in argument.elts
                    if isinstance(item, ast.Constant) and isinstance(item.value, str)
                )
    return values


class ProfileSummaryCatalogTests(unittest.TestCase):
    def test_every_engine_health_profile_has_a_canonical_code(self):
        emitted = set(_literal_mutation_values(create_health_profile, {"profiles"}))
        emitted.update(
            {
                "No Flagged Risk in Available Data",
                "Low Risk",
                "Insufficient Data",
            }
        )

        self.assertEqual(emitted, set(HEALTH_PROFILE_TEXT_BY_CODE.values()))

    def test_every_engine_recommendation_has_a_canonical_code(self):
        emitted = set(_literal_mutation_values(generate_recommendations, {"recommendations"}))
        emitted.update(rule["recommendation"] for rule in FOOD_GUIDE_RULES)

        self.assertEqual(emitted, set(RECOMMENDATION_TEXT_BY_CODE.values()))

    def test_every_engine_food_has_a_canonical_code(self):
        emitted = set(
            _literal_mutation_values(
                generate_recommendations,
                {"increase_foods", "limit_foods"},
            )
        )
        for rule in FOOD_GUIDE_RULES:
            for field in ("foods_to_increase", "foods_to_limit"):
                emitted.update(value.strip() for value in rule[field].split(",") if value.strip())

        self.assertEqual(emitted, set(FOOD_TEXT_BY_CODE.values()))

    def test_catalog_codes_have_stable_namespaces_and_unique_text(self):
        catalogs = (
            ("health.", HEALTH_PROFILE_TEXT_BY_CODE),
            ("recommendation.", RECOMMENDATION_TEXT_BY_CODE),
            ("food.", FOOD_TEXT_BY_CODE),
            ("warning.", INTERPRETATION_WARNING_TEXT_BY_CODE),
        )
        for prefix, catalog in catalogs:
            self.assertTrue(all(code.startswith(prefix) for code in catalog))
            self.assertEqual(len(catalog), len(set(catalog.values())))

    def test_profile_memory_v2_preserves_legacy_text_and_adds_display_codes(self):
        health_profile = "Blood Sugar Risk, Fiber Intake Signal"
        generated = generate_recommendations(
            pd.Series(
                {
                    "Age_Group": "Young Adult",
                    "Health_Profile": health_profile,
                }
            )
        )
        results = pd.DataFrame(
            [
                {
                    "Health_Profile": health_profile,
                    "Nutrition_Recommendation": generated["Nutrition_Recommendation"],
                    "Foods_To_Increase": generated["Foods_To_Increase"],
                    "Foods_To_Limit": generated["Foods_To_Limit"],
                    "Data_Quality_Status": "sufficient_for_screening",
                }
            ]
        )

        memory = build_profile_memory(
            results,
            extracted_values={
                "Glucose_mgdL": 90,
                "HbA1c_Percent": 5.2,
                "eGFR_ml_min_1_73m2": 90,
            },
        )

        self.assertEqual(memory["schema_version"], 2)
        self.assertEqual(memory["health_profile"], health_profile)
        self.assertEqual(
            memory["nutrition_recommendation"],
            generated["Nutrition_Recommendation"],
        )
        self.assertEqual(
            memory["display_codes"]["health_profiles"],
            ["health.blood_sugar_risk", "health.fiber_intake_signal"],
        )
        self.assertIn(
            "recommendation.medical_disclaimer",
            memory["display_codes"]["recommendations"],
        )
        self.assertEqual(
            memory["display_codes"]["interpretation_warnings"],
            [
                "warning.reference_intervals_vary",
                "warning.glucose_fasting_status_unknown",
                "warning.hba1c_clinical_factors",
                "warning.egfr_single_result_not_diagnostic",
            ],
        )
        self.assertTrue(memory["display_codes"]["foods_to_increase"])
        self.assertTrue(memory["display_codes"]["foods_to_limit"])

    def test_unknown_legacy_text_is_never_fuzzy_mapped(self):
        with self.assertRaises(UnknownProfileSummaryText):
            build_display_codes(
                health_profile="Blood Sugar-ish Risk",
                nutrition_recommendation="",
                foods_to_increase=[],
                foods_to_limit=[],
                interpretation_warnings=[],
            )


if __name__ == "__main__":
    unittest.main()
