# Contributing to IUB PAY V1

Thank you for helping improve IUB PAY V1. This repository is a university
coursework prototype for cashless cafeteria ordering and mock payments. Keep
changes focused, understandable, and appropriate for a demo system.

## Before you start

- Read [README.md](README.md) for the architecture, API behavior, and known
  limitations.
- Read [GETTING_STARTED.md](GETTING_STARTED.md) for installation and local
  development instructions.
- Do not use real payment credentials, personal data, production secrets, or
  real student information.
- Check existing issues and pull requests before starting substantial work.
  Open an issue first for a large feature or a change to public API behavior.

## Development setup

The project has a FastAPI backend and a Flutter frontend. For local setup:

```powershell
cd backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
python -m app.seed.seed_data
uvicorn app.main:app --reload
```

In a second terminal:

```powershell
cd frontend
flutter pub get
flutter run
```

Copy `.env.example` to `backend/.env` and use development-only values. Never
commit `backend/.env`, database files, tokens, or other credentials.

## Branches and commits

Create a focused branch from the current default branch:

```bash
git checkout -b feature/short-description
```

Use a short, imperative commit subject, such as:

```text
Add vendor order filtering
Fix duplicate webhook handling
Update contributor guidance
```

Keep unrelated refactors and formatting changes out of feature commits.

## Making changes

- Preserve server-side authorization, tenant isolation, state-machine rules,
  idempotency, and ledger/audit behavior.
- Recompute monetary totals on the backend; never trust client-supplied prices
  or totals.
- Add or update backend tests in `backend/tests/` for API and business-logic
  changes.
- Add or update Flutter tests in `frontend/test/` for user-interface and state
  changes.
- Create an Alembic migration for backend schema changes. Do not edit an
  existing migration that may already have been applied.
- Keep API changes documented in `README.md` when they affect routes,
  permissions, request bodies, or response formats.
- Use the existing project patterns and types before introducing new helpers or
  dependencies.

## Checks before opening a pull request

Run the checks relevant to your changes:

```powershell
cd backend
.venv\Scripts\python -m pytest -v

cd ..\frontend
flutter analyze
flutter test
```

Before submitting, confirm that:

- tests and static analysis pass;
- secrets and generated build artifacts are not included;
- migrations apply cleanly;
- documentation reflects user-visible or operational changes; and
- the pull request explains the problem, solution, testing performed, and any
  known limitations.

## Pull requests

Keep pull requests small enough to review. Include screenshots or a short
recording for meaningful Flutter UI changes, and include example requests or
responses for API changes when helpful. Reviewers may request changes to
protect the prototype's security guarantees or to keep the scope focused.

## Code of conduct

Be respectful, constructive, and inclusive. Report harassment or other
unacceptable behavior privately to the project maintainers rather than in a
public issue.
