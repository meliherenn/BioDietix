# Publishing the BioDietix Legal Site

The publishable static site is in [`legal-site/`](../legal-site/). It includes the landing page, privacy policy, bilingual account-deletion instructions, and shared CSS. It intentionally contains no JavaScript, analytics, trackers, cookies, or external visual assets.

## Mandatory gate

Before publishing or referencing the pages from Google Play:

1. Replace every `SUPPORT_EMAIL` and `EFFECTIVE_DATE` occurrence.
2. Confirm Melih Eren is the correct public developer/controller identity or update it with counsel.
3. Obtain final KVKK/GDPR legal review.
4. Reconcile retention, Firebase/backend providers, Data Safety, Health Apps declarations, and the actual production data flow.
5. Test the external deletion request from a signed-out browser through completion with a synthetic account.

## Recommended GitHub Pages deployment

Create a separate public repository named `meliherenn/biodietix-legal`, copy the contents of `legal-site/` into its root, and configure **Settings → Pages → Deploy from a branch → main → / (root)**.

Final URLs:

- `https://meliherenn.github.io/biodietix-legal/privacy-policy.html`
- `https://meliherenn.github.io/biodietix-legal/delete-account.html`

The alternative is a `gh-pages` branch or GitHub Pages Actions deployment from this repository. Publishing `legal-site/` as the artifact root for this repository changes the expected base URL to `https://meliherenn.github.io/BioDietix/`; update all canonical links and build defines if that option is used.

## Build-time configuration

After the recommended URLs are live and the support address is real, build from `mobile/`:

```bash
flutter build appbundle --release --flavor prod \
  --dart-define=FLAVOR=prod \
  --dart-define=BIODIETIX_API_URL=https://YOUR_PRODUCTION_API_HOST \
  --dart-define=BIODIETIX_PRIVACY_POLICY_URL=https://meliherenn.github.io/biodietix-legal/privacy-policy.html \
  --dart-define=BIODIETIX_ACCOUNT_DELETION_URL=https://meliherenn.github.io/biodietix-legal/delete-account.html \
  --dart-define=BIODIETIX_SUPPORT_EMAIL=SUPPORT_EMAIL \
  --dart-define=BIODIETIX_APP_CHECK_ENABLED=true
```

Do not upload this build until `YOUR_PRODUCTION_API_HOST` and `SUPPORT_EMAIL` are replaced, the version code is incremented, signing/Firebase/Play Integrity are verified, and all expert/manual release gates in [`PLAY_STORE_BLOCKERS_CLOSURE_PLAN.md`](PLAY_STORE_BLOCKERS_CLOSURE_PLAN.md) are closed.

See [`legal-site/README.md`](../legal-site/README.md) for both deployment options and the complete verification checklist.
