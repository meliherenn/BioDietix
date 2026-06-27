FROM python:3.13-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    BIODIETIX_ENV=production \
    BIODIETIX_AUTH_REQUIRED=true \
    BIODIETIX_EXPOSE_DOCS=false

WORKDIR /app

RUN addgroup --system biodietix && adduser --system --ingroup biodietix biodietix

COPY requirements-api.txt ./
RUN pip install --upgrade pip && pip install -r requirements-api.txt

COPY api.py biodietix.py ./
COPY utils ./utils
COPY data ./data

USER biodietix

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=3)"

CMD ["sh", "-c", "uvicorn api:app --host 0.0.0.0 --port ${PORT:-8000} --workers ${WEB_CONCURRENCY:-1} --proxy-headers --forwarded-allow-ips='*'"]
