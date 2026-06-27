# Deployment Runbook

## API

Build and run the production container:

```bash
docker build -t biodietix-api .
docker run --rm -p 8000:8000 \
  --env-file .env.production \
  biodietix-api
```

Required production controls:

- `BIODIETIX_ENV=production`
- `BIODIETIX_AUTH_REQUIRED=true`
- `BIODIETIX_APP_CHECK_REQUIRED=true`
- `BIODIETIX_FIREBASE_CHECK_REVOKED=true`
- `BIODIETIX_FIREBASE_CREDENTIALS_JSON` from a secret manager
- explicit CORS/host values if browser clients are introduced
- one worker while using the in-process rate limiter

Before a production mobile rollout, enable Play Integrity for the Android app
in Firebase App Check. Register development debug tokens only in non-production
Firebase projects. Verify that requests without `X-Firebase-AppCheck` receive
`401` in production.

Deploy Firestore and Storage rules before distributing a mobile build:

```bash
firebase deploy --only firestore:rules,storage
```

## Streamlit

The web image is separate so the API image does not contain the large default
CSV:

```bash
docker build -f Dockerfile.web -t biodietix-web .
```

Set `BIODIETIX_WEB_PASSWORD` through the platform secret manager. The built-in
shared password is a minimum gate, not identity-aware authorization; public
health-report access still requires an authenticated reverse proxy, TLS and an
approved retention/logging policy.

## Release process

1. CI must pass Python tests, Flutter format/analyze/test/build, Docker builds,
   Firebase rule compilation, secret scanning and dependency audit.
2. Deploy to staging with a separate Firebase environment collection.
3. Run authenticated API smoke tests and upload-limit/error-path tests.
4. Verify Firestore/Storage rules with Firebase Emulator Suite.
5. Deploy API, wait for `/health`, then release the mobile build.
6. Monitor error rate, latency, 401/429 volume and PDF processing duration.
7. Roll back the container image if error or latency budgets are exceeded.

Android release builds intentionally fail when `android/key.properties` is
missing. Never ship a debug-signed artifact.

Use `BIODIETIX_APP_CHECK_ENABLED=false` only for controlled sideload testing
against a backend where App Check is also disabled. Play/Internal Testing and
public production builds must set it to `true`.
