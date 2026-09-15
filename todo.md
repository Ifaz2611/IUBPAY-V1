---

# TODO.md

## Project Overview

* **Current State:** Functional prototype — P0 security/build + P2 app-separation partially landed on current branch. Unified `main.dart` still ships; split entrypoints coexist.
* **Target State:** Hardened, production-ready application with hard app separation (no unified fallback in release)

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
* Add `Field(min_length=32)` validation to `SECRET_KEY` and `MOCK_PAYMENT_WEBHOOK_TOKEN` in `backend/app/core/config.py:12,21`. — **DONE on this branch** (`min_length=32` + prod fail-fast in `_validate_prod_secrets`).
* Fail-fast on app launch if `ENV=prod` and secrets remain set to weak dev defaults. — **DONE** (`backend/app/core/config.py:44-55`)
* Explicitly reject wildcard `*` CORS origins when `ENV=prod`. — **DONE** (`backend/app/core/config.py:52-53`, `backend/app/main.py:54-55`)

* **Remaining:** Add startup check that `CORS_ORIGINS` parses to valid URLs; add test covering `is_prod()` rejection.

* **Rationale:** Eliminates hardcoded dev secrets and loose cross-origin rules in production environments.

### 2. Auth & Webhook Hardening

* **Action:**
* Use `hmac.compare_digest()` for webhook signature validation in `backend/app/api/payments.py:124`. — **DONE**
* Eliminate the auth timing leak in `backend/app/api/auth.py:19` by running a dummy `verify_password` check when `user is None`. — **TODO (next update)**
* Add rate-limiting middleware/guards to `POST /api/auth/login` and `POST /api/payments/webhook`. — **PARTIAL:** `payments.py` now has in-memory webhook rate-limit (`10/min/IP`, `backend/app/api/payments.py:25-42`); login rate-limit still uses `slowapi` limiter but needs lockout test.
* Hardened JWTs in `backend/app/core/security.py:20`: reduce 12h expiration, add `jti`, `iss`, and `aud` claims, and implement token revocation/blacklisting. — **PARTIAL:** `config.py` now has `JWT_ISSUER`/`JWT_AUDIENCE` and 15m/7d expiries; full `jti` + revocation list still TODO.

* **Rationale:** Defends against timing attacks, password brute-forcing, and stolen token replay.

### 3. Frontend Token & Secret Security

* **Action:**
* Migrate JWT storage in `frontend/lib/shared/api/api_client.dart:7` from `SharedPreferences` (plaintext) to `flutter_secure_storage`. — **DONE** (`api_client.dart:1-26`, `TokenStore` now uses `FlutterSecureStorage`)
* Remove hardcoded dev password (`Passw0rd!Dev`) in `frontend/lib/features/auth/screens/login_screen.dart:15` or wrap with a `kDebugMode` guard. — **TODO**
* Change cleartext endpoint `[http://10.0.2.2:8000/api](http://10.0.2.2:8000/api)` in `frontend/lib/core/constants/app_constants.dart:3` to enforce HTTPS in release builds. — **DONE** (`app_constants.dart:3-25`: `kReleaseMode` enforces `https://`, `kIsWeb` auto-switches to `localhost`)

* **Rationale:** Prevents credential exposure in compiled binaries and protects auth tokens on rooted/jailbroken devices.

### 4. Dependencies & Container Runtime

* **Action:**
* Add missing `psycopg[binary]` to `backend/requirements.txt` and `backend/pyproject.toml:6` (currently causes runtime crash with `postgresql+psycopg://` in `docker-compose.yml:24`). — **TODO: verify** — `pyproject.toml` was updated but confirm `requirements.txt` pins `psycopg[binary]`.
* Remove root execution in `backend/Dockerfile:1` by creating and switching to `USER appuser`. — **DONE** + multi-stage build, `HEALTHCHECK curl` added.

* **Rationale:** Resolves immediate startup crashes and applies least-privilege security to the container runtime.

---

## P1 — Reliability & Correctness

### 1. Database Concurrency & Transactions

* **Action:**
* Register a global `IntegrityError` handler in `backend/app/main.py`. — **DONE** (`main.py:80-86`, returns 409 on duplicate)
* Wrap idempotency checks (`app/services/order_service.py:33`) and double-pay checks (`app/services/payment_service.py:40`) in `try/except IntegrityError` with handle/re-select fallbacks. — **TODO**
* Wrap vendor suspension loop in `backend/app/api/vendors.py:109` in a single database transaction to prevent partial commits on `create_and_process_refund()`. — **TODO** (service already supports `commit=False`; call-site not yet wrapped)

