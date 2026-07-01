import unittest

from utils.mobile_health_core import evaluate_product_for_profile


class ProductEvaluationDecisionTests(unittest.TestCase):
    def setUp(self):
        self.profile = {
            "health_profile": "Blood Sugar Risk, Diet Quality, Weight Management",
            "foods_to_limit": [],
            "allergies": ["milk"],
            "bmi": 26,
        }

    def test_sparse_summary_data_does_not_become_not_recommended(self):
        result = evaluate_product_for_profile(
            {"name": "Snack", "nutrition_grade": "e", "nova_group": 4},
            self.profile,
        )

        self.assertEqual(result["decision"], "use_with_caution")
        self.assertEqual(result["data_quality"]["level"], "low")
        self.assertIn(
            "nutrition_data_missing",
            [reason["code"] for reason in result["reasons"]],
        )

    def test_allergy_conflict_remains_not_recommended_with_sparse_data(self):
        result = evaluate_product_for_profile(
            {"name": "Yogurt", "ingredients_text": "milk"},
            self.profile,
        )

        self.assertEqual(result["decision"], "not_recommended")
        self.assertIn("milk", result["allergy_conflicts"])

    def test_measured_high_sugar_can_still_be_not_recommended(self):
        result = evaluate_product_for_profile(
            {"name": "Sweet snack", "sugar_g_100g": 24},
            self.profile,
        )

        self.assertEqual(result["decision"], "not_recommended")
        self.assertEqual(result["data_quality"]["level"], "low")
        self.assertIn(
            "high_sugar_blood_sugar",
            [reason["code"] for reason in result["reasons"]],
        )

    def test_current_bmi_overrides_stale_weight_profile_text(self):
        profile = {
            **self.profile,
            "bmi": 22,
        }
        result = evaluate_product_for_profile(
            {"name": "Energy dense product", "energy_kcal_100g": 450},
            profile,
        )
        self.assertNotIn(
            "high_energy_weight",
            [reason["code"] for reason in result["reasons"]],
        )

    def test_unknown_manual_allergy_is_not_silently_dropped(self):
        profile = {**self.profile, "allergies": ["mustard"]}
        result = evaluate_product_for_profile(
            {"name": "Dressing", "ingredients_text": "water, mustard, vinegar"},
            profile,
        )
        self.assertEqual(result["decision"], "not_recommended")
        self.assertIn("mustard", result["allergy_conflicts"])

    def test_allergen_substring_does_not_match_coconut_as_tree_nut(self):
        profile = {**self.profile, "allergies": ["tree_nut"]}
        result = evaluate_product_for_profile(
            {"name": "Coconut water", "ingredients_text": "coconut water"},
            profile,
        )
        self.assertNotIn("tree_nut", result["allergy_conflicts"])

    def test_free_from_label_does_not_create_confirmed_allergy_match(self):
        result = evaluate_product_for_profile(
            {"name": "Dessert", "allergens_text": "milk-free"},
            self.profile,
        )
        self.assertNotIn("milk", result["allergy_conflicts"])

    def test_possible_identity_allergen_is_caution_not_absolute_rejection(self):
        result = evaluate_product_for_profile(
            {"name": "Milk-style dessert", "ingredients_text": ""},
            self.profile,
        )
        self.assertEqual(result["decision"], "use_with_caution")
        self.assertEqual(result["matched_allergens"][0]["certainty"], "possible")

    def test_low_creatinine_muscle_profile_does_not_trigger_kidney_protein_rule(self):
        profile = {
            "health_profile": "Kidney / Muscle Indicator",
            "risk_levels": {"Creatinine_Risk_Level": "Low"},
            "allergies": [],
        }
        result = evaluate_product_for_profile(
            {"name": "Protein food", "protein_g_100g": 30},
            profile,
        )
        self.assertNotIn(
            "high_protein_kidney",
            [reason["code"] for reason in result["reasons"]],
        )

    def test_explainability_fields_and_disclaimer_are_returned(self):
        result = evaluate_product_for_profile(
            {"name": "Sweet snack", "sugar_g_100g": 24},
            self.profile,
        )
        self.assertIn("blood_sugar", result["matched_risks"])
        self.assertIn("high_sugar", [flag["code"] for flag in result["nutrition_flags"]])
        self.assertIn("ingredients_missing", result["missing_data_warnings"])
        self.assertIn("not a medical device", result["disclaimer"])


if __name__ == "__main__":
    unittest.main()
