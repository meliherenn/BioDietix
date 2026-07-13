# BioDietix Legal Site

This directory is a static, responsive HTML/CSS site for the BioDietix privacy policy, external account-deletion instructions, and support contact. It has no JavaScript, analytics, advertising, tracking code, cookies, or third-party visual assets.

## Published values

- Support/privacy contact: `meliheren2834@gmail.com`
- Effective date: `2026-07-13`
- Canonical host: `https://meliherenn.github.io/biodietix-legal/`

Confirm that no release placeholder has been reintroduced:

```bash
rg -n 'SUPPORT_EMAIL|EFFECTIVE_DATE' legal-site
```

Reconcile material policy changes with the production backend/Firebase configuration, retention schedule, Play Data Safety form, Health Apps declaration, and applicable legal obligations.

## Option A — separate `biodietix-legal` repository

This option produces the URLs already embedded in the pages and is the simplest separation from application source.

1. Create a public GitHub repository owned by `meliherenn` and name it exactly `biodietix-legal`.
2. Copy the contents of this `legal-site/` directory—not the directory wrapper—to the new repository root.
3. Commit and push the files to its `main` branch.
4. Open **Settings → Pages** in that repository.
5. Under **Build and deployment**, choose **Deploy from a branch**, select `main`, choose `/ (root)`, and save.
6. Wait for the Pages deployment, then test every page on mobile and desktop without signing in.

Expected URLs:

- Home: `https://meliherenn.github.io/biodietix-legal/`
- Privacy: `https://meliherenn.github.io/biodietix-legal/privacy-policy.html`
- Account deletion: `https://meliherenn.github.io/biodietix-legal/delete-account.html`

## Option B — publish from the BioDietix repository

GitHub Pages branch settings publish only a branch root or `/docs`, not an arbitrary directory as the site root. Use one of these approaches:

- Create a `gh-pages` branch whose root contains the contents of `legal-site/`; or
- Configure an official GitHub Pages Actions workflow that uploads `legal-site/` as the Pages artifact.

When `legal-site/` is published as the Pages artifact root for the `BioDietix` project repository, expected URLs are:

- Home: `https://meliherenn.github.io/BioDietix/`
- Privacy: `https://meliherenn.github.io/BioDietix/privacy-policy.html`
- Account deletion: `https://meliherenn.github.io/BioDietix/delete-account.html`

If this option is selected, update both HTML canonical/absolute links and the Flutter build defines to the `BioDietix` URLs before publishing. Do not enable Pages from the application repository root without reviewing what other repository content would become part of the generated site.

## Pre-publication verification

From the repository root:

```bash
rg -n 'SUPPORT_EMAIL|EFFECTIVE_DATE' legal-site
rg -n '<script|analytics|googletag|cookie' legal-site --glob '*.html'
python -m http.server 8080 --directory legal-site
```

Then open `http://127.0.0.1:8080/` and verify:

- all navigation, privacy, deletion, and `mailto:` links;
- English and Turkish deletion instructions;
- mobile layout, keyboard focus, zoom, and text scaling;
- the medical-device disclaimer and effective/contact details;
- no network requests other than the local page assets; and
- the public Pages URLs after deployment.

## Final Flutter production build

After the public pages, production API host, and release signing are verified, run from `mobile/`:

```bash
flutter build appbundle --release --flavor prod \
  --dart-define=FLAVOR=prod \
  --dart-define=BIODIETIX_API_URL=https://biodietix-ml.onrender.com \
  --dart-define=BIODIETIX_PRIVACY_POLICY_URL=https://meliherenn.github.io/biodietix-legal/privacy-policy.html \
  --dart-define=BIODIETIX_ACCOUNT_DELETION_URL=https://meliherenn.github.io/biodietix-legal/delete-account.html \
  --dart-define=BIODIETIX_SUPPORT_EMAIL=meliheren2834@gmail.com \
  --dart-define=BIODIETIX_APP_CHECK_ENABLED=true
```

Increment `--build-number` for every Play upload and retain the exact AAB hash.
