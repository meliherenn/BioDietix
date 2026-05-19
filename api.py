from pathlib import Path
from tempfile import NamedTemporaryFile
import json

import pandas as pd
from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from utils.biodietix_web import BioDietixPDFError, analyze_pdf_file
from utils.mobile_health_core import (
    build_profile_memory,
    evaluate_product_for_profile,
    extract_allergies_from_pdf_file,
    lookup_open_food_facts_product,
    normalize_allergies,
)


app = FastAPI(
    title="BioDietix Mobile API",
    description="Mobile API for blood PDF analysis, allergy parsing, and scanned product evaluation.",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


class ProductEvaluationRequest(BaseModel):
    product: dict
    profile_memory: dict


def dataframe_records(dataframe):
    clean = dataframe.where(pd.notna(dataframe), None)
    return json.loads(clean.to_json(orient="records"))


def parse_allergies_json(value):
    if not value:
        return []
    try:
        loaded = json.loads(value)
    except json.JSONDecodeError as exc:
        raise HTTPException(status_code=400, detail="allergies_json must be a JSON array.") from exc
    return normalize_allergies(loaded)


async def save_upload_to_temp(upload_file, suffix=".pdf"):
    data = await upload_file.read()
    if not data:
        raise HTTPException(status_code=400, detail="Uploaded file is empty.")

    safe_suffix = Path(upload_file.filename or f"upload{suffix}").suffix or suffix
    with NamedTemporaryFile(delete=False, suffix=safe_suffix) as temporary_file:
        temporary_file.write(data)
        return Path(temporary_file.name)


@app.get("/health")
def health():
    return {"status": "ok", "service": "biodietix-mobile-api"}


@app.post("/analyze/blood-pdf")
async def analyze_blood_pdf(
    file: UploadFile = File(...),
    gender: str = Form("Female"),
    age: int = Form(22),
    weight_kg: float | None = Form(None),
    height_cm: float | None = Form(None),
    allergies_json: str = Form("[]"),
):
    pdf_path = await save_upload_to_temp(file)
    try:
        allergies = parse_allergies_json(allergies_json)
        results_df, extracted_values, extracted_text = analyze_pdf_file(
            pdf_path,
            gender=gender,
            age=age,
            weight_kg=weight_kg,
            height_cm=height_cm,
        )
        profile_memory = build_profile_memory(
            results_df,
            allergies=allergies,
            extracted_values=extracted_values,
        )
        return {
            "records": dataframe_records(results_df),
            "extracted_values": extracted_values,
            "text_preview": extracted_text[:4000],
            "profile_memory": profile_memory,
        }
    except BioDietixPDFError as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Blood PDF analysis failed: {exc}") from exc
    finally:
        pdf_path.unlink(missing_ok=True)


@app.post("/analyze/allergy-pdf")
async def analyze_allergy_pdf(file: UploadFile = File(...)):
    pdf_path = await save_upload_to_temp(file)
    try:
        allergies, text = extract_allergies_from_pdf_file(pdf_path)
        return {
            "allergies": allergies,
            "text_preview": text[:4000],
        }
    except Exception as exc:
        raise HTTPException(status_code=422, detail=f"Allergy PDF analysis failed: {exc}") from exc
    finally:
        pdf_path.unlink(missing_ok=True)


@app.get("/product/lookup/{barcode}")
def lookup_product(barcode: str):
    try:
        product = lookup_open_food_facts_product(barcode)
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"Product lookup failed: {exc}") from exc

    if not product:
        raise HTTPException(
            status_code=404,
            detail="Product not found in the online food database.",
        )
    return {"product": product}


@app.post("/product/evaluate")
def evaluate_product(request: ProductEvaluationRequest):
    try:
        return evaluate_product_for_profile(request.product, request.profile_memory)
    except Exception as exc:
        raise HTTPException(status_code=422, detail=f"Product evaluation failed: {exc}") from exc
