from pydantic import BaseModel, Field


class PaymentCreate(BaseModel):
    order_id: str


class MockCompleteRequest(BaseModel):
    payment_id: str
    delay_seconds: int = Field(default=0, ge=0, le=5)


class WebhookPayload(BaseModel):
    event: str = Field(pattern="^(payment.succeeded|payment.failed)$")
    payment_id: str
    provider_transaction_id: str
    amount_taka: int
    failure_reason: str | None = None


class PaymentOut(BaseModel):
    id: str
    order_id: str
    provider: str
    provider_transaction_id: str
    amount_taka: int
    status: str
    failure_reason: str | None = None
    verified_at: str | None = None

    class Config:
        from_attributes = True
