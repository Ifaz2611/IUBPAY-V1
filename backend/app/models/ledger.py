import uuid

from sqlalchemy import DateTime, Enum, ForeignKey, Integer, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base
from app.utils.enums import LedgerEntryType, sa_enum


def gen_uuid() -> str:
    return uuid.uuid4().hex


class LedgerEntry(Base):
    """Append-only money-movement ledger. Rows are never updated or deleted."""

    __tablename__ = "ledger_entries"

    id: Mapped[str] = mapped_column(String(32), primary_key=True, default=gen_uuid)
    payment_id: Mapped[str | None] = mapped_column(ForeignKey("payments.id"), nullable=True)
    order_id: Mapped[str | None] = mapped_column(ForeignKey("orders.id"), nullable=True)
    entry_type: Mapped[LedgerEntryType] = mapped_column(sa_enum(LedgerEntryType))
    amount_taka: Mapped[int] = mapped_column(Integer)  # positive = inflow, negative = outflow
    reference: Mapped[str] = mapped_column(String(120))
    created_at: Mapped[object] = mapped_column(DateTime(timezone=True), server_default=func.now())
