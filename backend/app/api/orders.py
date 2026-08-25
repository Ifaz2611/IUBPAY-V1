from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session, joinedload

from app.core.config import settings
from app.core.dependencies import get_current_user, require_role
from app.db.session import get_db
from app.models.order import Order
from app.models.user import User
from app.schemas.order import OrderCreate, OrderOut, OrderStatusUpdate
from app.services.audit_service import audit
from app.services.order_service import create_order, transition_order
from app.services.payment_service import create_and_process_refund
from app.utils.enums import OrderStatus, PaymentStatus, Role

router = APIRouter(tags=["orders"])

# Statuses a vendor may set on their own orders.
VENDOR_ALLOWED_STATUSES = {
    OrderStatus.ACCEPTED,
    OrderStatus.REJECTED,
    OrderStatus.PREPARING,
    OrderStatus.READY,
    OrderStatus.COLLECTED,
}


def _get_order(db: Session, order_id: str) -> Order:
    order = db.scalars(
        select(Order).options(joinedload(Order.items)).where(Order.id == order_id)
    ).unique().first()
    if order is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Order not found")
    return order


@router.post("/api/orders", response_model=OrderOut, status_code=201)
def place_order(
    body: OrderCreate,
    db: Session = Depends(get_db),
    student: User = Depends(require_role(Role.STUDENT)),
):
    """Idempotent order creation: same idempotency_key returns the same order."""
    return create_order(
        db,
        student_id=student.id,
        vendor_id=body.vendor_id,
        raw_items=[i.model_dump() for i in body.items],
        idempotency_key=body.idempotency_key,
        service_fee_taka=settings.SERVICE_FEE_TAKA,
    )


@router.get("/api/students/me/orders", response_model=list[OrderOut])
def my_orders(
    db: Session = Depends(get_db),
    student: User = Depends(require_role(Role.STUDENT)),
):
    q = (
        select(Order)
        .options(joinedload(Order.items))
        .where(Order.student_id == student.id)
        .order_by(Order.created_at.desc())
    )
    return db.scalars(q).unique().all()


@router.get("/api/vendors/me/orders", response_model=list[OrderOut])
def vendor_orders(
    db: Session = Depends(get_db),
    vendor_user: User = Depends(require_role(Role.VENDOR)),
):
    if vendor_user.vendor_id is None:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "User is not linked to a vendor")
    # Paid-and-beyond orders only: an order must never reach a vendor before payment.
    statuses = [
        OrderStatus.PAID, OrderStatus.ACCEPTED, OrderStatus.PREPARING,
        OrderStatus.READY, OrderStatus.COLLECTED, OrderStatus.REJECTED,
        OrderStatus.CANCELLED, OrderStatus.REFUND_PENDING, OrderStatus.REFUNDED,
    ]
    q = (
        select(Order)
        .options(joinedload(Order.items))
        .where(Order.vendor_id == vendor_user.vendor_id, Order.status.in_(statuses))
        .order_by(Order.created_at.desc())
    )
    return db.scalars(q).unique().all()


@router.get("/api/orders/{order_id}", response_model=OrderOut)
def get_order(
    order_id: str,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    order = _get_order(db, order_id)

    # Ownership / tenancy checks: students see only their own orders;
    # vendor staff only their own vendor's; admins everything.
    if user.role == Role.STUDENT and order.student_id != user.id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Not your order")
    if user.role == Role.VENDOR and (user.vendor_id is None or order.vendor_id != user.vendor_id):
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Not your vendor's order")
    return order


@router.patch("/api/orders/{order_id}/status", response_model=OrderOut)
def update_order_status(
    order_id: str,
    body: OrderStatusUpdate,
    db: Session = Depends(get_db),
    user: User = Depends(require_role(Role.VENDOR, Role.ADMIN)),
):
    order = _get_order(db, order_id)
    try:
        new_status = OrderStatus(body.status)
    except ValueError:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, f"Unknown status '{body.status}'")

    if user.role == Role.VENDOR:
        if user.vendor_id is None or order.vendor_id != user.vendor_id:
            raise HTTPException(status.HTTP_403_FORBIDDEN, "Not your vendor's order")
        if new_status not in VENDOR_ALLOWED_STATUSES:
            raise HTTPException(status.HTTP_403_FORBIDDEN,
                                "Vendors cannot set this status")

    transition_order(db, order, new_status, actor_id=user.id)

    # Vendor rejection after payment triggers an automatic refund.
    if new_status in (OrderStatus.REJECTED,):
        succeeded_payment = next(
            (p for p in order.payments if p.status == PaymentStatus.SUCCEEDED), None
        )
        if succeeded_payment and order.status != OrderStatus.REFUNDED:
            transition_order(db, order, OrderStatus.REFUND_PENDING, actor_id=user.id)
            create_and_process_refund(db, payment=succeeded_payment,
                                      reason="Vendor rejected order",
                                      processed_by=user.id)

    db.commit()
    db.refresh(order)
    return order


@router.post("/api/orders/{order_id}/cancel", response_model=OrderOut)
def cancel_order(
    order_id: str,
    db: Session = Depends(get_db),
    student: User = Depends(require_role(Role.STUDENT)),
):
    order = _get_order(db, order_id)
    if order.student_id != student.id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Not your order")

    if order.status not in (OrderStatus.PENDING_PAYMENT, OrderStatus.PAID):
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            f"Order cannot be cancelled in status {order.status.value}",
        )

    was_paid = order.status == OrderStatus.PAID
    transition_order(db, order, OrderStatus.CANCELLED, actor_id=student.id)
    audit(db, student.id, "order.cancelled", "order", order.id, {"was_paid": was_paid})

    if was_paid:
        payment = next((p for p in order.payments if p.status == PaymentStatus.SUCCEEDED), None)
        if payment:
            transition_order(db, order, OrderStatus.REFUND_PENDING, actor_id=student.id)
            create_and_process_refund(db, payment=payment, reason="Student cancelled order",
                                      processed_by=student.id)

    db.commit()
    db.refresh(order)
    return order