* **Rationale:** Prevents unhandled 500 crashes and state corruption during concurrent API requests.

### 2. Async Execution & Webhook Errors

* **Action:**
* Replace thread-blocking `time.sleep()` in `backend/app/services/payment_service.py:150` with an async handler (`async def` + `asyncio.sleep`). — **PARTIAL:** `simulate_provider_latency_async` added (`payment_service.py:162`) and `mock_complete` is now `async`; `mock_fail` still needs same change.
* Change missing header status code in `backend/app/api/payments.py:115` from `422` to `401` using `Header(None)`. — **DONE** (`401` on missing `X-Webhook-Token`)

* **Rationale:** Stops worker pool starvation under load and standardizes HTTP error contracts.

### 3. Identifiers & Datetime Consistency

* **Action:**
* Replace collision-prone pickup code math `uuid % 10000` in `backend/app/services/order_service.py:70` with a larger space + uniqueness retry check. — **TODO**
* Add retry logic for 6-character hex `order_number` generation on uniqueness collision. — **TODO**
* Resolve naive vs. timezone-aware datetime mismatches between `order_service.py:15` and `models/order.py:31` by standardizing on UTC (`datetime.now(timezone.utc)`). — **DONE** for `payment_service.py:98` (`verified_at` uses `timezone.utc`)

* **Rationale:** Eliminates ordering sequence overlaps and data corruption across timezone offsets.

### 4. Query Performance & PII Protection

* **Action:**
* Refactor `daily()` report in `backend/app/services/report_service.py:57` to aggregate in SQL using `GROUP BY date_trunc('day')` instead of loading all `LedgerEntry` objects into Python memory. — **TODO**
* Add pagination (`limit`/`offset`) to `GET /api/admin/users` in `backend/app/api/admin_reports.py:89`. — **CHECK:** endpoint supports pagination but frontend `admin_providers.dart` still fetches without params; ensure UI passes `limit`/`offset`.

* **Rationale:** Prevents out-of-memory errors on large reporting queries and mitigates full user database scrapability.

### 5. Frontend State & Resource Management

* **Action:**
* Make `CartLine.qty` immutable and provide a `copyWith()` method in `frontend/lib/features/student/providers/student_providers.dart:19` to restore Riverpod value equality. — **TODO (next update — high)**
* Fix memory leak in `frontend/lib/features/student/screens/order_screens.dart:62` by replacing active `Timer.periodic(5s)` with `StreamProvider.autoDispose` paired with a `WidgetsBindingObserver`. — **TODO**

* **Rationale:** Fixes UI re-rendering glitches and eliminates background battery/memory drain.

---

## P2 — Architecture & Separation

### 1. App Separation (Student Mobile vs. Vendor/Admin Web) — CORE FOR NEXT UPDATE

* **Current status — WHY YOU STILL SEE ALL ROLES IN ONE APP:**
  * Split entrypoints **already exist** on this branch: `frontend/lib/main_student.dart` (`StudentApp`), `frontend/lib/main_vendor.dart` (`VendorApp`), `frontend/lib/main_admin.dart` (`AdminApp`) sharing `core/`, `shared/models/`, `shared/api/`.
  * Dedicated routers exist: `frontend/lib/core/router/student_router.dart`, `vendor_router.dart`, `admin_router.dart` with hard `require_role` guards (wrong role -> redirect `/login`).
  * BUT `frontend/lib/main.dart` (`IubCafeteriaApp` + `app_router.dart`) **still exists** as a unified fallback. `flutter run` without `-t` launches `main.dart` by default, so you see student+vendor+admin routes together.
  * **How to test separation now (see also `agent.md` and `docss.md`):**
    ```powershell
    flutter run -t lib/main_student.dart -d windows  # or -d chrome
    flutter run -t lib/main_vendor.dart -d windows
    flutter run -t lib/main_admin.dart -d windows
    flutter run -t lib/main_student.dart -d chrome --dart-define=API_BASE_URL=http://localhost:8000/api
    ```
    Unified app (for comparison): `flutter run -d chrome` or `flutter run -t lib/main.dart -d chrome`

