# BioDietix Account Deletion Page Template

> **Template only — legal and operational review required.** This page must describe the process BioDietix can actually complete. Replace all placeholders before publication.

Public URL: `[PUBLIC_HTTPS_ACCOUNT_DELETION_URL]`  
Developer/legal entity: `[LEGAL_ENTITY_OR_DEVELOPER_NAME]`  
Contact: `[SUPPORT_EMAIL]`

## Delete your BioDietix account and associated data

BioDietix users can request deletion without reinstalling or signing in to the app.

### In the app

Open **Settings → Delete account**, confirm the action, and follow any recent-sign-in instruction. Verify in a release test that this deletes the Firebase Authentication account, local profile/cache data, the Firestore user profile and known subcollections, and the Firebase Storage profile photo.

### From this page

Provide one working method that does not redirect the user back to the app:

- Secure request form: `[FORM_URL_OR_EMBED]`; or
- Email request: `[MAILTO_SUPPORT_EMAIL_WITH_SUBJECT]`.

Ask only for information needed to locate and verify the account. Do not request a password, full health report or unnecessary identity document. State the verification steps: `[VERIFIED_PROCESS]`.

### What is deleted

List verified scope: Firebase account/UID, email-linked BioDietix profile, lab-derived values, allergies, body measurements, profile photo, saved product checks/notes and other associated cloud data: `[FINAL_SCOPE]`.

### What may be retained

State any legally required security, fraud, request-record or backup retention, the legal reason, access restriction and expiry: `[VERIFIED_RETENTION_EXCEPTIONS]`. If none, say so only after infrastructure/legal confirmation. Explain that expired backups may not be immediately overwritten.

### Timing and confirmation

State request acknowledgement, verification and completion targets approved by counsel: `[TIMELINE]`. Explain how confirmation is delivered and how a user can ask about a delayed/denied request.

### Local device data

Explain that uninstalling normally removes app-private local data but is not a substitute for cloud account deletion. Give verified steps for clearing any remaining device data: `[DEVICE_STEPS]`.

### Privacy rights

Link the public privacy policy `[PRIVACY_POLICY_URL]` and describe applicable KVKK/GDPR rights and complaint routes using counsel-approved text.

## Publication/operations gate

- [ ] BioDietix/developer name matches the Play listing.
- [ ] Page is public, prominent, functional, mobile-friendly and available without account/app access.
- [ ] Form/email creates a monitored ticket with a responsible owner.
- [ ] Synthetic request completes end to end across Auth, Firestore, Storage, local-data explanation and backups.
- [ ] Retention and response language matches the privacy policy and Data Safety form.
- [ ] Legal review and effective date are recorded.

Google’s current account deletion guidance requires both an in-app path and a functional external web resource for apps that permit account creation: [Play account deletion requirements](https://support.google.com/googleplay/android-developer/answer/13327111?hl=en).

