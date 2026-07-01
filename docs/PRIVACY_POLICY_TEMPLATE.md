# BioDietix Privacy Policy Template

> **Template only — not legal advice and not approved for publication.** Replace every bracketed placeholder with verified facts and obtain KVKK/GDPR counsel review before accepting real health data or linking this page from Google Play.

Effective date: `[DATE]`  
Version: `[VERSION]`  
Public URL: `[PUBLIC_HTTPS_URL]`

## 1. Controller/developer and contact

BioDietix is provided by `[LEGAL_ENTITY_OR_DEVELOPER_NAME]`, located at `[ADDRESS/JURISDICTION]`. For privacy questions or rights requests contact `[SUPPORT/PRIVACY_EMAIL]`. Identify the KVKK data controller, GDPR controller/representative, and data-protection contact where applicable: `[VERIFIED_DETAILS]`.

## 2. Scope and product position

Describe the Android app, API and public deletion page covered by this notice. State that BioDietix provides supportive nutrition information, is not a medical device, and does not diagnose, treat, cure or prevent a condition. Do not use this disclaimer to reduce statutory privacy rights.

## 3. Data actually handled

Complete a verified table for each category, purpose, lawful basis/consent, source, recipient/processor, location, retention and deletion behavior:

- Account and authentication: Firebase UID, email and provider metadata used by Firebase Authentication.
- Profile: `[AGE, SEX/GENDER FIELD, HEIGHT, WEIGHT, BMI, OPTIONAL PHOTO, OTHER ACTUAL FIELDS]`.
- Health/lab information: uploaded PDF content during processing, extracted lab values, derived range indicators and nutrition profile.
- Allergies: manual entries and possible sensitization signals extracted from reports; explain that these may be sensitive health data.
- Product activity: barcodes, manual product inputs, label/nutrition data, suitability results, saved product checks and notes.
- Device/app/network information collected by Firebase, Google Play services, the hosting provider or any diagnostics tools: `[SDK INVENTORY AND VERIFIED FACTS]`.
- Support and deletion correspondence: identity/contact details and request records.

## 4. How processing works

### Uploaded PDFs

Verify and explain that the selected PDF is transmitted over TLS to `[PRODUCTION_API_HOST/PROCESSOR]`, processed transiently, not intentionally retained by the BioDietix API, and removed from temporary storage after success or failure. State whether host/network/backups can contain transient copies or metadata and their retention. Explain that derived lab/profile values may be stored separately.

### Server and Firebase processing

Describe Firebase Authentication, Firestore profile/history sync, Firebase Storage profile photos, App Check, the backend host, regions, subprocessors, international transfers and access controls using confirmed production facts. Do not claim a region or retention period until verified.

### Open Food Facts

Explain that a barcode/product query is sent by the backend to Open Food Facts, that its volunteer-contributed data may be incomplete or outdated, what request metadata the service can receive, and whether BioDietix sends any account or health profile data to it. Insert verified behavior: `[OPEN_FOOD_FACTS_DATA_FLOW]`.

### Local storage

Describe encrypted Hive profile/cache data and protected local key storage, what remains on device, when it is cleared, and the limits of device/platform backups. Confirm Android backup behavior against the shipped manifest.

## 5. Purposes and legal bases

For each data category state a lawful basis appropriate to KVKK/GDPR and the intended population, including explicit-consent requirements for health/special-category data where counsel determines they apply. Include withdrawal consequences and avoid bundling optional processing. `[COUNSEL-APPROVED TABLE]`.

## 6. Collection, disclosure and “sharing”

List every processor/recipient and purpose, including Google/Firebase, `[HOSTING_PROVIDER]`, Open Food Facts and support vendors. Distinguish processor/service-provider handling from independent third-party use based on contracts and Google Play definitions. State whether data is sold or used for advertising only after verification.

## 7. Retention

Provide concrete periods or determination criteria for Auth, Firestore, Storage, local data, API temporary files, operational/security logs, support requests and backups: `[RETENTION_SCHEDULE]`. Explain deletion propagation and backup expiry; never promise immediate cryptographic erasure if infrastructure cannot deliver it.

## 8. Security

Describe verified controls such as TLS, access control, App Check, encrypted local storage, restricted secrets and redacted logs. Acknowledge that no system is completely secure and provide `[INCIDENT_CONTACT/PROCESS]`.

## 9. Deletion and account controls

Explain the in-app deletion path and public request URL `[ACCOUNT_DELETION_URL]`, identity verification, data in scope, any legally justified retention, processing time, notification and appeal/support route. Link to the dedicated deletion page.

## 10. KVKK/GDPR rights

With counsel, describe applicable access, confirmation/information, correction, erasure, restriction, objection, portability, consent withdrawal and complaint rights; provide the request channel, identity-verification process, response deadlines, Turkish Personal Data Protection Authority and any applicable EU/EEA supervisory authority. `[COUNSEL-APPROVED RIGHTS TEXT]`.

## 11. Children and intended users

BioDietix is currently designed for adults. State the actual age controls, whether children’s data is intentionally collected, and the response process if such data is discovered: `[VERIFIED POLICY]`.

## 12. Changes

Describe notice/change communication and version history. Material changes affecting consent require legal review before deployment.

## Publication checklist

- [ ] Every placeholder replaced with a verified fact.
- [ ] Data inventory reconciled with SDK/network inspection and Play Data Safety.
- [ ] KVKK/GDPR legal review recorded with version/date.
- [ ] Turkish and English versions legally consistent.
- [ ] Public HTTPS HTML URL works without login, geoblocking or PDF download.
- [ ] Same URL configured in the candidate AAB and Play Console.

