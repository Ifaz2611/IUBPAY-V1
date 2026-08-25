from datetime import datetime

from sqlalchemy import DateTime, Enum, ForeignKey, Integer, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.user import gen_uuid
from app.utils.enums import PaymentStatus, RefundStatus, sa_enum


class Payment(Base):
    __tablename__ = "payments"

    id: Mapped[str] = mapped_column(String(32), primary_key=True, default=gen_uuid)
    order_id: Mapped[str] = mapped_column(ForeignKey("orders.id"), index=True)
    provider: Mapped[str] = mapped_column(String(32), default="MOCK")
    provider_transaction_id: Mapped[str] = mapped_column(String(64), unique=True)
    amount_taka: Mapped[int] = mapped_column(Integer)
    status: Mapped[PaymentStatus] = mapped_column(
        sa_enum(PaymentStatus), default=PaymentStatus.CREATED, index=True
    )
    failure_reason: Mapped[str | None] = mapped_column(String(255), nullable=True)
    verified_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    refunds: Mapped[list["Refund"]] = relationship(back_populates="payment")


class Refund(Base):
    __tablename__ = "refunds"

    id: Mapped[str] = mapped_column(String(32), primary_key=True, default=gen_uuid)
    payment_id: Mapped[str] = mapped_column(ForeignKey("payments.id"), index=True)
    amount_taka: Mapped[int] = mapped_column(Integer)
    reason: Mapped[str | None] = mapped_column(String(255), nullable=True)
    status: Mapped[RefundStatus] = mapped_column(sa_enum(RefundStatus))
    processed_by: Mapped[str | None] = mapped_column(String(120), nullable=True)
    created_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    payment: Mapped[Payment] = relationship(back_populates="refunds")
