from sqlalchemy import select

from app.models.ledger import LedgerEntry
from tests.conftest import (
    WEBHOOK_HEADERS,
    pay_order,
    place_order,
    student_client,
    vendor_pair,
)


def test_successful_payment_flow_via_webhook(client, db):
    v, add_item, vh = vendor_pair(db, client)
    mi = add_item()
    h, s = student_client(db, client, "1")
    order = place_order(client, h, v.id, [{"menu_item_id": mi.id, "quantity": 2}])
    payment = pay_order(client, h, order["id"])

    # Order is PROCESSING while payment is in flight; not yet visible to vendor.
    assert payment["status"] == "PROCESSING"
    r = client.get(f"/api/orders/{order['id']}", headers=h)
    assert r.json()["status"] == "PAYMENT_PROCESSING"
    r = client.get("/api/vendors/me/orders", headers=vh)
    assert len(r.json()) == 0

    # Simulated provider webhook.
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
    assert r.json()["status"] == "processed"

    r = client.get(f"/api/orders/{order['id']}", headers=h)
    assert r.json()["status"] == "PAID"

    # Ledger has exactly one PAYMENT entry of the full amount.
    entries = db.scalars(
        select(LedgerEntry).where(
            LedgerEntry.order_id == order["id"], LedgerEntry.entry_type == "PAYMENT"
        )
    ).all()
    assert len(entries) == 1
    assert entries[0].amount_taka == payment["amount_taka"]


def test_failed_payment(client, db):
    v, add_item, _ = vendor_pair(db, client)
    mi = add_item()
    h, _ = student_client(db, client, "1")
    order = place_order(client, h, v.id, [{"menu_item_id": mi.id, "quantity": 1}])
    payment = pay_order(client, h, order["id"])

    r = client.post(
        "/api/payments/webhook",
        headers=WEBHOOK_HEADERS,
        json={
            "event": "payment.failed",
            "payment_id": payment["payment_id"],
            "provider_transaction_id": payment["provider_transaction_id"],
            "amount_taka": payment["amount_taka"],
            "failure_reason": "MOCK_INSUFFICIENT_BALANCE",
        },
    )
    assert r.status_code == 200

    r = client.get(f"/api/orders/{order['id']}", headers=h)
    body = r.json()
    assert body["status"] == "PAYMENT_FAILED"
    assert any(p["status"] == "FAILED" for p in body["payments"])

    # No money entered the ledger.
    entries = db.scalars(select(LedgerEntry).where(LedgerEntry.order_id == order["id"])).all()
    assert len(entries) == 0


def test_duplicate_webhook_is_idempotent_and_never_double_charges(client, db):
    v, add_item, _ = vendor_pair(db, client)
    mi = add_item()
    h, _ = student_client(db, client, "1")
    order = place_order(client, h, v.id, [{"menu_item_id": mi.id, "quantity": 1}])
    payment = pay_order(client, h, order["id"])

    payload = {
        "event": "payment.succeeded",
        "payment_id": payment["payment_id"],
        "provider_transaction_id": payment["provider_transaction_id"],
        "amount_taka": payment["amount_taka"],
    }
    responses = [
        client.post("/api/payments/webhook", headers=WEBHOOK_HEADERS, json=payload)
        for _ in range(3)
    ]

    # First callback processed; repeats are acknowledged but harmless.
    assert responses[0].json()["status"] == "processed"
    for dup in responses[1:]:
        assert dup.status_code == 200
        assert dup.json()["status"] == "already_processed"

    entries = db.scalars(
        select(LedgerEntry).where(
            LedgerEntry.entry_type == "PAYMENT", LedgerEntry.order_id == order["id"]
        )
    ).all()
    assert len(entries) == 1, "duplicate callback must not create a second ledger entry"


def test_amount_mismatch_in_webhook_rejected(client, db):
    v, add_item, _ = vendor_pair(db, client)
    mi = add_item()
    h, _ = student_client(db, client, "1")
    order = place_order(client, h, v.id, [{"menu_item_id": mi.id, "quantity": 1}])
    payment = pay_order(client, h, order["id"])

    r = client.post(
        "/api/payments/webhook",
        headers=WEBHOOK_HEADERS,
        json={
            "event": "payment.succeeded",
            "payment_id": payment["payment_id"],
            "provider_transaction_id": payment["provider_transaction_id"],
            "amount_taka": 1,  # tampered amount
        },
    )
    assert r.status_code == 400


def test_student_cannot_pay_same_order_twice(client, db):
    v, add_item, _ = vendor_pair(db, client)
    mi = add_item()
    h, _ = student_client(db, client, "1")
    order = place_order(client, h, v.id, [{"menu_item_id": mi.id, "quantity": 1}])
    p1 = pay_order(client, h, order["id"])
    p2 = pay_order(client, h, order["id"])  # returns same active payment, no double charge
    assert p1["payment_id"] == p2["payment_id"]

    # Complete it, then trying again must fail outright.
    client.post("/api/payments/mock/complete", json={"payment_id": p1["payment_id"]}, headers=h)
    r = client.post("/api/payments/create", json={"order_id": order["id"]}, headers=h)
    assert r.status_code == 409
