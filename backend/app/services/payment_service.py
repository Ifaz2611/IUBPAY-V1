"""Payment + refund logic. Every money movement writes a LedgerEntry and an
AuditLog row inside the same DB transaction as the state change."""

import asyncio
import time
from datetime import UTC

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.ledger import LedgerEntry
from app.models.order import Order
from app.models.payment import Payment, Refund
from app.services.audit_service import audit
from app.services.order_service import transition_order
from app.utils.enums import (
    LedgerEntryType,
    OrderStatus,
    PaymentStatus,
    RefundStatus,
)


def _ledger(db: Session, payment: Payment, entry_type: LedgerEntryType, amount: int, ref: str):
    db.add(
        LedgerEntry(
            payment_id=payment.id,
            order_id=payment.order_id,
            entry_type=entry_type,
            amount_taka=amount,
            reference=ref,
        )
    )


def create_payment(db: Session, order: Order) -> Payment:
    """Start a mock payment for the order. Order moves to PAYMENT_PROCESSING.

    Idempotent per order: if the order is already processing with a live payment,
    return that payment instead of charging again (never charge twice).
    """
    active = next(
        (
            p
            for p in order.payments
            if p.status in (PaymentStatus.CREATED, PaymentStatus.PROCESSING)
        ),
        None,
    )
    if active is not None:
        return active

    succeeded = [p for p in order.payments if p.status == PaymentStatus.SUCCEEDED]
    if succeeded or order.status not in (OrderStatus.PENDING_PAYMENT, OrderStatus.PAYMENT_FAILED):
        raise HTTPException(status.HTTP_409_CONFLICT, "This order cannot be paid again")

    payment = Payment(
        order_id=order.id,
        provider="MOCK",
        provider_transaction_id=f"MOCKTX-{payment_ref()}",
        amount_taka=order.total_amount_taka,
        status=PaymentStatus.PROCESSING,
    )
    db.add(payment)
    transition_order(db, order, OrderStatus.PAYMENT_PROCESSING)
    db.commit()
    db.refresh(payment)
    return payment


def payment_ref() -> str:
    from app.models.user import gen_uuid

    return gen_uuid()[:12].upper()


def apply_webhook_event(
    db: Session,
    *,
    payment: Payment,
    event: str,
    amount_taka: int,
    failure_reason: str | None,
) -> dict:
    """Handle a (possibly repeated) provider webhook. Fully idempotent:
    a webhook for an already-final payment returns 'already_processed'."""

    if event != "payment.succeeded" and event != "payment.failed":
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Unknown webhook event")

    if payment.status in (PaymentStatus.SUCCEEDED, PaymentStatus.FAILED):
        return {"status": "already_processed", "payment_status": payment.status.value}

    if amount_taka != payment.amount_taka:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Webhook amount mismatch")

    order = db.get(Order, payment.order_id)

    if event == "payment.succeeded":
        payment.status = PaymentStatus.SUCCEEDED
        from datetime import datetime

        payment.verified_at = datetime.now(UTC)
        transition_order(db, order, OrderStatus.PAID)
        _ledger(
            db,
            payment,
            LedgerEntryType.PAYMENT,
            payment.amount_taka,
            f"income:{payment.provider_transaction_id}",
        )
        audit(db, None, "payment.succeeded", "payment", payment.id, {"order": order.order_number})
    else:
        payment.status = PaymentStatus.FAILED
        payment.failure_reason = failure_reason or "MOCK_DECLINED"
        transition_order(db, order, OrderStatus.PAYMENT_FAILED)
        audit(db, None, "payment.failed", "payment", payment.id, {"reason": payment.failure_reason})

    db.commit()
    return {"status": "processed", "payment_status": payment.status.value}


def create_and_process_refund(
    db: Session,
    *,
    payment: Payment,
    reason: str,
    processed_by: str | None,
    commit: bool = True,
) -> Refund:
    """Mock instant refund. Records REFUND_PENDING then REFUNDED in the ledger."""
    existing = [
        r for r in payment.refunds if r.status in (RefundStatus.PENDING, RefundStatus.PROCESSED)
    ]
    if existing:
        raise HTTPException(status.HTTP_409_CONFLICT, "Refund already exists for this payment")

    refund = Refund(
        payment_id=payment.id,
        amount_taka=payment.amount_taka,
        reason=reason,
        status=RefundStatus.PENDING,
        processed_by=processed_by,
    )
    db.add(refund)

    order = db.get(Order, payment.order_id)
    _ledger(db, payment, LedgerEntryType.REFUND, -payment.amount_taka, f"refund:{refund.id}")
    audit(
        db,
        processed_by,
        "refund.created",
        "refund",
        refund.id,
        {"payment": payment.id, "amount_taka": payment.amount_taka},
    )

    # Mock provider processes instantly; a real integration would await the callback.
    refund.status = RefundStatus.PROCESSED
    if order is not None and order.status == OrderStatus.REFUND_PENDING:
        order.status = OrderStatus.REFUNDED
        audit(db, processed_by, "order.refunded", "order", order.id, {})

    if commit:
        db.commit()
        db.refresh(refund)
    else:
        db.flush()
        db.refresh(refund)
    return refund


def simulate_provider_latency(seconds: int) -> None:
    """Imitate network latency of a real payment provider (capped)."""
    if seconds > 0:
        time.sleep(min(seconds, 5))


async def simulate_provider_latency_async(seconds: int) -> None:
    if seconds > 0:
        await asyncio.sleep(min(seconds, 5))
