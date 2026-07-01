import unittest

import numpy as np
import pandas as pd

from utils.biodietix_web import REQUIRED_ANALYSIS_COLUMNS, analyze_dataframe


class DataframeSafetyTests(unittest.TestCase):
    def test_sparse_row_does_not_claim_low_risk(self):
        row = {column: np.nan for column in REQUIRED_ANALYSIS_COLUMNS}
        row.update({"Gender": "Female", "Glucose_mgdL": 90, "BMI": 22})

        result = analyze_dataframe(pd.DataFrame([row]))

        self.assertEqual(result.loc[0, "Data_Quality_Status"], "limited")
        self.assertEqual(result.loc[0, "Health_Profile"], "Insufficient Data")

    def test_limited_row_keeps_an_observed_risk(self):
        row = {column: np.nan for column in REQUIRED_ANALYSIS_COLUMNS}
        row.update({"Gender": "Male", "Glucose_mgdL": 180, "BMI": 22})

        result = analyze_dataframe(pd.DataFrame([row]))

        self.assertEqual(result.loc[0, "Data_Quality_Status"], "limited")
        self.assertIn("Blood Sugar Risk", result.loc[0, "Health_Profile"])

    def test_low_fiber_creates_a_signal_not_a_diet_quality_claim(self):
        row = {column: np.nan for column in REQUIRED_ANALYSIS_COLUMNS}
        row.update(
            {
                "Gender": "Female",
                "Glucose_mgdL": 90,
                "BMI": 22,
                "Daily_Fiber_g": 10,
            }
        )

        result = analyze_dataframe(pd.DataFrame([row]))

        self.assertEqual(
            result.loc[0, "Diet_Quality_Risk_Level"],
            "Low Fiber Intake Signal",
        )
        self.assertIn("Fiber Intake Signal", result.loc[0, "Health_Profile"])
        self.assertNotIn("Diet Quality Risk", result.loc[0, "Health_Profile"])


if __name__ == "__main__":
    unittest.main()
