import unittest

import numpy as np
import pandas as pd

from biodietix import (
    alt_risk,
    ast_risk,
    b12_risk,
    bmi_risk,
    bp_risk,
    cholesterol_risk,
    creatinine_risk,
    crp_risk,
    diet_quality_risk,
    egfr_risk,
    ferritin_risk,
    folate_risk,
    glucose_risk,
    hba1c_risk,
    hct_risk,
    hdl_risk,
    hemoglobin_risk,
    ldl_risk,
    platelet_risk,
    rbc_risk,
    triglyceride_risk,
    tsh_risk,
    vitamin_d_risk,
    wbc_risk,
)


class BiomarkerBoundaryTests(unittest.TestCase):
    def test_glycemic_boundaries_use_indicator_wording(self):
        self.assertEqual(glucose_risk(99.9), "Normal")
        self.assertEqual(glucose_risk(100), "Prediabetes-Range Indicator")
        self.assertIn("Clinical Confirmation", glucose_risk(126))
        self.assertEqual(hba1c_risk(5.6), "Normal")
        self.assertEqual(hba1c_risk(5.7), "Prediabetes-Range Indicator")
        self.assertIn("Clinical Confirmation", hba1c_risk(6.5))

    def test_bmi_and_blood_pressure_boundaries(self):
        self.assertEqual(bmi_risk(18.4), "Underweight")
        self.assertEqual(bmi_risk(18.5), "Normal")
        self.assertEqual(bmi_risk(25), "Overweight Risk")
        self.assertEqual(bmi_risk(30), "Obesity Risk")
        self.assertEqual(bp_risk(129, 79), "Elevated")
        self.assertEqual(bp_risk(130, 79), "Stage 1 Hypertension Risk")
        self.assertEqual(bp_risk(140, 90), "Stage 2 Hypertension Risk")
        self.assertIn("Prompt Clinical Review", bp_risk(181, 80))

    def test_lipid_boundaries(self):
        self.assertEqual(cholesterol_risk(200), "Borderline High")
        self.assertEqual(cholesterol_risk(240), "High Risk")
        self.assertEqual(ldl_risk(100), "Near Optimal")
        self.assertEqual(ldl_risk(190), "Very High")
        self.assertEqual(hdl_risk("Male", 39.9), "Low HDL Risk")
        self.assertEqual(hdl_risk("Female", 50), "Normal")
        self.assertEqual(triglyceride_risk(150), "Borderline High")
        self.assertEqual(triglyceride_risk(500), "Very High")

    def test_kidney_liver_and_inflammation_boundaries(self):
        self.assertEqual(creatinine_risk("Female", 1.05), "High Creatinine Indicator")
        self.assertEqual(egfr_risk(59.9), "Reduced eGFR Indicator")
        self.assertEqual(ast_risk(40), "Normal")
        self.assertEqual(alt_risk("Female", 36), "Elevated ALT Risk")
        self.assertEqual(crp_risk(5.1), "Elevated CRP Indicator")

    def test_micronutrient_and_thyroid_boundaries(self):
        self.assertEqual(vitamin_d_risk(11.9), "Low Vitamin D Indicator")
        self.assertEqual(vitamin_d_risk(12), "Vitamin D Inadequacy Indicator")
        self.assertEqual(vitamin_d_risk(20), "Normal")
        self.assertEqual(b12_risk(199), "Low Vitamin B12 Indicator")
        self.assertEqual(b12_risk(200), "Borderline Vitamin B12 Indicator")
        self.assertEqual(folate_risk(2.9), "Low Folate Indicator")
        self.assertEqual(folate_risk(3), "Normal")
        self.assertEqual(ferritin_risk("Female", 29), "Low Ferritin Indicator")
        self.assertEqual(ferritin_risk("Female", 151), "High Ferritin Indicator")
        self.assertEqual(tsh_risk(0.39), "Low TSH Indicator")
        self.assertEqual(tsh_risk(4.6), "Elevated TSH Indicator")

    def test_blood_count_boundaries(self):
        self.assertEqual(hemoglobin_risk("Female", 11.9), "Low Hemoglobin Risk")
        self.assertEqual(wbc_risk(4), "Normal")
        self.assertEqual(rbc_risk("Male", 4.4), "Low RBC Indicator")
        self.assertEqual(hct_risk("Female", 35), "Normal")
        self.assertEqual(platelet_risk(451), "Elevated Platelet Indicator")

    def test_diet_signal_uses_only_explainable_fiber_input(self):
        high_totals = pd.Series(
            {
                "Daily_Fiber_g": 30,
                "Daily_Sugar_g": 80,
                "Daily_Fat_g": 140,
                "Daily_Cholesterol_mg": 500,
                "Fiber_Risk_Level": "Adequate",
            }
        )
        self.assertEqual(
            diet_quality_risk(high_totals),
            "No Low-Fiber Intake Signal",
        )

        low_fiber = high_totals.copy()
        low_fiber["Daily_Fiber_g"] = 10
        low_fiber["Fiber_Risk_Level"] = "Low Fiber Intake Risk"
        self.assertEqual(diet_quality_risk(low_fiber), "Low Fiber Intake Signal")

        missing = pd.Series(
            {
                "Daily_Fiber_g": np.nan,
                "Daily_Sugar_g": np.nan,
                "Daily_Fat_g": np.nan,
                "Daily_Cholesterol_mg": np.nan,
            }
        )
        self.assertTrue(pd.isna(diet_quality_risk(missing)))


if __name__ == "__main__":
    unittest.main()
