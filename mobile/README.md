# BioDietix Flutter Mobile

Installable Android app for BioDietix.

## Features

- Firebase Auth email/password login.
- Firebase Auth Google sign-in.
- Phone storage for personal profile, allergies, theme/language preference, and latest lab memory.
- English and Turkish interface from the Settings tab.
- System, light, and dark theme options from the Settings tab.
- Blood test PDF upload through the BioDietix FastAPI backend.
- Allergy test PDF upload through the same backend.
- Camera QR/barcode scanning.
- Product lookup and suitability decision based on latest blood profile, BMI, allergies, and nutrition facts.

## Required production services

The production app connects to the hosted BioDietix API automatically. A user
who installs the app does not need to configure an API address.

Before building an APK for other users, provide:

- A Firebase project with Email/Password and Google Authentication enabled.
- A deployed BioDietix FastAPI backend with a public HTTPS URL. The default
  production endpoint is already embedded in the app.

The app intentionally has no preview/offline-login mode. If Firebase is not
configured, users see a setup-required screen instead of bypassing login.

## Backend

Run the Python API for development or deploy the same FastAPI app to a public
HTTPS host:

```bash
source .venv/bin/activate
uvicorn api:app --host 0.0.0.0 --port 8000
```

The app has this production HTTPS URL built in by default:

```json
{
  "BIODIETIX_API_URL": "https://biodietix-ml.onrender.com"
}
```

## Firebase

Create a Firebase project and enable these sign-in providers:

- Email/Password
- Google

For Google sign-in on Android, add the app signing certificate fingerprints
under Firebase Project settings > Your apps > Android app:

- SHA-1
- SHA-256

After changing providers or certificate fingerprints, download a fresh
`google-services.json`.

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

`firebase_defines.json` can override the API URL for development builds:

```json
{
  "BIODIETIX_API_URL": "https://biodietix-ml.onrender.com"
}
```

Firebase is read from `android/app/google-services.json` for Android builds.

## Run

```bash
flutter pub get
flutter run --flavor dev --dart-define=FLAVOR=dev
```

## Build APK

Debug APK:

```bash
flutter build apk --debug --flavor dev --dart-define=FLAVOR=dev
```

Release APK:

```bash
flutter build apk --release --flavor prod --dart-define=FLAVOR=prod
```

Play Store app bundle:

```bash
flutter build appbundle --release --flavor prod --dart-define=FLAVOR=prod
```

Output:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## Medical Note

Product decisions are educational guidance only. They are not medical diagnosis,
treatment, or a replacement for a healthcare professional.
