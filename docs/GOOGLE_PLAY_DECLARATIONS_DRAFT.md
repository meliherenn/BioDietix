# Google Play Declarations Draft

> **Draft for developer review — not submitted, not a Play/legal approval.** Reconcile every answer with the exact production AAB, SDK traffic, contracts, retention and console wording before submission.

## Health Apps declaration

Likely applicable feature: **Nutrition and Weight Management**. BioDietix accepts body measurements, laboratory-derived indicators and allergies to provide supportive food/product information. It must not be declared or marketed as diagnosis, treatment, clinical decision support or a regulated/certified medical device.

In the declaration and store listing, accurately state:

- Users can enter/upload sensitive health and allergy information.
- Outputs are conservative indicators based on user input and available product-label data.
- BioDietix is not a medical device and does not diagnose, treat, cure or prevent a medical condition.
- Users should consult a qualified healthcare professional about abnormal results, allergies, symptoms or major diet changes.

All apps in Play testing/production tracks must complete the form, and health functionality must be declared accurately. Review the current [Health Apps declaration instructions](https://support.google.com/googleplay/android-developer/answer/14738291?hl=en) at submission time.

## Data Safety working inventory

| Play data category likely applicable | Current code path/purpose | Collection/storage position to verify | Sharing decision |
| --- | --- | --- | --- |
| Email address and User IDs | Firebase Authentication and UID-scoped data | Collected by Firebase/Auth for account operation; stored until deletion/retention expiry. | Determine Firebase service-provider treatment under current Play definitions/contracts. |
| Health information | Lab values, BMI/body measurements, allergies, profile indicators | PDF content is intended to be transient at the API; derived values/profile are stored locally and in Firestore. Verify logs, host temp storage and backups. | Do not claim “not shared” until processors/recipients are classified. |
| Photos | Optional profile photo | User-selected/captured image stored locally during upload and in Firebase Storage. Uploaded lab PDF is a file/document, not a photo permission flow. | Verify Firebase/host treatment. |
| App activity / other user-generated content | Saved product checks, notes, barcode/manual product input | Local cache and Firestore paths; product lookup sent through backend. | Verify processor classification and whether Open Food Facts receives only barcode/request metadata. |
| Files and docs | User-selected lab PDF | Sent over TLS for transient server processing; not intentionally persisted by application code. | Verify hosting infrastructure, request logging and retention before answering. |
| Diagnostics / device or other identifiers | Firebase, Play Integrity/App Check, Google Play services, host/network logs | Exact SDK and production telemetry behavior requires network/console inspection. No Crashlytics dependency is currently intended. | Inventory actual SDK disclosures and contracts. |

### Collection, encryption and ephemerality

- **Collected versus processed ephemerally:** Play’s definition must be applied per category. The PDF file may qualify as ephemeral only if it is used in memory/temporary processing and is not retained beyond the real-time request; derived health values synced to Firestore are collected, not ephemeral.
- **Encrypted in transit:** app/backend/Firebase production endpoints must use HTTPS/TLS. Confirm with the deployed candidate; do not infer encryption at rest or end-to-end encryption from TLS.
- **Deletion available:** in-app deletion exists and the app supports a configurable external request URL. Mark deletion available only after the public route and end-to-end operations are verified.
- **Optional versus required:** account/authentication is required for current app use; PDF and profile photo are user-initiated/optional. Verify whether manual health/profile inputs are required for specific features.
- **Purpose:** select only actual purposes such as app functionality, account management, security/fraud prevention and developer communications. Do not select analytics/advertising/personalization unless actual production behavior meets Play’s definitions.

## Permissions and user-visible access

| Access | Purpose and declaration note |
| --- | --- |
| `CAMERA` | User-initiated barcode scanning and optional profile-photo capture. Test denial and explain at point of use. Camera frames are not intended for analytics. |
| File picker | User explicitly selects a lab PDF; no broad storage/media permission should be claimed. |
| `INTERNET` and dependency-added network state | Firebase, backend API, App Check and product lookup. Reinspect the merged release manifest. |

## Firebase SDK checks

- Review Firebase Authentication, Cloud Firestore, Cloud Storage and App Check data disclosures for the exact dependency versions.
- Confirm whether Google Sign-In/Play services collect device identifiers, diagnostics or interaction data independently.
- Confirm all automatic measurement/analytics/crash SDKs in the final dependency graph. Do not declare Firebase Analytics or Crashlytics unless actually shipped.
- Re-run the inventory after dependency or console-setting changes.

## Manual Play Console review

- [ ] Inspect final AAB dependency/permission reports and live network traffic.
- [ ] Confirm public privacy and external deletion URLs are live and identical to the AAB defines.
- [ ] Complete Health Apps declaration and Data Safety collection/sharing/security/deletion questions.
- [ ] Reconcile answers with privacy policy, retention schedule, processor contracts and deletion runbook.
- [ ] Confirm target audience is adults and complete content rating/app access truthfully.
- [ ] Save reviewer, date, release version and screenshots/export of submitted answers.
- [ ] Repeat review for every SDK, data-flow or retention change.

Use the current [Google Play Data Safety guidance](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en) rather than treating this draft as authoritative.

