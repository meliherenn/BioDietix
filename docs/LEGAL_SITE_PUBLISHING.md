# Publishing the BioDietix Legal Site

The publishable static site is in [`legal-site/`](../legal-site/). It includes the landing page, privacy policy, bilingual account-deletion instructions, and shared CSS. It intentionally contains no JavaScript, analytics, trackers, cookies, or external visual assets.

## Published configuration

The production pages use these release values:

- Developer/controller: `Melih Eren`
- Support/privacy contact: `meliheren2834@gmail.com`
- Effective date: `2026-07-13`
- Canonical host: `https://meliherenn.github.io/biodietix-legal/`

Before each Play release, confirm these values are still correct, reconcile
retention/Firebase/backend behavior with the Data Safety and Health Apps
declarations, and test account deletion from a signed-out browser using a
synthetic account.

## Recommended GitHub Pages deployment

Create a separate public repository named `meliherenn/biodietix-legal`, copy the contents of `legal-site/` into its root, and configure **Settings → Pages → Deploy from a branch → main → / (root)**.

Final URLs:

- `https://meliherenn.github.io/biodietix-legal/privacy-policy.html`
- `https://meliherenn.github.io/biodietix-legal/delete-account.html`

The alternative is a `gh-pages` branch or GitHub Pages Actions deployment from this repository. Publishing `legal-site/` as the artifact root for this repository changes the expected base URL to `https://meliherenn.github.io/BioDietix/`; update all canonical links and build defines if that option is used.

## Build-time configuration

Build the closed-testing update from `mobile/`:

```bash
flutter build appbundle --release --flavor prod \
  --build-name=1.0.1 \
  --build-number=20260713 \
  --dart-define=FLAVOR=prod \
  --dart-define=BIODIETIX_API_URL=https://biodietix-ml.onrender.com \
  --dart-define=BIODIETIX_PRIVACY_POLICY_URL=https://meliherenn.github.io/biodietix-legal/privacy-policy.html \
  --dart-define=BIODIETIX_ACCOUNT_DELETION_URL=https://meliherenn.github.io/biodietix-legal/delete-account.html \
  --dart-define=BIODIETIX_SUPPORT_EMAIL=meliheren2834@gmail.com \
  --dart-define=BIODIETIX_APP_CHECK_ENABLED=true
```

Use a version code greater than the highest code already uploaded in Play
Console if `20260713` has previously been used. The signed artifact and its
verification evidence are recorded in `PLAY_STORE_DELIVERY_1.0.1.md`.

See [`legal-site/README.md`](../legal-site/README.md) for both deployment options and the complete verification checklist.
