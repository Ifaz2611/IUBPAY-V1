from pydantic import BaseModel, Field


class VendorCreate(BaseModel):
    name: str = Field(min_length=2, max_length=160)
    description: str | None = None
    location: str = Field(min_length=2, max_length=200)
    contact_phone: str | None = Field(default=None, max_length=32)


class VendorUpdate(BaseModel):
    description: str | None = None
    location: str | None = Field(default=None, min_length=2, max_length=200)
    contact_phone: str | None = Field(default=None, max_length=32)
    settlement_reference: str | None = Field(default=None, max_length=64)
    status: str | None = Field(default=None, pattern="^(PENDING|APPROVED|SUSPENDED)$")


class VendorOut(BaseModel):
    id: str
    name: str
    description: str | None = None
    location: str
    contact_phone: str | None = None
    status: str

    class Config:
        from_attributes = True
