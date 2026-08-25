from pydantic import BaseModel


class ReportSummary(BaseModel):
    total_orders: int
    paid_orders: int
    total_sales_taka: int
    total_refunds_taka: int
    net_revenue_taka: int
    failed_payments: int
    active_vendors: int
    registered_students: int


class DailyReportRow(BaseModel):
    date: str  # YYYY-MM-DD
    orders: int
    sales_taka: int
    refunds_taka: int