* **Action (next update — must land before release):**
* Keep split entrypoints; **deprecate or gate** `main.dart` — either (a) make it debug-only, or (b) delete it before release, or (c) make it a thin re-export that picks router by role at `/splash`. Document the deprecation in `README.md` / `GETTING_STARTED.md`.
* Extract dedicated routers fully (no shared imports leaking opposite role screens): `student_router.dart` (routes `/splash`, `/login`, `/student/*`), `vendor_router.dart` (`/vendor/*`), `admin_router.dart` (`/admin/*`). — **DONE** (verify no cross-role imports beyond `splash/login`)
* Enforce role guards inside each router (`require_role`). If a user logs into the wrong target app, redirect to `/login` with an informational message. — **DONE** (redirect to `/login` when `user.role != expected`); **TODO**: add `SnackBar`/query-param message `?reason=wrong_role`.
* Add build flavors / `--flavor` or at least README section explaining which entrypoint maps to which deployment target (Student=Android/iOS, Vendor/Admin=Web/Desktop).

* **Rationale:** Separates user flows across mobile and desktop web targets while guaranteeing hard route-level access controls. Current unified `main.dart` is intentionally kept for local dev but must not ship as the production artifact if separation is required.

### 2. Code Decoupling & Clean Architecture

* **Action:**
* Extract business logic from fat routers (`app/api/*.py`) into service layers (e.g., move `suspend_vendor` and `vendor_reject` to `app/services/order_service.py`). — **TODO**
* Implement an application factory (`create_app()`) in `backend/app/main.py:22` to replace global `FastAPI()` initialization. — **DONE** (`main.py:28-99`)
* Consolidate duplicate helper functions (`require_vendor_or_admin`, `_get_or_404`, and status transition logic). — **TODO**
* Introduce a Repository layer in `frontend/lib/shared/api/api_client.dart:27` so UI widgets don't invoke `Dio` directly (e.g., `cart_screen.dart:91`, `vendor_screens.dart:153`). — **DONE** (`frontend/lib/shared/api/repositories.dart`: `OrderRepository`, `VendorRepository`, `MenuRepository`, `PaymentRepository`)
* Extract misplaced state providers from screen files (`vendor_screens.dart:15`, `admin_screens.dart:11`) into `features/*/providers/`. — **DONE** (`features/vendor/providers/vendor_providers.dart`, `features/admin/providers/admin_providers.dart`)
* Add `AsyncValueWidget` to deduplicate repetitive `when(data, error, loading)` handlers across `common_widgets.dart:61`. — **PARTIAL:** `common_widgets.dart` was refactored; confirm `AsyncValueWidget` exists.

* **Rationale:** Increases test coverage, streamlines unit testing, and establishes clean code boundaries.

### 3. API Hardening & Router Cleanup

* **Action:**
* Implement pagination (`limit`/`offset`) with `{ "items": [...], "total": N }` wrappers on `GET /api/vendors` and `GET /api/students/me/orders`. — **DONE** (backend supports both shapes; `_parsePaginated` in `repositories.dart:132`)
* Convert global `_Signaler` in `frontend/lib/core/router/app_router.dart:20` to a provider-scoped, disposable instance. — **DONE** (`Signaler` + `signalerProvider` with `ref.onDispose`)
* Change `ColorScheme` instantiation in `frontend/lib/core/theme/app_theme.dart:15` to a `static final` object. — **DONE / PARTIAL** (check `app_theme.dart:15`)
* Configure missing security headers (`HSTS`, `TrustedHostMiddleware`) and constrain CORS headers (`allow_headers`) in `backend/app/main.py:33`. — **DONE** (`TrustedHostMiddleware`, `allow_headers=["Authorization","Content-Type","X-Webhook-Token"]`, `HSTS` + `X-Frame-Options` etc.)

* **Rationale:** Improves payload delivery efficiency, eliminates UI rebuild overhead, and hardens browser security headers.

---

## P3 — Tooling, Quality & Testing

### 1. Developer Tooling & Linting

* **Action:**
* Add `[tool.ruff]`, `[tool.black]`, and `[tool.mypy]` sections to `backend/pyproject.toml`. — **DONE** (this branch adds `[tool.ruff]`, `[tool.black]`; verify `mypy`)
* Add strict rules to `frontend/analysis_options.yaml:10`. — **DONE** (updated)
* Create root `.pre-commit-config.yaml`, `.editorconfig`, and `.dockerignore` files (prevent copying `.venv` into container builds). — **DONE** (all three created, untracked)
* Synchronize dependency definitions between `backend/requirements.txt` and `backend/pyproject.toml` (e.g., resolve missing `email-validator`). — **TODO**

* **Rationale:** Standardizes formatting, prevents static typing errors, and reduces Docker image sizes.

### 2. CI/CD Pipeline & Infrastructure

