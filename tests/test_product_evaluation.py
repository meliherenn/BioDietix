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


if __name__ == "__main__":
    unittest.main()
