# Production Readiness Audit

Audit date: 2026-07-01  
Release verdict: **Not yet ready for public Google Play production.** The implementation is substantially safer after this audit, but the P0 owner/clinical/legal/Play configuration gates below cannot be completed from source code alone.

## Scope and architecture reviewed

- Python: `api.py`, `biodietix.py`, `app.py`, all `utils/*`, datasets and food-guide rules.
- Parsing: blood/allergy PDF extraction, CSV analysis, data-quality behavior and temporary-file handling.
- Product decisions: Open Food Facts lookup, nutrition flags and allergy normalization/matching.
- Flutter: auth, Google Sign-In, App Check, profile/report/product flows, local/cloud storage, deletion/export, localization, accessibility basics and Android configuration.
- Firebase: Auth integration, Firestore and Storage rules.
- Operations: Dockerfiles, Render configuration, environment defaults, secrets and documentation.
- Tests and release configuration.

The production decision path is deterministic rules. The ML audit code predicts rule-engine pseudo-labels and is not served by the API.

## Executive findings

### Critical bugs and safety issues found

| Priority | Finding | Impact | Status |
| --- | --- | --- | --- |
| P0 | A generic PDF glucose value was interpreted using fasting thresholds even though fasting status is often unknown. | False reassurance or false range flag. | Mitigated: result wording is now an indicator; profile includes fasting-status uncertainty. Explicit fasting metadata is still P1. |
| P0 | Unit text was ignored. For example, glucose `5.5 mmol/L` could be interpreted as `5.5 mg/dL`. Inequality values such as `<100` were treated as exact `100`. | Wrong biomarker category. | Fixed: incompatible units and inequality-only values are omitted, with regression tests. Explicit conversion/schema remains P1. |
| P0 | The combined “Kidney / Muscle” profile made low creatinine trigger a high-protein product restriction intended for reduced kidney function. | Scientifically incorrect personalized decision. | Fixed: kidney protein caution requires explicit reduced-eGFR or high-creatinine risk data. |
| P0 | Generic micronutrient advice could recommend iron-rich foods for high ferritin because low and high ferritin shared one profile. | Unsafe or contradictory guidance. | Fixed: high ferritin explicitly suppresses iron-increase advice and directs clinical review. |
| P0 | Production allowed App Check to be explicitly disabled and could run without Trusted Host enforcement. | Backend did not fully fail closed. | Fixed: production startup rejects disabled Auth/App Check, absent/wildcard trusted hosts, wildcard CORS and exposed docs by default. Render hosts are explicit. |
| P1 | Allergen matching used raw substring checks (`nut` could match `coconut`) and did not expose certainty/source. | False allergy conflicts and poor explainability. | Fixed: phrase matching, declared/ingredient/possible certainty, `matched_allergens`, and allergy override tests. |
| P1 | Product responses lacked the complete requested explainability contract. | User could not tell what profile signal or missing field drove a decision. | Fixed: `decision_label`, `matched_risks`, `matched_allergens`, `nutrition_flags`, `missing_data_warnings`, reasons and full disclaimer are returned. |
| P1 | `READ_MEDIA_IMAGES` was requested for an occasional system-picker use. | Google Play Photo/Video Permissions rejection risk. | Fixed: permission removed; camera remains for barcode/profile-photo capture. |
| P1 | No in-app privacy-policy access. | Health Apps policy blocker. | Fixed technically: Settings opens a configurable HTTPS policy URL. The policy content itself is still a P0 owner/legal task. |

## Medical and scientific accuracy risks

The detailed rule-by-rule matrix is in [SCIENTIFIC_VALIDATION.md](SCIENTIFIC_VALIDATION.md).

High-risk remaining items:

1. The rules have not been reviewed or signed off by a qualified physician/laboratory specialist and registered dietitian.
2. The PDF parser does not ingest the laboratory's own reference range, specimen type, fasting status or structured unit. Unsupported units are now omitted, which is safer but reduces coverage.
3. “Diet Quality Risk” is an unvalidated heuristic using fixed fiber/sugar/fat/cholesterol cutoffs. Total versus added/free sugar is unclear, and fixed total-fat/dietary-cholesterol cutoffs lack energy context.
4. Creatinine, CBC, liver, CRP, ferritin, thyroid and waist cutoffs vary by laboratory and population. The current bands are only screening-style indicators.
5. PDF allergy extraction treats `>=0.35` and positive/class text as sensitization signals. Sensitization is not equivalent to clinical allergy; provenance is not yet preserved in stored allergy entries.
6. The canonical allergy list is incomplete relative to EU/Türkiye labeling categories, although manual allergens are retained.
7. The large generated recommendation CSVs contain historical wording. Runtime web analysis refreshes rules, and the mobile API does not ship those files, but they must not be distributed as current clinical output without regeneration and review.

## Unsafe or misleading claims

Found wording included “improve glycemic control,” “reduce blood pressure/cardiovascular risk,” “improve insulin sensitivity,” “promote weight loss,” and broad micronutrient/thyroid support claims. These can read as treatment or prevention claims.

