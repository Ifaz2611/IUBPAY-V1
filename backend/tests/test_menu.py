def test_public_menu_lists_available_items(client, db):
    from tests.conftest import vendor_pair

    v, add_item, _ = vendor_pair(db, client)
    add_item("Chicken Biryani", 180)
    add_item("Tea", 25)

    from fastapi.testclient import TestClient  # noqa: F401

    from tests.conftest import student_client

    sh, _ = student_client(db, client, "x")
    r = client.get(f"/api/vendors/{v.id}/menu", headers=sh)
    assert r.status_code == 200
    names = {m["name"] for m in r.json()}
    assert names == {"Chicken Biryani", "Tea"}
    prices = {m["name"]: m["price_taka"] for m in r.json()}
    assert prices["Chicken Biryani"] == 180


def test_disabled_items_hidden_by_default(client, db):
    from tests.conftest import make_menu_item, student_client, vendor_pair

    v, add_item, vh = vendor_pair(db, client)
    visible = add_item("Coffee", 60)
    hidden = make_menu_item(db, v.id, "Old Item", 50)
    hidden.is_available = False
    db.commit()

    sh, _ = student_client(db, client, "x")
    r = client.get(f"/api/vendors/{v.id}/menu", headers=sh)
    ids = {m["id"] for m in r.json()}
    assert visible.id in ids and hidden.id not in ids

    # Vendor can request unavailable items for management view
    r = client.get(f"/api/vendors/{v.id}/menu?include_unavailable=true", headers=vh)
    assert len(r.json()) == 2
