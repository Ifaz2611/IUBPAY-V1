"""initial schema

Revision ID: 0001_initial
Revises:
Create Date: 2026-08-25
"""
from alembic import op
import sqlalchemy as sa

revision = "0001_initial"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "vendors",
        sa.Column("id", sa.String(32), primary_key=True),
        sa.Column("name", sa.String(160), nullable=False, unique=True),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("location", sa.String(200), nullable=False),
        sa.Column("contact_phone", sa.String(32), nullable=True),
        sa.Column("settlement_reference", sa.String(64), nullable=True),
        sa.Column("status", sa.Enum("PENDING", "APPROVED", "SUSPENDED", name="vendorstatus"), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )

    op.create_table(
        "users",
        sa.Column("id", sa.String(32), primary_key=True),
        sa.Column("name", sa.String(120), nullable=False),
        sa.Column("email", sa.String(255), nullable=False, unique=True, index=True),
        sa.Column("password_hash", sa.String(255), nullable=False),
        sa.Column("student_id", sa.String(32), nullable=True, unique=True),
        sa.Column("phone", sa.String(32), nullable=True),
        sa.Column("role", sa.Enum("student", "vendor", "admin", name="role"), nullable=False),
        sa.Column("status", sa.Enum("ACTIVE", "SUSPENDED", name="userstatus"), nullable=False),
        sa.Column("vendor_id", sa.String(32), sa.ForeignKey("vendors.id", use_alter=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )

    op.create_table(
        "menu_items",
        sa.Column("id", sa.String(32), primary_key=True),
        sa.Column("vendor_id", sa.String(32), sa.ForeignKey("vendors.id"), index=True, nullable=False),
        sa.Column("name", sa.String(160), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("price_taka", sa.Integer(), nullable=False),
        sa.Column("image_url", sa.String(500), nullable=True),
        sa.Column("category", sa.Enum("MEAL", "SNACK", "BEVERAGE", "OTHER", name="itemcategory"), nullable=False),
        sa.Column("is_available", sa.Boolean(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.UniqueConstraint("vendor_id", "name", name="uq_vendor_item_name"),
    )

    op.create_table(
        "orders",
        sa.Column("id", sa.String(32), primary_key=True),
        sa.Column("order_number", sa.String(32), nullable=False, unique=True, index=True),
        sa.Column("student_id", sa.String(32), sa.ForeignKey("users.id"), index=True, nullable=False),
        sa.Column("vendor_id", sa.String(32), sa.ForeignKey("vendors.id"), index=True, nullable=False),
        sa.Column("subtotal_taka", sa.Integer(), nullable=False),
        sa.Column("service_fee_taka", sa.Integer(), nullable=False),
        sa.Column("total_amount_taka", sa.Integer(), nullable=False),
        sa.Column("status", sa.Enum(
            "PENDING_PAYMENT", "PAYMENT_PROCESSING", "PAYMENT_FAILED", "PAID",
            "ACCEPTED", "PREPARING", "READY", "COLLECTED", "CANCELLED",
            "REJECTED", "REFUND_PENDING", "REFUNDED", name="orderstatus"), index=True, nullable=False),
        sa.Column("pickup_code", sa.String(8), nullable=False),
        sa.Column("idempotency_key", sa.String(64), nullable=False, unique=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )

    op.create_table(
        "order_items",
        sa.Column("id", sa.String(32), primary_key=True),
        sa.Column("order_id", sa.String(32), sa.ForeignKey("orders.id"), index=True, nullable=False),
        sa.Column("menu_item_id", sa.String(32), sa.ForeignKey("menu_items.id"), nullable=True),
        sa.Column("item_name_snapshot", sa.String(160), nullable=False),
        sa.Column("unit_price_snapshot_taka", sa.Integer(), nullable=False),
        sa.Column("quantity", sa.Integer(), nullable=False),
        sa.Column("subtotal_taka", sa.Integer(), nullable=False),
    )

    op.create_table(
        "payments",
        sa.Column("id", sa.String(32), primary_key=True),
        sa.Column("order_id", sa.String(32), sa.ForeignKey("orders.id"), index=True, nullable=False),
        sa.Column("provider", sa.String(32), nullable=False),
        sa.Column("provider_transaction_id", sa.String(64), nullable=False, unique=True),
        sa.Column("amount_taka", sa.Integer(), nullable=False),
        sa.Column("status", sa.Enum("CREATED", "PROCESSING", "SUCCEEDED", "FAILED", name="paymentstatus"), index=True, nullable=False),
        sa.Column("failure_reason", sa.String(255), nullable=True),
        sa.Column("verified_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )

    op.create_table(
        "refunds",
        sa.Column("id", sa.String(32), primary_key=True),
        sa.Column("payment_id", sa.String(32), sa.ForeignKey("payments.id"), index=True, nullable=False),
        sa.Column("amount_taka", sa.Integer(), nullable=False),
        sa.Column("reason", sa.String(255), nullable=True),
        sa.Column("status", sa.Enum("REFUND_PENDING", "REFUNDED", "FAILED", name="refundstatus"), nullable=False),
        sa.Column("processed_by", sa.String(120), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )

    op.create_table(
        "ledger_entries",
        sa.Column("id", sa.String(32), primary_key=True),
        sa.Column("payment_id", sa.String(32), sa.ForeignKey("payments.id"), nullable=True),
        sa.Column("order_id", sa.String(32), sa.ForeignKey("orders.id"), nullable=True),
        sa.Column("entry_type", sa.Enum("PAYMENT", "REFUND", "FEE", "ADJUSTMENT", name="ledgerentrytype"), nullable=False),
        sa.Column("amount_taka", sa.Integer(), nullable=False),
        sa.Column("reference", sa.String(120), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )

    op.create_table(
        "audit_logs",
        sa.Column("id", sa.String(32), primary_key=True),
        sa.Column("actor_id", sa.String(32), nullable=True, index=True),
        sa.Column("action", sa.String(80), nullable=False),
        sa.Column("entity_type", sa.String(40), nullable=False),
        sa.Column("entity_id", sa.String(32), nullable=True),
        sa.Column("metadata", sa.JSON(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )


def downgrade() -> None:
    for table in ["audit_logs", "ledger_entries", "refunds", "payments",
                  "order_items", "orders", "menu_items", "users", "vendors"]:
        op.drop_table(table)
