import os
import unittest
from unittest.mock import patch

from utils.api_config import APISettings


class APISettingsTests(unittest.TestCase):
    def test_production_defaults_require_auth_and_app_check(self):
        with patch.dict(
            os.environ,
            {
                "BIODIETIX_ENV": "production",
                "BIODIETIX_ALLOWED_HOSTS": "api.example.com",
            },
            clear=True,
        ):
            settings = APISettings.from_environment()
        self.assertTrue(settings.auth_required)
        self.assertTrue(settings.app_check_required)
        self.assertFalse(settings.expose_docs)

    def test_production_rejects_disabled_authentication(self):
        with patch.dict(
            os.environ,
            {
                "BIODIETIX_ENV": "production",
                "BIODIETIX_AUTH_REQUIRED": "false",
            },
            clear=True,
        ):
            with self.assertRaises(ValueError):
                APISettings.from_environment()

    def test_production_rejects_wildcard_cors(self):
        with patch.dict(
            os.environ,
            {
                "BIODIETIX_ENV": "production",
                "BIODIETIX_ALLOWED_ORIGINS": "*",
                "BIODIETIX_ALLOWED_HOSTS": "api.example.com",
            },
            clear=True,
        ):
            with self.assertRaises(ValueError):
                APISettings.from_environment()

    def test_production_rejects_disabled_app_check(self):
        with patch.dict(
            os.environ,
            {
                "BIODIETIX_ENV": "production",
                "BIODIETIX_APP_CHECK_REQUIRED": "false",
                "BIODIETIX_ALLOWED_HOSTS": "api.example.com",
            },
            clear=True,
        ):
            with self.assertRaises(ValueError):
                APISettings.from_environment()

    def test_production_requires_explicit_trusted_hosts(self):
        with patch.dict(os.environ, {"BIODIETIX_ENV": "production"}, clear=True):
            with self.assertRaises(ValueError):
                APISettings.from_environment()


if __name__ == "__main__":
    unittest.main()
