import re
from datetime import datetime
from typing import Annotated

from pydantic import AfterValidator, BaseModel, ConfigDict, Field

# Lenient email check: unlike pydantic's EmailStr this accepts reserved
# development domains such as '@iub.test' used by our seed data.
_EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


def _validate_email(value: str) -> str:
    if not _EMAIL_RE.match(value):
        raise ValueError("Invalid email address")
    return value.lower()


LenientEmail = Annotated[str, Field(max_length=255), AfterValidator(_validate_email)]


class LoginRequest(BaseModel):
    email: LenientEmail
    password: str = Field(min_length=6, max_length=128)


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str | None = None
    token_type: str = "bearer"  # noqa: S105
    user: "UserOut"


class TestUserCreate(BaseModel):
    name: str = Field(min_length=2, max_length=120)
    email: LenientEmail
    password: str = Field(min_length=8, max_length=128)
    role: str = Field(pattern="^(student|vendor|admin)$")
    student_id: str | None = None
    phone: str | None = None


class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    name: str
    email: LenientEmail
    student_id: str | None = None
    phone: str | None = None
    role: str
    status: str
    vendor_id: str | None = None
    created_at: datetime | None = None


TokenResponse.model_rebuild()
