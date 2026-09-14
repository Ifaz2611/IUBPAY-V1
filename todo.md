
---

# TODO.md

## Project Overview

* **Current State:** Functional prototype
* **Target State:** Hardened, production-ready application

---

## Priority Levels

* **P0 (Blocker):** Must be completed before release. Fixes critical security vulnerabilities, auth flaws, and build/runtime crashes.
* **P1 (High):** Critical for data correctness, system reliability, concurrency safety, and leak prevention.
* **P2 (Medium):** Architectural refactoring, app separation, abstraction layers, and maintainability.
* **P3 (Low):** Tooling, CI/CD, testing coverage, accessibility (a11y), and documentation.

---

## P0 — Security & Build (Blocker)

### 1. Backend Configuration & Secrets Management

* **Action:**
* Add `Field(min_length=32)` validation to `SECRET_KEY` and `MOCK_PAYMENT_WEBHOOK_TOKEN` in `backend/app/core/config.py:12,21`.
* Fail-fast on app launch if `ENV=prod` and secrets remain set to weak dev defaults.
* Explicitly reject wildcard `*` CORS origins when `ENV=prod`.


* **Rationale:** Eliminates hardcoded dev secrets and loose cross-origin rules in production environments.

### 2. Auth & Webhook Hardening

* **Action:**
* Use `hmac.compare_digest()` for non-constant-time webhook signature validation in `backend/app/api/payments.py:124`.
* Eliminate the auth timing leak in `backend/app/api/auth.py:19` by running a dummy `verify_password` check when `user is None`.
* Add rate-limiting middleware/guards to `POST /api/auth/login` and `POST /api/payments/webhook`.
* Hardened JWTs in `backend/app/core/security.py:20`: reduce 12h expiration, add `jti`, `iss`, and `aud` claims, and implement token revocation/blacklisting.


* **Rationale:** Defends against timing attacks, password brute-forcing, and stolen token replay.

### 3. Frontend Token & Secret Security

* **Action:**
* Migrate JWT storage in `frontend/lib/shared/api/api_client.dart:7` from `SharedPreferences` (plaintext) to `flutter_secure_storage`.
* Remove hardcoded dev password (`Passw0rd!Dev`) in `frontend/lib/features/auth/screens/login_screen.dart:15` or wrap with a `kDebugMode` guard.
* Change cleartext endpoint `[http://10.0.2.2:8000/api](http://10.0.2.2:8000/api)` in `frontend/lib/core/constants/app_constants.dart:3` to enforce HTTPS in release builds.


* **Rationale:** Prevents credential exposure in compiled binaries and protects auth tokens on rooted/jailbroken devices.

### 4. Dependencies & Container Runtime

* **Action:**
* Add missing `psycopg[binary]` to `backend/requirements.txt` and `backend/pyproject.toml:6` (currently causes runtime crash with `postgresql+psycopg://` in `docker-compose.yml:24`).
* Remove root execution in `backend/Dockerfile:1` by creating and switching to `USER appuser`.


* **Rationale:** Resolves immediate startup crashes and applies least-privilege security to the container runtime.

---

## P1 — Reliability & Correctness

### 1. Database Concurrency & Transactions

* **Action:**
* Register a global `IntegrityError` handler in `backend/app/main.py`.
* Wrap idempotency checks (`app/services/order_service.py:33`) and double-pay checks (`app/services/payment_service.py:40`) in `try/except IntegrityError` with handle/re-select fallbacks.
* Wrap vendor suspension loop in `backend/app/api/vendors.py:109` in a single database transaction to prevent partial commits on `create_and_process_refund()`.


* **Rationale:** Prevents unhandled 500 crashes and state corruption during concurrent API requests.

### 2. Async Execution & Webhook Errors

* **Action:**
* Replace thread-blocking `time.sleep()` in `backend/app/services/payment_service.py:150` with an async handler (`async def` + `asyncio.sleep`).
* Change missing header status code in `backend/app/api/payments.py:115` from `422` to `401` using `Header(None)`.


