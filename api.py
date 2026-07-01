import json
import logging
import re
import time
from pathlib import Path
from tempfile import NamedTemporaryFile
from typing import Annotated, Any
from uuid import uuid4

import pandas as pd
from fastapi import APIRouter, Depends, FastAPI, File, Form, HTTPException, Request, UploadFile
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, ConfigDict, Field, StringConstraints
from starlette.concurrency import run_in_threadpool
from starlette.middleware.trustedhost import TrustedHostMiddleware

from utils.api_config import APISettings, get_api_settings
from utils.api_security import UserRateLimit
from utils.biodietix_web import BioDietixPDFError, analyze_pdf_file
from utils.mobile_health_core import (
    build_profile_memory,
    evaluate_product_for_profile,
    extract_allergies_from_pdf_file,
    lookup_open_food_facts_product,
    normalize_allergies,
)

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s %(message)s")
LOGGER = logging.getLogger("biodietix.api")
SETTINGS = get_api_settings()
ShortText = Annotated[str, StringConstraints(strip_whitespace=True, max_length=500)]
LongText = Annotated[str, StringConstraints(strip_whitespace=True, max_length=10_000)]


app = FastAPI(
    title="BioDietix Mobile API",
    description="Authenticated API for blood PDF analysis, allergy parsing, and product evaluation.",
    version="2.0.0",
    docs_url="/docs" if SETTINGS.expose_docs else None,
    redoc_url="/redoc" if SETTINGS.expose_docs else None,
    openapi_url="/openapi.json" if SETTINGS.expose_docs else None,
)

if SETTINGS.allowed_origins:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=list(SETTINGS.allowed_origins),
        allow_credentials=False,
        allow_methods=["GET", "POST"],
        allow_headers=[
            "Authorization",
            "Content-Type",
            "X-Firebase-AppCheck",
            "X-Request-ID",
        ],
    )
if SETTINGS.allowed_hosts:
    app.add_middleware(TrustedHostMiddleware, allowed_hosts=list(SETTINGS.allowed_hosts))


class ProductPayload(BaseModel):
    model_config = ConfigDict(extra="forbid", allow_inf_nan=False)

    barcode: ShortText = ""
    name: ShortText = ""
    brand: ShortText = ""
    quantity: ShortText = ""
    category: ShortText = ""
    ingredients_text: LongText = ""
    allergens_text: LongText = ""
    labels: LongText = ""
    serving_size: ShortText = ""
    nutrition_grade: Annotated[str, StringConstraints(strip_whitespace=True, max_length=2)] = ""
    nova_group: float | None = Field(default=None, ge=1, le=4)
    energy_kcal_100g: float | None = Field(default=None, ge=0, le=1000)
    sugar_g_100g: float | None = Field(default=None, ge=0, le=100)
    saturated_fat_g_100g: float | None = Field(default=None, ge=0, le=100)
    salt_g_100g: float | None = Field(default=None, ge=0, le=100)
    sodium_mg_100g: float | None = Field(default=None, ge=0, le=100_000)
    protein_g_100g: float | None = Field(default=None, ge=0, le=100)
    fiber_g_100g: float | None = Field(default=None, ge=0, le=100)


class ProfileMemoryPayload(BaseModel):
    model_config = ConfigDict(extra="forbid", allow_inf_nan=False)

    schema_version: int = Field(default=1, ge=1, le=10)
    updated_at: ShortText = ""
    personal_info: dict[str, Any] = Field(default_factory=dict)
    bmi: float | None = Field(default=None, ge=5, le=100)
    health_profile: LongText = ""
    nutrition_recommendation: LongText = ""
    foods_to_increase: list[ShortText] = Field(default_factory=list, max_length=100)
    foods_to_limit: list[ShortText] = Field(default_factory=list, max_length=100)
    risk_levels: dict[str, Any] = Field(default_factory=dict)
    data_quality: dict[str, Any] = Field(default_factory=dict)
    lab_values: dict[str, Any] = Field(default_factory=dict)
    allergies: list[ShortText] = Field(default_factory=list, max_length=100)


class ProductEvaluationRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    product: ProductPayload
    profile_memory: ProfileMemoryPayload


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
    if not isinstance(loaded, list) or len(loaded) > 100:
        raise HTTPException(
            status_code=400, detail="allergies_json must contain at most 100 items."
        )
    return normalize_allergies(loaded)


async def save_pdf_upload_to_temp(upload_file: UploadFile, settings: APISettings):
    filename = upload_file.filename or "upload.pdf"
    if Path(filename).suffix.lower() != ".pdf":
        raise HTTPException(status_code=415, detail="Only PDF uploads are supported.")
    if upload_file.content_type not in {"application/pdf", "application/octet-stream"}:
        raise HTTPException(status_code=415, detail="Uploaded file must use a PDF content type.")

    temporary_path = None
    total = 0
    header = bytearray()
    try:
        with NamedTemporaryFile(delete=False, suffix=".pdf") as temporary_file:
            temporary_path = Path(temporary_file.name)
            while chunk := await upload_file.read(1024 * 1024):
                total += len(chunk)
                if total > settings.max_pdf_bytes:
                    raise HTTPException(status_code=413, detail="Uploaded PDF is too large.")
                if len(header) < 1024:
                    header.extend(chunk[: 1024 - len(header)])
                temporary_file.write(chunk)
        if total == 0:
            raise HTTPException(status_code=400, detail="Uploaded file is empty.")
        if not bytes(header).lstrip().startswith(b"%PDF-"):
            raise HTTPException(status_code=415, detail="Uploaded file is not a valid PDF.")
        return temporary_path
    except Exception:
        if temporary_path:
            temporary_path.unlink(missing_ok=True)
        raise
    finally:
        await upload_file.close()


