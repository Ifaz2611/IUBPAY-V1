import uuid

from sqlalchemy import DateTime, Enum, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.utils.enums import VendorStatus, sa_enum
from app.models.user import gen_uuid


class Vendor(Base):
    __tablename__ = "vendors"

    id: Mapped[str] = mapped_column(String(32), primary_key=True, default=gen_uuid)
    name: Mapped[str] = mapped_column(String(160), unique=True)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    location: Mapped[str] = mapped_column(String(200))
    contact_phone: Mapped[str | None] = mapped_column(String(32), nullable=True)
    settlement_reference: Mapped[str | None] = mapped_column(String(64), nullable=True)
    status: Mapped[VendorStatus] = mapped_column(sa_enum(VendorStatus), default=VendorStatus.PENDING)
    service_fee_taka: Mapped[int | None] = mapped_column(default=None, nullable=True)
    created_at: Mapped[object] = mapped_column(DateTime(timezone=True), server_default=func.now())

    staff: Mapped[list["User"]] = relationship(back_populates="vendor")  # noqa: F821
