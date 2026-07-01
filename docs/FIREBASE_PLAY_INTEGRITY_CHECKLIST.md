# Firebase, Google Sign-In and Play Integrity Checklist

This is a manual production checklist. Never paste private keys, service-account JSON, keystore passwords or token values into release evidence.

## 1. Freeze identity and obtain fingerprints

- [ ] Confirm permanent Android package ID `com.biodietix.biodietix_mobile` in Gradle, Firebase and Play Console.
- [ ] Inspect the local upload certificate:

  ```bash
  keytool -list -v -keystore /secure/path/biodietix-upload.jks -alias biodietix-upload
  ```

- [ ] After enrolling in Play App Signing, record both **upload key certificate** and **app signing key certificate** SHA-1/SHA-256 from **Play Console → Test and release → Setup → App signing/App integrity**. Play-installed artifacts use the Play app-signing certificate; local release builds use the upload certificate.
- [ ] Store fingerprints, key owner and recovery location in the private release record—not the keystore/password.

## 2. Firebase Android app and Google Sign-In

- [ ] In Firebase Project settings, select the Android app with the exact package ID.
- [ ] Add all required release SHA-1 and SHA-256 fingerprints, especially the Play app-signing certificate; keep debug fingerprints separate.
- [ ] Download a regenerated `google-services.json` if Firebase indicates configuration changed. Confirm its project/package identity, review the diff, and never substitute an Admin SDK credential.
- [ ] Enable **Authentication → Sign-in method → Google** and select a verified support email.
- [ ] Confirm OAuth consent screen/project status and required tester/publication settings in Google Cloud.
- [ ] Test email/password and Google Sign-In from an Internal Testing install. A local APK test is insufficient for the Play signing identity.

## 3. Link Play Integrity and register App Check

- [ ] In Play Console **App integrity → Play Integrity API**, link the Google Cloud project belonging to the same Firebase project. The operator needs the required project/Play permissions.
- [ ] In Firebase **App Check → Apps**, register the production Android app with the **Play Integrity** provider and supply the Play app-signing SHA-256.
- [ ] Review provider advanced settings for the actual distribution model. Do not tighten recognition/licensing/device-integrity verdicts without device coverage tests.
- [ ] Confirm prod flavor initializes Play Integrity and dev/debug uses only an approved debug workflow. Never ship or publish a debug token.
- [ ] Install the signed candidate through Play Internal Testing and verify valid App Check requests for Firestore, Storage, Authentication where supported, and the BioDietix backend.
- [ ] Confirm backend rejects missing/invalid App Check tokens in production and accepts a valid Play-issued token.
- [ ] Monitor App Check metrics for legitimate/invalid traffic and device coverage. Enable enforcement per used Firebase product only after clean internal-test metrics and a rollback plan.

Firebase currently instructs developers to link Play Integrity to the same project, register the app with its SHA-256, monitor metrics, and enable enforcement after assessing legitimate traffic: [Firebase App Check Play Integrity setup](https://firebase.google.com/docs/app-check/android/play-integrity-provider).

## 4. Deploy and test Firebase rules

- [ ] Select the intended project explicitly and review it before deployment:

  ```bash
  firebase use --add
  firebase deploy --only firestore:rules,storage
  ```

- [ ] Record project ID, command output, deployed rule version/time and approver.
- [ ] Run Emulator Suite tests for unauthenticated/cross-user denial, owner CRUD, recursive data deletion, invalid MIME and oversized images.
- [ ] Inspect production rules after deployment; never assume committed rules are active.

## 5. Backend host and secrets

- [ ] Configure production hostname, explicit trusted hosts/CORS and HTTPS API URL.
- [ ] Store Firebase Admin credentials and all secrets only in the hosting provider’s secret mechanism. Prefer workload/managed credentials where supported.
- [ ] Set production Auth/App Check requirements, docs disabled, PDF limits, rate limits, Open Food Facts contact User-Agent and PHI-redacted logging values.
- [ ] Verify no Firebase Admin service-account JSON is tracked:

  ```bash
  git ls-files | grep -Ei '(service.?account|adminsdk|\.jks$|\.keystore$|key\.properties$|\.env$)'
  git log --all --name-only --pretty=format: | grep -Ei '(service.?account|adminsdk|\.jks$|\.keystore$|key\.properties$|\.env$)'
  ```

- [ ] If historical exposure is suspected, rotate/revoke credentials; deleting a file from the current tree is not sufficient.
- [ ] Run production smoke tests for valid auth/App Check, invalid/missing tokens, host/CORS rejection, upload limits, product lookup timeouts and log redaction.

## Required evidence

Retain redacted screenshots/exports for fingerprints, Auth provider, linked Cloud project, App Check registration/metrics/enforcement, rule deployment and host secret names; plus candidate version/commit, device test results and negative-request logs without personal health data.

