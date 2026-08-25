"""Role authorization and cross-tenant access control."""
import pytest

from tests.conftest import (
    WEBHOOK_HEADERS,
    login_headers,
    make_user,
    pay_order,
    place_order,
    student_client,
    vendor_pair,
)


def test_student_cannot_access_vendor_endpoints(client, db):
    h, _ = student_client(db, client)
    r = client.get("/api/vendors/me/orders", headers=h)
    assert r.status_code == 403


def test_vendor_cannot_create_orders(client, db):
    _, _, vh = vendor_pair(db, client)
    r = client.post("/api/orders", json={
        "vendor_id": "x", "items": [{"menu_item_id": "y", "quantity": 1}],
        "idempotency_key": "abcd1234"}, headers=vh)
    assert r.status_code == 403


def test_student_cannot_view_other_students_order(client, db):
    v1, item, _ = vendor_pair(db, client, "V1", "a")
    menu_item = item()

    h1, s1 = student_client(db, client, "1")
    order = place_order(client, h1, v1.id, [{"menu_item_id": menu_item.id, "quantity": 1}])

    h2, _ = student_client(db, client, "2")
    r = client.get(f"/api/orders/{order['id']}", headers=h2)
    assert r.status_code == 403

    # Also invisible in the other student's order list
    r = client.get("/api/students/me/orders", headers=h2)
    assert all(o["id"] != order["id"] for o in r.json())


def test_vendor_cannot_view_other_vendors_order(client, db):
    v1, add_item, _ = vendor_pair(db, client, "Vendor One", "a")
    mi = add_item()
    h, _ = student_client(db, client, "1")
    order = place_order(client, h, v1.id, [{"menu_item_id": mi.id, "quantity": 1}])
    pay_order(client, h, order["id"])

    _, _, other_vendor_h = vendor_pair(db, client, "Vendor Two", "b")
    r = client.get(f"/api/orders/{order['id']}", headers=other_vendor_h)
    assert r.status_code == 403

    r = client.patch(f"/api/orders/{order['id']}/status",
                     json={"status": "ACCEPTED"}, headers=other_vendor_h)
    assert r.status_code == 403


def test_unauthenticated_request_rejected(client):
    r = client.get("/api/students/me/orders")
    assert r.status_code == 401


def test_webhook_rejects_bad_token(client, db):
    v, add_item, _ = vendor_pair(db, client, "V", "a")
    mi = add_item()
    h, _ = student_client(db, client, "1")
    order = place_order(client, h, v.id, [{"menu_item_id": mi.id, "quantity": 1}])
    payment = pay_order(client, h, order["id"])

    r = client.post("/api/payments/webhook", headers={"X-Webhook-Token": "WRONG"}, json={
        "event": "payment.succeeded", "payment_id": payment["payment_id"],
        "provider_transaction_id": payment["provider_transaction_id"],
        "amount_taka": 185})
    assert r.status_code == 401
