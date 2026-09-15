from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user, require_role
from app.db.session import get_db
from app.models.menu_item import MenuItem
from app.models.order import Order
from app.models.user import User
from app.models.vendor import Vendor
from app.schemas.menu_item import MenuItemOut
from app.schemas.vendor import VendorCreate, VendorOut, VendorUpdate
from app.services.audit_service import audit
from app.services.order_service import transition_order
from app.services.payment_service import create_and_process_refund
from app.utils.enums import OrderStatus, PaymentStatus, Role, VendorStatus

router = APIRouter(prefix="/api/vendors", tags=["vendors"])


@router.get("/me/sales")
def my_vendor_sales(
    days: int | None = None,
    db: Session = Depends(get_db),
    user: User = Depends(require_role(Role.VENDOR)),
):
    from datetime import date, timedelta

    from app.services.report_service import vendor_sales

    if user.vendor_id is None:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "User is not linked to a vendor")
    since = (date.today() - timedelta(days=days - 1)) if days else None
    return vendor_sales(db, user.vendor_id, since)


@router.get("", response_model=list[VendorOut])
def list_vendors(
    include_all: bool = False,
    limit: int | None = Query(default=None, ge=1, le=100),
    offset: int | None = Query(default=None, ge=0),
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    """Approved vendors for everyone; admins may pass include_all=true.

    Supports pagination via `limit`/`offset`. When pagination params are
    provided, returns `{"items": [...], "total": N, "limit": ..., "offset": ...}`.
    Otherwise returns a plain list for backward compatibility.
    """
    q = select(Vendor).order_by(Vendor.name)
    count_q = select(func.count(Vendor.id))
    if include_all:
        if user.role != Role.ADMIN:
            raise HTTPException(status.HTTP_403_FORBIDDEN, "include_all requires admin role")
    else:
        q = q.where(Vendor.status == VendorStatus.APPROVED)
        count_q = count_q.where(Vendor.status == VendorStatus.APPROVED)
    if limit is not None or offset is not None:
        lim = limit if limit is not None else 50
        off = offset if offset is not None else 0
        total = db.scalar(count_q) or 0
        items = db.scalars(q.limit(lim).offset(off)).all()
        return {"items": items, "total": total, "limit": lim, "offset": off}
    return db.scalars(q).all()


@router.get("/me/menu", response_model=list[MenuItemOut])
def my_vendor_menu(
    include_unavailable: bool = True,
    db: Session = Depends(get_db),
    user: User = Depends(require_role(Role.VENDOR)),
):
    """Menu of the logged-in vendor staff's own vendor."""
    if user.vendor_id is None:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "User is not linked to a vendor")
    q = select(MenuItem).where(MenuItem.vendor_id == user.vendor_id).order_by(MenuItem.name)
    if not include_unavailable:
        q = q.where(MenuItem.is_available.is_(True))
    return db.scalars(q).all()


def _get_vendor_or_404(db: Session, vendor_id: str) -> Vendor:
    vendor = db.get(Vendor, vendor_id)
    if vendor is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Vendor not found")
    return vendor


@router.get("/{vendor_id}", response_model=VendorOut)
def get_vendor(
    vendor_id: str, db: Session = Depends(get_db), user: User = Depends(get_current_user)
):
    return _get_vendor_or_404(db, vendor_id)


@router.post("", response_model=VendorOut, status_code=201)
def create_vendor(
    body: VendorCreate,
    db: Session = Depends(get_db),
    admin: User = Depends(require_role(Role.ADMIN)),
):
    if db.scalar(select(Vendor).where(Vendor.name == body.name)):
        raise HTTPException(status.HTTP_409_CONFLICT, "Vendor name already exists")
    vendor = Vendor(**body.model_dump(), status=VendorStatus.APPROVED)
    db.add(vendor)
    audit(db, admin.id, "vendor.created", "vendor", None, {"name": body.name})
    db.commit()
    db.refresh(vendor)
    return vendor


@router.patch("/{vendor_id}", response_model=VendorOut)
def update_vendor(
    vendor_id: str,
    body: VendorUpdate,
    db: Session = Depends(get_db),
    admin: User = Depends(require_role(Role.ADMIN)),
):
    vendor = _get_vendor_or_404(db, vendor_id)
    changes = body.model_dump(exclude_unset=True, exclude_none=True)
    for field, value in changes.items():
        setattr(vendor, field, value)
    audit(db, admin.id, "vendor.updated", "vendor", vendor.id, changes)
    db.commit()
    db.refresh(vendor)
    return vendor


@router.post("/{vendor_id}/suspend", response_model=VendorOut)
def suspend_vendor(
    vendor_id: str,
    db: Session = Depends(get_db),
    admin: User = Depends(require_role(Role.ADMIN)),
):
    vendor = _get_vendor_or_404(db, vendor_id)
    vendor.status = VendorStatus.SUSPENDED
    # Auto-reject any paid orders that have not started preparation.
    # Only PAID is auto-refunded atomically; ACCEPTED/PREPARING require manual vendor action.
    live_orders = db.scalars(
        select(Order).where(Order.vendor_id == vendor_id, Order.status == OrderStatus.PAID)
    ).all()
    refunded = []
    try:
        for order in live_orders:
            transition_order(db, order, OrderStatus.REJECTED, actor_id=admin.id)
            payment = next((p for p in order.payments if p.status == PaymentStatus.SUCCEEDED), None)
            if payment:
                create_and_process_refund(
                    db,
                    payment=payment,
                    reason="Vendor suspended",
                    processed_by=admin.id,
                    commit=False,
                )
                refunded.append(order.order_number)
        audit(db, admin.id, "vendor.suspended", "vendor", vendor.id, {"refunded": refunded})
        db.commit()
    except Exception:
        db.rollback()
        raise
    db.refresh(vendor)
    return vendor
