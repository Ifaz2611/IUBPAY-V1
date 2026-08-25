# Getting Started — New Developer Guide

Welcome! This guide covers **everything you need to install** and the **basics of
running and editing** this project, even if you have never used Flutter before.

---

## 1. What to install first

| # | Tool | Why you need it | Download |
|---|------|-----------------|----------|
| 1 | **Git** | Clone & version control | https://git-scm.com/downloads |
| 2 | **Flutter SDK** | The app framework (includes Dart) | https://docs.flutter.dev/get-started/install/windows |
| 3 | **VS Code** (+ Flutter extension) or **Android Studio** (+ Flutter plugin) | Code editor with hot reload, debugger | https://code.visualstudio.com / https://developer.android.com/studio |
| 4 | **Python 3.11+** | Run the backend API | https://www.python.org/downloads/ |
| 5 | **Docker Desktop** *(optional)* | One-command backend + PostgreSQL | https://www.docker.com/products/docker-desktop |

### After installing Flutter — verify it

Open a terminal:

```bash
flutter doctor
```

Fix anything it marks with an ✗ before continuing (it tells you exactly what to do).
At minimum you want Flutter, a device platform (Windows/Chrome/Android), and no
missing licenses for Android.

> 💡 Add `flutter/bin` to your system PATH if `flutter` is not recognized.

---

## 2. Get the project running

This project has **two parts**: a Python backend (API) and a Flutter frontend (app).

### Step A — Start the backend

**Option 1 — Docker (easiest):**

```bash
docker compose up --build
```

Backend runs at http://localhost:8000 · Swagger docs at http://localhost:8000/docs
Migrations and seed data run automatically.

**Option 2 — Local Python (no Docker):**

```bash
cd backend

# Windows PowerShell / CMD
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt

python -m app.seed.seed_data        # creates test users, vendors, menus
uvicorn app.main:app --reload       # starts the API
```

Leave this terminal open while developing.

### Step B — Run the Flutter app

Open a **second terminal** in the repo root:

```bash
cd frontend
flutter pub get                     # download dependencies (first time only)
flutter devices                     # see where you can run
flutter run                         # run on default/emulated device
```

Common targets:

```bash
flutter run -d chrome               # run in web browser
flutter run -d windows              # run as Windows desktop app
flutter run --dart-define=API_BASE_URL=http://<your-lan-ip>:8000/api   # physical phone
```

> Default base URL is `http://10.0.2.2:8000/api` (Android emulator → your PC).

---

## 3. Test accounts (seeded)

Password for **every** account: `Passw0rd!Dev`

| Role | Email |
|---|---|
| Student | `student@iub.test` |
| Vendor staff | `vendor@iub.test` |
| Vendor staff | `vendor2@iub.test` |
| Admin | `admin@iub.test` |

Log in with each role to explore the student app, vendor dashboard, and admin panel.

---

## 4. Basics of editing the code

### Where things live

```
frontend/lib/
├── main.dart            ← app entry point (start reading here)
├── core/                ← theme, router, shared widgets
├── features/
│   ├── auth/            ← splash, login screens
│   ├── student/         ← browse, cart, checkout, tracking
│   ├── vendor/          ← vendor dashboard, menu management
│   └── admin/           ← admin panel, reports
backend/app/
├── api/                 ← API endpoints (routers)
├── services/            ← business logic
├── models/              ← database tables
└── seed/seed_data.py    ← dev test data
```

### Hot reload — your best friend 🔥

With `flutter run` active, **save any file (Ctrl+S)** and the app updates instantly.
In the terminal:

- `r` → hot reload (fast, keeps state)
- `R` → hot restart (full reset)
- `q` → quit

### Everyday commands

```bash
flutter pub get          # install dependencies after pulling changes
flutter analyze          # check code for errors/lints
flutter test             # run frontend tests
flutter clean            # nuke build cache when weird errors appear
```

Backend tests:

```bash
cd backend
.venv\Scripts\python -m pytest -v
```

---

## 5. Golden rules

1. **Never commit `.env`, secrets, or keys** (`.gitignore` handles most of it — still double-check).
2. Pull latest (`git pull`) and run `flutter pub get` before starting work each day.
3. Create a branch per feature: `git checkout -b my-feature`.
4. If the app behaves strangely → try `flutter clean && flutter pub get && flutter run`.
5. Read [`README.md`](README.md) for full architecture, API docs, and security notes.

---

## 6. Learning resources

- Flutter basics codelab (~30 min): https://docs.flutter.dev/get-started/codelab
- Dart language tour: https://dart.dev/language
- Riverpod (state management): https://riverpod.dev
- FastAPI docs: https://fastapi.tiangolo.com
