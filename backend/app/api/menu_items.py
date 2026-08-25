from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
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


@router.get("/api/vendors/{vendor_id}/menu", response_model=list[MenuItemOut])
def get_menu(
    vendor_id: str,
    include_unavailable: bool = False,
    db: Session = Depends(get_db),
    viewer: User | None = Depends(require_role(Role.STUDENT, Role.VENDOR, Role.ADMIN)),
):
    vendor = db.get(Vendor, vendor_id)
    if vendor is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Vendor not found")
    q = select(MenuItem).where(MenuItem.vendor_id == vendor_id).order_by(MenuItem.name)
    if not include_unavailable:
        q = q.where(MenuItem.is_available.is_(True))
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
