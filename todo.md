# TODO — IUB PAY V1

**Current state:** Production-ready prototype. All P0, P1, P2, and P3 items have
landed and passed verification: security hardening (startup CORS checks, prod
secret validation, lockout tests, JWT claims + revocation), app separation
(discrete role entrypoints + guarded routers), test coverage (82% backend
coverage + comprehensive frontend provider/router suites), and documentation.

---

## Priority legend

| Level | Meaning |
|-------|---------|
| **P0 — Blocker** | Security/auth/build issues that must be fixed before release. |
| **P1 — High** | Data correctness, concurrency, reliability, and resource-leak fixes. |
| **P2 — Medium** | Architecture, app separation, maintainability refactors. |
| **P3 — Low** | Tooling, CI, test coverage, accessibility, documentation. |

---

## P0 — Security & Build (Blocker)

### 1. Backend config & secrets — done

Done in `backend/app/core/config.py` and `backend/app/main.py`:

- `SECRET_KEY` / `MOCK_PAYMENT_WEBHOOK_TOKEN` enforce `min_length=32`.
- Production (`ENV=prod`) fails fast on weak defaults, short keys, wildcard CORS, or test registration.
- Wildcard CORS origins are rejected in prod (`backend/app/main.py`).
- [x] Add a startup check that `CORS_ORIGINS` parses to valid URLs (`_validate_cors_origins` validator and `create_app()` startup check).
- [x] Add a test covering the `is_prod()` secret rejection (`backend/tests/test_config_security.py`).

### 2. Auth & webhook hardening — done

Done:

- Webhook signature uses `hmac.compare_digest` (`backend/app/api/payments.py`).
- Login timing leak fixed — dummy `verify_password` runs when user is `None`
  (`backend/app/api/auth.py:29,56`).
- Webhook endpoint has in-memory rate limiting (10/min/IP).
- Login has in-memory rate limiting + account lockout (5 failed attempts -> 15 min lock).
- [x] Test the login lockout after repeated failures (`backend/tests/test_auth.py`).
- [x] JWTs: `JWT_ISSUER`/`JWT_AUDIENCE` and short expiries exist in config —
      `iss`/`aud` are set and validated in `security.py`, and `jti` + token revocation/blacklist
      are implemented and verified (`backend/tests/test_todo_audit_coverage.py`, `backend/tests/test_auth.py`).

### 3. Frontend token & secret security — done

- JWTs stored via `flutter_secure_storage` (`shared/api/api_client.dart` `TokenStore`).
- Dev password `Passw0rd!Dev` is wrapped in `kDebugMode` guards
  (`features/auth/screens/login_screen.dart`).
- `app_constants.dart` enforces HTTPS in release builds and auto-switches
  `localhost` on web.

### 4. Dependencies & container runtime — done

Done:

- `psycopg[binary]` and `email-validator` are pinned in **both**
  `requirements.txt` and `pyproject.toml`.
- `backend/Dockerfile` is multi-stage with `USER appuser` and a `HEALTHCHECK`.
- [x] `docker-compose.yml` restricts Postgres port to `127.0.0.1:5432:5432`.
- [x] `docker-compose.yml` defaults `CORS_ORIGINS` to explicit local origins (`http://localhost:8000,http://127.0.0.1:8000,http://localhost:3000`).

---

## P1 — Reliability & Correctness

### 1. Database concurrency & transactions — done

- Global `IntegrityError` → 409 handler in `backend/app/main.py`.
- Idempotency checks wrapped with `IntegrityError` fallbacks in
  `order_service.py` and `payment_service.py`.
- Vendor suspension refund loop wrapped in a single transaction
  (`api/vendors.py`).

### 2. Async execution & webhook errors — done

- `time.sleep` replaced with `asyncio.sleep` in payment service.
- Missing `X-Webhook-Token` header returns 401 (was 422).

### 3. Identifiers & datetime consistency — done

- `order_number` and `pickup_code` generation retry on uniqueness collision
  (`order_service.py:16-40`).
- Datetimes standardized on UTC.

### 4. Query performance & PII — done

- `daily()` report aggregates in SQL (`GROUP BY` on date) with a Python
  fallback for SQLite (`report_service.py:75-149`).
- `GET /api/admin/users` pagination wired through the frontend:
  `adminUsersPageProvider` (family on offset, `limit`/`offset` params) +
  `adminUsersTotalProvider`; `UserManagementScreen` has prev/next paging with
  an "x–y of N" footer; the dashboard KPI uses the real `total` instead of the
  page length (`admin_providers.dart`, `admin_report_screens.dart`).
- `transactions_csv` is bounded: replaced by `stream_transactions_csv()`,
  which streams row-by-row via `StreamingResponse` using `yield_per` chunked
  fetches — the full payment history is never materialised in memory
  (`report_service.py`, `admin_reports.py`).

Tests: `backend/tests/test_admin_pagination_export.py` (pagination envelope,
page disjointness, backward-compat unpaginated list, CSV stream shape +
endpoint streaming).

### 5. Frontend state & resource management — done

- `CartLine` is immutable with `copyWith()` (`student_providers.dart:33-38`).
- Order-tracking `Timer.periodic` cancels on terminal statuses and pauses on
  app background (`order_screens.dart:98-139`); payment-result polling
  cancels on terminal states (`payment_result_screen.dart:23-39`).
- `SplashScreen` timer cancelled on dispose to prevent timer leaks.

---

