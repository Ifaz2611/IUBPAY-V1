from pydantic import BaseModel, ConfigDict, Field, field_validator


class MenuItemCreate(BaseModel):
    name: str = Field(min_length=2, max_length=160)
    description: str | None = None
    price_taka: int = Field(ge=1, le=100000)  # whole Taka
    category: str = Field(default="OTHER", pattern="^(MEAL|SNACK|BEVERAGE|OTHER)$")
    image_url: str | None = Field(default=None, max_length=500)

    @field_validator("price_taka")
    @classmethod
    def price_must_be_positive_int(cls, v: int) -> int:
        if v <= 0:
            raise ValueError("Price must be a positive amount in Taka")
        return v

    @field_validator("image_url")
    @classmethod
    def validate_image_url(cls, v: str | None) -> str | None:
        if v:
            v_clean = v.strip().lower()
            if not (
                v_clean.startswith("http://")
                or v_clean.startswith("https://")
                or v_clean.startswith("/")
            ):
                raise ValueError("Image URL must start with http://, https://, or /")
        return v


class MenuItemUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=2, max_length=160)
    description: str | None = None
    price_taka: int | None = Field(default=None, ge=1, le=100000)
    category: str | None = Field(default=None, pattern="^(MEAL|SNACK|BEVERAGE|OTHER)$")
    is_available: bool | None = None
    image_url: str | None = Field(default=None, max_length=500)

    @field_validator("image_url")
    @classmethod
    def validate_image_url(cls, v: str | None) -> str | None:
        if v:
            v_clean = v.strip().lower()
            if not (
                v_clean.startswith("http://")
                or v_clean.startswith("https://")
                or v_clean.startswith("/")
            ):
                raise ValueError("Image URL must start with http://, https://, or /")
        return v


class MenuItemOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    vendor_id: str
    name: str
    description: str | None = None
    price_taka: int
    category: str
    image_url: str | None = None
    is_available: bool
