import uuid

from sqlalchemy import DateTime, ForeignKey, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.utils.enums import Role, UserStatus, sa_enum


def gen_uuid() -> str:
    return uuid.uuid4().hex


class User(Base):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(String(32), primary_key=True, default=gen_uuid)
    name: Mapped[str] = mapped_column(String(120))
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    password_hash: Mapped[str] = mapped_column(String(255))
    student_id: Mapped[str | None] = mapped_column(String(32), unique=True, nullable=True)
    phone: Mapped[str | None] = mapped_column(String(32), nullable=True)
    role: Mapped[Role] = mapped_column(sa_enum(Role), default=Role.STUDENT)
    status: Mapped[UserStatus] = mapped_column(sa_enum(UserStatus), default=UserStatus.ACTIVE)

    # Vendor accounts are linked to exactly one vendor. Null for students/admins.
    vendor_id: Mapped[str | None] = mapped_column(
        ForeignKey("vendors.id", use_alter=True), nullable=True
    )

    created_at: Mapped[object] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[object] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    vendor: Mapped["Vendor"] = relationship(
        back_populates="staff", foreign_keys=[vendor_id]
    )  # noqa: F821
