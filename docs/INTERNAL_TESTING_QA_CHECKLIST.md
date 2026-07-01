# Internal Testing QA Checklist

Candidate version/commit: `[VERSION / COMMIT]`  
AAB SHA-256: `[HASH]`  
Tester/date: `[NAME / DATE]`  
Devices/Android versions: `[MATRIX]`

Use only synthetic accounts, PDFs, allergies and product data. Record pass/fail, evidence and defect ID for each row; retest fixes on the same Play-delivered candidate path.

## Installation, identity and integrity

- [ ] Clean install from Google Play Internal Testing; verify correct app name/package/version and no prior local state.
- [ ] Create an email/password account, sign out, sign in and reset password.
- [ ] Google Sign-In succeeds and cancellation/error paths remain understandable.
- [ ] App Check uses Play Integrity in prod; Firebase/API requests succeed from Play install and invalid/unattested requests are rejected as configured.
- [ ] Upgrade from the previous candidate preserves expected profile/session data.

## Health/profile flows

- [ ] Enter valid manual adult profile data and allergies; reject out-of-range/invalid input.
- [ ] Upload a synthetic text PDF after consent; verify extracted values, uncertainty/incomplete-data warning and medical disclaimer.
- [ ] Try malformed, encrypted, image-only, wrong-type and oversized files; app/API fail safely without exposing content in errors/logs.
- [ ] Confirm no diagnosis/treatment claim and no supplement/medication instruction appears in English or Turkish.
- [ ] Restart app and device; verify intended profile/session persistence and no cross-account data leakage.

## Product flows

- [ ] Grant camera and scan a known barcode; verify physical-label/incomplete-data warning.
- [ ] Deny camera once and permanently; verify recovery/manual entry remains usable.
- [ ] Enter a product manually and test missing nutrition/ingredient/allergen fields.
- [ ] Verify a confirmed allergen overrides favorable nutrition scoring; possible/uncertain matches show strong caution, never absolute “safe.”
- [ ] Verify low-fiber profile behavior is described as a diet-pattern signal, not overall diet quality or disease risk.

## Network and resilience

- [ ] Test slow network, timeout, backend 4xx/5xx, Firebase unavailable and Open Food Facts not-found/incomplete responses.
- [ ] Launch and navigate offline; cached/local state is clear and online-only analysis actions fail recoverably.
- [ ] Switch Wi-Fi/mobile network/background/foreground during PDF upload and product lookup; no duplicate or stuck operations.
- [ ] Confirm logs/crash output contain no PDF text, lab values, allergies, email, tokens or profile payloads.

## Privacy and deletion

- [ ] Privacy policy opens the exact live public URL in English/Turkish context.
- [ ] External account-deletion request page opens without login and a synthetic request reaches the monitored owner.
- [ ] Support email action opens the configured address.
- [ ] In-app health-data deletion clears local and cloud health/profile/photo data while retaining account as described.
- [ ] In-app account deletion handles recent-authentication, deletes known local/Firestore/Storage/Auth data, signs out and cannot restore deleted profile data after reinstall.
- [ ] Test deletion after partial network failure and verify the support/escalation path.

## Accessibility and presentation

- [ ] TalkBack reading order, labels, focus and destructive-action confirmations are understandable.
- [ ] Font scaling at 200% does not hide actions or truncate safety text; landscape/small supported screen remains operable.
- [ ] Contrast, touch targets, keyboard/switch navigation and reduced-motion behavior are acceptable.
- [ ] Light/dark/system themes preserve contrast and all warnings.
- [ ] English/Turkish language switching, grammar, line wrapping and safety meaning are consistent.

## Play release evidence

- [ ] Play pre-launch report reviewed; crashes, ANRs, accessibility/security findings resolved or formally accepted with rationale.
- [ ] Final merged manifest permissions match the declarations draft and Data Safety submission.
- [ ] Reviewer test account works without unavailable 2FA; synthetic PDF/barcode and exact instructions are supplied.
- [ ] Crash/ANR vitals and App Check metrics remain clean through the agreed internal-test window.
- [ ] Medical/dietetic and legal approvals reference this exact candidate; no post-approval health/privacy code or copy changed.

