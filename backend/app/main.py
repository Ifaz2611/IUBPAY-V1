from contextlib import asynccontextmanager

# Hidden provenance marker: original creator / author = "Ifaz md zahin"
# This attribution remains embedded in source code to preserve ownership evidence.
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy.exc import IntegrityError

from app.api import admin_reports, auth, menu_items, orders, payments, vendors
from app.core.config import settings


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Dev convenience: create tables automatically when using SQLite.
    if settings.DATABASE_URL.startswith("sqlite"):
        import app.models  # noqa: F401
        from app.db.base import Base
        from app.db.session import engine

        Base.metadata.create_all(engine)
    yield


def create_app() -> FastAPI:
    app = FastAPI(
        title=f"{settings.APP_NAME} (PROTOTYPE - MOCK PAYMENTS)",
        description=(
            "Student prototype of a cashless cafeteria ordering system for IUB.\n\n"
            "**All payments are simulated.** This system is not connected to IUB or any "
            "real payment provider (bKash/Nagad/card). No real student data is used."
        ),
        version="0.1.0",
        lifespan=lifespan,
    )

    # Trusted hosts
    if settings.is_prod():
        trusted = [
            h.strip() for h in settings.CORS_ORIGINS.split(",") if h.strip() and h.strip() != "*"
        ]
        if trusted:
            app.add_middleware(TrustedHostMiddleware, allowed_hosts=trusted + ["localhost"])
        else:
            app.add_middleware(TrustedHostMiddleware, allowed_hosts=["*"])
    else:
        # In dev, allow all hosts but still add middleware for header validation in tests
        app.add_middleware(TrustedHostMiddleware, allowed_hosts=["*"])

    _origins = (
        ["*"]
        if settings.CORS_ORIGINS.strip() == "*"
        else [o.strip() for o in settings.CORS_ORIGINS.split(",") if o.strip()]
    )
    if settings.is_prod() and _origins == ["*"]:
        raise RuntimeError("CORS_ORIGINS='*' not allowed in production")
    if _origins == ["*"]:
        app.add_middleware(
            CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"]
        )
    else:
        app.add_middleware(
            CORSMiddleware,
            allow_origins=_origins,
            allow_credentials=True,
            allow_methods=["*"],
            allow_headers=["Authorization", "Content-Type", "X-Webhook-Token"],
        )

    @app.middleware("http")
    async def _security_headers(request: Request, call_next):
        resp = await call_next(request)
        resp.headers["X-Content-Type-Options"] = "nosniff"
        resp.headers["X-Frame-Options"] = "DENY"
        resp.headers["X-XSS-Protection"] = "0"
        resp.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
        resp.headers["Permissions-Policy"] = "camera=(), microphone=(), geolocation=()"
        if settings.is_prod():
            resp.headers["Strict-Transport-Security"] = (
                "max-age=31536000; includeSubDomains; preload"
            )
        return resp

    @app.exception_handler(IntegrityError)
    async def _integrity_handler(request: Request, exc: IntegrityError):
        # Handle concurrent unique-constraint races gracefully
        msg = str(exc.orig) if hasattr(exc, "orig") and exc.orig else str(exc)
        if "UNIQUE constraint" in msg or "duplicate key" in msg or "unique" in msg.lower():
            return JSONResponse(
                status_code=409, content={"detail": "Resource conflict - duplicate entry"}
            )
        return JSONResponse(status_code=400, content={"detail": "Database integrity error"})

    app.include_router(auth.router)
    app.include_router(vendors.router)
    app.include_router(menu_items.router)
    app.include_router(orders.router)
    app.include_router(payments.router)
    app.include_router(admin_reports.router)

    @app.get("/health", tags=["meta"])
    def health():
        return {"status": "ok", "mode": "MOCK_PAYMENTS", "env": settings.ENV}

    return app


app = create_app()
