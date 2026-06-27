# BioDietix Architecture

## Runtime components

```text
Flutter app
  ├─ Firebase Auth ── ID token ───────────────┐
  ├─ Firebase App Check ── attestation token ─┤
  ├─ encrypted Hive cache                     │
  ├─ Firestore/Storage (UID-scoped rules)     │
  └─ HTTPS /v1 API calls ─────────────────────▼
                                      FastAPI service
                                        ├─ token verification
                                        ├─ upload/rate limits
                                        ├─ PDF extraction
                                        ├─ rule-based risk engine
                                        └─ Open Food Facts adapter

Streamlit web app ── shared Python rule engine and audit utilities
```

The production decision path is rule-based. The scikit-learn models are audit
experiments and are never loaded by FastAPI or Flutter.

## Trust boundaries

- A Firebase login in the UI is not sufficient by itself. FastAPI verifies the
  bearer token for every `/v1` request and App Check in production.
- Uploaded PDFs are untrusted input. The API verifies extension, content type,
  PDF signature and size before parsing, then deletes the temporary file.
- Product data is external and may be incomplete. Every decision carries a data
  quality result.
- Firestore and Storage access must be deployed from the versioned rules in the
  repository. Client-side paths are not an authorization mechanism.

## Python boundaries

- `biodietix.py`: deterministic risk and recommendation domain logic.
- `utils/biodietix_web.py`: CSV/PDF application orchestration.
- `utils/mobile_health_core.py`: allergy, profile-memory and product rules.
- `utils/biodietix_audit.py`: non-production ML audit.
- `utils/api_*`: API configuration, authentication and abuse controls.
- `api.py`: typed HTTP contract and endpoint orchestration.

## Mobile boundaries

- `features/*/data`: Firebase/local persistence adapters.
- `features/*/presentation`: Cubit state and UI.
- `services/biodietix_api.dart`: authenticated HTTP adapter.
- `core/storage`: encrypted local persistence and migration.

## Known scaling boundary

The included rate limiter is single-process. A multi-instance deployment must
replace it with a Redis-backed limiter keyed by Firebase UID. PDF work is moved
off the event loop, but high traffic should use a bounded worker queue.
