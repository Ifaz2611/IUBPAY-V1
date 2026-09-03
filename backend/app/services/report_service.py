"""Aggregated reports for admins. All figures derive from the ledger where
possible so reports always reconcile with recorded money movement."""
import csv
import io
from collections import defaultdict
from datetime import date, timedelta

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.ledger import LedgerEntry
from app.models.order import Order
from app.models.payment import Payment
from app.models.user import User
from app.models.vendor import Vendor
from app.utils.enums import LedgerEntryType, OrderStatus, PaymentStatus


def summary(db: Session) -> dict:
    total_orders = db.scalar(select(func.count(Order.id))) or 0
    paid_orders = db.scalar(
        select(func.count(Order.id)).where(Order.status.in_([
            OrderStatus.PAID, OrderStatus.ACCEPTED, OrderStatus.PREPARING,
            OrderStatus.READY, OrderStatus.COLLECTED]))
    ) or 0

    sales = db.scalar(
        select(func.coalesce(func.sum(LedgerEntry.amount_taka), 0)).where(
            LedgerEntry.entry_type == LedgerEntryType.PAYMENT)
    ) or 0
    refunds = -db.scalar(
        select(func.coalesce(func.sum(LedgerEntry.amount_taka), 0)).where(
            LedgerEntry.entry_type == LedgerEntryType.REFUND)
    ) or 0
    failed_payments = db.scalar(
        select(func.count(Payment.id)).where(Payment.status == PaymentStatus.FAILED)
    ) or 0
    active_vendors = db.scalar(
        select(func.count(Vendor.id)).where(Vendor.status == "APPROVED")
    ) or 0
    students = db.scalar(
        select(func.count(User.id)).where(User.role == "student")
    ) or 0

    return {
        "total_orders": total_orders,
        "paid_orders": paid_orders,
        "total_sales_taka": int(sales),
        "total_refunds_taka": int(refunds),
        "net_revenue_taka": int(sales - refunds),
        "failed_payments": failed_payments,
        "active_vendors": active_vendors,
        "registered_students": students,
    }


def daily(db: Session, days: int = 30) -> list[dict]:
    since = date.today() - timedelta(days=days - 1)
    # Try SQL aggregation; fallback to Python for SQLite compat
    try:
        from sqlalchemy import String as SAString, cast
        # Use func.date for SQLite/Postgres agnostic
        rows_q = db.execute(
            select(
                func.date(LedgerEntry.created_at).label("day"),
                func.count(func.distinct(LedgerEntry.order_id)).filter(LedgerEntry.entry_type == LedgerEntryType.PAYMENT).label("orders"),
                func.coalesce(func.sum(LedgerEntry.amount_taka).filter(LedgerEntry.entry_type == LedgerEntryType.PAYMENT), 0).label("sales"),
                func.coalesce(func.sum(-LedgerEntry.amount_taka).filter(LedgerEntry.entry_type == LedgerEntryType.REFUND), 0).label("refunds"),
            ).where(LedgerEntry.created_at >= since).group_by(func.date(LedgerEntry.created_at))
        ).all()
        by_day = {str(r.day): {"orders": r.orders, "sales_taka": int(r.sales), "refunds_taka": int(r.refunds)} for r in rows_q}
        return [{"date": (since + timedelta(days=i)).isoformat(), "orders": by_day.get((since + timedelta(days=i)).isoformat(), {}).get("orders", 0), "sales_taka": by_day.get((since + timedelta(days=i)).isoformat(), {}).get("sales_taka", 0), "refunds_taka": by_day.get((since + timedelta(days=i)).isoformat(), {}).get("refunds_taka", 0)} for i in range(days)]
    except Exception:
        entries = db.scalars(select(LedgerEntry).where(LedgerEntry.created_at >= since)).all()
        buckets: dict[str, dict] = defaultdict(lambda: {"orders": set(), "sales_taka": 0, "refunds_taka": 0})
        for e in entries:
            day = e.created_at.date().isoformat() if e.created_at else date.today().isoformat()
            b = buckets[day]
            if e.entry_type == LedgerEntryType.PAYMENT:
                b["sales_taka"] += e.amount_taka
                if e.order_id:
                    b["orders"].add(e.order_id)
            elif e.entry_type == LedgerEntryType.REFUND:
                b["refunds_taka"] += -e.amount_taka
        rows = []
        for i in range(days):
            d = (since + timedelta(days=i)).isoformat()
            b = buckets.get(d)
            rows.append({"date": d, "orders": len(b["orders"]) if b else 0, "sales_taka": b["sales_taka"] if b else 0, "refunds_taka": b["refunds_taka"] if b else 0})
        return rows


def vendor_sales(db: Session, vendor_id: str, since: date | None = None) -> dict:
    from app.models.order import Order, OrderItem
    q = select(func.coalesce(func.sum(OrderItem.subtotal_taka), 0)).join(Order, OrderItem.order_id == Order.id).where(Order.vendor_id == vendor_id, Order.status.in_([OrderStatus.PAID, OrderStatus.ACCEPTED, OrderStatus.PREPARING, OrderStatus.READY, OrderStatus.COLLECTED]))
    if since:
        q = q.where(Order.created_at >= since)
    total = db.scalar(q) or 0
    # also count
    cnt = db.scalar(select(func.count(Order.id)).where(Order.vendor_id == vendor_id, Order.status.in_([OrderStatus.PAID, OrderStatus.ACCEPTED, OrderStatus.PREPARING, OrderStatus.READY, OrderStatus.COLLECTED]))) or 0
    return {"vendor_id": vendor_id, "total_sales_taka": int(total), "paid_orders": int(cnt)}


def transactions_csv(db: Session) -> str:
    rows = db.execute(
        select(Payment, Order, User, Vendor)
        .join(Order, Payment.order_id == Order.id)
        .join(User, Order.student_id == User.id)
        .join(Vendor, Order.vendor_id == Vendor.id)
        .order_by(Payment.created_at.desc())
    ).all()

    buf = io.StringIO()
    writer = csv.writer(buf)
    writer.writerow([
        "payment_id", "created_at", "provider", "provider_transaction_id",
        "status", "amount_taka", "failure_reason",
        "order_number", "vendor_name", "student_email", "order_status",
    ])
    for p, o, u, v in rows:
        writer.writerow([
            p.id, p.created_at, p.provider, p.provider_transaction_id,
            p.status.value if hasattr(p.status, "value") else p.status,
            p.amount_taka, p.failure_reason or "",
            o.order_number, v.name, u.email,
            o.status.value if hasattr(o.status, "value") else o.status,
        ])
    return buf.getvalue()
