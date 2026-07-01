import unittest

from fastapi.testclient import TestClient

from api import app
from utils.api_auth import require_user
from utils.api_config import APISettings, get_api_settings


class APISecurityTests(unittest.TestCase):
    def setUp(self):
        app.dependency_overrides.clear()
        self.client = TestClient(app, raise_server_exceptions=False)

    def tearDown(self):
        app.dependency_overrides.clear()

    def test_health_is_public_and_reports_auth_requirement(self):
        response = self.client.get("/health")
        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.json()["authentication_required"])
        self.assertIn("X-Request-ID", response.headers)

    def test_protected_endpoint_rejects_missing_token(self):
        response = self.client.post(
            "/v1/product/evaluate",
            json={"product": {}, "profile_memory": {}},
        )
        self.assertEqual(response.status_code, 401)

    def test_typed_product_evaluation_accepts_authenticated_request(self):
        app.dependency_overrides[require_user] = lambda: {"uid": "test-user"}
        response = self.client.post(
            "/v1/product/evaluate",
            json={
                "product": {"name": "Sweet snack", "sugar_g_100g": 24},
                "profile_memory": {
                    "health_profile": "Blood Sugar Risk",
                    "allergies": [],
                },
            },
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["decision"], "not_recommended")

    def test_invalid_nutrient_value_is_rejected(self):
        app.dependency_overrides[require_user] = lambda: {"uid": "test-user"}
        response = self.client.post(
            "/v1/product/evaluate",
            json={
                "product": {"sugar_g_100g": -1},
                "profile_memory": {},
            },
        )
        self.assertEqual(response.status_code, 422)
        self.assertNotIn("input", response.text)

    def test_unknown_payload_field_is_rejected(self):
        app.dependency_overrides[require_user] = lambda: {"uid": "test-user"}
        response = self.client.post(
            "/v1/product/evaluate",
            json={
                "product": {"sugars_g_100g": 20},
                "profile_memory": {},
            },
        )
        self.assertEqual(response.status_code, 422)

    def test_upload_rejects_non_pdf_content(self):
        app.dependency_overrides[require_user] = lambda: {"uid": "test-user"}
        response = self.client.post(
            "/v1/analyze/blood-pdf",
            files={"file": ("report.pdf", b"not a pdf", "application/pdf")},
        )
        self.assertEqual(response.status_code, 415)

    def test_upload_rejects_pdf_over_configured_limit(self):
        app.dependency_overrides[require_user] = lambda: {"uid": "test-user"}
        app.dependency_overrides[get_api_settings] = lambda: APISettings(
            environment="test",
            auth_required=True,
            app_check_required=False,
            firebase_check_revoked=False,
            expose_docs=False,
            allowed_origins=(),
            allowed_hosts=(),
            max_pdf_bytes=64,
            max_json_bytes=512 * 1024,
        )
        response = self.client.post(
            "/v1/analyze/blood-pdf",
            files={"file": ("report.pdf", b"%PDF-1.7\n" + b"x" * 100, "application/pdf")},
        )
        self.assertEqual(response.status_code, 413)

    def test_oversized_json_is_rejected_before_validation(self):
        response = self.client.post(
            "/v1/product/evaluate",
            content=b"x" * (600 * 1024),
            headers={"content-type": "application/json"},
        )
        self.assertEqual(response.status_code, 413)
        self.assertIn("X-Request-ID", response.headers)
        self.assertEqual(response.headers["X-Content-Type-Options"], "nosniff")

    def test_unsafe_request_id_is_replaced(self):
        response = self.client.get(
            "/health",
            headers={"X-Request-ID": "contains spaces"},
        )
        self.assertEqual(response.status_code, 200)
        self.assertNotEqual(response.headers["X-Request-ID"], "contains spaces")


if __name__ == "__main__":
    unittest.main()
