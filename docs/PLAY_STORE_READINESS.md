# Google Play Release Readiness

Last reviewed: 2026-07-01. Recheck Play policies in Console immediately before submission; requirements change.

## Release gate

Do not upload to a public, closed, or open track until every P0 item in [PRODUCTION_READINESS_AUDIT.md](PRODUCTION_READINESS_AUDIT.md) is closed. Internal testing is appropriate only with synthetic/de-identified data and correct disclosures.

## App Bundle command

From `mobile/`:

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release --flavor prod \
  --build-name=1.0.0 \
  --build-number=1 \
  --dart-define=FLAVOR=prod \
  --dart-define=BIODIETIX_API_URL=https://YOUR_PRODUCTION_API_HOST \
  --dart-define=BIODIETIX_PRIVACY_POLICY_URL=https://YOUR_PUBLIC_PRIVACY_POLICY \
  --dart-define=BIODIETIX_ACCOUNT_DELETION_URL=https://YOUR_PUBLIC_DELETION_PAGE \
  --dart-define=BIODIETIX_SUPPORT_EMAIL=YOUR_MONITORED_SUPPORT_EMAIL \
  --dart-define=BIODIETIX_APP_CHECK_ENABLED=true
```

Expected output:

```text
mobile/build/app/outputs/bundle/prodRelease/app-prod-release.aab
```

Never set `BIODIETIX_APP_CHECK_ENABLED=false` for a production flavor; the app now refuses that configuration. Production startup also rejects a missing/non-HTTPS privacy or deletion URL and a missing/invalid support email. Placeholder values are acceptable only for local build validation and must not be uploaded to Play.

## Identity, version and SDK

- [ ] Confirm permanent package/application ID: `com.biodietix.biodietix_mobile`.
- [ ] Confirm the same ID in Play Console, Firebase Android app and `google-services.json`.
- [ ] Confirm app name and developer identity are consistent with the privacy/deletion pages.
- [ ] Increment `versionCode` (`--build-number`) for every upload; use intentional semantic `versionName`.
- [x] Local merged manifests currently show `minSdk 24` and `targetSdk 36` under Flutter 3.44.4 / Android SDK 36.1.
- [ ] Inspect the final signed AAB in Play Console/App Bundle Explorer and reconfirm target SDK API 35 or newer. Google currently states API 35+ for new apps and updates from 2025-08-31; recheck for a newer 2026 deadline. [Official target API requirements](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en)
- [ ] Record actual `compileSdk`, `targetSdk`, `minSdk`, Flutter and AGP versions from the final release artifact in release evidence.

## Signing and upload key

- [ ] Enroll in Play App Signing.
- [ ] Generate a dedicated upload keystore; never use debug signing.
- [ ] Store the keystore and passwords in a password manager/secret backup with owner recovery instructions.
- [ ] Create uncommitted `mobile/android/key.properties` with `storeFile`, `storePassword`, `keyAlias`, `keyPassword`.
- [ ] Register release SHA-1 and SHA-256 in Firebase, then download the updated `google-services.json`.
- [ ] Verify Google Sign-In on an Internal Testing build installed from Play, not only via local APK.
- [ ] Retain AAB hash, mapping files, native symbols and release notes.

The Gradle build intentionally fails release tasks when `key.properties` is absent.

Example upload-key generation (choose a secure path/alias and enter passwords interactively; do not place them in shell history):

```bash
keytool -genkeypair -v \
  -keystore /secure/path/biodietix-upload.jks \
  -alias biodietix-upload \
  -keyalg RSA -keysize 4096 -validity 10000
