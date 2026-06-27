import unittest
from unittest.mock import patch

import numpy as np
import pandas as pd

from biodietix import create_health_profile, summarize_pdf_lab_coverage
from utils.biodietix_web import BioDietixPDFError, analyze_pdf_file


class PDFSafetyTests(unittest.TestCase):
    def test_metadata_only_pdf_is_rejected(self):
        parsed = pd.DataFrame(
            [{"Analysis_Source": "pdf", "Health_Profile": "No Flagged Risk in Available Data"}]
        )
        metadata_and_empty_labs = {
            "Report_Date": "2026-06-27",
            "Birth_Date": "1990-01-01",
            "Glucose_mgdL": np.nan,
        }
        with patch(
            "utils.biodietix_web.analyze_pdf_report",
            return_value=(parsed, metadata_and_empty_labs, "Tarih: 27.06.2026"),
        ):
            with self.assertRaises(BioDietixPDFError):
                analyze_pdf_file("unused.pdf")

    def test_pdf_without_flags_never_claims_low_risk(self):
        profile = create_health_profile(
            pd.Series({"Analysis_Source": "pdf", "Glucose_Risk_Level": "Normal"})
        )
        self.assertEqual(profile, "No Flagged Risk in Available Data")

    def test_coverage_requires_multiple_domains_for_screening_status(self):
        limited = summarize_pdf_lab_coverage({"Glucose_mgdL": 90, "HbA1c_Percent": 5.2})
        sufficient = summarize_pdf_lab_coverage(
            {
                "Glucose_mgdL": 90,
                "HbA1c_Percent": 5.2,
                "Cholesterol_Total_mgdL": 180,
                "Kidney_Creatinine_mgdL": 0.9,
                "Liver_AST_UL": 20,
            }
        )
        self.assertEqual(limited["Data_Quality_Status"], "limited")
        self.assertEqual(sufficient["Data_Quality_Status"], "sufficient_for_screening")


if __name__ == "__main__":
    unittest.main()
