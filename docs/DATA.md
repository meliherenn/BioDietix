# Data Governance

## Current inventory

The repository contains survey-cycle XPT files, derived CSV files and a food
recommendation table. Filenames and columns appear compatible with public
health-survey data, but source URLs, checksums, extraction dates and the exact
transformation pipeline are not present. Provenance is therefore unverified.

No clinical or research claim should be based on the derived CSV until the
following are recorded:

1. Authoritative source URL and license for every raw file.
2. SHA-256 checksum and acquisition date.
3. Variable mapping for every survey cycle.
4. Join keys, exclusions, unit conversions and missing-value policy.
5. Sampling weights and survey-design treatment.
6. Deterministic build command producing `BioDietix_CLEAN.csv`.

`data/dataset_manifest.json` records current derived-file hashes without
claiming provenance. Validate schema, physiological ranges and basic quality:

```bash
python -m scripts.validate_dataset BioDietix_CLEAN.csv
```

## Repository policy

- Never commit patient reports, names, dates of birth, identifiers or derived
  per-patient outputs.
- Raw/large survey data should move to DVC or object storage. Git history must
  be rewritten separately after remote artifact storage is configured.
- Runtime containers include only the files explicitly copied by their
  Dockerfile; raw survey cycles are excluded.
- Generated outputs belong under an ignored `artifacts/` directory.

The previously tracked sample patient PDF and its generated result were removed
from the current tree. Because Git retains historical objects, repository owners
must perform a coordinated history purge and credential/access audit before
considering the data removed from every clone.
