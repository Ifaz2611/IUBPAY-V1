"""P1 #4 — Query performance & PII: admin user pagination + bounded CSV export."""

import csv
import io

from app.services.report_service import CSV_COLUMNS, stream_transactions_csv
from tests.conftest import (
    login_headers,
    make_menu_item,
    make_user,
    make_vendor,
    pay_order,
    place_order,
    student_client,
    vendor_pair,
)


def _admin_headers(client, db):
    make_user(db, "admin@test.bd", role="admin", name="Admin")
    return login_headers(client, "admin@test.bd")


# ---------- GET /api/admin/users pagination ----------


def test_admin_users_paginated_envelope(client, db):
    ah = _admin_headers(client, db)
    # 12 users total (1 admin + 11 students)
    for i in range(11):
        make_user(db, f"u{i}@test.bd")

    r = client.get("/api/admin/users?limit=5&offset=0", headers=ah)
    assert r.status_code == 200
    body = r.json()
    assert body["total"] == 12
    assert body["limit"] == 5
    assert body["offset"] == 0
    assert len(body["items"]) == 5

    # second page
    r = client.get("/api/admin/users?limit=5&offset=5", headers=ah)
    body = r.json()
    assert len(body["items"]) == 5
    page0_emails = {
        u["email"]
        for u in client.get("/api/admin/users?limit=5&offset=0", headers=ah).json()["items"]
    }
    page1_emails = {u["email"] for u in body["items"]}
    assert page0_emails.isdisjoint(page1_emails), "pages must not overlap"

    # last partial page
    r = client.get("/api/admin/users?limit=5&offset=10", headers=ah)
    assert len(r.json()["items"]) == 2


def test_admin_users_unpaginated_backcompat(client, db):
    ah = _admin_headers(client, db)
    for i in range(3):
        make_user(db, f"x{i}@test.bd")

    r = client.get("/api/admin/users", headers=ah)
    assert r.status_code == 200
    body = r.json()
    assert isinstance(body, list), "no params -> plain list (backward compat)"
    assert len(body) == 4


# ---------- CSV export boundedness ----------


def test_csv_stream_contains_header_and_rows(client, db):
    v, add_item, _ = vendor_pair(db, client)
    mi = add_item()
    h, _ = student_client(db, client, "1")
    for _ in range(3):
        order = place_order(client, h, v.id, [{"menu_item_id": mi.id, "quantity": 1}])
        pay_order(client, h, order["id"])

    rows = list(stream_transactions_csv(db))
    assert len(rows) == 4  # header + 3 payments

    parsed = list(csv.reader(io.StringIO("".join(rows))))
    assert parsed[0] == CSV_COLUMNS
    assert len(parsed) == 4
    amounts = [int(row[5]) for row in parsed[1:]]
    assert all(a > 0 for a in amounts)
    # Streaming must be lazy — each yielded chunk is a single line.
    assert all(r.endswith("\r\n") or r.endswith("\n") for r in rows)


def test_csv_export_endpoint_streams(client, db):
    ah = _admin_headers(client, db)
    v = make_vendor(db)
    make_menu_item(db, v.id)

    r = client.get("/api/admin/reports/export.csv", headers=ah)
    assert r.status_code == 200
    assert r.headers["content-type"].startswith("text/csv")
    assert "attachment" in r.headers["content-disposition"]
    parsed = list(csv.reader(io.StringIO(r.text)))
    assert parsed[0] == CSV_COLUMNS
    # Header only (no payments yet) but valid CSV.
    assert len(parsed) >= 1
