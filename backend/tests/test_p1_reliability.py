"""P1 reliability & correctness tests.

Covers the P1 checklist items:
- webhook auth: missing/wrong X-Webhook-Token -> 401 (not 422)
- webhook validation: unknown event -> 400
- identifier generation: order_number format + uniqueness, pickup_code
  uniqueness among active orders (retry-on-collision)
"""

import uuid

from sqlalchemy import func, select

from app.models.order import Order
from tests.conftest import (
    TEST_PASSWORD,
    WEBHOOK_HEADERS,
    make_user,
    pay_order,
    place_order,
    student_client,
    vendor_pair,
)

# ---------- webhook auth (P1 #2) ----------


def test_webhook_missing_token_returns_401_not_422(client, db):
    v, add_item, _ = vendor_pair(db, client)
    mi = add_item()
    h, _ = student_client(db, client, "1")
    order = place_order(client, h, v.id, [{"menu_item_id": mi.id, "quantity": 1}])
    payment = pay_order(client, h, order["id"])

    r = client.post(
        "/api/payments/webhook",
        headers={},  # no X-Webhook-Token header at all
        json={
            "event": "payment.succeeded",
            "payment_id": payment["payment_id"],
            "provider_transaction_id": payment["provider_transaction_id"],
            "amount_taka": payment["amount_taka"],
        },
    )
    assert r.status_code == 401, "missing header must be 401 (auth), not 422 (validation)"
    assert r.json()["detail"] == "Missing webhook token"


def test_webhook_wrong_token_returns_401(client, db):
    v, add_item, _ = vendor_pair(db, client)
    mi = add_item()
    h, _ = student_client(db, client, "1")
    order = place_order(client, h, v.id, [{"menu_item_id": mi.id, "quantity": 1}])
    payment = pay_order(client, h, order["id"])

    r = client.post(
        "/api/payments/webhook",
        headers={"X-Webhook-Token": "wrong-token-value-000000000000"},
        json={
            "event": "payment.succeeded",
            "payment_id": payment["payment_id"],
            "provider_transaction_id": payment["provider_transaction_id"],
            "amount_taka": payment["amount_taka"],
        },
    )
    assert r.status_code == 401
    assert r.json()["detail"] == "Invalid webhook token"


def test_webhook_unknown_event_rejected(client, db):
    v, add_item, _ = vendor_pair(db, client)
    mi = add_item()
    h, _ = student_client(db, client, "1")
    order = place_order(client, h, v.id, [{"menu_item_id": mi.id, "quantity": 1}])
    payment = pay_order(client, h, order["id"])

    # HTTP path: schema rejects the payload with 422 before reaching the service.
    r = client.post(
        "/api/payments/webhook",
        headers=WEBHOOK_HEADERS,
        json={
            "event": "payment.refunded",
            "payment_id": payment["payment_id"],
            "provider_transaction_id": payment["provider_transaction_id"],
            "amount_taka": payment["amount_taka"],
        },
    )
    assert r.status_code == 422

    # Defense-in-depth: the service-level guard raises 400 if ever bypassed.
    from fastapi import HTTPException

    from app.models.payment import Payment
    from app.services.payment_service import apply_webhook_event

    real_payment = db.get(Payment, payment["payment_id"])
    try:
        apply_webhook_event(
            db,
            payment=real_payment,
            event="payment.exploded",
            amount_taka=payment["amount_taka"],
            failure_reason=None,
        )
        raised = None
    except HTTPException as exc:
        raised = exc
    assert raised is not None and raised.status_code == 400


# ---------- identifiers (P1 #3) ----------


def test_order_number_format_and_uniqueness(client, db):
    v, add_item, _ = vendor_pair(db, client)
    mi = add_item()
    h, _ = student_client(db, client, "1")

    numbers = set()
    for _ in range(5):
        order = place_order(client, h, v.id, [{"menu_item_id": mi.id, "quantity": 1}])
        number = order["order_number"]
        # Format: IUB-YYYYMMDD-XXXXXX (6 chars suffix)
        parts = number.split("-")
        assert len(parts) == 3, number
        assert parts[0] == "IUB" and len(parts[1]) == 8 and parts[1].isdigit(), number
        assert len(parts[2]) == 6, number
        numbers.add(number)

    assert len(numbers) == 5, "order numbers must be unique"
    count = db.scalar(select(func.count(Order.id)))
    assert count == 5


def test_pickup_code_unique_among_active_orders(client, db):
    v, add_item, _ = vendor_pair(db, client)
    mi = add_item()
    h, _ = student_client(db, client, "1")

    alphabet = set("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
    active_codes = []
    order_ids = []
    for _ in range(5):
        order = place_order(client, h, v.id, [{"menu_item_id": mi.id, "quantity": 1}])
        code = order["pickup_code"]
        assert len(code) == 6
        assert set(code) <= alphabet, f"confusable characters in pickup code: {code}"
        active_codes.append(code)
        order_ids.append(order["id"])

    assert len(set(active_codes)) == 5, "active orders must never share a pickup code"

    # Cancel them all; uniqueness only applies among active orders, so new
    # orders may reuse these codes.
    for oid in order_ids:
        r = client.post(f"/api/orders/{oid}/cancel", headers=h)
        assert r.status_code == 200

    for _ in range(3):
        order = place_order(client, h, v.id, [{"menu_item_id": mi.id, "quantity": 1}])

    active_now = db.scalars(
        select(Order.pickup_code).where(Order.status.notin_(["COLLECTED", "CANCELLED", "REFUNDED"]))
    ).all()
    assert len(active_now) == len(set(active_now)), "duplicate active pickup codes in DB"


def test_pickup_code_hidden_from_other_users(client, db):
    """The pickup code is a shared secret between student and vendor staff."""
    v, add_item, _ = vendor_pair(db, client)
    mi = add_item()
    h, _ = student_client(db, client, "1")
    order = place_order(client, h, v.id, [{"menu_item_id": mi.id, "quantity": 1}])
    assert order["pickup_code"]  # owner sees it at creation

    make_user(db, "other@test.bd")
    r = client.post("/api/auth/login", json={"email": "other@test.bd", "password": TEST_PASSWORD})
    other_h = {"Authorization": f"Bearer {r.json()['access_token']}"}

    # Another student cannot even read this order.
    r = client.get(f"/api/orders/{order['id']}", headers=other_h)
    assert r.status_code == 403

    # Vendor staff of a different vendor cannot either.
    _, _, other_vh = vendor_pair(db, client, "Other Vendor", suffix="z")
    r = client.get(f"/api/orders/{order['id']}", headers=other_vh)
    assert r.status_code in (403, 404)


def test_idempotency_key_retries_return_same_order(client, db):
    """The unique constraint on idempotency_key + IntegrityError fallback keeps
    duplicate submissions returning the same order (P1 #1)."""
    v, add_item, _ = vendor_pair(db, client)
    mi = add_item()
    h, _ = student_client(db, client, "1")

    key = uuid.uuid4().hex
    body = {
        "vendor_id": v.id,
        "items": [{"menu_item_id": mi.id, "quantity": 1}],
        "idempotency_key": key,
    }
    responses = [client.post("/api/orders", json=body, headers=h) for _ in range(3)]
    assert all(r.status_code == 201 for r in responses)
    ids = {r.json()["id"] for r in responses}
    assert len(ids) == 1, "all retries must resolve to the same order"

    count = db.scalar(select(func.count(Order.id)).where(Order.idempotency_key == key))
    assert count == 1