Code changes replaced these with food-choice support language, added “not a medical device” and “does not diagnose, treat, cure, or prevent” text, removed supplement-like thyroid advice, and made “recommended” display as “appears suitable based on available data.” Store listing copy and screenshots must receive the same review; source changes cannot verify Play Console text.

## Backend and API security

### Controls present or added

- Typed Pydantic payloads now reject unknown fields, NaN/infinity and physiologically impossible product values.
- Authenticated `/v1` endpoints require Firebase ID tokens; production also requires App Check and revoked-token checking.
- Production docs/OpenAPI are disabled unless explicitly enabled.
- PDF extension, MIME, header and streaming byte limits are enforced; empty/non-PDF/oversized uploads are rejected.
- PDF processing now limits pages (default 50) and extracted text (default 200,000 characters), and always deletes temporary files.
- Malformed parser errors are returned generically. Production logs record event/type/request metadata, not request bodies, tokens, PDF text, profile data or stack traces.
- JSON size, request ID normalization, security headers, CORS allowlists and Trusted Host middleware are present.
- Product lookup has a timeout, a 2 MB response cap, bounded TTL cache and a documented custom User-Agent.
- Product lookup API rate is now 10/user/minute, consistent with the upstream's shared-IP constraints more closely than the previous 60.

### Remaining backend risks

| Priority | Risk | Required action |
| --- | --- | --- |
| P0 | No production secret/config proof. | Put Firebase Admin credentials only in Render secret storage; verify no historical exposure and rotate if uncertain. |
| P1 | Rate limiting and cache are process-local. Multiple workers/instances bypass per-user totals and duplicate upstream traffic. | Keep one worker or use Redis/shared rate limits and cache before scaling. |
| P1 | Render hostnames and current app default endpoint may not match the eventual service. | Confirm the actual hostname, update `BIODIETIX_ALLOWED_HOSTS` and build-time API URL, then run authenticated smoke tests. |
| P1 | PDF parser libraries process attacker-controlled files. | Apply dependency scanning, resource/CPU/memory limits, request timeouts at the proxy, and consider isolated worker processing. |
| P1 | Open Food Facts v2 is deprecated and v0 fallback is legacy. | Plan a tested v3 migration; do not change immediately without schema compatibility tests. |
| P2 | `/health` exposes environment/auth booleans. | Low sensitivity; optionally reduce public metadata after operations tooling is established. |

## Privacy and data protection

Data handled includes email/UID, age, sex field, height, weight, BMI, laboratory values, derived flags, allergies, product history, optional photo and transient PDF text. These are personal and sensitive health data.

Positive controls:

- Explicit pre-upload consent dialog.
- API does not persist PDFs; temp files are deleted.
- Encrypted Hive local box; key is held in platform secure storage.
- UID-scoped Firestore/Storage paths with deny-all fallback.
- In-app export, health-data deletion and account deletion.
- Android backup and cleartext traffic disabled.

Release blockers and gaps:

- `PRIVACY.md` is explicitly a draft and lacks verified controller identity, contact, legal bases, detailed retention periods, international transfer/subprocessor explanation, backup deletion, complaint authority and effective date. It is not ready to publish.
- A public, active, non-geofenced, non-PDF privacy URL must replace the default repository link at build time and in Play Console.
- Play also requires an external web account-deletion request route; in-app deletion alone is insufficient.
- A KVKK/GDPR data-protection impact assessment and records of processing are needed before real health data is accepted.
- Firebase/Render region, retention, backups, support access and deletion propagation are not documented as verified facts.
- Firestore rules isolate users but do not validate document schemas or sizes. Add emulator-tested field/size rules or server-mediated writes if abuse/billing risk warrants it.

## Google Play policy risks

Google Play's Health Content and Services policy requires the Health apps declaration, a public and in-app privacy policy, and—unless regulated medical-device proof is supplied—a clear app-description disclaimer that the app is not a medical device and does not diagnose, treat, cure, or prevent a condition. See [Google Play Health Content and Services](https://support.google.com/googleplay/android-developer/answer/16679511?hl=en).

P0 Play tasks:

- Complete Health apps declaration accurately as nutrition/health support handling lab/allergy data.
- Publish and link the final privacy policy.
- Provide the external deletion-request URL.
- Put the exact non-medical-device disclaimer in store description and in-app surfaces.
- Complete Data Safety based on actual Firebase, API, logging and SDK behavior.
- Verify the 2026 target API rule in Play Console immediately before upload. As of this audit, Google's published requirement states new apps/updates must target API 35+ from 2025-08-31. [Target API requirements](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en)

