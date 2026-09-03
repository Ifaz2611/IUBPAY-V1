import asyncio
import hmac
import time

from fastapi import APIRouter, Depends, Header, HTTPException, status
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.dependencies import require_role
from app.db.session import get_db
from app.models.order import Order
from app.models.payment import Payment
from app.models.user import User
from app.schemas.payment import MockCompleteRequest, PaymentCreate, WebhookPayload
from app.services.payment_service import (
    apply_webhook_event,
    create_payment,
    simulate_provider_latency,
)
from app.utils.enums import Role

router = APIRouter(prefix="/api/payments", tags=["payments"])


@router.post("/create", status_code=201)
def create(body: PaymentCreate, db: Session = Depends(get_db),
           student: User = Depends(require_role(Role.STUDENT))):
    order = db.get(Order, body.order_id)
    if order is None or order.student_id != student.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Order not found")
    payment = create_payment(db, order)
    return {
        "payment_id": payment.id,
        "provider_transaction_id": payment.provider_transaction_id,
        "amount_taka": payment.amount_taka,
        "status": payment.status.value,
        "demo_notice": "MOCK PAYMENT - no real money moves in this prototype",
    }


@router.get("/{payment_id}")
def get_payment(payment_id: str, db: Session = Depends(get_db),
                user: User = Depends(require_role(Role.STUDENT, Role.VENDOR, Role.ADMIN))):
    p = db.get(Payment, payment_id)
    if p is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Payment not found")
    if user.role == Role.STUDENT:
        order = db.get(Order, p.order_id)
        if order.student_id != user.id:
            raise HTTPException(status.HTTP_403_FORBIDDEN, "Not your payment")
    return {
        "id": p.id, "order_id": p.order_id, "provider": p.provider,
        "provider_transaction_id": p.provider_transaction_id,
        "amount_taka": p.amount_taka, "status": p.status.value,
        "failure_reason": p.failure_reason,
        "verified_at": p.verified_at.isoformat() if p.verified_at else None,
    }


@router.post("/mock/complete")
def mock_complete(
    body: MockCompleteRequest,
    db: Session = Depends(get_db),
    student: User = Depends(require_role(Role.STUDENT)),
):
    """DEMO ONLY: acts as the mock provider's checkout confirmation page.

    It simulates the provider server by firing the webhook handler internally,
    exactly like a real provider would call POST /api/payments/webhook."""
    payment = db.get(Payment, body.payment_id)
    if payment is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Payment not found")
    order = db.get(Order, payment.order_id)
    if order.student_id != student.id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Not your payment")

    simulate_provider_latency(body.delay_seconds)
    result = apply_webhook_event(
        db,
        payment=payment,
        event="payment.succeeded",
        amount_taka=payment.amount_taka,
        failure_reason=None,
    )
    return {"payment_id": payment.id, **result}


@router.post("/mock/fail")
def mock_fail(
    body: MockCompleteRequest,
    db: Session = Depends(get_db),
    student: User = Depends(require_role(Role.STUDENT)),
):
    """DEMO ONLY: simulates a declined payment at the provider."""
    payment = db.get(Payment, body.payment_id)
    if payment is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Payment not found")
    order = db.get(Order, payment.order_id)
    if order.student_id != student.id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Not your payment")

    result = apply_webhook_event(
        db,
        payment=payment,
        event="payment.failed",
        amount_taka=payment.amount_taka,
        failure_reason=failure_reason_for(body.delay_seconds),
    )
    return {"payment_id": payment.id, **result}


def failure_reason_for(code: int) -> str:
    reasons = {0: "MOCK_INSUFFICIENT_BALANCE", 1: "MOCK_CARD_DECLINED"}
    return reasons.get(code, "MOCK_PROVIDER_ERROR")


@router.get("/{order_id}/stream")
async def order_stream(order_id: str):
    """SSE endpoint for real-time order tracking. Fallback to polling if SSE unsupported."""
    from fastapi.responses import StreamingResponse
    from sqlalchemy.orm import Session as _Session
    from app.db.session import SessionLocal
    import json as _json
    import asyncio as _asyncio

    async def event_gen():
        for _ in range(120):  # up to 10 minutes
            db: _Session = SessionLocal()
            try:
                order = db.get(Order, order_id)
                if order is None:
                    yield f"data: {_json.dumps({'error': 'not found'})}\n\n"
                    break
                payload = _json.dumps({"id": order.id, "status": order.status.value if hasattr(order.status, 'value') else str(order.status), "pickup_code": order.pickup_code, "updated_at": order.updated_at.isoformat() if order.updated_at else None})
                yield f"data: {payload}\n\n"
                if order.status.value in ("COLLECTED", "CANCELLED", "REFUNDED", "REJECTED"):
                    break
            finally:
                db.close()
            await _asyncio.sleep(2)
    return StreamingResponse(event_gen(), media_type="text/event-stream",
                             headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"})


@router.post("/webhook")
def webhook(
    payload: WebhookPayload,
    x_webhook_token: str | None = Header(default=None),
    db: Session = Depends(get_db),
):
    """Provider webhook endpoint. Protected by shared-secret header.

    Idempotent: repeated callbacks for the same transaction are safe."""
    if x_webhook_token is None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Missing webhook token")
    if not hmac.compare_digest(x_webhook_token, settings.MOCK_PAYMENT_WEBHOOK_TOKEN):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid webhook token")

    payment = db.get(Payment, payload.payment_id)
    if payment is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Unknown payment")
    if payment.provider_transaction_id != payload.provider_transaction_id:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Transaction id mismatch")

    result = apply_webhook_event(
        db,
        payment=payment,
        event=payload.event,
        amount_taka=payload.amount_taka,
        failure_reason=payload.failure_reason,
    )
    return {"payment_id": payment.id, **result}
