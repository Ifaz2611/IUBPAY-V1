from tests.conftest import TEST_PASSWORD, login_headers, make_user


def test_login_success(client, db):
    make_user(db, "s@test.bd")
    r = client.post("/api/auth/login", json={"email": "s@test.bd", "password": TEST_PASSWORD})
    assert r.status_code == 200
    body = r.json()
    assert body["token_type"] == "bearer"
    assert body["user"]["role"] == "student"


def test_login_wrong_password(client, db):
    make_user(db, "s@test.bd")
    r = client.post("/api/auth/login", json={"email": "s@test.bd", "password": "wrong-pass"})
    assert r.status_code == 401


def test_me_requires_token(client):
    r = client.get("/api/auth/me")
    assert r.status_code == 401


def test_me_returns_profile(client, db):
    u = make_user(db, "me@test.bd", name="Me")
    h = login_headers(client, u.email)
    r = client.get("/api/auth/me", headers=h)
    assert r.status_code == 200
    assert r.json()["email"] == "me@test.bd"
    assert "password_hash" not in r.json()


def test_password_is_hashed_in_db(client, db):
    u = make_user(db, "hash@test.bd", name="Hashed")
    from sqlalchemy import select

    stored = db.scalar(select(type(u)).where(type(u).id == u.id))
    assert stored.password_hash != TEST_PASSWORD
    assert stored.password_hash.startswith("$2")


def test_register_test_user_admin_only(client, db):
    admin = make_user(db, "admin@test.bd", role="admin")
    student = make_user(db, "stu@test.bd")

    r = client.post(
        "/api/auth/register-test-user",
        json={
            "name": "New Student",
            "email": "new@test.bd",
            "password": "LongEnough1!",
            "role": "student",
        },
        headers=login_headers(client, student.email),
    )
    assert r.status_code == 403

    r = client.post(
        "/api/auth/register-test-user",
        json={
            "name": "New Student",
            "email": "new@test.bd",
            "password": "LongEnough1!",
            "role": "student",
        },
        headers=login_headers(client, admin.email),
    )
    assert r.status_code == 201
