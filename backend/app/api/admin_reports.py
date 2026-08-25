import csv
import io

from fastapi import APIRouter, Depends, Query
from fastapi.responses import StreamingResponse
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.dependencies import require_role
from app.db.session import get_db
from app.models.user import User
from app.schemas.report import DailyReportRow, ReportSummary
from app.services.report_service import daily, summary, transactions_csv
from app.utils.enums import Role

router = APIRouter(prefix="/api/admin", tags=["admin"])


@router.get("/reports/summary", response_model=ReportSummary)
def reports_summary(
    db: Session = Depends(get_db),
    _: User = Depends(require_role(Role.ADMIN)),
):
    return summary(db)


@router.get("/reports/daily", response_model=list[DailyReportRow])
def reports_daily(
    days: int = Query(default=14, ge=1, le=90),
    db: Session = Depends(get_db),
    _: User = Depends(require_role(Role.ADMIN)),
):
    return daily(db, days)


@router.get("/reports/transactions")
def reports_transactions(
    limit: int = Query(default=50, ge=1, le=500),
    offset: int = Query(default=0, ge=0),
    db: Session = Depends(get_db),
    _: User = Depends(require_role(Role.ADMIN)),
):
    """Raw payment transactions (includes failures and refunds)."""
    from sqlalchemy import func

    from app.models.order import Order
    from app.models.payment import Payment
    from app.models.vendor import Vendor

    q = (
        select(Payment, Order, Vendor)
        .join(Order, Payment.order_id == Order.id)
        .join(Vendor, Order.vendor_id == Vendor.id)
        .order_by(Payment.created_at.desc())
        .limit(limit)
        .offset(offset)
    )
    total = db.scalar(select(func.count(Payment.id))) or 0
    rows = []
    for p, o, v in db.execute(q).all():
        rows.append({
            "payment_id": p.id,
            "created_at": p.created_at.isoformat() if p.created_at else None,
            "provider": p.provider,
            "status": p.status.value,
            "amount_taka": p.amount_taka,
            "failure_reason": p.failure_reason,
            "order_number": o.order_number,
            "vendor_name": v.name,
            "order_status": o.status.value,
        })
    return {"total": total, "items": rows}


@router.get("/reports/export.csv", response_class=StreamingResponse)
def export_csv(
    db: Session = Depends(get_db),
    _: User = Depends(require_role(Role.ADMIN)),
):
    content = transactions_csv(db)
    filename = "iub_cafeteria_transactions.csv"
    return StreamingResponse(
        iter([content]),
        media_type="text/csv",
        headers={"Content-Disposition": f"attachment; filename={filename}"},
    )


@router.get("/users")
def list_users(
    role: str | None = None,
    db: Session = Depends(get_db),
    _: User = Depends(require_role(Role.ADMIN)),
):
    from app.schemas.auth import UserOut

    q = select(User).order_by(User.created_at.desc())
    if role:
        q = q.where(User.role == role)
    return [UserOut.model_validate(u) for u in db.scalars(q).all()]