* **Rationale:** Stops worker pool starvation under load and standardizes HTTP error contracts.

### 3. Identifiers & Datetime Consistency

* **Action:**
* Replace collision-prone pickup code math `uuid % 10000` in `backend/app/services/order_service.py:70` with a larger space + uniqueness retry check.
* Add retry logic for 6-character hex `order_number` generation on uniqueness collision.
* Resolve naive vs. timezone-aware datetime mismatches between `order_service.py:15` and `models/order.py:31` by standardizing on UTC (`datetime.now(timezone.utc)`).


* **Rationale:** Eliminates ordering sequence overlaps and data corruption across timezone offsets.

### 4. Query Performance & PII Protection

* **Action:**
* Refactor `daily()` report in `backend/app/services/report_service.py:57` to aggregate in SQL using `GROUP BY date_trunc('day')` instead of loading all `LedgerEntry` objects into Python memory.
* Add pagination (`limit`/`offset`) to `GET /api/admin/users` in `backend/app/api/admin_reports.py:89`.


* **Rationale:** Prevents out-of-memory errors on large reporting queries and mitigates full user database scrapability.

### 5. Frontend State & Resource Management

* **Action:**
* Make `CartLine.qty` immutable and provide a `copyWith()` method in `frontend/lib/features/student/providers/student_providers.dart:19` to restore Riverpod value equality.
* Fix memory leak in `frontend/lib/features/student/screens/order_screens.dart:62` by replacing active `Timer.periodic(5s)` with `StreamProvider.autoDispose` paired with a `WidgetsBindingObserver`.


* **Rationale:** Fixes UI re-rendering glitches and eliminates background battery/memory drain.

---

## P2 — Architecture & Separation

### 1. App Separation (Student Mobile vs. Vendor/Admin Web)

* **Action:**
* Split frontend into 3 entrypoints sharing `core/`, `shared/models/`, and `shared/api/`:
* `frontend/lib/main_student.dart` (`StudentApp`)
* `frontend/lib/main_vendor.dart` (`VendorApp`)
* `frontend/lib/main_admin.dart` (`AdminApp`)


* Extract dedicated routers: `student_router.dart` (routes `/splash`, `/login`, `/student/*`), `vendor_router.dart` (`/vendor/*`), and `admin_router.dart` (`/admin/*`).
* Enforce role guards inside each router (`require_role`). If a user logs into the wrong target app, redirect to `/login` with an informational message.


* **Rationale:** Separates user flows across mobile and desktop web targets while guaranteeing hard route-level access controls.

### 2. Code Decoupling & Clean Architecture

* **Action:**
* Extract business logic from fat routers (`app/api/*.py`) into service layers (e.g., move `suspend_vendor` and `vendor_reject` to `app/services/order_service.py`).
* Implement an application factory (`create_app()`) in `backend/app/main.py:22` to replace global `FastAPI()` initialization.
* Consolidate duplicate helper functions (`require_vendor_or_admin`, `_get_or_404`, and status transition logic).
* Introduce a Repository layer in `frontend/lib/shared/api/api_client.dart:27` so UI widgets don't invoke `Dio` directly (e.g., `cart_screen.dart:91`, `vendor_screens.dart:153`).
* Extract misplaced state providers from screen files (`vendor_screens.dart:15`, `admin_screens.dart:11`) into `features/*/providers/`.
* Add `AsyncValueWidget` to deduplicate repetitive `when(data, error, loading)` handlers across `common_widgets.dart:61`.


* **Rationale:** Increases test coverage, streamlines unit testing, and establishes clean code boundaries.

### 3. API Hardening & Router Cleanup

* **Action:**
* Implement pagination (`limit`/`offset`) with `{ "items": [...], "total": N }` wrappers on `GET /api/vendors` and `GET /api/students/me/orders`.
* Convert global `_Signaler` in `frontend/lib/core/router/app_router.dart:20` to a provider-scoped, disposable instance.
* Change `ColorScheme` instantiation in `frontend/lib/core/theme/app_theme.dart:15` to a `static final` object.
* Configure missing security headers (`HSTS`, `TrustedHostMiddleware`) and constrain CORS headers (`allow_headers`) in `backend/app/main.py:33`.