* **Action:**
* Add `.github/workflows/ci.yml` running `pytest -v`, `flutter analyze`, `flutter test`, and `docker compose build`. — **DONE** (untracked `.github/workflows/ci.yml` — run `git status` to confirm and commit)
* Add `.github/dependabot.yml` for automated dependency security patches. — **TODO if missing**
* Update `backend/Dockerfile` with image digest pinning (`python:3.12-slim@sha256:...`), multi-stage builds, and a `HEALTHCHECK CMD curl -f http://localhost:8000/health`. — **DONE**
* Update `docker-compose.yml` to use `env_file`, variable expansion `${VAR:-default}`, `restart: unless-stopped`, and restrict Postgres exposure (`127.0.0.1:5432:5432`). — **PARTIAL** (check `docker-compose.yml`)

* **Rationale:** Guarantees repeatable builds, blocks breaking changes at PR phase, and improves production container resiliency.

### 3. Test Coverage Gaps

* **Action:**
* **Backend:** Write unit/integration tests for suspended user blocking (`app/core/dependencies.py:27`), JWT expiration, `PATCH /api/vendors/{id}` permissions (403), menu XSS payloads (`image_url: "javascript:..."`), pagination bounds, and seed idempotency. Add coverage tracking setup. — **TODO**
* **Frontend:** Refactor basic default tests in `frontend/test/widget_test.dart:1` to use `mocktail` and `riverpod_test`. Test `CartController` rules (vendor mismatches, quantity limits 1–20), `AuthController`, and router redirect matrices (student->vendor, vendor->admin). — **TODO**

* **Rationale:** Raises confidence in core application behavior and protects business rules against regressions.

### 4. Accessibility (A11y) & Documentation

* **Action:**
* Wrap interactive elements with `Semantics` widgets, replace color-only status indicators in `common_widgets.dart:13` (`StatusBadge`), append `autofillHints` to login forms, enforce scaling dynamic `fontSize`, and add action `Tooltip`s. — **TODO** (common_widgets badge semantics partially improved)
* Update `GETTING_STARTED.md` with explicit `.env` setup instructions (`cp .env.example backend/.env`), document the empty database URL in `backend/alembic.ini:4`, and add `CONTRIBUTING.md` and `SECURITY.md`. — **PARTIAL:** `.env.example` and `GETTING_STARTED.md` updated this branch; `CONTRIBUTING.md`/`SECURITY.md` still TODO.

* **Rationale:** Ensures compliance with accessibility standards and simplifies contributor onboarding.

---

## Minimal Next PR Checklist

Execute this checklist for your immediate unblocking Pull Request (commit current branch!):

* [x] **Dependencies & Docker:** Pin `psycopg[binary]` in `requirements.txt`/`pyproject.toml`, add `.dockerignore`, configure `USER appuser` and `HEALTHCHECK` in `Dockerfile`. — verify `requirements.txt` pin.
* [x] **Security:** Implement `hmac.compare_digest()` for webhooks and `Field(min_length=32)` validation for configuration secrets. — done.
* [x] **Database Reliability:** Add global `IntegrityError` handler in `main.py` and wrap idempotency checks in `try/except`. — handler done; wrapping still TODO.
* [x] **Code Quality & CI:** Add `.pre-commit-config.yaml`, `ruff`/`mypy` configs in `pyproject.toml`, and GitHub Actions workflow `.github/workflows/ci.yml`. — done (commit untracked files).
* [x] **Frontend Fixes:** Migrate token storage to `flutter_secure_storage`, make `CartLine` immutable, and introduce the base Repository layer abstraction. — token + repository done; `CartLine` immutable still TODO.

### Next Update After That (Priority Order)

1. **Close P2 separation gap:** Gate/deprecate `main.dart`, add wrong-role message, document `-t lib/main_*.dart` in `README.md` + `GETTING_STARTED.md`, add build flavors if targeting separate deploys.
2. **P0 remaining:** timing-leak dummy hash in `auth.py:19`, JWT `jti`/revocation, login lockout tests.
3. **P1 correctness:** `IntegrityError` wrapping for idempotency, `time.sleep` -> `asyncio.sleep` for `mock_fail`, pickup-code / order-number retry, `Timer.periodic` leak, `CartLine` immutability.
4. **P3 tests:** backend auth/pagination/XSS tests + frontend `mocktail` router tests.
5. **Commit & push:** `git add .dockerignore .editorconfig .pre-commit-config.yaml .github/ frontend/lib/main_*.dart frontend/lib/core/router/*_router.dart frontend/lib/shared/api/repositories.dart frontend/lib/features/*/providers/*.dart` then `git commit -m "feat: app separation + security hardening (P0/P2)"`.

---

**Last Updated:** September 15, 2026
