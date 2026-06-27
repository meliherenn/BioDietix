# BioDietix Decision-System Card

## System type

BioDietix production decisions are deterministic rules, not machine-learning
inference. The Random Forest and HistGradientBoosting code is an engineering
audit that attempts to reproduce rule-engine pseudo-labels.

## Intended use

- Educational nutrition guidance and software demonstration.
- Screening-style explanation of values already present in a user report.
- Conservative product suitability hints based on declared allergens and
  nutrition-label data.

It is not intended for diagnosis, treatment, emergency decisions, medication
changes, pregnancy care, pediatric use or replacement of a clinician.

## Inputs and outputs

Inputs include age, binary sex field used by existing reference rules, body
measurements, laboratory values, allergy statements and product nutrition data.
Outputs are flags, explanatory recommendations and product decisions.

Missing data is not normal data. PDF output distinguishes limited coverage and
uses `No Flagged Risk in Available Data` instead of `Low Risk`.
CSV rows with fewer than 16 observed core analysis signals are marked `limited`;
they retain observed risk flags but cannot produce a general `Low Risk` claim.

## Audit methodology

- Target: rule-engine `Health_Profile` pseudo-label.
- Rare target combinations: grouped as `Other Profile`.
- Preferred split: survey-cycle/year group holdout.
- Fallback: stratified random split only if group holdout introduces unseen
  test-only classes.
- Reported metrics: accuracy, balanced accuracy, weighted and macro
  precision/recall/F1, and log-loss.

Label-index RMSE was removed because categorical label indices have no numeric
distance meaning.

## Limitations and validation gates

- The current target is circular and cannot establish clinical validity.
- Thresholds require review and sign-off by qualified clinicians.
- The source dataset pipeline and sampling methodology must be reproduced
  before research claims are made.
- Performance must be reported by demographic subgroup and survey cycle.
- A real learned model would require independently labeled outcomes, a frozen
  external test set, calibration, drift monitoring and model/version rollback.

Until those gates are satisfied, no audit estimator may be exported or served
as a production medical model.
