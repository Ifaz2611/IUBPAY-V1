import uuid
from datetime import datetime, timedelta, timezone

import bcrypt
import jwt

from app.core.config import settings

# In-memory blacklist (use Redis in production). Maps jti -> exp timestamp.
_revoked_jtis: dict[str, float] = {}


def hash_password(plain: str) -> str:
    return bcrypt.hashpw(plain.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def verify_password(plain: str, hashed: str) -> bool:
    try:
        return bcrypt.checkpw(plain.encode("utf-8"), hashed.encode("utf-8"))
    except ValueError:
        return False


def _base_payload(subject: str, role: str, jti: str, now: datetime, exp: datetime) -> dict:
    return {
        "sub": subject,
        "role": role,
        "jti": jti,
        "iss": settings.JWT_ISSUER,
        "aud": settings.JWT_AUDIENCE,
        "iat": now,
        "exp": exp,
    }


def create_access_token(subject: str, role: str) -> str:
    now = datetime.now(timezone.utc)
    jti = uuid.uuid4().hex
    payload = _base_payload(
        subject, role, jti, now,
        now + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES),
    )
    payload["type"] = "access"
    return jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.JWT_ALGORITHM)


def create_refresh_token(subject: str, role: str) -> str:
    now = datetime.now(timezone.utc)
    jti = uuid.uuid4().hex
    payload = _base_payload(
        subject, role, jti, now,
        now + timedelta(minutes=settings.REFRESH_TOKEN_EXPIRE_MINUTES),
    )
    payload["type"] = "refresh"
    return jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.JWT_ALGORITHM)


def decode_access_token(token: str, *, verify_type: str = "access") -> dict:
    """Raises jwt.PyJWTError on invalid/expired tokens. Checks blacklist and type."""
    payload = jwt.decode(
        token, settings.SECRET_KEY,
        algorithms=[settings.JWT_ALGORITHM],
        issuer=settings.JWT_ISSUER,
        audience=settings.JWT_AUDIENCE,
        options={"require": ["exp", "iat", "sub", "jti", "iss", "aud"]},
    )
    jti = payload.get("jti")
    if jti in _revoked_jtis:
        # lazy cleanup
        now_ts = datetime.now(timezone.utc).timestamp()
        if _revoked_jtis[jti] < now_ts:
            _revoked_jtis.pop(jti, None)
        else:
            raise jwt.InvalidTokenError("Token revoked")
    if verify_type and payload.get("type") != verify_type:
        raise jwt.InvalidTokenError(f"Invalid token type: expected {verify_type}")
    return payload


def revoke_token(token: str) -> None:
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.JWT_ALGORITHM],
                             options={"verify_exp": False})
        jti = payload.get("jti")
        exp = payload.get("exp")
        if jti and exp:
            _revoked_jtis[jti] = float(exp)
    except jwt.PyJWTError:
        pass


def is_revoked(jti: str) -> bool:
    return jti in _revoked_jtis