The removed broad photo permission addressed a known policy risk: one-time/infrequent photo use should use a system picker rather than `READ_MEDIA_IMAGES`. [Photo/Video Permissions policy](https://support.google.com/googleplay/android-developer/answer/14115180?hl=en-CA)

## Mobile app findings

- Auth and Google Sign-In flows exist with provider/configuration error handling.
- Production App Check selects Play Integrity and now fails configuration if disabled for a prod flavor.
- API calls require bearer and App Check tokens, use HTTPS except loopback development, and have request/upload timeouts.
- Barcode lookup supports not-found/manual fallback; product data-quality warnings are displayed.
- PDF upload has explicit consent, loading/error behavior and limited-data warnings.
- Allergy entry and allergy-PDF signals are present.
- Profile data is cached locally and synced to UID-scoped Firestore.
- Export, health-data deletion and account deletion exist. Recent-login failure is explained.
- Medical disclaimer is now visible in report, profile, scan-result and Settings contexts.
- Privacy policy access is now present in Settings.
- Android permissions are reduced to `INTERNET` and `CAMERA`.

Remaining mobile issues:

- Firebase `google-services.json`, generated options, SHA-1/SHA-256 registration and real provider configuration are intentionally not verifiable from committed source.
- Camera denial/permanent denial behavior depends on scanner/image-picker plugins and needs physical-device QA plus accessibility review.
- Full screen-reader, large-font, contrast, switch-access and Turkish truncation testing has not been completed.
- Offline cloud reads use cache, but report analysis and product lookup/evaluation require network; store copy must not imply full offline analysis.
- Local deletion does not cryptographically erase historical cloud provider backups; privacy wording must describe actual retention.

## Firebase rules audit

`firestore.rules` grants authenticated users CRUD only under `environments/{environment}/users/{uid}` and descendants, with a deny-all fallback. `storage.rules` grants only owner access to a single profile image path, limits writes to `<5 MiB` and image MIME types, then denies all other paths. This is a sound isolation baseline.

Before release, run Emulator Suite tests for cross-user denial, unauthenticated denial, valid owner CRUD, invalid file type, oversized photo and recursive deletion. Enable Firebase App Check enforcement for Firestore, Storage and applicable services after monitoring legitimate traffic.

## Release and build problems

- Package/application ID: `com.biodietix.biodietix_mobile`. It is syntactically usable but must be confirmed as the permanent Play/Firebase ID before first upload; it cannot later be changed for the same listing.
- Version is `1.0.0+1`; version code must increase on every Play upload.
- Gradle uses Flutter's compile/target SDK. Local merged manifests from Flutter 3.44.4 show minSdk 24 and targetSdk 36; the final signed AAB metadata must still be confirmed in Play Console.
- Release builds intentionally fail without `mobile/android/key.properties`, preventing accidental debug signing.
- No keystore or `key.properties` is committed. Configure Play App Signing and securely back up the upload key.
- A production AAB cannot be completed here because release signing credentials are owner-controlled.

## Missing or incomplete tests

Added during this audit: biomarker boundary tests, unit/inequality PDF cases, PDF page/text limits, payload extra-field rejection, configurable large-PDF rejection, allergy substring/certainty, kidney/muscle separation, product explainability and disclaimer tests.

Still needed:

- Real de-identified multi-laboratory Turkish PDF corpus, including scanned/image-only files, corrupt/encrypted PDFs, unusual fonts/layouts and every supported unit.
- Firebase Emulator rule tests and full authenticated App Check integration tests.
- Open Food Facts v3 contract fixtures and timeout/cache/load tests.
- Flutter widget/integration tests for report consent/upload failure, camera denial, incomplete product display, deletion reauthentication and privacy-link failure.
- Physical-device Play Integrity tests from Internal Testing.
- Accessibility automation and manual assistive-technology tests.
- End-to-end deletion verification across local store, Firestore, Storage, Auth and the external deletion-request process.

## Prioritized remediation plan

### P0 — before any public/closed health-app release

1. Obtain medical/dietetic review and approve or remove every unvalidated rule/claim.
2. Replace the draft privacy notice with counsel-reviewed, publicly hosted KVKK/GDPR-compliant content; add an external deletion route.
3. Complete Play Health declaration, Data Safety, app access and exact store disclaimer.
4. Freeze package ID, configure Play App Signing/upload key, production Firebase app, Auth providers, SHA fingerprints and Play Integrity.
5. Verify deployed host/secrets/rules, run authenticated/App Check smoke tests, and confirm final AAB target SDK/version/signing.
6. Do not use real patient data until DPIA, retention, incident response and support-access controls are approved.

### P1 — required for a credible production launch

1. Replace the diet-quality heuristic and add structured lab units, fasting status and report reference ranges.
2. Validate PDF extraction on a representative de-identified Turkish corpus; add OCR only with a new privacy/security review.
3. Preserve allergy provenance and expand canonical allergens with allergist/local-label review.
4. Add shared Redis rate limiting/cache or enforce single-instance operation.
5. Add Firebase Emulator and end-to-end mobile integration tests.
6. Complete physical-device accessibility, camera, Google Sign-In, deletion and offline/error QA.
7. Establish monitoring with PHI-redacted errors, alerting, dependency/secret scanning and a rollback drill.

### P2 — post-launch hardening

1. Migrate Open Food Facts integration to API v3 with contract fixtures.
2. Add schema/size validation in Firestore rules and data-retention automation.
3. Localize backend reason codes server-side or maintain a versioned client translation contract.
4. Remove/rebuild stale generated recommendation artifacts and document reproducible dataset generation.
5. Conduct periodic scientific, policy, dependency and threat-model review.