## P2 — Architecture & Separation

### 1. App separation — done

Done:

- Four entrypoints exist: `main.dart` (unified demo, deprecated for release), `main_student.dart`,
  `main_vendor.dart`, `main_admin.dart`.
- Role-scoped routers (`student_router.dart`, `vendor_router.dart`,
  `admin_router.dart`) with hard `require_role` guards that redirect to
  `/login?reason=wrong_role` and clear the unauthorized session.
- [x] **Deprecate or remove `main.dart` + `app_router.dart` before release** —
      annotated with `@deprecated` doc blocks for standalone role entrypoints.
- [x] Document entrypoint → target mapping in `README.md` / `GETTING_STARTED.md`
      (Student = Android/iOS, Vendor/Admin = Web/Desktop) and/or add
      `--flavor` build configs.
- [x] Final check: no cross-role screen imports leak between the split
      routers (shared `splash`/`login` are fine).

**Testing the split apps:**

```powershell
cd frontend
flutter run -t lib/main_student.dart -d windows
flutter run -t lib/main_vendor.dart -d windows
flutter run -t lib/main_admin.dart -d windows
flutter run -t lib/main_student.dart -d chrome --dart-define=API_BASE_URL=http://localhost:8000/api
```

### 2. Code decoupling — done

Done:

- `create_app()` factory in `backend/app/main.py`.
- Repository layer: `shared/api/repositories.dart`
  (`OrderRepository`, `VendorRepository`, `MenuRepository`, `PaymentRepository`).
- Providers extracted to `features/{vendor,admin}/providers/`.
- `AsyncValueWidget` exists (`core/widgets/common_widgets.dart:611`).
- Pagination (`limit`/`offset`, `{items,total,...}`) on list endpoints; the
  client handles both paginated and legacy shapes (`repositories.dart`).
- Provider-scoped `Signaler` in routers.
- [x] Move fat-router business logic (e.g. `suspend_vendor`, order status
      transitions) from `api/*.py` into `services/`.
- [x] Consolidate duplicated helpers (`require_vendor_or_admin`,
      `_get_or_404`, status-transition checks).
- [x] Audit for remaining direct `dioProvider` calls in screens that should go
      through repositories.
- [x] Verify `ColorScheme`/theme objects are `static final` (no per-build
      allocation) in `core/theme/app_theme.dart`.

### 3. API hardening — done

- `TrustedHostMiddleware`, constrained `allow_headers`, HSTS, `X-Frame-Options`
  etc. in `main.py`.
- SSE endpoint `GET /api/payments/{order_id}/stream` with frontend polling
  fallback.

---

## P3 — Tooling, Quality & Testing

### 1. Developer tooling — done

Done:

- `[tool.ruff]` / `[tool.black]` in `backend/pyproject.toml` (verify `mypy`).
- Strict lint rules in `frontend/analysis_options.yaml`.
- `.pre-commit-config.yaml`, `.editorconfig`, `.dockerignore`,
  `.github/workflows/ci.yml` exist.
- `mypy` verified: `mypy app` passes clean (42 source files).
- Dependency sync audited: runtime deps identical in `requirements.txt` and
  `pyproject.toml`; dev tools (`ruff`/`black`/`mypy`/`pytest*`/`httpx`/`pytest-cov`) in
  `backend/requirements-dev.txt` and `pyproject.toml` dev extras.
- `.github/dependabot.yml` present and extended: pip / docker / pub /
  github-actions ecosystems, weekly, commit-message prefixes, dev-dep
  grouping, open-PR limits.

### 2. CI/CD & infra — done

Done:

- CI workflow runs backend pytest + frontend analyze/test + docker build.
- Dockerfile pinned digest, multi-stage, non-root, healthcheck.
- Compose has `env_file`, `${VAR:-default}` expansion, `restart: unless-stopped`.
- CI installs `requirements-dev.txt` (single source; no ad-hoc pip install).
- Postgres port binding restricted to `127.0.0.1:5432:5432` (loopback only).
- Compose `CORS_ORIGINS` default tightened from `*` to explicit local dev
  origins; comment documents that prod must override (backend already fails
  fast on `ENV=prod` + `*`).

### 3. Test coverage gaps — done

Backend:

- [x] Tests for suspended-user blocking (`core/dependencies.py`), JWT
      expiration/`iss`/`aud`, `PATCH /api/vendors/{id}` permissions (403),
      menu `image_url` XSS payloads, pagination bounds, seed idempotency
      (`backend/tests/test_todo_audit_coverage.py`).
- [x] Coverage tracking setup (`pytest-cov`, `--cov=app --cov-report=term-missing`, 82% coverage across 73 tests).

Frontend:

- [x] Replace default widget test with `mocktail`/`riverpod_test` suites:
      `CartController` rules (vendor mismatch, qty 1–20 in `widget_test.dart`),
      `AuthController` (in `auth_controller_test.dart`),
      router redirect matrix (wrong-role cases in `router_redirect_test.dart`).

### 4. Accessibility & docs — done

Done:

- [x] `Semantics` wrappers, non-color-only `StatusBadge` / `StatusChip` with dot + text + semantic labels + tooltips,
      `autofillHints` on login (`[AutofillHints.email]`, `[AutofillHints.password]`),
      dynamic font scaling, action `Tooltip`s.
- [x] `CONTRIBUTING.md` and `SECURITY.md` verified and in place.

---

**Last updated:** 2026-11-10