```

Verify the candidate bundle and inspect its signing certificate before upload:

```bash
jarsigner -verify -verbose -certs build/app/outputs/bundle/prodRelease/app-prod-release.aab
keytool -printcert -jarfile build/app/outputs/bundle/prodRelease/app-prod-release.aab
sha256sum build/app/outputs/bundle/prodRelease/app-prod-release.aab
```

The local AAB is signed with the upload key. Google signs delivered APKs with the Play app-signing key after Play App Signing enrollment. Record and register both certificate identities where required; see [Android app signing](https://developer.android.com/studio/publish/app-signing).

## Health apps declaration

All Play apps must complete the Health apps declaration, including testing tracks. Declare the actual nutrition/health functionality: lab-report processing, BMI/body measurements, allergy data and personalized food-product guidance. Do not describe BioDietix as diagnosis, treatment, clinical decision support or a certified medical device. [Official Health apps declaration guidance](https://support.google.com/googleplay/android-developer/answer/14738291?hl=en)

Store description disclaimer (use this exact meaning in Turkish and English):

> BioDietix is not a medical device and does not diagnose, treat, cure, or prevent any medical condition. It provides supportive nutrition information based on user-entered and available product data. Consult a qualified healthcare professional about abnormal results, allergies, symptoms, or major diet changes.

Google requires this type of disclaimer for non-regulated health/medical apps and prohibits misleading or harmful functionality. [Health Content and Services policy](https://support.google.com/googleplay/android-developer/answer/16679511?hl=en)

## Privacy policy

- [ ] Replace `PRIVACY.md` draft with counsel-reviewed content.
- [ ] Host it at an active, public, non-geofenced HTTPS URL; it must not be a PDF and must be viewable without login.
- [ ] Put the same URL in Play Console and `BIODIETIX_PRIVACY_POLICY_URL`; verify the Settings button.
- [ ] Configure `BIODIETIX_SUPPORT_EMAIL` to a monitored address shown by the app.
- [ ] State controller/developer identity and contact, data categories, purposes, legal bases/consent, retention, deletion, international transfers, Firebase/Render/Open Food Facts roles, security, children's policy, user rights, complaint authority and effective/change dates.
- [ ] Explain that PDFs are processed transiently, while derived profile/lab values sync to Firebase unless deleted.
- [ ] Do not say data “stays on this phone” without also explaining Firestore sync.
- [ ] Complete a KVKK/GDPR review and DPIA before processing real reports.

## Account deletion

- [ ] Verify in-app account deletion removes known Firestore subcollections, user document, Storage photo, local encrypted data and Firebase Auth account.
- [ ] Test the recent-login/reauthentication path.
- [ ] Publish an external web route where an uninstalled/signed-out user can request account and associated-data deletion.
- [ ] Put that URL in Play Console Data Safety and `BIODIETIX_ACCOUNT_DELETION_URL`; identify any retention exceptions and completion timeline.

Google requires both an in-app path and an external web deletion-request resource for apps that create accounts. [Official account deletion requirements](https://support.google.com/googleplay/android-developer/answer/13327111?hl=en-EN)

## Data Safety guidance

Answer from observed production behavior, not this checklist alone. Likely declarations requiring owner verification include:

| Data type | Why collected/processed | Handling to verify |
| --- | --- | --- |
| Email / user ID | Account, authentication, per-user sync | Firebase Auth; encryption in transit; deletion route |
| Health information | Lab values, BMI/body measurements, derived flags, allergies | API transient PDF processing; local encrypted cache; Firestore profile sync |
| Photos | Optional profile photo | System picker/camera; Firebase Storage; user deletion |
| App activity | Saved product checks/notes | Local cache and Firestore |
| Diagnostics | Backend operational logs and any Firebase/SDK diagnostics | Confirm exact production SDK and logging collection; do not guess |

- [ ] Declare collection versus sharing exactly as Play defines those terms.
- [ ] Confirm whether Firebase data is considered service-provider processing under Play definitions.
- [ ] Confirm encryption in transit and whether users can request deletion.
- [ ] Ensure Data Safety, privacy policy and actual SDK traffic are consistent.
- [ ] Repeat the audit whenever SDKs or telemetry change. [Official Data Safety guidance](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en)

## Permissions

Final main manifest permissions:

| Permission | Purpose | Release action |
| --- | --- | --- |
| `INTERNET` | Firebase Auth/Firestore/Storage, BioDietix API and product lookup | Required; disclose network/cloud processing. |
| `CAMERA` | User-initiated barcode scan and optional profile photo capture | Required for current features; test denial and settings recovery; explain at point of use. |

The locally generated prod-release merged manifest also contains these
dependency-added normal/signature permissions:

| Permission | Source/purpose to verify |
| --- | --- |
| `ACCESS_NETWORK_STATE` | Connectivity/Firebase network-state handling. |
| `USE_BIOMETRIC`, `USE_FINGERPRINT` | `flutter_secure_storage` platform support for protected key storage; verify whether both can be removed with the chosen Android storage options. |
| `com.google.android.providers.gsf.permission.READ_GSERVICES` | Google/Firebase services integration. |
| `com.biodietix.biodietix_mobile.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` | AndroidX protection for non-exported dynamic receivers. |

`DUMP`, `BIND_JOB_SERVICE`, and Google Sign-In revocation permissions appear as
component requirements, not app-requested `<uses-permission>` entries.

`READ_MEDIA_IMAGES` was removed. Gallery selection is occasional and must continue using the system picker. Apps with infrequent photo access should not request broad media permission. [Photo/Video Permissions policy](https://support.google.com/googleplay/android-developer/answer/14115180?hl=en-CA)

Before every upload, re-inspect the **merged release manifest** for permission
changes and reconcile them with Data Safety and policy declarations.

## Firebase App Check / Play Integrity

- [ ] Register the production Android app/package and release SHA-256 in Firebase.
- [ ] Link the correct Play Console/Cloud project where required.
- [ ] Enable Play Integrity provider in Firebase App Check.
- [ ] Upload to Internal Testing and install from Play so Play Integrity can attest the real artifact.
- [ ] Monitor App Check metrics before enforcing Firebase products.
- [ ] Enable enforcement for Firestore, Storage and other used Firebase products once legitimate traffic is confirmed.
- [ ] Keep backend `BIODIETIX_APP_CHECK_REQUIRED=true`; verify missing/invalid tokens receive rejection.
- [ ] Never register production debug tokens or ship debug provider in the prod flavor.
- [ ] Verify “Meets basic device integrity” settings/device coverage as appropriate. [Firebase App Check Flutter guide](https://firebase.google.com/docs/app-check/flutter/default-providers)

## App access and reviewer instructions

Provide Play reviewers with:

1. A dedicated non-personal test account (email/password), pre-verified and not protected by unavailable 2FA.
2. Exact sign-in steps and Google Sign-In alternative status.
3. A synthetic PDF containing clearly fake adult lab data; never provide a real patient report.
4. Steps: sign in → Reports → consent → upload synthetic PDF → Profile → Scan/manual product → evaluate → Settings → privacy/export/delete.
5. A sample barcode known to exist plus manual fallback data.
6. Any region/network requirements and a support contact.

Keep the test account active through review and verify it against the production backend/App Check configuration immediately before submission.

Internal Testing sequence:

1. Upload the exact signed candidate AAB and retain its SHA-256.
2. Complete App content forms required for the testing track and add named testers/test list.
3. Install only through the Play opt-in link, then execute [INTERNAL_TESTING_QA_CHECKLIST.md](INTERNAL_TESTING_QA_CHECKLIST.md).
4. Review pre-launch report, Android vitals and App Check metrics; resolve defects and upload a higher version code for every replacement.
5. Keep reviewer credentials active and provide synthetic PDF/product data only—never a real patient report.

## Content rating and target audience

- [ ] Complete IARC questionnaire accurately; the app contains health/nutrition information but no gambling/violence/sexual content.
- [ ] Set target audience to adults. API accepts only age 18–120 and the product has not been validated for children, pregnancy or pediatric nutrition.
- [ ] Do not market weight loss, disease management or emergency use.
- [ ] Declare any regulated/medical functionality truthfully; current intended position is non-medical-device wellness support.

## Store listing and screenshots

- [ ] Short/full descriptions match actual online/offline behavior and avoid “safe,” “diagnoses,” “prevents,” “treats,” “controls,” “clinically proven,” “AI doctor,” or certification claims.
- [ ] Say “appears suitable based on available label/profile data,” never “safe to eat.”
- [ ] Mention Open Food Facts data can be missing/outdated and users must check the physical label, especially for allergies.
- [ ] Include the full health disclaimer in the long description.
- [ ] Use current screenshots from a production-like build with synthetic data only; no email, UID, lab report, barcode history or other personal data.
- [ ] Provide Turkish and English listing text consistent with in-app translations.
- [ ] Verify icon, feature graphic, phone screenshots and accessibility descriptions meet current Play dimensions.

## Crash, logging and operational checklist

- [ ] No PDF text, lab values, allergies, tokens, email or profile payloads in logs/crash reports.
- [ ] Confirm whether Crashlytics or any diagnostics SDK is actually present; update privacy/Data Safety before enabling it.
- [ ] Configure PHI-redacted backend alerts for 5xx, latency, auth/App Check failures, rate limiting and PDF parser failures.
- [ ] Run dependency and secret scanning; resolve high/critical findings.
- [ ] Verify API TLS, trusted host, CORS, docs-disabled, one-worker/shared-rate-limit configuration and secret-manager credentials.
- [ ] Deploy and emulator-test Firestore/Storage rules.
- [ ] Run backup/restore and rollback drills; document incident response and breach notification ownership.
- [ ] Establish support, vulnerability and medical-safety escalation channels.

## Final manual acceptance

- [ ] `python -m pytest`
- [ ] `ruff check .`
- [ ] `ruff format --check .`
- [ ] `pip check` and `pip-audit` (when installed).
- [ ] `flutter analyze`
- [ ] `flutter test`
- [ ] Debug dev APK build.
- [ ] Signed prod AAB build and Play Console pre-launch report.
- [ ] Physical-device Android 13–current tests: auth, Google, Play Integrity, camera permission denial, PDF picker/upload, offline/error, privacy link, export, health deletion and account deletion.
- [ ] Screen reader, 200% font, contrast and Turkish/English truncation review.
- [ ] Qualified medical/dietetic approval and legal/privacy approval recorded with version/date.

## Do not upload until

Do not upload even to a Play testing track with placeholder privacy/deletion/support values, an unconfirmed package ID, debug signing, unconfigured reviewer access, or declarations that do not match the artifact. Do not promote beyond Internal Testing until medical/dietetic and legal review, live public pages, production Firebase/Play Integrity/backend verification, rule deployment, Data Safety/Health Apps review and the physical-device QA checklist are complete for the exact AAB.
