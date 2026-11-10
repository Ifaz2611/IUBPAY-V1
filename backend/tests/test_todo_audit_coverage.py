"""Tests targeting specific coverage items listed in todo.md:

- Suspended-user blocking (core/dependencies.py)
- Non-existent user blocking (core/dependencies.py)
- JWT expiration, iss, aud, jti, and revocation verification (core/security.py)
- PATCH /api/vendors/{id} permissions (403 for non-admin, 200 for admin)
- Menu image_url XSS payloads rejection (422)
- Pagination bounds validation (422 for limit/offset violations)
- Seed idempotency (seed_data.run executes safely multiple times)
"""

import uuid
from datetime import UTC, datetime, timedelta

import jwt
import pytest

from app.core.config import settings
from app.core.security import create_access_token, decode_access_token, revoke_token
from app.models.user import User
from app.models.vendor import Vendor
from app.utils.enums import UserStatus
from tests.conftest import (
    TEST_PASSWORD,
    admin_client,
    make_user,
    student_client,
    vendor_pair,
)

# ─── 1. Suspended-user & user existence blocking ───────────────────────────────

def test_suspended_user_blocked_with_403(client, db):
    u = make_user(db, "suspended@test.bd", role="student")
    u.status = UserStatus.SUSPENDED
    db.commit()

    # Login attempt should be rejected with 403
    r_login = client.post(
        "/api/auth/login",
        json={"email": "suspended@test.bd", "password": TEST_PASSWORD},
    )
    assert r_login.status_code == 403
    assert "suspended" in r_login.json()["detail"].lower()

    # Even with a valid unexpired token generated before suspension:
    token = create_access_token(subject=u.id, role=u.role.value)
    headers = {"Authorization": f"Bearer {token}"}
    r_me = client.get("/api/auth/me", headers=headers)
    assert r_me.status_code == 403
    assert "suspended" in r_me.json()["detail"].lower()


def test_nonexistent_user_token_blocked_with_401(client, db):
    # Valid token signed with correct secret, but sub user does not exist in DB
    fake_user_id = str(uuid.uuid4())
    token = create_access_token(subject=fake_user_id, role="student")
    headers = {"Authorization": f"Bearer {token}"}

    r = client.get("/api/auth/me", headers=headers)
    assert r.status_code == 401
    assert "user no longer exists" in r.json()["detail"].lower()


def test_malformed_or_garbage_token_rejected_with_401(client):
    headers = {"Authorization": "Bearer invalid.garbage.token"}
    r = client.get("/api/auth/me", headers=headers)
    assert r.status_code == 401
    assert "invalid or expired token" in r.json()["detail"].lower()


# ─── 2. JWT claims, expiration, iss/aud, and revocation ────────────────────────

def test_jwt_expired_token_rejected():
    now = datetime.now(UTC)
    expired_payload = {
        "sub": "user-123",
        "role": "student",
        "jti": uuid.uuid4().hex,
        "iss": settings.JWT_ISSUER,
        "aud": settings.JWT_AUDIENCE,
        "type": "access",
        "iat": now - timedelta(hours=2),
        "exp": now - timedelta(hours=1),
    }
    expired_token = jwt.encode(
        expired_payload, settings.SECRET_KEY, algorithm=settings.JWT_ALGORITHM
    )

    with pytest.raises(jwt.ExpiredSignatureError):
        decode_access_token(expired_token)


def test_jwt_wrong_issuer_rejected():
    now = datetime.now(UTC)
    payload = {
        "sub": "user-123",
        "role": "student",
        "jti": uuid.uuid4().hex,
        "iss": "rogue-issuer",
        "aud": settings.JWT_AUDIENCE,
        "type": "access",
        "iat": now,
        "exp": now + timedelta(minutes=15),
    }
    token = jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.JWT_ALGORITHM)

    with pytest.raises(jwt.InvalidIssuerError):
        decode_access_token(token)


def test_jwt_wrong_audience_rejected():
    now = datetime.now(UTC)
    payload = {
        "sub": "user-123",
        "role": "student",
        "jti": uuid.uuid4().hex,
        "iss": settings.JWT_ISSUER,
        "aud": "rogue-audience",
        "type": "access",
        "iat": now,
        "exp": now + timedelta(minutes=15),
    }
    token = jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.JWT_ALGORITHM)

    with pytest.raises(jwt.InvalidAudienceError):
        decode_access_token(token)


def test_jwt_token_type_mismatch_rejected():
    # Attempting to use a refresh token as an access token
    token = create_access_token("user-123", "student")
    with pytest.raises(jwt.InvalidTokenError, match="Invalid token type: expected refresh"):
        decode_access_token(token, verify_type="refresh")


