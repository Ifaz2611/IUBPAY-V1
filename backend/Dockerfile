# syntax=docker/dockerfile:1
# Pinned digest for reproducible builds - update via dependabot
FROM python:3.12-slim@sha256:47e9d2d2a67bce5bb19f3cd289095e7cca2adbcfb841444d41643cb9ff90f48ba AS builder

ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1

WORKDIR /srv/app

RUN pip install --no-cache-dir --upgrade pip

COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM python:3.12-slim@sha256:47e9d2d2a67bce5bb19f3cd289095e7cca2adbcfb841444d41643cb9ff90f48ba

ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1

WORKDIR /srv/app

RUN useradd -m -u 1000 appuser && \
    apt-get update && apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /install /usr/local
COPY . .
RUN chown -R appuser:appuser /srv/app

USER appuser

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 CMD curl -f http://localhost:8000/health || python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
