# BioDietix Flutter Mobile

Installable Android app for BioDietix.

## Features

- Firebase Auth email/password login.
- Phone storage for personal profile, allergies, theme/language preference, and latest lab memory.
- English and Turkish interface from the Settings tab.
- System, light, and dark theme options from the Settings tab.
- Blood test PDF upload through the BioDietix FastAPI backend.
- Allergy test PDF upload through the same backend.
- Camera QR/barcode scanning.
- Product lookup and suitability decision based on latest blood profile, BMI, allergies, and nutrition facts.

## Required production services

This APK is not self-contained. A physical phone cannot reach a developer laptop
address such as `127.0.0.1`, emulator-only addresses, or private LAN addresses
when another user installs the APK.

Before building an APK for other users, provide:

- A Firebase project with Email/Password Authentication enabled.
- A deployed BioDietix FastAPI backend with a public HTTPS URL.

The app intentionally has no preview/offline-login mode. If Firebase is not
configured, users see a setup-required screen instead of bypassing login.

## Backend

Run the Python API for development or deploy the same FastAPI app to a public
HTTPS host:

```bash
source .venv/bin/activate
uvicorn api:app --host 0.0.0.0 --port 8000
```

Production APK builds must use an HTTPS URL:

```json
{
  "BIODIETIX_API_URL": "https://biodietix-ml.onrender.com"
}
```

## Firebase

Create a Firebase project and enable Email/Password authentication.

Place the Android Firebase file at:

```text
android/app/google-services.json
```

The Android package name must be:

```text
com.biodietix.biodietix_mobile
```

Copy the API define template:

```bash
cp firebase_defines.example.json firebase_defines.json
```

Fill `firebase_defines.json` with the deployed BioDietix API URL:

```json
{
  "BIODIETIX_API_URL": "https://biodietix-ml.onrender.com"
}
```

Firebase is read from `android/app/google-services.json` for Android builds.

## Run

```bash
flutter pub get
flutter run --dart-define-from-file=firebase_defines.json
```

## Build APK

Debug APK:

```bash
flutter build apk --debug --dart-define-from-file=firebase_defines.json
```

Release APK:

```bash
flutter build apk --release --dart-define-from-file=firebase_defines.json
```

Output:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## Medical Note

Product decisions are educational guidance only. They are not medical diagnosis,
treatment, or a replacement for a healthcare professional.
