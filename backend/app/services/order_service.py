import secrets
import uuid
from datetime import UTC, datetime

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.models.menu_item import MenuItem
from app.models.order import Order, OrderItem
from app.models.vendor import Vendor
from app.utils.enums import ALLOWED_TRANSITIONS, PAID_STATUSES, OrderStatus, VendorStatus


def _gen_order_number(db: Session) -> str:
    date_part = datetime.now(UTC).strftime("%Y%m%d")
    for _ in range(5):
        candidate = f"IUB-{date_part}-{secrets.token_hex(3).upper()}"
        exists = db.scalar(select(Order).where(Order.order_number == candidate))
        if not exists:
            return candidate
    return f"IUB-{date_part}-{uuid.uuid4().hex[:6].upper()}"


def _gen_pickup_code(db: Session) -> str:
    """Cryptographically secure 6-char alphanumeric, unique among active orders."""
    alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"  # no 0/O/I/1 confusables
    for _ in range(10):
        code = "".join(secrets.choice(alphabet) for _ in range(6))
        active = db.scalar(
            select(Order).where(
                Order.pickup_code == code,
                Order.status.notin_(
                    [OrderStatus.COLLECTED, OrderStatus.CANCELLED, OrderStatus.REFUNDED]
                ),
            )
        )
        if not active:
            return code
    # fallback
    return "".join(secrets.choice(alphabet) for _ in range(6))


def create_order(
    db: Session,
    *,
    student_id: str,
    vendor_id: str,
    raw_items: list[dict],
    idempotency_key: str,
    service_fee_taka: int,
) -> Order:
    """Create an order with backend-computed totals.

    SECURITY: prices always come from the database, never from the client.
    Runs in a single transaction; unique idempotency_key prevents duplicates.
    """
    existing = db.scalar(select(Order).where(Order.idempotency_key == idempotency_key))
    if existing is not None:
        return existing

    vendor = db.get(Vendor, vendor_id)
    if vendor is None or vendor.status != VendorStatus.APPROVED:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Vendor not found or not approved")

    menu_ids = [ri["menu_item_id"] for ri in raw_items]
    items = {
        mi.id: mi
        for mi in db.scalars(
            select(MenuItem).where(MenuItem.id.in_(menu_ids), MenuItem.is_available.is_(True))
        ).all()
    }

    missing = set(menu_ids) - set(items)
    if missing:
        raise HTTPException(
            status.HTTP_422_UNPROCESSABLE_ENTITY,
            f"Menu item(s) unavailable: {', '.join(sorted(missing))}",
        )

    wrong_vendor = [i.id for i in items.values() if i.vendor_id != vendor_id]
    if wrong_vendor:
        raise HTTPException(
            status.HTTP_422_UNPROCESSABLE_ENTITY, "All items must belong to the selected vendor"
        )

    order = Order(
        order_number=_gen_order_number(db),
        student_id=student_id,
        vendor_id=vendor_id,
        subtotal_taka=0,
        service_fee_taka=service_fee_taka,
        total_amount_taka=0,
        status=OrderStatus.PENDING_PAYMENT,
        pickup_code=_gen_pickup_code(db),
        idempotency_key=idempotency_key,
        version=1,
    )

    subtotal = 0
    for ri in raw_items:
        mi = items[ri["menu_item_id"]]
        line_subtotal = mi.price_taka * ri["quantity"]
        subtotal += line_subtotal
        order.items.append(
            OrderItem(
                menu_item_id=mi.id,
                item_name_snapshot=mi.name,
                unit_price_snapshot_taka=mi.price_taka,
                quantity=ri["quantity"],
                subtotal_taka=line_subtotal,
            )
        )

    order.subtotal_taka = subtotal
    order.total_amount_taka = subtotal + service_fee_taka

    db.add(order)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        # Race on idempotency_key: re-fetch existing
        existing = db.scalar(select(Order).where(Order.idempotency_key == idempotency_key))
        if existing is not None:
            return existing
        raise
    db.refresh(order)
    return order


def transition_order(
    db: Session,
    order: Order,
    new_status: OrderStatus,
    *,
    actor_id: str | None = None,
    expected_version: int | None = None,
) -> Order:
    """Enforce the order state machine. Invalid transitions raise 409.
    Optimistic locking: if expected_version provided, 409 if stale."""
    if expected_version is not None and order.version != expected_version:
        raise HTTPException(
            status.HTTP_409_CONFLICT, "Order was updated concurrently. Please refresh."
        )
    allowed = ALLOWED_TRANSITIONS.get(order.status, set())
    if new_status not in allowed:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            f"Invalid transition {order.status.value} -> {new_status.value}",
        )
    old = order.status
    order.status = new_status
    order.version = (order.version or 1) + 1
    from app.services.audit_service import audit

    audit(
        db,
        actor_id,
        "order.transition",
        "order",
        order.id,
        {"from": old.value, "to": new_status.value},
    )
    return order


def is_paid_like(order: Order) -> bool:
    return order.status in PAID_STATUSES
