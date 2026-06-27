# Security Policy

## Reporting

Do not open a public issue for vulnerabilities or exposed health data. Contact
the repository owner privately and include affected version, reproduction steps
and impact. Do not attach real patient reports.

## Production baseline

- Firebase bearer verification is mandatory for `/v1`.
- Firebase service-account JSON belongs only in a secret manager.
- Firestore and Storage rules are deployed from this repository.
- Local health data is encrypted with a key held by platform secure storage.
- PDF and JSON body limits, per-user rate limits and safe errors are enabled.
- API documentation is disabled in production by default.
- Production builds require a release signing key.

## Remaining operational requirements

- Replace the single-process limiter with Redis before horizontal scaling.
- Add centralized log/metric collection with health-data redaction.
- Run secret scanning and dependency audit in CI.
- Purge the removed patient sample from Git history and existing forks/clones.
- Rotate any credential if exposure is suspected.

Firebase web/API keys in client configuration are identifiers, not server
secrets. Security depends on Auth, App Check where appropriate, and restrictive
Firestore/Storage rules.
