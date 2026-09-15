

How to start (Windows):
Backend:
cp .env.example backend/.env   # edit SECRET_KEY etc if needed
# Docker (easiest):
docker compose up --build       # http://localhost:8000/docs, seed runs auto
# OR local:
cd backend
python -m venv .venv && .venv\Scripts\activate
pip install -r requirements.txt
alembic upgrade head
python -m app.seed.seed_data
uvicorn app.main:app --reload   # keep open
================================================
Frontend (frontend/lib/main.dart:1 is unified, main_student/vendor/admin.dart are split entrypoints):
cd frontend
flutter pub get
flutter analyze        # → 995 infos, 0 errors
flutter test           # → 1 passed

# default unified app:
flutter run -d chrome
flutter run -d windows

# split apps (per todo):
flutter run -t lib/main_student.dart -d windows  # StudentApp localhost:8000
flutter run -t lib/main_vendor.dart -d windows   # VendorApp
flutter run -t lib/main_admin.dart -d windows    # AdminApp

# physical phone on same WiFi:
flutter run --dart-define=API_BASE_URL=http://<PC_LAN_IP>:8000/api

# release (enforces HTTPS in lib/core/constants/app_constants.dart:8):
flutter run --dart-define=API_BASE_URL=https://api.example.com/api --release
Test accounts (Passw0rd!Dev): student@iub.test, vendor@iub.test, admin@iub.test.



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
# Chrome
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




-----------------------------------------------------------------

This is frontend/lib/core/constants/app_constants.dart:3 - default API is Android emulator only:
const String kApiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8000/api');
10.0.2.2 = Android emulator -> host loopback. Chrome runs on host, it can't reach 10.0.2.2 -> DioExceptionType.connectionError -> frontend/lib/shared/api/api_client.dart:48 Cannot reach the server.
Fix (no code change) - when running on Chrome:
Stop current flutter run, then:
# 1. Verify backend is actually up (should return {"status":"ok"})
curl http://localhost:8000/health
# or open in browser: http://localhost:8000/docs

# 2. Run with overridden URL
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000/api
If backend is Docker docker compose up --build -> same URL http://localhost:8000/api. If backend is uvicorn --port 8000 -> same.
Permanent fix (so flutter run -d chrome works without --dart-define):
Want me to patch it? Replace frontend/lib/core/constants/app_constants.dart:1-6 with:
import 'package:flutter/foundation.dart';

const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: kIsWeb ? 'http://localhost:8000/api' : 'http://10.0.2.2:8000/api',
);
Then Chrome defaults to localhost, Android emulator still defaults to 10.0.2.2, and --dart-define=API_BASE_URL=http://<your-lan-ip>:8000/api still overrides both for physical device.
Check: after applying, do flutter run -d chrome again (hot-restart not enough - need full restart for String.fromEnvironment).
If still Cannot reach after fix, check http://localhost:8000/health in same Chrome - if that fails, backend isn't listening on 8000 (check terminal where uvicorn / docker compose is running).




----------------------------------------------------------------------------------

In  todo.md , P2 means medium-priority architecture work. The “separation” mainly refers to separating the frontend applications by user role:

1. Three separate app entrypoints

Instead of one frontend app handling every user type, create:

•  main_student.dart  →  StudentApp 
•  main_vendor.dart  →  VendorApp 
•  main_admin.dart  →  AdminApp 

They should still share common code:

•  core/ 
•  shared/models/ 
•  shared/api/ 

So the apps are separated at the entrypoint and user-flow level, but do not duplicate common functionality.

2. Separate routers

Each app gets its own router:

•  student_router.dart 
•  /splash 
•  /login 
•  /student/* 
•  vendor_router.dart 
•  /vendor/* 
•  admin_router.dart 
•  /admin/* 

This prevents student, vendor, and admin screens from being mixed in one large router.

3. Role protection

Each router checks the logged-in user’s role using something like  require_role .

For example:

• A student opening the vendor app is rejected.
• A vendor trying to access  /admin/*  is rejected.
• If the user opens the wrong application, they are redirected to  /login  with an informational message.

This is route-level separation, so hiding buttons in the UI is not the only protection.

4. Backend and code separation

The second part of P2 separates responsibilities inside the code:

• API routers should handle HTTP requests only.
• Business logic should move into service classes/functions.
• Database access should be separated into repository layers.
• UI widgets should call repositories instead of using  Dio  directly.
• Providers should move out of screen files into  features/*/providers/ .

For example, instead of putting vendor rejection logic directly inside an API route:

API route → OrderService → Repository → Database

The overall goal is:

Student app     Vendor app     Admin app
      \             |             /
       Shared core, models, and API

This makes each app easier to maintain, test, deploy, and secure.