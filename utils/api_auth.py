import json
import logging
import os

from fastapi import Depends, Header, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from utils.api_config import APISettings, get_api_settings

LOGGER = logging.getLogger("biodietix.api.auth")
BEARER = HTTPBearer(auto_error=False)


def _firebase_auth():
    try:
        import firebase_admin
        from firebase_admin import auth, credentials
    except ImportError as exc:
        raise RuntimeError("firebase-admin is not installed") from exc

    try:
        firebase_admin.get_app()
    except ValueError:
        try:
            credentials_json = os.getenv("BIODIETIX_FIREBASE_CREDENTIALS_JSON")
            if credentials_json:
                firebase_admin.initialize_app(credentials.Certificate(json.loads(credentials_json)))
            else:
                firebase_admin.initialize_app()
        except Exception as exc:
            raise RuntimeError("Firebase credentials are invalid") from exc
    return auth


def _verify_app_check_token(token):
    _firebase_auth()
    try:
        from firebase_admin import app_check
    except ImportError as exc:
        raise RuntimeError("firebase-admin App Check support is unavailable") from exc
    return app_check.verify_token(token)


def require_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(BEARER),
    app_check_token: str | None = Header(default=None, alias="X-Firebase-AppCheck"),
    settings: APISettings = Depends(get_api_settings),
):
    if not settings.auth_required:
        return {"uid": "local-development", "auth_disabled": True}

    if credentials is None or credentials.scheme.lower() != "bearer":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication required.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    try:
        decoded = _firebase_auth().verify_id_token(
            credentials.credentials,
            check_revoked=settings.firebase_check_revoked,
        )
    except RuntimeError as exc:
        LOGGER.error("firebase_authentication_unavailable error_type=%s", type(exc).__name__)
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Authentication service unavailable.",
        ) from exc
    except Exception as exc:
        LOGGER.warning("Firebase token verification failed: %s", type(exc).__name__)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired authentication token.",
            headers={"WWW-Authenticate": "Bearer"},
        ) from exc

    uid = decoded.get("uid") or decoded.get("sub")
    if not uid:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication token has no user identity.",
        )
    if settings.app_check_required:
        if not app_check_token:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="App attestation required.",
            )
        try:
            _verify_app_check_token(app_check_token)
        except RuntimeError as exc:
            LOGGER.error("firebase_app_check_unavailable error_type=%s", type(exc).__name__)
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="App attestation service unavailable.",
            ) from exc
        except Exception as exc:
            LOGGER.warning("Firebase App Check verification failed: %s", type(exc).__name__)
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid app attestation token.",
            ) from exc
    return decoded
