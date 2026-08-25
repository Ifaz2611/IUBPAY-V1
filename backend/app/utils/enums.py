from enum import Enum

from sqlalchemy import Enum as SaEnum


def sa_enum(enum_cls):
    """SQLAlchemy Enum that persists enum *values* (not names) so the DB
    matches what the REST API exposes, e.g. 'student' not 'STUDENT'."""
    return SaEnum(enum_cls, values_callable=lambda cls: [m.value for m in cls])


class Role(str, Enum):
    STUDENT = "student"
    VENDOR = "vendor"
    ADMIN = "admin"


class UserStatus(str, Enum):
    ACTIVE = "ACTIVE"
    SUSPENDED = "SUSPENDED"


class VendorStatus(str, Enum):
    PENDING = "PENDING"
    APPROVED = "APPROVED"
    SUSPENDED = "SUSPENDED"


class OrderStatus(str, Enum):
    PENDING_PAYMENT = "PENDING_PAYMENT"
    PAYMENT_PROCESSING = "PAYMENT_PROCESSING"
    PAYMENT_FAILED = "PAYMENT_FAILED"
    PAID = "PAID"
    ACCEPTED = "ACCEPTED"
    PREPARING = "PREPARING"
    READY = "READY"
    COLLECTED = "COLLECTED"
    CANCELLED = "CANCELLED"
    REJECTED = "REJECTED"
    REFUND_PENDING = "REFUND_PENDING"
    REFUNDED = "REFUNDED"


# Single source of truth for the order lifecycle. Any transition not listed here is rejected with 409.
ALLOWED_TRANSITIONS: dict["OrderStatus", set["OrderStatus"]] = {
    OrderStatus.PENDING_PAYMENT: {OrderStatus.PAYMENT_PROCESSING, OrderStatus.CANCELLED},
    OrderStatus.PAYMENT_PROCESSING: {OrderStatus.PAID, OrderStatus.PAYMENT_FAILED},
    OrderStatus.PAYMENT_FAILED: {OrderStatus.PENDING_PAYMENT},
    OrderStatus.PAID: {OrderStatus.ACCEPTED, OrderStatus.REJECTED, OrderStatus.CANCELLED},
    OrderStatus.ACCEPTED: {OrderStatus.PREPARING, OrderStatus.REJECTED},
    OrderStatus.PREPARING: {OrderStatus.READY},
    OrderStatus.READY: {OrderStatus.COLLECTED},
    OrderStatus.COLLECTED: set(),
    OrderStatus.CANCELLED: {OrderStatus.REFUND_PENDING},
    OrderStatus.REJECTED: {OrderStatus.REFUND_PENDING},
    OrderStatus.REFUND_PENDING: {OrderStatus.REFUNDED},
    OrderStatus.REFUNDED: set(),
}

# Statuses where money has been captured (payment succeeded).
PAID_STATUSES = {
    OrderStatus.PAID,
    OrderStatus.ACCEPTED,
    OrderStatus.PREPARING,
    OrderStatus.READY,
    OrderStatus.COLLECTED,
}


class PaymentStatus(str, Enum):
    CREATED = "CREATED"
    PROCESSING = "PROCESSING"
    SUCCEEDED = "SUCCEEDED"
    FAILED = "FAILED"


class RefundStatus(str, Enum):
    PENDING = "REFUND_PENDING"
    PROCESSED = "REFUNDED"
    FAILED = "FAILED"


class LedgerEntryType(str, Enum):
    PAYMENT = "PAYMENT"
    REFUND = "REFUND"
    FEE = "FEE"
    ADJUSTMENT = "ADJUSTMENT"


class ItemCategory(str, Enum):
    MEAL = "MEAL"
    SNACK = "SNACK"
    BEVERAGE = "BEVERAGE"
    OTHER = "OTHER"
