from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.dependencies import get_current_user, require_role
from app.core.security import create_access_token, hash_password, verify_password
from app.db.session import get_db
from app.models.user import User
from app.schemas.auth import LoginRequest, TestUserCreate, TokenResponse, UserOut
from app.utils.enums import Role

router = APIRouter(prefix="/api/auth", tags=["auth"])


@router.post("/login", response_model=TokenResponse)
def login(body: LoginRequest, db: Session = Depends(get_db)):
    user = db.scalar(select(User).where(User.email == body.email.lower()))
    if user is None or not verify_password(body.password, user.password_hash):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid email or password")
    if user.status != "ACTIVE":
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Account suspended")
    token = create_access_token(subject=user.id, role=user.role.value)
    return TokenResponse(access_token=token, user=UserOut.model_validate(user))


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


@router.get("/me", response_model=UserOut)
def me(user: User = Depends(get_current_user)):
    return user
