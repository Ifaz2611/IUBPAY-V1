import os

# Must be set before app modules are imported.
os.environ["SECRET_KEY"] = "test-secret-key-32-chars-long-1234567890"
os.environ["DATABASE_URL"] = "sqlite:///:memory:"
os.environ["MOCK_PAYMENT_WEBHOOK_TOKEN"] = "test-webhook-token-32-chars-long-123456"
os.environ["SERVICE_FEE_TAKA"] = "5"

import pytest  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402
from sqlalchemy import create_engine  # noqa: E402
from sqlalchemy.orm import sessionmaker  # noqa: E402
from sqlalchemy.pool import StaticPool  # noqa: E402

from app.core.security import hash_password  # noqa: E402
from app.db.base import Base  # noqa: E402
from app.db.session import get_db  # noqa: E402
from app.main import app  # noqa: E402
from app.models.menu_item import MenuItem  # noqa: E402
from app.models.user import User  # noqa: E402
from app.models.vendor import Vendor  # noqa: E402

TEST_PASSWORD = "Passw0rd!Test"
WEBHOOK_HEADERS = {"X-Webhook-Token": "test-webhook-token-32-chars-long-123456"}

engine = create_engine(
    "sqlite://",
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)


def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = override_get_db


@pytest.fixture(autouse=True)
def setup_db():
    Base.metadata.create_all(engine)
    # Clear webhook rate limiter between tests
    try:
        from app.api.payments import _webhook_attempts

        _webhook_attempts.clear()
        from app.api.auth import _lockouts, _login_attempts

        _login_attempts.clear()
        _lockouts.clear()
    except Exception:  # noqa: S110
        pass
    yield
    Base.metadata.drop_all(engine)


@pytest.fixture
def client():
    return TestClient(app)


@pytest.fixture
def db():
    session = TestingSessionLocal()
    yield session
    session.close()


# ---------- factory helpers ----------


def make_user(db, email, role="student", vendor_id=None, name="Test") -> User:
    u = User(
        name=name,
        email=email,
        password_hash=hash_password(TEST_PASSWORD),
        role=role,
        vendor_id=vendor_id,
    )
    db.add(u)
    db.commit()
    db.refresh(u)
    return u


def make_vendor(db, name="Vendor One") -> Vendor:
    v = Vendor(name=name, location="Loc", status="APPROVED")
    db.add(v)
    db.commit()
    db.refresh(v)
    return v


def make_menu_item(db, vendor_id, name="Chicken Biryani", price=180) -> MenuItem:
    mi = MenuItem(vendor_id=vendor_id, name=name, price_taka=price)
    db.add(mi)
    db.commit()
    db.refresh(mi)
    return mi


def login_headers(client, email, password=TEST_PASSWORD) -> dict:
    r = client.post("/api/auth/login", json={"email": email, "password": password})
    assert r.status_code == 200, r.text
    return {"Authorization": f"Bearer {r.json()['access_token']}"}


def student_client(db, client, suffix="a") -> tuple[dict, User]:
    user = make_user(db, f"student{suffix}@test.bd", name=f"Student {suffix.upper()}")
    return login_headers(client, user.email), user


def vendor_pair(db, client, vendor_name="Vendor One", suffix="a"):
    """Creates a vendor + linked staff account. Returns (vendor, item_factory, headers)."""
    vendor = make_vendor(db, vendor_name)

    def add_item(name="Chicken Biryani", price=180):
        return make_menu_item(db, vendor.id, name, price)

    user = make_user(
        db, f"vendorstaff{suffix}@test.bd", role="vendor", vendor_id=vendor.id, name="Vendor Staff"
    )
    return vendor, add_item, login_headers(client, user.email)


def place_order(client, headers, vendor_id, items) -> dict:
    import uuid

    body = {
        "vendor_id": vendor_id,
        "items": items,
        "idempotency_key": uuid.uuid4().hex,
    }
    r = client.post("/api/orders", json=body, headers=headers)
    assert r.status_code == 201, r.text
    return r.json()


def pay_order(client, headers, order_id) -> dict:
    r = client.post("/api/payments/create", json={"order_id": order_id}, headers=headers)
    assert r.status_code == 201, r.text
    return r.json()
