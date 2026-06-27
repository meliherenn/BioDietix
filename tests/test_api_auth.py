import unittest
from unittest.mock import Mock, patch

from fastapi import HTTPException
from fastapi.security import HTTPAuthorizationCredentials

from utils.api_auth import require_user
from utils.api_config import APISettings


def settings(*, auth_required=True, app_check_required=True):
    return APISettings(
        environment="production" if auth_required else "development",
        auth_required=auth_required,
        app_check_required=app_check_required,
        firebase_check_revoked=True,
        expose_docs=False,
        allowed_origins=(),
        allowed_hosts=(),
        max_pdf_bytes=10 * 1024 * 1024,
        max_json_bytes=512 * 1024,
    )


class APIAuthenticationTests(unittest.TestCase):
    def test_local_auth_disabled_returns_development_identity(self):
        result = require_user(
            credentials=None,
            app_check_token=None,
            settings=settings(auth_required=False, app_check_required=False),
        )
        self.assertEqual(result["uid"], "local-development")

    def test_valid_firebase_and_app_check_tokens_are_accepted(self):
        firebase_auth = Mock()
        firebase_auth.verify_id_token.return_value = {"uid": "user-1"}
        credentials = HTTPAuthorizationCredentials(scheme="Bearer", credentials="id-token")

        with (
            patch("utils.api_auth._firebase_auth", return_value=firebase_auth),
            patch("utils.api_auth._verify_app_check_token") as verify_app_check,
        ):
            result = require_user(
                credentials=credentials,
                app_check_token="attestation-token",
                settings=settings(),
            )

        self.assertEqual(result["uid"], "user-1")
        firebase_auth.verify_id_token.assert_called_once_with("id-token", check_revoked=True)
        verify_app_check.assert_called_once_with("attestation-token")

    def test_missing_app_check_token_is_rejected_in_production(self):
        firebase_auth = Mock()
        firebase_auth.verify_id_token.return_value = {"uid": "user-1"}
        credentials = HTTPAuthorizationCredentials(scheme="Bearer", credentials="id-token")

        with patch("utils.api_auth._firebase_auth", return_value=firebase_auth):
            with self.assertRaises(HTTPException) as raised:
                require_user(
                    credentials=credentials,
                    app_check_token=None,
                    settings=settings(),
                )

        self.assertEqual(raised.exception.status_code, 401)

    def test_auth_configuration_failure_is_reported_as_unavailable(self):
        credentials = HTTPAuthorizationCredentials(scheme="Bearer", credentials="id-token")

        with patch(
            "utils.api_auth._firebase_auth",
            side_effect=RuntimeError("configuration detail"),
        ):
            with self.assertRaises(HTTPException) as raised:
                require_user(
                    credentials=credentials,
                    app_check_token="attestation-token",
                    settings=settings(),
                )

        self.assertEqual(raised.exception.status_code, 503)
        self.assertNotIn("configuration detail", str(raised.exception.detail))


if __name__ == "__main__":
    unittest.main()
