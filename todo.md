This codebase is functional prototype but needs hardening before production. Prioritized improvements:
P0 — Security / Breaks Build
- backend/app/core/config.py:12,21 SECRET_KEY/MOCK_PAYMENT_WEBHOOK_TOKEN have weak dev defaults with no fail-fast when ENV=prod. Add Field(min_length=32) validation + reject * CORS in prod.
- backend/app/api/payments.py:124 non-constant-time webhook compare → hmac.compare_digest(). app/api/auth.py:19 timing leak (dummy verify_password when user is None). No rate-limit on POST /api/auth/login and POST /api/payments/webhook.
- backend/app/core/security.py:20 12h JWT, no jti/iss/aud, no revocation/blacklist. frontend/lib/shared/api/api_client.dart:7 stores JWT in SharedPreferences plaintext → migrate to flutter_secure_storage.
- frontend/lib/core/constants/app_constants.dart:3 default http://10.0.2.2:8000/api (cleartext) + frontend/lib/features/auth/screens/login_screen.dart:15 hardcoded Passw0rd!Dev shipped in release binary (guard with kDebugMode).
- backend/requirements.txt + backend/pyproject.toml:6 missing psycopg[binary] but docker-compose.yml:24 uses postgresql+psycopg:// → runtime crash. backend/Dockerfile:1 runs as root.
P1 — Reliability / Correctness
- backend/app/main.py no global IntegrityError handler; race on app/services/order_service.py:33 idempotency check and app/services/payment_service.py:40 double-pay → concurrent requests get 500 vs handled re-select. Wrap with try/except IntegrityError.
- backend/app/services/payment_service.py:150 time.sleep() blocks worker; use async def + asyncio.sleep. backend/app/api/payments.py:115 webhook missing header returns 422 not 401 → Header(None).
- backend/app/api/vendors.py:109 suspend loop commits per-order create_and_process_refund() partially → wrap in single transaction. backend/app/services/order_service.py:70 pickup code uuid % 10000 (10k collisions), order_number 6-hex no uniqueness retry. Mixed naive/aware datetime (order_service.py:15 vs models/order.py:31).
- backend/app/services/report_service.py:57 daily() loads all LedgerEntry into Python then buckets; replace with GROUP BY date_trunc('day'). backend/app/api/admin_reports.py:89 GET /api/admin/users no pagination → PII enumeration/DoS.
- frontend/lib/features/student/providers/student_providers.dart:19 CartLine.qty mutable + shallow map copy → breaks Riverpod equality; make immutable + copyWith. frontend/lib/features/student/screens/order_screens.dart:62 Timer.periodic(5s) leaks when backgrounded; use StreamProvider.autoDispose + WidgetsBindingObserver.
P2 — Architecture
- backend/app/api/*.py fat routers import select/joinedload; move suspend_vendor, vendor_reject to app/services/order_service.py. Add create_app() factory in backend/app/main.py:22 (currently global FastAPI()) for testability. Unify duplicated require_vendor_or_admin, _get_or_404, transition+refund helpers.
- frontend/lib/shared/api/api_client.dart:27 Dio called directly from widgets (cart_screen.dart:91, vendor_screens.dart:153, etc.) → add Repository layer. Providers defined inside screen files (vendor_screens.dart:15, admin_screens.dart:11) → extract to features/*/providers/. Add AsyncValueWidget to dedup 12× when(loading/error) in common_widgets.dart:61.
- No pagination on GET /api/vendors, GET /api/students/me/orders; add limit/offset + wrapper {items,total}. frontend/lib/core/router/app_router.dart:20 global _Signaler leaks across ProviderScope; make provider-scoped + dispose. frontend/lib/core/theme/app_theme.dart:15 recreates ColorScheme per build → static final.
- Missing security headers (HSTS, TrustedHostMiddleware), CORS allow_headers=["*"] with allow_credentials=True in backend/app/main.py:33.
P3 — Tooling / Quality
- backend/pyproject.toml only has pytest; missing [tool.ruff], [tool.black], [tool.mypy]. No frontend/analysis_options.yaml:10 strict rules, no .pre-commit-config.yaml, no .editorconfig, no .dockerignore (copies .venv into image). backend/requirements.txt vs pyproject.toml drift (email-validator missing in pyproject).
- No CI (.github/workflows missing) — README roadmap item 10 calls this out. Add ci.yml for pytest -v, flutter analyze, flutter test, docker compose build + dependabot.yml.
- backend/Dockerfile:1 needs USER appuser, HEALTHCHECK CMD curl -f http://localhost:8000/health, pinned digest python:3.12-slim@sha256:..., multi-stage. docker-compose.yml needs env_file, ${VAR:-default}, restart: unless-stopped, restrict 5432:127.0.0.1:5432.
P3 — Testing / A11y / Docs
- Backend: 31 tests miss suspended-user block (app/core/dependencies.py:27), token expiry, PATCH /api/vendors/{id} 403, menu XSS (image_url javascript:), pagination boundaries, seed idempotency. No coverage config.
- Frontend: frontend/test/widget_test.dart:1 only taka(180) → add CartController (vendor mismatch, qty 1..20), AuthController, router redirect matrix, mocktail + riverpod_test.
- Frontend a11y: 0 Semantics hits, StatusBadge common_widgets.dart:13 color-only, no autofillHints on login, fixed fontSize. Needs Semantics, contrast pass, Tooltip.
- Docs: GETTING_STARTED.md missing cp .env.example backend/.env step, no prod hardening checklist, no CONTRIBUTING.md/SECURITY.md. backend/alembic.ini:4 empty URL undocumented.
Minimal next PR: 1) pin psycopg[binary] + Dockerfile non-root/healthcheck/.dockerignore, 2) hmac.compare_digest + secret validation, 3) IntegrityError handler + atomic idempotency, 4) add ruff/mypy/pre-commit + ci.yml, 5) flutter_secure_storage + immutable CartLine + repository layer.








--------------------------------------------------



A. Restart backend with external bind: Stop current terminal (Ctrl+C) and restart:
cd backend
.venv\Scripts\activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
Verify: curl.exe http://192.168.0.103:8000/health should now return ok (currently fails). Allow Windows Firewall prompt if shown.



B. Run frontend with correct API_BASE_URL:
cd frontend
# Windows desktop
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:8000/api
# Chrome / Edge
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000/api
# Physical Android phone (same Wi-Fi, USB debugging)
flutter run --dart-define=API_BASE_URL=http://192.168.0.103:8000/api
# Android emulator ONLY (when you create one)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
# or just `flutter run` - default is correct for emulator
Use http://127.0.0.1:8000/api if localhost gives IPv6 issues on Windows.
Then login: student@iub.test / Passw0rd!Dev
Permanent fix (optional) so you don't need dart-define every time
I can patch frontend/lib/core/constants/app_constants.dart:3 to auto-detect platform (kIsWeb -> localhost, android -> 10.0.2.2, windows/others -> localhost) and only use API_BASE_URL when explicitly passed. Want me to apply it?