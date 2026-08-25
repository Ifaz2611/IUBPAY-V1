import uuid
from datetime import datetime

from sqlalchemy import DateTime, Enum, ForeignKey, Integer, String, UniqueConstraint, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.user import gen_uuid
from app.utils.enums import OrderStatus, sa_enum


class Order(Base):
    __tablename__ = "orders"

    id: Mapped[str] = mapped_column(String(32), primary_key=True, default=gen_uuid)
    order_number: Mapped[str] = mapped_column(String(32), unique=True, index=True)
    student_id: Mapped[str] = mapped_column(ForeignKey("users.id"), index=True)
    vendor_id: Mapped[str] = mapped_column(ForeignKey("vendors.id"), index=True)

    # All money values are whole Taka integers, computed on the backend only.
    subtotal_taka: Mapped[int] = mapped_column(Integer)
    service_fee_taka: Mapped[int] = mapped_column(Integer)
    total_amount_taka: Mapped[int] = mapped_column(Integer)

    status: Mapped[OrderStatus] = mapped_column(
        sa_enum(OrderStatus), default=OrderStatus.PENDING_PAYMENT, index=True
    )
    pickup_code: Mapped[str] = mapped_column(String(8))
    idempotency_key: Mapped[str] = mapped_column(String(64), unique=True)

    created_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    items: Mapped[list["OrderItem"]] = relationship(  # noqa: F821
        back_populates="order", cascade="all, delete-orphan"
    )
    payments: Mapped[list["Payment"]] = relationship(  # noqa: F821
        "Payment", primaryjoin="Order.id==Payment.order_id", viewonly=True
    )


class OrderItem(Base):
    __tablename__ = "order_items"

    id: Mapped[str] = mapped_column(String(32), primary_key=True, default=gen_uuid)
    order_id: Mapped[str] = mapped_column(ForeignKey("orders.id"), index=True)
    menu_item_id: Mapped[str | None] = mapped_column(ForeignKey("menu_items.id"), nullable=True)
    item_name_snapshot: Mapped[str] = mapped_column(String(160))
    unit_price_snapshot_taka: Mapped[int] = mapped_column(Integer)
    quantity: Mapped[int] = mapped_column(Integer)
    subtotal_taka: Mapped[int] = mapped_column(Integer)

    order: Mapped[Order] = relationship(back_populates="items")
