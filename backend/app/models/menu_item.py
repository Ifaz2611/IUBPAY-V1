from datetime import datetime

from sqlalchemy import (
    Boolean,
    DateTime,
    ForeignKey,
    Integer,
    String,
    Text,
    UniqueConstraint,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base
from app.models.user import gen_uuid
from app.utils.enums import ItemCategory, sa_enum


class MenuItem(Base):
    __tablename__ = "menu_items"
    __table_args__ = (UniqueConstraint("vendor_id", "name", name="uq_vendor_item_name"),)

    id: Mapped[str] = mapped_column(String(32), primary_key=True, default=gen_uuid)
    vendor_id: Mapped[str] = mapped_column(ForeignKey("vendors.id"), index=True)
    name: Mapped[str] = mapped_column(String(160))
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    price_taka: Mapped[int] = mapped_column(Integer)  # whole Taka; no floats for money
    image_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    category: Mapped[ItemCategory] = mapped_column(
        sa_enum(ItemCategory), default=ItemCategory.OTHER
    )
    is_available: Mapped[bool] = mapped_column(Boolean, default=True)

    created_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )
