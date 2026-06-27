# API Contract

Base path: `/v1`

All `/v1` endpoints require `Authorization: Bearer <Firebase ID token>`.
Production also requires `X-Firebase-AppCheck: <App Check token>`.
`/health` is public. Authentication may be disabled only in non-production
local development with `BIODIETIX_AUTH_REQUIRED=false`.

## Endpoints

| Method | Path | Limit | Purpose |
| --- | --- | --- | --- |
| GET | `/health` | public | Liveness and deployment metadata |
| POST | `/v1/analyze/blood-pdf` | 10/user/min | Parse a blood report and build profile memory |
| POST | `/v1/analyze/allergy-pdf` | 10/user/min | Extract positive allergy signals |
| GET | `/v1/product/lookup/{barcode}` | 60/user/min | Query and normalize product data |
| POST | `/v1/product/evaluate` | 120/user/min | Evaluate a typed product/profile payload |

PDF uploads are limited to 10 MiB by default. Files must have a `.pdf`
extension, an accepted content type and a PDF header. Configure limits with the
environment variables listed in `.env.example`.

## Response behavior

- `400`: malformed form data.
- `401`: missing, expired or invalid Firebase/Auth/App Check token.
- `413`: request or upload is too large.
- `415`: unsupported or invalid PDF.
- `422`: typed validation or supported-value extraction failed.
- `429`: per-user rate limit exceeded; inspect `Retry-After`.
- `502`: upstream product lookup unavailable.
- `503`: authentication service is unavailable.

Every response includes `X-Request-ID`. Internal exception messages and stack
traces are logged server-side and are not returned to clients.

## Data sufficiency

A PDF must contain at least one supported laboratory result; report metadata
does not count. Limited reports carry `Data_Quality_Status=limited` and never
claim overall low health risk. `No Flagged Risk in Available Data` only means
that the values present did not trigger a rule.
