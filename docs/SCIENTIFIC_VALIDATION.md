# Scientific Validation Review

Review date: 2026-07-01  
Scope: rules in `biodietix.py`, `utils/food_recommendation_guide.py`, PDF/allergy extraction, and `utils/mobile_health_core.py`.

## Safety position

BioDietix is a general wellness and nutrition-support application. It is not a medical device and must not diagnose, treat, cure, or prevent a condition. A rule match is an indicator from user-supplied data, not a diagnosis. Reference intervals vary by laboratory, assay, fasting status, age, sex, pregnancy, altitude, ethnicity, medicines, and clinical context. The reporting laboratory's interval and a qualified healthcare professional take precedence.

No rule has yet undergone prospective clinical validation. Release requires review and sign-off by a physician experienced in laboratory medicine and a registered dietitian familiar with the intended Turkish user population.

## Biomarker rules

“Acceptable” below means acceptable only as conservative educational categorization with the stated caveats; it does not establish clinical validation.

| Biomarker/rule | Current code threshold | Assessment | Safer user wording / required action | Source |
| --- | --- | --- | --- | --- |
| Glucose | `<100` normal; `100–125.9` prediabetes-range; `>=126 mg/dL` diabetes-range | Conditionally acceptable only for fasting plasma glucose. A generic PDF “Glucose” line does not prove fasting status. | “Fasting-range indicator; fasting status and repeat/confirmatory testing matter.” Code now adds a fasting-status warning and uses “clinical confirmation needed.” | [CDC Diabetes Testing](https://www.cdc.gov/diabetes/diabetes-testing/index.html) |
| HbA1c | `<5.7` normal; `5.7–6.4` prediabetes-range; `>=6.5%` diabetes-range | Thresholds acceptable for screening wording. HbA1c can be unreliable with anemia, kidney/liver disease, hemoglobin disorders, pregnancy, blood loss, or transfusion. | “Range indicator; discuss confirmation and factors affecting HbA1c.” | [CDC A1C Test](https://www.cdc.gov/diabetes/diabetes-testing/prediabetes-a1c-test.html) |
| BMI | `<18.5` underweight; `18.5–24.9` normal; `25–29.9` overweight; `>=30` obesity range | Standard adult population categories, but BMI is not an individual diagnosis and can misclassify muscularity/body composition. | “BMI range; consider body composition and clinical context.” | [WHO BMI among adults](https://www.who.int/data/gho/data/themes/topics/indicator-groups/indicator-group-details/GHO/bmi-among-adults) |
| Waist circumference | Male `>102 cm`, female `>88 cm` | Common US cutoffs but ethnicity-specific; not validated for the intended Turkish population. | “Above the configured waist threshold; ethnicity-specific guidance may differ.” | Needs Turkish/European clinical source and local validation before relying on this rule. |
| Blood pressure | `<120/<80` normal; `120–129/<80` elevated; `130–139 or 80–89` stage 1 range; `>=140 or >=90` stage 2 range; `>180 or >120` severe | Matches AHA categories. One reading does not diagnose hypertension. Code now flags severe values for prompt review. | “Single-reading category; repeat correctly. Seek prompt advice for severe readings and emergency help if severe readings occur with concerning symptoms.” | [American Heart Association BP categories](https://www.heart.org/en/health-topics/high-blood-pressure/understanding-blood-pressure-readings) |
| Total cholesterol | `<200` desirable; `200–239` borderline; `>=240 mg/dL` high | Conventional descriptive ranges; treatment decisions require overall cardiovascular risk. | “Lipid indicator; personal targets depend on overall risk.” | [NIH MedlinePlus cholesterol levels](https://medlineplus.gov/lab-tests/cholesterol-levels/) |
| LDL | `<100` optimal; `100–129` near optimal; `130–159` borderline; `160–189` high; `>=190 mg/dL` very high | Descriptive categories are reasonable, but current guidelines use risk-based targets rather than this rule alone. | “LDL range indicator; discuss overall cardiovascular risk and the laboratory method.” | [NIH MedlinePlus cholesterol](https://medlineplus.gov/cholesterollevelswhatyouneedtoknow.html) |
| HDL | Male `<40`, female `<50 mg/dL` low | Broad screening convention; HDL must not be treated as an independent treatment target. | “Lower HDL indicator; interpret with the full lipid profile and overall risk.” | [NIH MedlinePlus cholesterol levels](https://medlineplus.gov/lab-tests/cholesterol-levels/); female threshold needs local guideline verification. |
| Triglycerides | `<150` normal; `150–199` borderline; `200–499` high; `>=500 mg/dL` very high | Acceptable descriptive bands. Fasting status and very-high pancreatitis risk need clinical context. | “Triglyceride range indicator; discuss fasting status and prompt review of very high values.” | [NIH MedlinePlus triglycerides](https://medlineplus.gov/triglycerides.html) |
| Creatinine | Male `0.74–1.35`, female `0.59–1.04 mg/dL` normal | Lab- and assay-dependent; muscle mass, hydration and medicines strongly affect it. Fixed sex ranges are not sufficient for kidney conclusions. | “Outside configured creatinine range; interpret with the report range, eGFR and context.” Code no longer applies kidney protein restrictions to low creatinine. | [MedlinePlus reference-range limitations](https://medlineplus.gov/lab-tests/how-to-understand-your-lab-results/); exact cutoffs need local lab source. |
| eGFR | `<60 mL/min/1.73m²` reduced | Appropriate as an indicator only. CKD requires persistence for at least three months and/or kidney-damage markers. | “Reduced single eGFR indicator; this does not establish chronic kidney disease.” | [National Kidney Foundation eGFR](https://www.kidney.org/kidney-failure-risk-factor-estimated-glomerular-filtration-rate-egfr), [KDIGO 2024 CKD guideline](https://kdigo.org/wp-content/uploads/2024/03/KDIGO-2024-CKD-Guideline.pdf) |
| Urea | Parsed, no risk rule | Appropriate not to classify without unit, hydration, kidney and dietary context. | Display only with source unit/reference range; current parser omits incompatible-unit values. | Needs local lab source. |
| AST | `<=40 U/L` normal | Lab-, method-, age- and sex-dependent; AST is not liver-specific. | “Above configured AST threshold; review with the laboratory range and other liver/muscle markers.” | [NIH MedlinePlus liver tests](https://medlineplus.gov/lab-tests/liver-function-tests/); exact cutoff needs local lab source. |
| ALT | Male `<=41`, female `<=35 U/L` normal | Lab- and method-dependent. A single result cannot diagnose liver disease. | “Above configured ALT threshold; discuss with a healthcare professional.” | [NIH MedlinePlus ALT](https://medlineplus.gov/ency/article/003473.htm); exact sex cutoffs need local validation. |
| CRP | `>5 mg/L` elevated | CRP is nonspecific and reference ranges vary; must not infer a cause. | “Nonspecific inflammation indicator; the result does not identify a cause.” | [NIH MedlinePlus CRP](https://medlineplus.gov/lab-tests/c-reactive-protein-crp-test/) |
| Hemoglobin | Male `<13.5`/`>17.5`; female `<12`/`>15.5 g/dL` | Broad ranges only; altitude, pregnancy, smoking and lab interval matter. | “Outside configured hemoglobin range; several causes are possible.” Do not recommend iron supplements. | [NIH MedlinePlus CBC](https://medlineplus.gov/ency/article/003642.htm); exact configured limits need local validation. |
| RBC | Female `3.8–5.1`; male `4.5–5.9` | Lab-/population-dependent. Units must be verified. | “Outside configured RBC range; use the report reference interval.” | [NIH MedlinePlus CBC](https://medlineplus.gov/ency/article/003642.htm) |
| Hematocrit | Female `35–45%`; male `41–53%` | Lab-/population-dependent. | “Outside configured hematocrit range; use the report interval.” | [NIH MedlinePlus CBC](https://medlineplus.gov/ency/article/003642.htm) |
| WBC | `<4`, `4–11`, `>11` | Conventional broad band; differential count and symptoms matter. | “Outside configured WBC range; nonspecific and requires context.” | [NIH MedlinePlus blood count tests](https://medlineplus.gov/bloodcounttests.html); exact cutoff needs lab verification. |
| Platelets | `<150`, `150–450`, `>450` | Upper limit varies (often 400–450). | “Outside configured platelet range; use the report interval and clinical review.” | [NIH MedlinePlus CBC](https://medlineplus.gov/ency/article/003642.htm) |
| Ferritin | `<30 ng/mL` low; female `>150`, male `>400` high | Low/high interpretation depends on inflammation and menstruation; male high cutoff does not match WHO's general healthy-adult `>200` risk indicator. Current rule needs clinician decision before release. | “Ferritin indicator; inflammation can elevate ferritin. Do not start iron from this result.” Code now prevents iron-increase advice for high ferritin. | [WHO ferritin guidance](https://www.who.int/tools/elena/interventions/ferritin-concentrations) |
| Serum iron | Parsed, no risk rule | Correct not to classify alone; serum iron varies and needs ferritin/transferrin context. | Display only with unit/reference range. | Needs source. |
| Iron-binding capacity | Parsed, no risk rule | Correct not to classify alone. | Display only with unit/reference range. | Needs source. |
| Vitamin B12 | `<200` low; `200–299 pg/mL` borderline | Reasonable screening bands. Borderline results often require methylmalonic acid and kidney context. | “Low/borderline indicator; confirm as clinically appropriate.” No supplement dose advice. | [NIH ODS Vitamin B12](https://ods.od.nih.gov/factsheets/VitaminB12-HealthProfessional/) |
| Folate | `<3 ng/mL` low | Updated from 4.6 to the NIH ODS serum-adequacy boundary. Serum folate reflects recent intake. | “Low serum folate indicator; confirm with laboratory and clinical context.” | [NIH ODS Folate](https://ods.od.nih.gov/factsheets/Folate-HealthProfessional/) |
| Vitamin D | `<12` low; `12–19.9 ng/mL` inadequate; `>=20` not flagged | Updated from `<20/<30` to NASEM/NIH ODS bands. Assay variability remains. | “Vitamin D indicator; do not start high-dose supplements from the app.” | [NIH ODS Vitamin D](https://ods.od.nih.gov/factsheets/Vitamind-HealthProfessional/) |
| Calcium | Parsed, no rule | Correct not to classify without albumin/ionized calcium and unit context. | Display only with source unit/reference range. | Needs source. |
| Magnesium | Parsed, no rule | Correct not to classify without lab context. | Display only with source unit/reference range. | Needs source. |
| TSH | `<0.4`, `0.4–4.5`, `>4.5 mIU/L` | Common adult band but lab, age, pregnancy, medicines, pituitary disease and thyroid treatment matter. Free T4 is needed for interpretation. | “Outside configured TSH range; use the report interval.” Code explicitly warns against iodine/selenium/thyroid supplements. | [NIH MedlinePlus TSH](https://medlineplus.gov/ency/article/003684.htm) |
| Free T3 / Free T4 | Parsed, no rule | Correct not to classify because assay/reference intervals vary. | Display only with unit/reference range. | Needs local lab source. |
| ESR/sedimentation | Parsed, no rule | Correct not to classify; age/sex/method and nonspecificity matter. | Display only with source unit/reference range. | Needs source. |

## Diet-intake and anthropometric rules

| Rule | Current threshold | Assessment / required change |
| --- | --- | --- |
| Daily fiber | `>=25 g` adequate; `15–24.9` low-moderate; `<15` low | Useful general adult heuristic, but targets vary by age, sex and energy intake. Keep as general pattern guidance only. |
| Daily sugar | `<=25`, `25–50`, `>50 g` remains in a legacy descriptive column | Not scientifically reliable unless the field distinguishes added/free sugar from total sugar and includes energy intake. It no longer contributes to a profile, recommendation trigger or aggregate score. Do not expose it as a clinical/diet-quality threshold; the data dictionary still needs correction. |
| Daily fat | No longer used in a diet-quality score | The unsupported `>100 g` aggregate-score contribution was removed. Total fat requires energy and fat-type context. |
| Dietary cholesterol | No longer used in a diet-quality score | The unsupported `>300 mg` aggregate-score contribution was removed. Do not use a stand-alone universal cutoff to characterize overall diet quality. |
| Fiber intake signal (legacy API field `Diet_Quality_Risk_Level`) | `<15 g`: “Low Fiber Intake Signal”; `15–24.9 g`: “Lower Fiber Intake Signal”; `>=25 g`: “No Low-Fiber Intake Signal”; missing fiber: not assessed | Replaces the unvalidated aggregate diet-quality score. This is an explainable input signal, not a validated overall diet score or health diagnosis. User wording is conditional on the entry reflecting usual intake and recommends gradual varied sources/individual review. Adult targets vary by age, sex and energy intake, so dietitian sign-off is still required. |
| Age group | Adult bands at 18/31/51/65 | Product segmentation, not a medical rule. The exact breaks have no cited clinical basis (“needs source”). |

## Allergy extraction and matching

- Manual allergy entries are normalized and retained, including unsupported allergens.
- PDF extraction treats positive language or a numeric value `>=0.35` as a sensitization signal. This is **not proof of clinical food allergy**; allergen-specific IgE must be interpreted with history and a clinician. The exact 0.35 rule needs an allergist-approved source.
- Negative/class-0 lines are ignored unless contradictory positive evidence exists.
- Confirmed label/ingredient matches override nutrition scoring and return `not_recommended`.
- Product-name/category-only matches return `use_with_caution` because certainty is lower.
- Matching now uses phrase boundaries, preventing `nut` from matching `coconut`, and reports source/certainty.
- The current nine canonical groups do not cover all 14 EU-declarable allergens (celery, mustard, lupin, molluscs, sulphites are missing as canonical choices). Manual entries work, but the predefined list should be expanded after localization and allergy review. [European Commission allergen list](https://food.ec.europa.eu/food-safety/campaign-2026/allergies_en)
- “May contain” precautionary labels are treated conservatively as a declared match. The user must still read the physical package because formulas and databases can be outdated.

## Product suitability rules

The high thresholds for solid foods—total sugar `>22.5 g/100g`, saturated fat `>5 g/100g`, and salt `>1.5 g/100g` or sodium `>600 mg/100g`—are consistent with UK front-of-pack guidance. The current medium thresholds are BioDietix heuristics and are not official medical limits. Different thresholds apply to drinks. [NHS food-label guidance](https://www.nhs.uk/live-well/eat-well/food-guidelines-and-food-labels/how-to-read-food-labels/)

Other rules require caution:

- `>=400/550 kcal/100g`: internal energy-density heuristic; needs source and category/portion awareness.
- fiber `<3` or `>=6 g/100g`: reasonable label comparison bands, but not a medical decision by themselves.
- protein `>=25 g/100g` with an explicit kidney marker: conservative flag only; individual kidney diets require clinician/dietitian advice.
- NOVA 4 and Nutri-Score D/E: supporting signals only; never sufficient to claim a product is unsafe.
- ingredient keywords such as palm oil, emulsifier, or preservative do not prove harm. They remain secondary pattern-quality signals and should not be described as treatment decisions.
- Open Food Facts is volunteer-contributed and gives no assurance of accuracy, completeness, or reliability. Results must say “based on available data,” show missing fields, and direct users to the physical label. [Open Food Facts API documentation](https://openfoodfacts.github.io/openfoodfacts-server/api/)

## Recommendation text review

Implemented safety changes:

- Every generated recommendation ends with the not-medical-device / no diagnosis-treatment-cure-prevention disclaimer and a healthcare-professional reminder.
- Direct supplement or medication treatment advice is prohibited.
- High ferritin no longer receives generic “increase iron” advice.
- TSH flags no longer recommend iodine or selenium intake; the text warns against starting supplements.
- A creatinine flag no longer tells users to change protein/fluid intake from that result alone.
- Vitamin D wording no longer recommends high-dose supplements or treats `20–29 ng/mL` as universally insufficient.
- “Improve,” “reduce disease risk,” and “promote weight loss” purposes in the food guide were replaced with supportive food-choice language.

Remaining validation gates:

1. Obtain dietitian review of the replacement fiber-intake signal and decide whether the legacy daily sugar classification should be removed or redesigned with added/free-sugar and energy context.
2. Validate Turkish lab names, units, decimal separators, and reference intervals against de-identified reports from multiple laboratories.
3. Add explicit fasting status and source units to the API schema; incompatible units and inequality-only values are now omitted rather than silently misinterpreted.
4. Expand canonical allergens and preserve provenance (“manual” versus “PDF sensitization signal”).
5. Obtain written medical/dietetic review of every user-visible Turkish and English recommendation before production release.