* **Rationale:** Improves payload delivery efficiency, eliminates UI rebuild overhead, and hardens browser security headers.

---

## P3 — Tooling, Quality & Testing

### 1. Developer Tooling & Linting

* **Action:**
* Add `[tool.ruff]`, `[tool.black]`, and `[tool.mypy]` sections to `backend/pyproject.toml`.
* Add strict rules to `frontend/analysis_options.yaml:10`.
* Create root `.pre-commit-config.yaml`, `.editorconfig`, and `.dockerignore` files (prevent copying `.venv` into container builds).
* Synchronize dependency definitions between `backend/requirements.txt` and `backend/pyproject.toml` (e.g., resolve missing `email-validator`).


* **Rationale:** Standardizes formatting, prevents static typing errors, and reduces Docker image sizes.

### 2. CI/CD Pipeline & Infrastructure

* **Action:**
* Add `.github/workflows/ci.yml` running `pytest -v`, `flutter analyze`, `flutter test`, and `docker compose build`.
* Add `.github/dependabot.yml` for automated dependency security patches.
* Update `backend/Dockerfile` with image digest pinning (`python:3.12-slim@sha256:...`), multi-stage builds, and a `HEALTHCHECK CMD curl -f http://localhost:8000/health`.
* Update `docker-compose.yml` to use `env_file`, variable expansion `${VAR:-default}`, `restart: unless-stopped`, and restrict Postgres exposure (`127.0.0.1:5432:5432`).


* **Rationale:** Guarantees repeatable builds, blocks breaking changes at PR phase, and improves production container resiliency.

### 3. Test Coverage Gaps

* **Action:**
* **Backend:** Write unit/integration tests for suspended user blocking (`app/core/dependencies.py:27`), JWT expiration, `PATCH /api/vendors/{id}` permissions (403), menu XSS payloads (`image_url: "javascript:..."`), pagination bounds, and seed idempotency. Add coverage tracking setup.
* **Frontend:** Refactor basic default tests in `frontend/test/widget_test.dart:1` to use `mocktail` and `riverpod_test`. Test `CartController` rules (vendor mismatches, quantity limits 1–20), `AuthController`, and router redirect matrices.


* **Rationale:** Raises confidence in core application behavior and protects business rules against regressions.

### 4. Accessibility (A11y) & Documentation

* **Action:**
* Wrap interactive elements with `Semantics` widgets, replace color-only status indicators in `common_widgets.dart:13` (`StatusBadge`), append `autofillHints` to login forms, enforce scaling dynamic `fontSize`, and add action `Tooltip`s.
* Update `GETTING_STARTED.md` with explicit `.env` setup instructions (`cp .env.example backend/.env`), document the empty database URL in `backend/alembic.ini:4`, and add `CONTRIBUTING.md` and `SECURITY.md`.


* **Rationale:** Ensures compliance with accessibility standards and simplifies contributor onboarding.

---

## Minimal Next PR Checklist

Execute this checklist for your immediate unblocking Pull Request:

* [ ] **Dependencies & Docker:** Pin `psycopg[binary]` in `requirements.txt`/`pyproject.toml`, add `.dockerignore`, configure `USER appuser` and `HEALTHCHECK` in `Dockerfile`.
* [ ] **Security:** Implement `hmac.compare_digest()` for webhooks and `Field(min_length=32)` validation for configuration secrets.
* [ ] **Database Reliability:** Add global `IntegrityError` handler in `main.py` and wrap idempotency checks in `try/except`.
* [ ] **Code Quality & CI:** Add `.pre-commit-config.yaml`, `ruff`/`mypy` configs in `pyproject.toml`, and GitHub Actions workflow `.github/workflows/ci.yml`.
* [ ] **Frontend Fixes:** Migrate token storage to `flutter_secure_storage`, make `CartLine` immutable, and introduce the base Repository layer abstraction.

---

**Last Updated:** September 8, 2026