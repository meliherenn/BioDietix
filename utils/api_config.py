import os
from dataclasses import dataclass
from functools import lru_cache


def _bool_env(name, default):
    value = os.getenv(name)
    if value is None:
        return default
    return value.strip().lower() in {"1", "true", "yes", "on"}


def _csv_env(name):
    return tuple(item.strip() for item in os.getenv(name, "").split(",") if item.strip())


@dataclass(frozen=True)
class APISettings:
    environment: str
    auth_required: bool
    app_check_required: bool
    firebase_check_revoked: bool
    expose_docs: bool
    allowed_origins: tuple[str, ...]
    allowed_hosts: tuple[str, ...]
    max_pdf_bytes: int
    max_json_bytes: int

    @classmethod
    def from_environment(cls):
        environment = os.getenv("BIODIETIX_ENV", "development").strip().lower()
        auth_required = _bool_env("BIODIETIX_AUTH_REQUIRED", True)
        allowed_origins = _csv_env("BIODIETIX_ALLOWED_ORIGINS")
        if environment == "production" and not auth_required:
            raise ValueError("Authentication cannot be disabled in production.")
        if environment == "production" and "*" in allowed_origins:
            raise ValueError("Wildcard CORS origins are not allowed in production.")
        return cls(
            environment=environment,
            auth_required=auth_required,
            app_check_required=_bool_env(
                "BIODIETIX_APP_CHECK_REQUIRED",
                environment == "production",
            ),
            firebase_check_revoked=_bool_env(
                "BIODIETIX_FIREBASE_CHECK_REVOKED",
                environment == "production",
            ),
            expose_docs=_bool_env("BIODIETIX_EXPOSE_DOCS", environment != "production"),
            allowed_origins=allowed_origins,
            allowed_hosts=_csv_env("BIODIETIX_ALLOWED_HOSTS"),
            max_pdf_bytes=max(
                1024,
                int(os.getenv("BIODIETIX_MAX_PDF_BYTES", str(10 * 1024 * 1024))),
            ),
            max_json_bytes=max(
                1024,
                int(os.getenv("BIODIETIX_MAX_JSON_BYTES", str(512 * 1024))),
            ),
        )


@lru_cache(maxsize=1)
def get_api_settings():
    return APISettings.from_environment()
