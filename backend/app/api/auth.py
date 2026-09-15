import time
from collections import defaultdict

from fastapi import APIRouter, Depends, HTTPException, Request, status
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.dependencies import get_current_user, require_role
from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_access_token,
    hash_password,
    revoke_token,
    verify_password,
)
from app.db.session import get_db
from app.models.user import User
from app.schemas.auth import LoginRequest, TestUserCreate, TokenResponse, UserOut
from app.utils.enums import Role

router = APIRouter(prefix="/api/auth", tags=["auth"])

# Simple in-memory rate limit / lockout (use Redis in prod)
_login_attempts: dict[str, list[float]] = defaultdict(list)
_lockouts: dict[str, float] = {}
_DUMMY_HASH = hash_password("dummy-password-for-timing-mitigation-IUB-PAY-2026")


def _check_rate_limit(identifier: str) -> None:
    now = time.time()
    # lockout check
    until = _lockouts.get(identifier, 0)
    if now < until:
        raise HTTPException(
            status.HTTP_429_TOO_MANY_REQUESTS, "Account temporarily locked. Try again later."
        )
    # sliding window 5 attempts / 60s
    attempts = [t for t in _login_attempts[identifier] if now - t < 60]
    _login_attempts[identifier] = attempts
    if len(attempts) >= 5:
        _lockouts[identifier] = now + settings.ACCOUNT_LOCKOUT_MINUTES * 60
        raise HTTPException(status.HTTP_429_TOO_MANY_REQUESTS, "Too many attempts. Account locked.")


@router.post("/login", response_model=TokenResponse)
def login(body: LoginRequest, request: Request, db: Session = Depends(get_db)):
    client_id = request.client.host if request.client else body.email.lower()
    key = f"{client_id}:{body.email.lower()}"
    _check_rate_limit(key)
    user = db.scalar(select(User).where(User.email == body.email.lower()))
    # constant-time mitigation: always verify a dummy hash when user not found
    if user is None:
        verify_password(body.password, _DUMMY_HASH)
        _login_attempts[key].append(time.time())
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid email or password")
    if not verify_password(body.password, user.password_hash):
        _login_attempts[key].append(time.time())
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid email or password")
    if user.status != "ACTIVE":
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Account suspended")
    # success -> clear attempts
    _login_attempts.pop(key, None)
    _lockouts.pop(key, None)
    token = create_access_token(subject=user.id, role=user.role.value)
    refresh = create_refresh_token(subject=user.id, role=user.role.value)
    # attach refresh token via extra field if schema allows, otherwise return dict
    # Keep backward compat: return access_token, include refresh_token in response
    return {
        "access_token": token,
        "refresh_token": refresh,
        "user": UserOut.model_validate(user),
        "token_type": "bearer",
    }


@router.post("/register-test-user", response_model=UserOut, status_code=201)
def register_test_user(
    body: TestUserCreate,
    db: Session = Depends(get_db),
    _: User = Depends(require_role(Role.ADMIN)),
):
    """Dev-only helper to create extra test users. Disabled in production via env."""
    if not settings.ALLOW_TEST_REGISTRATION:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Test registration is disabled")

    if db.scalar(select(User).where(User.email == body.email.lower())):
        raise HTTPException(status.HTTP_409_CONFLICT, "Email already registered")

    user = User(
        name=body.name,
        email=body.email.lower(),
        password_hash=hash_password(body.password),
        student_id=body.student_id,
        phone=body.phone,
        role=Role(body.role),
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


class RefreshRequest(BaseModel):
    refresh_token: str


@router.post("/refresh", response_model=TokenResponse)
def refresh(body: RefreshRequest, db: Session = Depends(get_db)):
    try:
        payload = decode_access_token(body.refresh_token, verify_type="refresh")
    except Exception as err:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid refresh token") from err
    user = db.get(User, payload.get("sub"))
    if user is None or user.status != "ACTIVE":
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "User no longer exists")
    # rotate: revoke old refresh
    revoke_token(body.refresh_token)
    new_access = create_access_token(subject=user.id, role=user.role.value)
    new_refresh = create_refresh_token(subject=user.id, role=user.role.value)
    return {
        "access_token": new_access,
        "refresh_token": new_refresh,
        "user": UserOut.model_validate(user),
        "token_type": "bearer",
    }


@router.post("/logout")
def logout(request: Request, user: User = Depends(get_current_user)):
    auth = request.headers.get("Authorization", "")
    token = auth.replace("Bearer ", "") if auth.startswith("Bearer ") else ""
    if token:
        revoke_token(token)
    return {"status": "logged out"}


@router.get("/me", response_model=UserOut)
def me(user: User = Depends(get_current_user)):
    return user
