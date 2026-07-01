import math

import numpy as np
import pandas as pd

MODEL_FEATURE_COLUMNS = [
    "Gender",
    "Age",
    "Age_Group",
    "Daily_Calories_kcal",
    "Daily_Protein_g",
    "Daily_Carbs_g",
    "Daily_Sugar_g",
    "Daily_Fiber_g",
    "Daily_Fat_g",
    "Daily_Cholesterol_mg",
    "Daily_VitC_mg",
    "BMI",
    "Weight_kg",
    "Height_cm",
    "Waist_Circumference_cm",
    "BP_Systolic_mmHg",
    "BP_Diastolic_mmHg",
    "Glucose_mgdL",
    "Insulin_uUmL",
    "HbA1c_Percent",
    "Diabetes_Diagnosed",
    "Cholesterol_Total_mgdL",
    "Cholesterol_LDL_mgdL",
    "Cholesterol_HDL_mgdL",
    "Triglycerides_mgdL",
    "Liver_ALT_UL",
    "Liver_AST_UL",
    "Kidney_Creatinine_mgdL",
    "eGFR_ml_min_1_73m2",
    "Uric_Acid_mgdL",
    "Albumin_gdL",
    "Total_Protein_gdL",
    "CRP_mg_L",
    "Ferritin_ng_mL",
    "Folate_ng_mL",
    "Vitamin_B12_pg_mL",
    "VitaminD_ng_mL",
    "Iron_ugdL",
    "White_Blood_Cells_count",
    "Hemoglobin_gdL",
    "Hematocrit_Percent",
    "Red_Blood_Cells_count",
    "Platelet_count",
    "CRP_mgdL",
    "Weak_Failing_Kidneys",
    "Alcohol_Frequency_12_Months",
    "Physical_Activity_Level",
    "Vigorous_Activity",
    "Smoked_100_Cigarettes",
    "Currently_Smoking",
]

TARGET_COLUMN = "Health_Profile"


class MLAuditError(ValueError):
    """Raised when the dataset is not large enough for model auditing."""


def available_model_features(dataframe):
    return [column for column in MODEL_FEATURE_COLUMNS if column in dataframe.columns]


def build_data_audit(dataframe):
    missing_ratio = dataframe.isna().mean().sort_values(ascending=False)
    missing_table = missing_ratio.reset_index().rename(
        columns={"index": "Column", 0: "Missing_Ratio"}
    )
    missing_table["Missing_Percent"] = (missing_table["Missing_Ratio"] * 100).round(2)

    target_distribution = pd.DataFrame(columns=[TARGET_COLUMN, "Count", "Percent"])
    if TARGET_COLUMN in dataframe.columns:
        target_distribution = (
            dataframe[TARGET_COLUMN]
            .fillna("Missing")
            .value_counts()
            .rename_axis(TARGET_COLUMN)
            .reset_index(name="Count")
        )
        target_distribution["Percent"] = (
            target_distribution["Count"] / len(dataframe) * 100
        ).round(2)

    feature_columns = available_model_features(dataframe)
    feature_coverage = pd.DataFrame(
        {
            "Feature": feature_columns,
            "Non_Null_Percent": [
                round(dataframe[column].notna().mean() * 100, 2) for column in feature_columns
            ],
        }
    )

    duplicate_patients = (
        int(dataframe["Patient_ID"].duplicated().sum()) if "Patient_ID" in dataframe.columns else 0
    )
    age_min = float(dataframe["Age"].min()) if "Age" in dataframe.columns else math.nan
    age_max = float(dataframe["Age"].max()) if "Age" in dataframe.columns else math.nan

    summary = {
        "Rows": int(len(dataframe)),
        "Columns": int(len(dataframe.columns)),
        "Duplicate_Patient_IDs": duplicate_patients,
        "Missing_Cells_Percent": round(dataframe.isna().mean().mean() * 100, 2),
        "Model_Features_Available": len(feature_columns),
        "Target_Classes": int(dataframe[TARGET_COLUMN].nunique())
        if TARGET_COLUMN in dataframe.columns
        else 0,
        "Age_Min": age_min,
        "Age_Max": age_max,
    }

    return {
        "summary": summary,
        "missing_table": missing_table,
        "target_distribution": target_distribution,
        "feature_coverage": feature_coverage,
    }


