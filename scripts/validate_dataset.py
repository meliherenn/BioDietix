import argparse
import hashlib
import json
from pathlib import Path

import pandas as pd

from utils.biodietix_audit import build_data_audit
from utils.biodietix_web import prepare_analysis_input


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def validate_dataset(path):
    dataframe = pd.read_csv(path)
    prepared = prepare_analysis_input(dataframe)
    audit = build_data_audit(prepared)
    return {
        "path": str(path),
        "sha256": sha256(path),
        "validation": "passed",
        "summary": audit["summary"],
    }


def main():
    parser = argparse.ArgumentParser(description="Validate a BioDietix analysis dataset.")
    parser.add_argument("path", nargs="?", default="BioDietix_CLEAN.csv")
    arguments = parser.parse_args()
    report = validate_dataset(Path(arguments.path))
    print(json.dumps(report, ensure_ascii=False, indent=2, default=str))


if __name__ == "__main__":
    main()
