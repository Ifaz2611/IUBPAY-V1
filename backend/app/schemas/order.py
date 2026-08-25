from datetime import datetime

from pydantic import BaseModel, Field, field_validator


class OrderItemIn(BaseModel):
    menu_item_id: str
    quantity: int = Field(ge=1, le=20)


class OrderCreate(BaseModel):
    vendor_id: str
    items: list[OrderItemIn] = Field(min_length=1)
    idempotency_key: str = Field(min_length=8, max_length=64)

    @field_validator("items")
    @classmethod
    def no_duplicate_items(cls, v: list[OrderItemIn]) -> list[OrderItemIn]:
        ids = [i.menu_item_id for i in v]
        if len(ids) != len(set(ids)):
            raise ValueError("Duplicate menu item ids in order")
        return v


class OrderStatusUpdate(BaseModel):
    status: str


class OrderItemOut(BaseModel):
    id: str
    menu_item_id: str | None = None
    item_name_snapshot: str
    unit_price_snapshot_taka: int
    quantity: int
    subtotal_taka: int

    class Config:
        from_attributes = True


class PaymentOut(BaseModel):
    id: str
    provider: str
    amount_taka: int
    status: str
    failure_reason: str | None = None

    class Config:
        from_attributes = True


class OrderOut(BaseModel):
    id: str
    order_number: str
    student_id: str
    vendor_id: str
    subtotal_taka: int
    service_fee_taka: int
    total_amount_taka: int
    status: str
    pickup_code: str
    created_at: datetime | None = None
    items: list[OrderItemOut] = []
    payments: list[PaymentOut] = []

    class Config:
        from_attributes = True
