import secrets as _secrets

from pydantic import Field, field_validator, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    APP_NAME: str = "IUB Cafeteria API"
    ENV: str = "dev"

    DATABASE_URL: str = "sqlite:///./iub_cafeteria.db"

    SECRET_KEY: str = Field(default="dev-only-secret-change-me-32-chars-long!!", min_length=16)
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = Field(default=15, ge=5, le=60)
    REFRESH_TOKEN_EXPIRE_MINUTES: int = Field(default=60 * 24 * 7, ge=60)
    JWT_ISSUER: str = "iub-pay"
    JWT_AUDIENCE: str = "iub-pay-client"

    # Comma-separated list of allowed CORS origins ("*" allowed for dev only)
    CORS_ORIGINS: str = "*"

    # Shared secret between the mock payment provider and this backend.
    # In a real system this would be the provider's webhook signature secret.
    MOCK_PAYMENT_WEBHOOK_TOKEN: str = Field(default="mock-webhook-token-dev-32-chars-long!!", min_length=16)

    # Flat service fee charged per order, in whole Taka.
    SERVICE_FEE_TAKA: int = 5

    ALLOW_TEST_REGISTRATION: bool = True
    # Rate limiting
    RATE_LIMIT_LOGIN: str = "5/minute"
    RATE_LIMIT_WEBHOOK: str = "10/minute"
    ACCOUNT_LOCKOUT_ATTEMPTS: int = 5
    ACCOUNT_LOCKOUT_MINUTES: int = 15

    @field_validator("SECRET_KEY", "MOCK_PAYMENT_WEBHOOK_TOKEN")
    @classmethod
    def _not_default_in_prod(cls, v: str, info) -> str:
        return v

    @model_validator(mode="after")
    def _validate_prod_secrets(self):
        weak_defaults = {"dev-only-secret-change-me", "mock-webhook-token-dev", "change-me-in-real-deployments"}
        if self.ENV.lower() in ("prod", "production"):
            if self.SECRET_KEY in weak_defaults or len(self.SECRET_KEY) < 32:
                raise ValueError("SECRET_KEY must be strong (>=32 chars) in production")
            if self.MOCK_PAYMENT_WEBHOOK_TOKEN in weak_defaults or len(self.MOCK_PAYMENT_WEBHOOK_TOKEN) < 32:
                raise ValueError("MOCK_PAYMENT_WEBHOOK_TOKEN must be strong in production")
            if self.CORS_ORIGINS.strip() == "*":
                raise ValueError("CORS_ORIGINS='*' is not allowed in production")
            if self.ALLOW_TEST_REGISTRATION:
                raise ValueError("ALLOW_TEST_REGISTRATION must be false in production")
        return self

    def is_prod(self) -> bool:
        return self.ENV.lower() in ("prod", "production")


settings = Settings()
