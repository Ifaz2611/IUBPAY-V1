from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    APP_NAME: str = "IUB Cafeteria API"
    ENV: str = "dev"

    DATABASE_URL: str = "sqlite:///./iub_cafeteria.db"

    SECRET_KEY: str = "dev-only-secret-change-me"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 720

    # Comma-separated list of allowed CORS origins ("*" allowed for dev only)
    CORS_ORIGINS: str = "*"

    # Shared secret between the mock payment provider and this backend.
    # In a real system this would be the provider's webhook signature secret.
    MOCK_PAYMENT_WEBHOOK_TOKEN: str = "mock-webhook-token-dev"

    # Flat service fee charged per order, in whole Taka.
    SERVICE_FEE_TAKA: int = 5

    ALLOW_TEST_REGISTRATION: bool = True


settings = Settings()
