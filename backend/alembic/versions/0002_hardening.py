"""hardening: version, service_fee, pickup code length

Revision ID: 0002_hardening
Revises: 0001_initial
Create Date: 2026-09-03
"""
from alembic import op
import sqlalchemy as sa

revision = "0002_hardening"
down_revision = "0001_initial"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("orders", sa.Column("version", sa.Integer(), nullable=False, server_default="1"))
    op.add_column("vendors", sa.Column("service_fee_taka", sa.Integer(), nullable=True))


def downgrade() -> None:
    op.drop_column("vendors", "service_fee_taka")
    op.drop_column("orders", "version")
