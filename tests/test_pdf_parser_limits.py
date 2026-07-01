import unittest
from unittest.mock import Mock, patch

import pandas as pd

from biodietix import extract_lab_values, extract_pdf_text


class PDFParserLimitTests(unittest.TestCase):
    def test_turkish_decimal_is_parsed_and_inequality_is_not_treated_as_exact(self):
        values = extract_lab_values("GLUKOZ < 100,5\nVitamin B12 245\n")
        self.assertTrue(pd.isna(values["Glucose_mgdL"]))
        self.assertEqual(values["Vitamin_B12_pg_mL"], 245)

    def test_incompatible_units_are_not_silently_misinterpreted(self):
        values = extract_lab_values(
            "Glucose 5.5 mmol/L\nKreatinin 80 µmol/L\nVitamin D 50 nmol/L\n"
        )
        self.assertTrue(pd.isna(values["Glucose_mgdL"]))
        self.assertTrue(pd.isna(values["Kidney_Creatinine_mgdL"]))
        self.assertTrue(pd.isna(values["VitaminD_ng_mL"]))

    def test_excessive_page_count_is_rejected_before_page_extraction(self):
        fake_pdf = Mock()
        fake_pdf.pages = [Mock() for _ in range(51)]
        context = Mock()
        context.__enter__ = Mock(return_value=fake_pdf)
        context.__exit__ = Mock(return_value=False)
        with patch("pdfplumber.open", return_value=context):
            with self.assertRaisesRegex(ValueError, "page count"):
                extract_pdf_text("unused.pdf", max_pages=50)

    def test_extracted_text_limit_is_enforced(self):
        page = Mock()
        page.extract_text.return_value = "x" * 20
        fake_pdf = Mock()
        fake_pdf.pages = [page]
        context = Mock()
        context.__enter__ = Mock(return_value=fake_pdf)
        context.__exit__ = Mock(return_value=False)
        with patch("pdfplumber.open", return_value=context):
            with self.assertRaisesRegex(ValueError, "text exceeds"):
                extract_pdf_text("unused.pdf", max_pages=1, max_text_chars=10)


if __name__ == "__main__":
    unittest.main()
