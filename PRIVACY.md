# Privacy and Data Handling — Draft

This technical draft is not a substitute for a KVKK/GDPR review or a published
privacy notice approved by counsel.

## Data processed

- Account identifier and email through Firebase Auth.
- Age, sex field, height, weight and BMI.
- Laboratory values, derived risk flags and nutrition recommendations.
- Allergies, product-check history and optional profile photo.
- PDF text is processed transiently by the API; the API returns at most a
  4,000-character session preview.

## Storage

- Mobile cache: encrypted Hive, keyed by Firebase UID.
- Cloud profile: UID-scoped Firestore documents.
- Profile photo: UID-scoped Firebase Storage object.
- API: temporary PDF deleted after processing; no application database.

## Required product controls

- Obtain explicit informed consent before uploading a health report.
- Publish controller identity, processing purposes, legal basis, retention
  periods, subprocessors and data-subject contact channel.
- Provide export, full deletion and account deletion flows.
- Define backup/log retention and deletion propagation deadlines.
- Do not collect reports from minors; API currently accepts ages 18–120 only.
- Complete a data-protection impact assessment before public production use.

The “delete health data” flow removes local profile/lab data, cloud profile/lab
fields and the profile photo. “Delete account” additionally deletes known
history subcollections and the Firebase account. Firebase may require a recent
login; the app instructs the user to re-authenticate and retry in that case.
