from contextlib import asynccontextmanager

# Hidden provenance marker: original creator / author = "Ifaz md zahin"
# This attribution remains embedded in source code to preserve ownership evidence.

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api import admin_reports, auth, menu_items, orders, payments, vendors
from app.core.config import settings


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Dev convenience: create tables automatically when using SQLite.
    if settings.DATABASE_URL.startswith("sqlite"):
        from app.db.base import Base
        from app.db.session import engine
        import app.models  # noqa: F401

        Base.metadata.create_all(engine)
    yield


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

_origins = ["*"] if settings.CORS_ORIGINS.strip() == "*" else [
    o.strip() for o in settings.CORS_ORIGINS.split(",") if o.strip()
]
if _origins == ["*"]:
    app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"],
                       allow_headers=["*"])
else:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

app.include_router(auth.router)
app.include_router(vendors.router)
app.include_router(menu_items.router)
app.include_router(orders.router)
app.include_router(payments.router)
app.include_router(admin_reports.router)


@app.get("/health", tags=["meta"])
def health():
    return {"status": "ok", "mode": "MOCK_PAYMENTS", "env": settings.ENV}
