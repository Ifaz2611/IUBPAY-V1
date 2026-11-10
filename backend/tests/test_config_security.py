import pytest
from pydantic import ValidationError

from app.core.config import Settings
from app.main import create_app


def test_is_prod_detection():
    dev_settings = Settings(ENV="dev")
    assert not dev_settings.is_prod()

    prod_settings = Settings(
        ENV="prod",
        SECRET_KEY="prod-super-secret-key-that-is-at-least-32-chars-long",
        MOCK_PAYMENT_WEBHOOK_TOKEN="prod-mock-token-secret-that-is-at-least-32-chars",
        CORS_ORIGINS="https://iub.edu.bd,https://app.iub.edu.bd",
        ALLOW_TEST_REGISTRATION=False,
    )
    assert prod_settings.is_prod()


def test_prod_rejects_weak_secret_key():
    with pytest.raises(ValidationError, match="SECRET_KEY must be strong"):
        Settings(
            ENV="prod",
            SECRET_KEY="dev-only-secret-change-me-32-chars-long!!",
            MOCK_PAYMENT_WEBHOOK_TOKEN="prod-mock-token-secret-that-is-at-least-32-chars",
            CORS_ORIGINS="https://iub.edu.bd",
            ALLOW_TEST_REGISTRATION=False,
        )


def test_prod_rejects_weak_webhook_token():
    with pytest.raises(ValidationError, match="MOCK_PAYMENT_WEBHOOK_TOKEN must be strong"):
        Settings(
            ENV="prod",
            SECRET_KEY="prod-super-secret-key-that-is-at-least-32-chars-long",
            MOCK_PAYMENT_WEBHOOK_TOKEN="mock-webhook-token-dev-32-chars-long!!",
            CORS_ORIGINS="https://iub.edu.bd",
            ALLOW_TEST_REGISTRATION=False,
        )


def test_prod_rejects_wildcard_cors():
    with pytest.raises(ValidationError, match="CORS_ORIGINS='\\*' is not allowed in production"):
        Settings(
            ENV="prod",
            SECRET_KEY="prod-super-secret-key-that-is-at-least-32-chars-long",
            MOCK_PAYMENT_WEBHOOK_TOKEN="prod-mock-token-secret-that-is-at-least-32-chars",
            CORS_ORIGINS="*",
            ALLOW_TEST_REGISTRATION=False,
        )


def test_prod_rejects_allow_test_registration():
    with pytest.raises(
        ValidationError, match="ALLOW_TEST_REGISTRATION must be false in production"
    ):
        Settings(
            ENV="prod",
            SECRET_KEY="prod-super-secret-key-that-is-at-least-32-chars-long",
            MOCK_PAYMENT_WEBHOOK_TOKEN="prod-mock-token-secret-that-is-at-least-32-chars",
            CORS_ORIGINS="https://iub.edu.bd",
            ALLOW_TEST_REGISTRATION=True,
        )


def test_cors_origins_validation():
    # Valid configurations
    s1 = Settings(CORS_ORIGINS="*")
    assert s1.CORS_ORIGINS == "*"

    s2 = Settings(CORS_ORIGINS="http://localhost:3000, https://cafeteria.iub.edu.bd")
    assert "http://localhost:3000" in s2.CORS_ORIGINS

    # Invalid configurations
    with pytest.raises(ValidationError, match="must be a valid URL with http or https scheme"):
        Settings(CORS_ORIGINS="not-a-valid-url")

    with pytest.raises(ValidationError, match="must be a valid URL with http or https scheme"):
        Settings(CORS_ORIGINS="ftp://cafeteria.iub.edu.bd")

    with pytest.raises(ValidationError, match="origins must not include a path"):
        Settings(CORS_ORIGINS="https://cafeteria.iub.edu.bd/subpath")

    with pytest.raises(ValidationError, match="origins must not include query or fragment"):
        Settings(CORS_ORIGINS="https://cafeteria.iub.edu.bd?foo=bar")


def test_create_app_startup_cors_check(monkeypatch):
    from app.core import config

    # Mock settings with an invalid origin that somehow bypassed or direct
    monkeypatch.setattr(config.settings, "CORS_ORIGINS", "bad-origin-no-scheme")
    with pytest.raises(RuntimeError, match="must be an http or https URL"):
        create_app()