@app.middleware("http")
async def request_safety_middleware(request: Request, call_next):
    request_id = request.headers.get("X-Request-ID", "")
    if not re.fullmatch(r"[A-Za-z0-9._:-]{1,100}", request_id):
        request_id = str(uuid4())
    content_length = request.headers.get("content-length")
    try:
        json_body_too_large = (
            content_length
            and request.headers.get("content-type", "").startswith("application/json")
            and int(content_length) > SETTINGS.max_json_bytes
        )
    except ValueError:
        json_body_too_large = True
    if json_body_too_large:
        response = JSONResponse(
            status_code=413,
            content={"detail": "Request body is too large."},
        )
        response.headers["X-Request-ID"] = request_id
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["Referrer-Policy"] = "no-referrer"
        return response

    started = time.monotonic()
    response = await call_next(request)
    response.headers["X-Request-ID"] = request_id
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["Referrer-Policy"] = "no-referrer"
    LOGGER.info(
        "request_complete request_id=%s method=%s path=%s status=%s duration_ms=%.1f",
        request_id,
        request.method,
        request.url.path,
        response.status_code,
        (time.monotonic() - started) * 1000,
    )
    return response


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(_request: Request, exc: RequestValidationError):
    errors = [
        {
            "location": [str(part) for part in error.get("loc", ())],
            "message": error.get("msg", "Invalid value."),
            "type": error.get("type", "validation_error"),
        }
        for error in exc.errors()
    ]
    return JSONResponse(
        status_code=422,
        content={"detail": "Request validation failed.", "errors": errors},
    )


@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception):
    LOGGER.error(
        "unhandled_api_error path=%s error_type=%s",
        request.url.path,
        type(exc).__name__,
        exc_info=SETTINGS.environment != "production",
    )
    return JSONResponse(status_code=500, content={"detail": "Internal server error."})


router = APIRouter(prefix="/v1")
upload_limit = UserRateLimit(requests=10)
lookup_limit = UserRateLimit(requests=10)
evaluation_limit = UserRateLimit(requests=120)


@app.get("/health")
def health():
    return {
        "status": "ok",
        "service": "biodietix-mobile-api",
        "version": app.version,
        "environment": SETTINGS.environment,
        "authentication_required": SETTINGS.auth_required,
        "app_check_required": SETTINGS.app_check_required,
    }


@router.post("/analyze/blood-pdf")
async def analyze_blood_pdf(
    file: UploadFile = File(...),
    gender: str = Form("Female", pattern="^(Female|Male)$"),
    age: int = Form(22, ge=18, le=120),
    weight_kg: float | None = Form(None, gt=0, le=350),
    height_cm: float | None = Form(None, gt=0, le=250),
    allergies_json: str = Form("[]", max_length=10_000),
    _user=Depends(upload_limit),
    settings: APISettings = Depends(get_api_settings),
):
    pdf_path = await save_pdf_upload_to_temp(file, settings)
    try:
        allergies = parse_allergies_json(allergies_json)
        results_df, extracted_values, extracted_text = await run_in_threadpool(
            analyze_pdf_file,
            pdf_path,
            gender,
            age,
            weight_kg,
            height_cm,
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
    except HTTPException:
        raise
    except Exception as exc:
        LOGGER.error(
            "blood_pdf_analysis_failed error_type=%s",
            type(exc).__name__,
            exc_info=SETTINGS.environment != "production",
        )
        raise HTTPException(status_code=500, detail="Blood PDF analysis failed.") from exc
    finally:
        pdf_path.unlink(missing_ok=True)


@router.post("/analyze/allergy-pdf")
async def analyze_allergy_pdf(
    file: UploadFile = File(...),
    _user=Depends(upload_limit),
    settings: APISettings = Depends(get_api_settings),
):
    pdf_path = await save_pdf_upload_to_temp(file, settings)
    try:
        allergies, text = await run_in_threadpool(extract_allergies_from_pdf_file, pdf_path)
        return {"allergies": allergies, "text_preview": text[:4000]}
    except Exception as exc:
        LOGGER.error(
            "allergy_pdf_analysis_failed error_type=%s",
            type(exc).__name__,
            exc_info=SETTINGS.environment != "production",
        )
        raise HTTPException(status_code=422, detail="Allergy PDF analysis failed.") from exc
    finally:
        pdf_path.unlink(missing_ok=True)


@router.get("/product/lookup/{barcode}")
async def lookup_product(
    barcode: Annotated[str, StringConstraints(pattern=r"^\d{6,18}$")],
    _user=Depends(lookup_limit),
):
    try:
        product = await run_in_threadpool(lookup_open_food_facts_product, barcode)
    except Exception as exc:
        LOGGER.error(
            "product_lookup_failed error_type=%s",
            type(exc).__name__,
            exc_info=SETTINGS.environment != "production",
        )
        raise HTTPException(status_code=502, detail="Product lookup service unavailable.") from exc
    if not product:
        raise HTTPException(
            status_code=404, detail="Product not found in the online food database."
        )
    return {"product": product}


@router.post("/product/evaluate")
def evaluate_product(
    request: ProductEvaluationRequest,
    _user=Depends(evaluation_limit),
):
    try:
        return evaluate_product_for_profile(
            request.product.model_dump(),
            request.profile_memory.model_dump(),
        )
    except Exception as exc:
        LOGGER.error(
            "product_evaluation_failed error_type=%s",
            type(exc).__name__,
            exc_info=SETTINGS.environment != "production",
        )
        raise HTTPException(status_code=422, detail="Product evaluation failed.") from exc


app.include_router(router)
