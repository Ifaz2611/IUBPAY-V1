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


def test_login_lockout_after_repeated_failures(client, db):
    make_user(db, "lockout@test.bd")
    for _ in range(5):
        r = client.post(
            "/api/auth/login",
            json={"email": "lockout@test.bd", "password": "wrong-password"},
        )
        assert r.status_code == 401

    r6 = client.post(
        "/api/auth/login",
        json={"email": "lockout@test.bd", "password": "wrong-password"},
    )
    assert r6.status_code == 429
    assert "locked" in r6.json()["detail"].lower()

    r_locked = client.post(
        "/api/auth/login",
        json={"email": "lockout@test.bd", "password": TEST_PASSWORD},
    )
    assert r_locked.status_code == 429
    assert "locked" in r_locked.json()["detail"].lower()


def test_refresh_token_rotation_and_revocation(client, db):
    make_user(db, "refresh@test.bd")
    r = client.post(
        "/api/auth/login",
        json={"email": "refresh@test.bd", "password": TEST_PASSWORD},
    )
    assert r.status_code == 200
    data = r.json()
    refresh_token = data["refresh_token"]
    assert refresh_token

    r_refresh = client.post("/api/auth/refresh", json={"refresh_token": refresh_token})
    assert r_refresh.status_code == 200
    new_data = r_refresh.json()
    new_refresh = new_data["refresh_token"]
    assert new_refresh != refresh_token

    r_old = client.post("/api/auth/refresh", json={"refresh_token": refresh_token})
    assert r_old.status_code == 401


def test_logout_revokes_token(client, db):
    make_user(db, "logout@test.bd")
    r = client.post(
        "/api/auth/login",
        json={"email": "logout@test.bd", "password": TEST_PASSWORD},
    )
    token = r.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    r_me = client.get("/api/auth/me", headers=headers)
    assert r_me.status_code == 200

    r_logout = client.post("/api/auth/logout", headers=headers)
    assert r_logout.status_code == 200

    r_me_after = client.get("/api/auth/me", headers=headers)
    assert r_me_after.status_code == 401

