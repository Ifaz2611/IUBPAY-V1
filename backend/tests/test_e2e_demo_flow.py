"""End-to-end demo flow:

student login -> browse vendors -> menu -> create order -> mock payment ->
webhook verification -> vendor sees paid order -> vendor marks ready ->
student views receipt.
"""
import uuid

from app.models.user import User as UserModel
from tests.conftest import (
    WEBHOOK_HEADERS,
    login_headers,
    make_menu_item,
    make_user,
    student_client,
    vendor_pair,
)


def test_e2e_demo_flow(client, db):
    # ---------- setup: two vendors with menus + staff accounts ----------
    cafeteria_v, add_cafeteria_item, _ = vendor_pair(db, client, "IUB Main Cafeteria", "a")
    foodcourt_v, _, _ = vendor_pair(db, client, "IUB Food Court", "b")
    biryani = add_cafeteria_item("Chicken Biryani", 180)
    tea = add_cafeteria_item("Tea", 25)
    make_menu_item(db, foodcourt_v.id, "Chicken Sandwich", 150)

    # ---------- 1. student logs in ----------
    stu_h, _ = student_client(db, client, "e2e")

    # ---------- 2. browse vendors and menus ----------
    r = client.get("/api/vendors", headers=stu_h)
    assert r.status_code == 200
    assert {v["name"] for v in r.json()} >= {"IUB Main Cafeteria", "IUB Food Court"}

    r = client.get(f"/api/vendors/{cafeteria_v.id}/menu", headers=stu_h)
    assert any(m["name"] == "Chicken Biryani" for m in r.json())

    # ---------- 3. cart: create order (biryani x2 + tea x1) ----------
    body = {
        "vendor_id": cafeteria_v.id,
        "items": [
            {"menu_item_id": biryani.id, "quantity": 2},
            {"menu_item_id": tea.id, "quantity": 1},
        ],
        "idempotency_key": uuid.uuid4().hex,
    }
    r = client.post("/api/orders", json=body, headers=stu_h)
    assert r.status_code == 201, r.text
    order = r.json()
    assert order["total_amount_taka"] == 180 * 2 + 25 + 5  # subtotal + service fee

    # ---------- 4. mock payment + webhook verification ----------
    r = client.post("/api/payments/create", json={"order_id": order["id"]}, headers=stu_h)
    assert r.status_code == 201
    payment = r.json()
    assert payment["status"] == "PROCESSING"

    r = client.post("/api/payments/mock/complete",
                    json={"payment_id": payment["payment_id"], "delay_seconds": 0},
                    headers=stu_h)
    assert r.status_code == 200
    assert r.json()["payment_status"] == "SUCCEEDED"

    # duplicate callback must be harmless
    r = client.post("/api/payments/webhook", headers=WEBHOOK_HEADERS, json={
        "event": "payment.succeeded",
        "payment_id": payment["payment_id"],
        "provider_transaction_id": payment["provider_transaction_id"],
        "amount_taka": payment["amount_taka"],
    })
    assert r.json()["status"] == "already_processed"

    # ---------- 5. vendor sees the PAID order ----------
    staff = db.query(UserModel).filter(
        UserModel.vendor_id == cafeteria_v.id, UserModel.role == "vendor").first()
    assert staff is not None
    vh = login_headers(client, staff.email)

    r = client.get("/api/vendors/me/orders", headers=vh)
    incoming = [o for o in r.json() if o["id"] == order["id"]]
    assert len(incoming) == 1 and incoming[0]["status"] == "PAID"

    # ---------- 6. vendor accepts -> preparing -> ready ----------
    oid = order["id"]
    for status in ["ACCEPTED", "PREPARING", "READY"]:
        r = client.patch(f"/api/orders/{oid}/status", json={"status": status}, headers=vh)
        assert r.status_code == 200, r.text

    # ---------- 7. student views receipt / tracking ----------
    receipt = client.get(f"/api/orders/{oid}", headers=stu_h).json()
    assert receipt["status"] == "READY"
    snap = {i["item_name_snapshot"]: i["unit_price_snapshot_taka"] for i in receipt["items"]}
    assert snap == {"Chicken Biryani": 180, "Tea": 25}
    assert len(receipt["pickup_code"]) == 4
    assert any(p["status"] == "SUCCEEDED" for p in receipt["payments"])

    # ---------- bonus: reports reconcile with the ledger ----------
    from tests.conftest import make_user

    admin_h = login_headers(client, make_user(db, "admin@e2e.example.com", role="admin").email)
    r = client.get("/api/admin/reports/summary", headers=admin_h)
    assert r.status_code == 200
    summary = r.json()
    assert summary["total_sales_taka"] == 390
    assert summary["paid_orders"] == 1

    csv_resp = client.get("/api/admin/reports/export.csv", headers=admin_h)
    assert csv_resp.status_code == 200
    assert "order_number" in csv_resp.text