def test_jwt_revocation_and_blacklist():
    token = create_access_token("user-123", "student")
    payload = decode_access_token(token)
    assert payload["sub"] == "user-123"

    # Revoke the token
    revoke_token(token)

    # Subsequent decode fails with revoked token error
    with pytest.raises(jwt.InvalidTokenError, match="Token revoked"):
        decode_access_token(token)


# ─── 3. PATCH /api/vendors/{id} permissions (403 for non-admin) ────────────────

def test_patch_vendor_permissions(client, db):
    v, _, vh = vendor_pair(db, client)
    sh, _ = student_client(db, client, "stu")
    ah, _ = admin_client(db, client)

    update_payload = {"contact_phone": "+8801999999999"}

    # 1. Student cannot patch vendor (403)
    r_student = client.patch(f"/api/vendors/{v.id}", headers=sh, json=update_payload)
    assert r_student.status_code == 403

    # 2. Vendor staff cannot patch vendor (403 - requires admin)
    r_vendor = client.patch(f"/api/vendors/{v.id}", headers=vh, json=update_payload)
    assert r_vendor.status_code == 403

    # 3. Admin can patch vendor (200)
    r_admin = client.patch(f"/api/vendors/{v.id}", headers=ah, json=update_payload)
    assert r_admin.status_code == 200
    assert r_admin.json()["contact_phone"] == "+8801999999999"


def test_list_vendors_include_all_admin_only(client, db):
    sh, _ = student_client(db, client, "stu")
    ah, _ = admin_client(db, client)

    # Student cannot pass include_all=true
    r = client.get("/api/vendors?include_all=true", headers=sh)
    assert r.status_code == 403

    # Admin can
    r_admin = client.get("/api/vendors?include_all=true", headers=ah)
    assert r_admin.status_code == 200


# ─── 4. Menu image_url XSS payloads ────────────────────────────────────────────

def test_menu_item_image_url_xss_rejections(client, db):
    v, _, vh = vendor_pair(db, client)

    xss_payloads = [
        "javascript:alert('xss')",
        "data:text/html,<script>alert(1)</script>",
        "vbscript:msgbox(1)",
        "<script src='http://evil.com/xss.js'></script>",
        "jav\tascript:alert(1)",
    ]

    for bad_url in xss_payloads:
        r = client.post(
            f"/api/vendors/{v.id}/menu-items",
            headers=vh,
            json={
                "name": "Suspicious Dish",
                "price_taka": 100,
                "category": "MEAL",
                "image_url": bad_url,
            },
        )
        assert r.status_code == 422, f"Expected 422 for payload: {bad_url}"

    # Valid image URLs should succeed
    for valid_url in [
        "https://cdn.example.com/images/biryani.jpg",
        "http://images.example.com/burger.png",
        "/assets/images/coffee.webp",
    ]:
        r = client.post(
            f"/api/vendors/{v.id}/menu-items",
            headers=vh,
            json={
                "name": f"Valid Dish {uuid.uuid4().hex[:6]}",
                "price_taka": 120,
                "category": "MEAL",
                "image_url": valid_url,
            },
        )
        assert r.status_code == 201


# ─── 5. Pagination bounds ──────────────────────────────────────────────────────

def test_pagination_bounds_validation(client, db):
    ah, _ = admin_client(db, client)

    # Limit > 100 is rejected
    r = client.get("/api/vendors?limit=101", headers=ah)
    assert r.status_code == 422

    # Limit < 1 is rejected
    r = client.get("/api/vendors?limit=0", headers=ah)
    assert r.status_code == 422

    # Negative offset is rejected
    r = client.get("/api/vendors?offset=-1", headers=ah)
    assert r.status_code == 422

    # Admin users pagination bounds
    r = client.get("/api/admin/users?limit=101", headers=ah)
    assert r.status_code == 422

    r = client.get("/api/admin/users?offset=-5", headers=ah)
    assert r.status_code == 422


# ─── 6. Seed idempotency ───────────────────────────────────────────────────────

def test_seed_idempotency(db):
    from app.seed import seed_data

    # Running run() multiple times should not fail and should not duplicate data
    seed_data.run()
    user_count_1 = db.query(User).count()
    vendor_count_1 = db.query(Vendor).count()

    # Second run
    seed_data.run()
    user_count_2 = db.query(User).count()
    vendor_count_2 = db.query(Vendor).count()

    assert user_count_1 == user_count_2
    assert vendor_count_1 == vendor_count_2
