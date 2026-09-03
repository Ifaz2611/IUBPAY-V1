from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.dependencies import require_role
from app.db.session import get_db
from app.models.menu_item import MenuItem
from app.models.user import User
from app.models.vendor import Vendor
from app.schemas.menu_item import MenuItemCreate, MenuItemOut, MenuItemUpdate
from app.services.audit_service import audit
from app.utils.enums import Role

router = APIRouter(tags=["menu"])


def _require_vendor_access(db: Session, user: User, vendor_id: str) -> None:
    """Admins may manage any vendor; vendor staff only their own."""
    if user.role == Role.ADMIN:
        return
    if user.role != Role.VENDOR or user.vendor_id != vendor_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Not your vendor")


@router.get("/api/vendors/{vendor_id}/menu")
def get_menu(
    vendor_id: str,
    include_unavailable: bool = False,
    limit: int | None = Query(default=None, ge=1, le=100),
    offset: int | None = Query(default=None, ge=0),
    db: Session = Depends(get_db),
    viewer: User | None = Depends(require_role(Role.STUDENT, Role.VENDOR, Role.ADMIN)),
):
    vendor = db.get(Vendor, vendor_id)
    if vendor is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Vendor not found")
    base = select(MenuItem).where(MenuItem.vendor_id == vendor_id)
    if not include_unavailable:
        base = base.where(MenuItem.is_available.is_(True))
    q = base.order_by(MenuItem.name)
    if limit is not None or offset is not None:
        lim = limit if limit is not None else 50
        off = offset if offset is not None else 0
        total = db.scalar(select(func.count()).select_from(base.subquery())) or 0
        items = db.scalars(q.limit(lim).offset(off)).all()
        return {"items": items, "total": total, "limit": lim, "offset": off}
    return db.scalars(q).all()


@router.post("/api/vendors/{vendor_id}/menu-items", response_model=MenuItemOut, status_code=201)
def create_menu_item(
    vendor_id: str,
    body: MenuItemCreate,
    db: Session = Depends(get_db),
    user: User = Depends(require_role(Role.VENDOR, Role.ADMIN)),
):
    _require_vendor_access(db, user, vendor_id)
    if db.get(Vendor, vendor_id) is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Vendor not found")
    item = MenuItem(vendor_id=vendor_id, **body.model_dump(), is_available=True)
    db.add(item)
    db.flush()
    audit(db, user.id, "menu_item.created", "menu_item", item.id, {"name": item.name})
    db.commit()
    db.refresh(item)
    return item


def _get_item(db: Session, item_id: str) -> MenuItem:
    item = db.get(MenuItem, item_id)
    if item is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Menu item not found")
    return item


@router.patch("/api/menu-items/{item_id}", response_model=MenuItemOut)
def update_menu_item(
    item_id: str,
    body: MenuItemUpdate,
    db: Session = Depends(get_db),
    user: User = Depends(require_role(Role.VENDOR, Role.ADMIN)),
):
    item = _get_item(db, item_id)
    _require_vendor_access(db, user, item.vendor_id)
    changes = body.model_dump(exclude_unset=True, exclude_none=True)
    for field, value in changes.items():
        setattr(item, field, value)
    audit(db, user.id, "menu_item.updated", "menu_item", item.id, changes)
    db.commit()
    db.refresh(item)
    return item


@router.delete("/api/menu-items/{item_id}", response_model=MenuItemOut)
def disable_menu_item(
    item_id: str,
    db: Session = Depends(get_db),
    user: User = Depends(require_role(Role.VENDOR, Role.ADMIN)),
):
    """Soft-disable (never hard delete): keeps historical order snapshots valid."""
    item = _get_item(db, item_id)
    _require_vendor_access(db, user, item.vendor_id)
    item.is_available = False
    audit(db, user.id, "menu_item.disabled", "menu_item", item.id, {})
    db.commit()
    db.refresh(item)
    return item