def run_ml_profile_audit(dataframe, max_rows=1000, max_classes=15, random_state=42):
    try:
        from sklearn.compose import ColumnTransformer
        from sklearn.ensemble import HistGradientBoostingClassifier, RandomForestClassifier
        from sklearn.impute import SimpleImputer
        from sklearn.metrics import (
            accuracy_score,
            balanced_accuracy_score,
            log_loss,
            precision_recall_fscore_support,
        )
        from sklearn.model_selection import GroupShuffleSplit, train_test_split
        from sklearn.pipeline import Pipeline
        from sklearn.preprocessing import LabelEncoder, OneHotEncoder
    except ImportError as exc:
        raise MLAuditError(
            "ML audit requires scikit-learn. Install dependencies with: "
            "pip install -r requirements.txt"
        ) from exc

    if TARGET_COLUMN not in dataframe.columns:
        raise MLAuditError("Health_Profile target column is required for ML audit.")

    feature_columns = available_model_features(dataframe)
    if len(feature_columns) < 5:
        raise MLAuditError("Not enough raw model features are available for ML audit.")

    group_column = next(
        (column for column in ("Survey_Cycle", "Survey_Year") if column in dataframe.columns),
        None,
    )
    selected_columns = feature_columns + [TARGET_COLUMN]
    if group_column:
        selected_columns.append(group_column)
    model_data = dataframe[selected_columns].dropna(subset=[TARGET_COLUMN]).copy()
    model_data = model_data[model_data[TARGET_COLUMN].astype(str).str.strip() != ""]
    class_counts = model_data[TARGET_COLUMN].value_counts()
    frequent_classes = class_counts.head(max_classes).index
    model_data[TARGET_COLUMN] = np.where(
        model_data[TARGET_COLUMN].isin(frequent_classes),
        model_data[TARGET_COLUMN],
        "Other Profile",
    )
    class_counts = model_data[TARGET_COLUMN].value_counts()
    valid_classes = class_counts[class_counts >= 2].index
    model_data = model_data[model_data[TARGET_COLUMN].isin(valid_classes)].copy()

    if len(model_data) < 80 or model_data[TARGET_COLUMN].nunique() < 2:
        raise MLAuditError("At least 80 rows and 2 target classes are required for ML audit.")

    if len(model_data) > max_rows:
        model_data = model_data.sample(max_rows, random_state=random_state)

    X = model_data[feature_columns]
    y = model_data[TARGET_COLUMN].astype(str)

    label_encoder = LabelEncoder()
    encoded_y = label_encoder.fit_transform(y)

    numeric_features = [
        column for column in feature_columns if pd.api.types.is_numeric_dtype(X[column])
    ]
    categorical_features = [column for column in feature_columns if column not in numeric_features]

    preprocessor = ColumnTransformer(
        transformers=[
            ("num", SimpleImputer(strategy="median"), numeric_features),
            (
                "cat",
                Pipeline(
                    steps=[
                        ("imputer", SimpleImputer(strategy="most_frequent")),
                        (
                            "onehot",
                            OneHotEncoder(handle_unknown="ignore", sparse_output=False),
                        ),
                    ]
                ),
                categorical_features,
            ),
        ],
        remainder="drop",
        verbose_feature_names_out=False,
    )

    test_size = 0.25
    can_stratify = pd.Series(encoded_y).value_counts().min() >= 2 and int(
        len(encoded_y) * test_size
    ) >= len(label_encoder.classes_)
    stratify = encoded_y if can_stratify else None
    split_strategy = "random_stratified" if stratify is not None else "random"
    if group_column and model_data[group_column].nunique() >= 2:
        splitter = GroupShuffleSplit(
            n_splits=1,
            test_size=test_size,
            random_state=random_state,
        )
        train_index, test_index = next(
            splitter.split(X, encoded_y, groups=model_data[group_column])
        )
        X_train, X_test = X.iloc[train_index], X.iloc[test_index]
        y_train, y_test = encoded_y[train_index], encoded_y[test_index]
        split_strategy = f"group_holdout:{group_column}"
        if not set(y_test).issubset(set(y_train)):
            X_train, X_test, y_train, y_test = train_test_split(
                X,
                encoded_y,
                test_size=test_size,
                random_state=random_state,
                stratify=stratify,
            )
            split_strategy = "random_fallback_for_unseen_group_classes"
    else:
        X_train, X_test, y_train, y_test = train_test_split(
            X,
            encoded_y,
            test_size=test_size,
            random_state=random_state,
            stratify=stratify,
        )

    models = {
        "Random Forest": RandomForestClassifier(
            n_estimators=55,
            max_depth=12,
            min_samples_leaf=3,
            class_weight="balanced_subsample",
            random_state=random_state,
            n_jobs=-1,
        ),
        "Gradient Boosting": HistGradientBoostingClassifier(
            max_iter=35,
            max_leaf_nodes=15,
            learning_rate=0.1,
            random_state=random_state,
        ),
    }

    metric_rows = []
    feature_importance = pd.DataFrame(columns=["Feature", "Importance"])
    for model_name, estimator in models.items():
        pipeline = Pipeline(
            steps=[
                ("preprocess", preprocessor),
                ("model", estimator),
            ]
        )
        pipeline.fit(X_train, y_train)
        predictions = pipeline.predict(X_test)
        precision, recall, f1, _ = precision_recall_fscore_support(
            y_test,
            predictions,
            average="weighted",
            zero_division=0,
        )
        macro_precision, macro_recall, macro_f1, _ = precision_recall_fscore_support(
            y_test,
            predictions,
            average="macro",
            zero_division=0,
        )
        probabilities = pipeline.predict_proba(X_test)
        metric_rows.append(
            {
                "Model": model_name,
                "Accuracy": round(accuracy_score(y_test, predictions), 4),
                "Balanced_Accuracy": round(
                    balanced_accuracy_score(y_test, predictions),
                    4,
                ),
                "Precision": round(precision, 4),
                "Recall": round(recall, 4),
                "F1": round(f1, 4),
                "Macro_Precision": round(macro_precision, 4),
                "Macro_Recall": round(macro_recall, 4),
                "Macro_F1": round(macro_f1, 4),
                "Log_Loss": round(
                    log_loss(
                        y_test,
                        probabilities,
                        labels=np.arange(len(label_encoder.classes_)),
                    ),
                    4,
                ),
            }
        )

        if model_name == "Random Forest":
            fitted_preprocessor = pipeline.named_steps["preprocess"]
            feature_names = fitted_preprocessor.get_feature_names_out()
            importances = pipeline.named_steps["model"].feature_importances_
            feature_importance = (
                pd.DataFrame({"Feature": feature_names, "Importance": importances})
                .sort_values("Importance", ascending=False)
                .head(15)
                .reset_index(drop=True)
            )
            feature_importance["Importance"] = feature_importance["Importance"].round(4)

    metrics = pd.DataFrame(metric_rows)
    return {
        "metrics": metrics,
        "feature_importance": feature_importance,
        "sample_rows": int(len(model_data)),
        "target_classes": int(model_data[TARGET_COLUMN].nunique()),
        "feature_count": int(len(feature_columns)),
        "grouped_top_classes": int(max_classes),
        "split_strategy": split_strategy,
        "target_provenance": "rule_engine_pseudo_label",
    }
