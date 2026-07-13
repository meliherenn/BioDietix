# BioDietix 1.0.1 Closed Testing Delivery

- Delivery date: 2026-07-13
- Track: existing Google Play closed testing track
- Source commit: `b4baa226a4ef1c16095422d53f18e7f42efdebc4`
- Legal-site commit: `54f6e1861285271a862b53aa64becce59214caf4`

## Upload artifact

- Package: `com.biodietix.biodietix_mobile`
- Version name: `1.0.1`
- Version code: `20260713`
- Minimum SDK: 24
- Target SDK: 36
- AAB: `mobile/build/app/outputs/bundle/prodRelease/app-prod-release.aab`
- Size: `66,260,783` bytes
- SHA-256: `073408645c47575feb0c0bbf7a5548c3c36ed0073314c1195aafcef2fcdff0f9`
- Signing verification: `jarsigner` exit 0

Upload certificate:

- SHA-1: `CB:5C:83:DE:17:14:27:AF:87:AE:2B:84:27:16:5A:C3:BF:B4:5A:F6`
- SHA-256: `53:AD:77:CC:BA:8E:E8:CC:82:9B:8B:6D:FE:E3:CB:BB:8C:ED:1A:EB:BA:3E:46:35:43:27:F3:A4:6B:0E:C0:95`
- Algorithm: SHA384withRSA, 2048-bit RSA

The upload certificate is intentionally self-signed. Google Play verifies the
upload key, then signs delivered APKs with the Play App Signing key.

## Crash deobfuscation evidence

- R8 mapping: `mobile/build/app/outputs/mapping/prodRelease/mapping.txt`
- R8 mapping SHA-256: `afa4bdbf44d9d04863781d768b7448abf1a14468e6411b317fab92a3a39c3d03`
- Flutter ARM symbols SHA-256: `4fe7f5e16f9619c332a422c0b60d0d5210d526abf18084a147157e1890b21d43`
- Flutter ARM64 symbols SHA-256: `a8c852b3d2e69a77e3b1405bcdecfeb00dce193d01470eba739e6c69aab9b01b`
- Flutter x86_64 symbols SHA-256: `3c2f9632b0c809b72fbb2037e87c48a4c2b0af2847da405a6663d436ba74a6b6`

Keep the AAB, mapping and symbol files together. The mapping is also embedded
in the AAB metadata, but the local copy is the recovery record for this exact
artifact.

## Production configuration verified

- API: `https://biodietix-ml.onrender.com`
- API health: HTTP 200, production, Auth required, App Check required,
  `profile_memory_schema_version=2`
- Privacy: `https://meliherenn.github.io/biodietix-legal/privacy-policy.html`
- Account deletion: `https://meliherenn.github.io/biodietix-legal/delete-account.html`
- Both legal URLs: HTTP 200, effective date `2026-07-13`, no draft/placeholder notice
- Support: `meliheren2834@gmail.com`
- Production App Check provider: Play Integrity
- Cleartext traffic: disabled
- Android backup and device transfer: disabled for application data
- Broad storage/media permissions: absent
- Camera hardware: optional, so devices without a camera are not filtered out

## Verification result

- Python: 64 tests passed
- Flutter: 45 tests passed
- `flutter analyze`: no issues
- `dart format`: no changes required
- Ruff check/format: passed
- `pip check`: no broken requirements
- Android `lintProdRelease`: 0 errors, 8 non-blocking maintenance/icon warnings
- Signed prod AAB: built successfully with R8 shrinking, Flutter obfuscation and split debug symbols

The remaining lint warnings concern newer available tooling, the default
Flutter `drawable-v21` folder and launcher-icon/themed-icon recommendations;
none changes package compatibility, signing, permissions or Play upload
validity.

## Closed testing update steps

1. Open Play Console → **Testing → Closed testing** and create a new release in
   the existing track.
2. Upload `app-prod-release.aab` from the path above.
3. Confirm Play shows package `com.biodietix.biodietix_mobile`, version
   `1.0.1`, version code `20260713`, and no signing mismatch.
4. Paste the matching release notes from:
   - Turkish: `mobile/play-store/release-notes-tr.txt`
   - English: `mobile/play-store/release-notes-en.txt`
5. Review and save the release. If Play reports that version code `20260713`
   was already used, rebuild with a strictly larger build number; never reuse a
   Play version code.
6. Install the update from the Play opt-in link. Do not validate Play Integrity
   with a locally sideloaded prod artifact.
7. On the Play-installed update, verify sign-in, one blood PDF, one allergy PDF,
   EN→TR→EN summary switching, privacy/deletion links and account deletion with
   synthetic data.
8. Review App Check metrics and the Play pre-launch report before promoting the
   release beyond closed testing.

Optional device log filter during the Play-installed smoke test:

```bash
adb logcat -c
adb logcat -v time | rg --line-buffered \
  'BioDietix|Firebase|AppCheck|PlayIntegrity|AndroidRuntime|FATAL EXCEPTION'
```

Release builds intentionally omit verbose debug diagnostics. Never capture or
share tokens, PDF content, health values, email addresses or other personal
data in release evidence.
