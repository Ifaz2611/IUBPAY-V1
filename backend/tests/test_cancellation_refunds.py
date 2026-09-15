from sqlalchemy import select

from app.models.ledger import LedgerEntry
from app.models.payment import Refund
from tests.conftest import (
    WEBHOOK_HEADERS,
    pay_order,
    place_order,
    student_client,
    vendor_pair,
)


def _paid_order(client, db):
    v, add_item, vh = vendor_pair(db, client)
    mi = add_item("Beef Burger", 220)
    h, s = student_client(db, client, "1")
    order = place_order(client, h, v.id, [{"menu_item_id": mi.id, "quantity": 1}])
    payment = pay_order(client, h, order["id"])
    r = client.post(
        "/api/payments/webhook",
        headers=WEBHOOK_HEADERS,
        json={
            "event": "payment.succeeded",
            "payment_id": payment["payment_id"],
            "provider_transaction_id": payment["provider_transaction_id"],
            "amount_taka": payment["amount_taka"],
        },
    )
    assert r.status_code == 200
    return v, vh, h, s, order, payment


def test_cancel_unpaid_order_no_refund_needed(client, db):
    vendor, add_item, vh = vendor_pair(db, client)
    mi = add_item()
    h, s = student_client(db, client, "1")
    order = place_order(client, h, vendor.id, [{"menu_item_id": mi.id, "quantity": 1}])

    r = client.post(f"/api/orders/{order['id']}/cancel", headers=h)
    assert r.status_code == 200
    assert r.json()["status"] == "CANCELLED"

    entries = db.scalars(select(LedgerEntry).where(LedgerEntry.order_id == order["id"])).all()
    assert len(entries) == 0


def test_cancel_paid_order_creates_refund(client, db):
    v, vh, h, s, order, payment = _paid_order(client, db)

    r = client.post(f"/api/orders/{order['id']}/cancel", headers=h)
    assert r.status_code == 200
    body = r.json()
    assert body["status"] == "REFUNDED"

    refunds = db.scalars(select(Refund)).all()
    assert len(refunds) == 1
    assert refunds[0].amount_taka == payment["amount_taka"]
    assert refunds[0].status.value == "REFUNDED"

    # Ledger: one inflow + one outflow that cancel out.
    entries = db.scalars(
        select(LedgerEntry)
        .where(LedgerEntry.order_id == order["id"])
        .order_by(LedgerEntry.created_at)
    ).all()
    types = [e.entry_type for e in entries]
    assert types.count("PAYMENT") == 1
    assert types.count("REFUND") == 1

    final = client.get(f"/api/orders/{order['id']}", headers=h).json()
    assert final["status"] == "REFUNDED"


def test_cannot_cancel_after_preparing(client, db):
    v, vh, h, s, order, payment = _paid_order(client, db)

    for status in ["ACCEPTED", "PREPARING"]:
        assert (
            client.patch(
                f"/api/orders/{order['id']}/status", json={"status": status}, headers=vh
            ).status_code
            == 200
        )

    r = client.post(f"/api/orders/{order['id']}/cancel", headers=h)
    assert r.status_code == 409


def test_vendor_rejection_refunds_student(client, db):
    v, vh, h, s, order, payment = _paid_order(client, db)

    r = client.patch(f"/api/orders/{order['id']}/status", json={"status": "REJECTED"}, headers=vh)
    assert r.status_code == 200
    body = r.json()
    assert body["status"] == "REFUNDED"

    refunds = db.scalars(select(Refund)).all()
    assert len(refunds) == 1
    assert refunds[0].processed_by is not None  # audited actor recorded

    # No duplicate refund possible.
    r = client.post(f"/api/orders/{order['id']}/cancel", headers=h)
    assert r.status_code == 409
