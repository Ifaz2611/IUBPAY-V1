import uuid

from tests.conftest import (
    make_menu_item,
    pay_order,
    place_order,
    student_client,
    vendor_pair,
)


def _order_body(vendor_id, items):
    return {"vendor_id": vendor_id, "items": items, "idempotency_key": uuid.uuid4().hex}


def test_order_creation_computes_totals_on_backend(client, db):
    """Client never sends prices; backend computes totals from DB values."""
    v, _, _ = vendor_pair(db, client)
    a = make_menu_item(db, v.id, "Biryani", 180)
    b = make_menu_item(db, v.id, "Tea", 25)

    h, _ = student_client(db, client, "1")
    order = place_order(
        client,
        h,
        v.id,
        [
            {"menu_item_id": a.id, "quantity": 2},
            {"menu_item_id": b.id, "quantity": 1},
        ],
    )

    assert order["subtotal_taka"] == 180 * 2 + 25  # 385
    assert order["service_fee_taka"] == 5
    assert order["total_amount_taka"] == 390
    assert order["status"] == "PENDING_PAYMENT"
    assert len(order["items"]) == 2
    assert order["order_number"].startswith("IUB-")


def test_order_totals_use_db_prices_not_client_values(client, db):
    v, _, _ = vendor_pair(db, client)
    tea = make_menu_item(db, v.id, "Tea", 25)
    h, _ = student_client(db, client, "1")
    # No matter what the client sends, price always comes from the DB row.
    order = place_order(client, h, v.id, [{"menu_item_id": tea.id, "quantity": 3}])
    assert order["total_amount_taka"] == 25 * 3 + 5


def test_order_cannot_mix_items_from_two_vendors(client, db):
    v1, add1, _ = vendor_pair(db, client, "V1", "a")
    v2, add2, _ = vendor_pair(db, client, "V2", "b")
    i1 = add1()
    i2 = add2("Coffee", 60)

    h, _ = student_client(db, client, "1")
    r = client.post(
        "/api/orders",
        json=_order_body(
            v1.id, [{"menu_item_id": i1.id, "quantity": 1}, {"menu_item_id": i2.id, "quantity": 1}]
        ),
        headers=h,
    )
    assert r.status_code in (403, 422)


def test_order_creation_is_idempotent(client, db):
    v, add_item, _ = vendor_pair(db, client)
    mi = add_item()
    h, _ = student_client(db, client, "1")

    key = uuid.uuid4().hex
    body = {
        "vendor_id": v.id,
        "items": [{"menu_item_id": mi.id, "quantity": 2}],
        "idempotency_key": key,
    }
    r1 = client.post("/api/orders", json=body, headers=h)
    r2 = client.post("/api/orders", json=body, headers=h)

    assert r1.status_code == 201 and r2.status_code == 201
    assert r1.json()["id"] == r2.json()["id"]
    assert r1.json()["order_number"] == r2.json()["order_number"]

    from sqlalchemy import func, select

    from app.models.order import Order

    count = db.scalar(select(func.count(Order.id)).where(Order.idempotency_key == key))
    assert count == 1


def test_unavailable_item_cannot_be_ordered(client, db):
    v, _, _ = vendor_pair(db, client)
    mi = make_menu_item(db, v.id, "Old Stock", 100)
    mi.is_available = False
    db.commit()

    h, _ = student_client(db, client, "1")
    r = client.post(
        "/api/orders", json=_order_body(v.id, [{"menu_item_id": mi.id, "quantity": 1}]), headers=h
    )
    assert r.status_code == 422


def test_invalid_status_transition_rejected(client, db):
    v, add_item, vh = vendor_pair(db, client)
    mi = add_item()
    h, _ = student_client(db, client, "1")
    order = place_order(client, h, v.id, [{"menu_item_id": mi.id, "quantity": 1}])
    payment = pay_order(client, h, order["id"])
    # complete the mock payment so the order becomes PAID
    r = client.post(
        "/api/payments/mock/complete", json={"payment_id": payment["payment_id"]}, headers=h
    )
    assert r.status_code == 200 and r.json()["payment_status"] == "SUCCEEDED"
    oid = order["id"]

    # PAID -> READY skips ACCEPTED/PREPARING: forbidden.
    r = client.patch(f"/api/orders/{oid}/status", json={"status": "READY"}, headers=vh)
    assert r.status_code == 409

    # Valid happy-path transitions.
    for status in ["ACCEPTED", "PREPARING", "READY", "COLLECTED"]:
        r = client.patch(f"/api/orders/{oid}/status", json={"status": status}, headers=vh)
        assert r.status_code == 200, r.text
        assert r.json()["status"] == status

    # COLLECTED is terminal.
    r = client.patch(f"/api/orders/{oid}/status", json={"status": "PREPARING"}, headers=vh)
    assert r.status_code == 409


def test_vendor_does_not_see_unpaid_orders(client, db):
    v, add_item, vh = vendor_pair(db, client)
    mi = add_item()
    h, _ = student_client(db, client, "1")
    order = place_order(client, h, v.id, [{"menu_item_id": mi.id, "quantity": 1}])

    r = client.get("/api/vendors/me/orders", headers=vh)
    assert all(o["id"] != order["id"] for o in r.json())
