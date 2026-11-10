"""Regression tests for the SSE order stream authorization bug.

GET /api/payments/{order_id}/stream previously had NO authentication: anyone
who knew an order id could stream its live status and pickup code.
"""

import json

from tests.conftest import (
    student_client,
    vendor_pair,
)


def _create_order(client, headers, item, key):
    r = client.post(
        "/api/orders",
        json={
            "vendor_id": item.vendor_id,
            "items": [{"menu_item_id": item.id, "quantity": 1}],
            "idempotency_key": key,
        },
        headers=headers,
    )
    assert r.status_code == 201, r.text
    order_id = r.json()["id"]
    # Put the order into a terminal state so the SSE stream ends after its
    # first event instead of looping for up to 10 minutes in tests.
    r = client.post(f"/api/orders/{order_id}/cancel", headers=headers)
    assert r.status_code == 200, r.text
    return order_id


def test_stream_requires_auth(client, db):
    sh, _ = student_client(db, client)
    _, add_item, _ = vendor_pair(db, client)
    item = add_item()
    order_id = _create_order(client, sh, item, "key-0001")

    # No token at all -> 401
    r = client.get(f"/api/payments/{order_id}/stream")
    assert r.status_code == 401

    # Invalid token -> 401
    r = client.get(f"/api/payments/{order_id}/stream?token=garbage")
    assert r.status_code == 401


def test_stream_owner_can_connect(client, db):
    sh, _ = student_client(db, client)
    _, add_item, _ = vendor_pair(db, client)
    item = add_item()
    order_id = _create_order(client, sh, item, "key-0002")

    with client.stream("GET", f"/api/payments/{order_id}/stream", headers=sh) as resp:
        assert resp.status_code == 200
        assert resp.headers["content-type"].startswith("text/event-stream")
        first = next(resp.iter_lines())
    data = json.loads(first.removeprefix("data: "))
    assert data["id"] == order_id


def test_stream_other_student_forbidden(client, db):
    sh, _ = student_client(db, client)
    other, _ = student_client(db, client, suffix="b")
    _, add_item, _ = vendor_pair(db, client)
    item = add_item()
    order_id = _create_order(client, sh, item, "key-0003")

    r = client.get(f"/api/payments/{order_id}/stream", headers=other)
    assert r.status_code == 403


def test_stream_other_vendor_forbidden(client, db):
    sh, _ = student_client(db, client)
    _, add_item, _ = vendor_pair(db, client, "Vendor A", suffix="a")
    item = add_item()
    order_id = _create_order(client, sh, item, "key-0004")

    _, _, other_vendor_h = vendor_pair(db, client, "Vendor B", suffix="b")
    r = client.get(f"/api/payments/{order_id}/stream", headers=other_vendor_h)
    assert r.status_code == 403


def test_stream_own_vendor_allowed(client, db):
    sh, _ = student_client(db, client)
    _, add_item, vh = vendor_pair(db, client)
    item = add_item()
    order_id = _create_order(client, sh, item, "key-0005")

    with client.stream("GET", f"/api/payments/{order_id}/stream", headers=vh) as resp:
        assert resp.status_code == 200


def test_stream_unknown_order_404(client, db):
    sh, _ = student_client(db, client)
    r = client.get("/api/payments/nonexistent/stream", headers=sh)
    assert r.status_code == 404
