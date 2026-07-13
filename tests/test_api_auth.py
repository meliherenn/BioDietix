import unittest
from unittest.mock import Mock, patch

from fastapi import HTTPException
from fastapi.security import HTTPAuthorizationCredentials
from starlette.requests import Request

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


def request_with_id(request_id):
    request = Request({"type": "http", "method": "POST", "path": "/", "headers": []})
    request.state.request_id = request_id
    return request


class APIAuthenticationTests(unittest.TestCase):
    def test_local_auth_disabled_returns_development_identity(self):
        result = require_user(
            request=request_with_id("test-local"),
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
                request=request_with_id("test-valid"),
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
                    request=request_with_id("test-missing-app-check"),
                    credentials=credentials,
                    app_check_token=None,
                    settings=settings(),
                )

        self.assertEqual(raised.exception.status_code, 403)

    def test_auth_configuration_failure_is_reported_as_unavailable(self):
        credentials = HTTPAuthorizationCredentials(scheme="Bearer", credentials="id-token")

        with patch(
            "utils.api_auth._firebase_auth",
            side_effect=RuntimeError("configuration detail"),
        ):
            with self.assertRaises(HTTPException) as raised:
                require_user(
                    request=request_with_id("test-auth-unavailable"),
                    credentials=credentials,
                    app_check_token="attestation-token",
                    settings=settings(),
                )

        self.assertEqual(raised.exception.status_code, 503)
        self.assertNotIn("configuration detail", str(raised.exception.detail))

    def test_invalid_app_check_token_is_forbidden(self):
        firebase_auth = Mock()
        firebase_auth.verify_id_token.return_value = {"uid": "user-1"}
        credentials = HTTPAuthorizationCredentials(scheme="Bearer", credentials="id-token")

        with (
            patch("utils.api_auth._firebase_auth", return_value=firebase_auth),
            patch(
                "utils.api_auth._verify_app_check_token",
                side_effect=ValueError("sensitive verifier detail"),
            ),
        ):
            with self.assertRaises(HTTPException) as raised:
                require_user(
                    request=request_with_id("test-invalid-app-check"),
                    credentials=credentials,
                    app_check_token="invalid-attestation-token",
                    settings=settings(),
                )

        self.assertEqual(raised.exception.status_code, 403)
        self.assertEqual(raised.exception.detail, "Invalid app attestation token.")
        self.assertNotIn("sensitive", str(raised.exception.detail))

    def test_app_check_key_fetch_failure_is_service_unavailable(self):
        class PyJWKClientError(Exception):
            pass

        firebase_auth = Mock()
        firebase_auth.verify_id_token.return_value = {"uid": "user-1"}
        credentials = HTTPAuthorizationCredentials(scheme="Bearer", credentials="id-token")

        with (
            patch("utils.api_auth._firebase_auth", return_value=firebase_auth),
            patch(
                "utils.api_auth._verify_app_check_token",
                side_effect=PyJWKClientError("key service detail"),
            ),
        ):
            with self.assertRaises(HTTPException) as raised:
                require_user(
                    request=request_with_id("test-key-fetch"),
                    credentials=credentials,
                    app_check_token="attestation-token",
                    settings=settings(),
                )

        self.assertEqual(raised.exception.status_code, 503)
        self.assertEqual(raised.exception.detail, "App attestation service unavailable.")


if __name__ == "__main__":
    unittest.main()
