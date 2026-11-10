"""check_financials tool: deterministic funding, projection, and debt-service checks."""

from typing import Any

from azure_functions_agents import tool
from pydantic import BaseModel, Field

_MIN_DSCR = 1.25
_TOLERANCE = 1.0


class Financials(BaseModel):
    currency: str | None = None
    total_assets: float | None = None
    total_liabilities: float | None = None
    stated_net_worth: float | None = None
    liquid_assets: float | None = None
    equity_commitment: float | None = None
    remaining_personal_reserve: float | None = None
    loan_amount: float | None = None
    financing_status: str | None = None
    loan_interest_rate_pct: float | None = Field(default=None, ge=0, le=100)
    loan_term_months: int | None = Field(default=None, gt=0)
    startup_budget: float | None = None
    annual_revenue_projection: float | None = None
    downside_sales_decline_pct: float | None = Field(default=None, ge=0, le=100)


class StartupUse(BaseModel):
    name: str
    amount: float


class AnnualExpense(BaseModel):
    name: str
    annual_amount: float
    variable_share_pct: float | None = Field(
        default=None, ge=0, le=100, description="Stated share (0-100) that varies with sales."
    )
    variable_amount: float | None = Field(
        default=None, ge=0, description="Stated portion of annual_amount that varies with sales."
    )


class CheckFinancialsInput(BaseModel):
    financials: Financials = Field(default_factory=Financials)
    startup_uses: list[StartupUse] = Field(default_factory=list)
    monthly_sales: list[float] = Field(default_factory=list, description="12 monthly amounts, no total.")
    annual_expenses: list[AnnualExpense] = Field(default_factory=list)


def _round(value: float | None) -> float | None:
    return None if value is None else round(value, 2)


def _monthly_payment(principal: float, annual_rate_pct: float, months: int) -> float:
    rate = annual_rate_pct / 100 / 12
    if rate == 0:
        return principal / months
    return principal * rate / (1 - (1 + rate) ** -months)


def _variable_amount(expense: AnnualExpense) -> float | None:
    if expense.variable_amount is not None:
        return min(expense.variable_amount, expense.annual_amount)
    if expense.variable_share_pct is not None:
        return expense.annual_amount * expense.variable_share_pct / 100
    return None


def _scenario(
    revenue: float, expenses: list[AnnualExpense], sales_factor: float, annual_debt_service: float | None
) -> dict[str, Any]:
    total = 0.0
    for expense in expenses:
        variable = _variable_amount(expense) or 0.0
        total += (expense.annual_amount - variable) + variable * sales_factor
    earnings = revenue - total
    result: dict[str, Any] = {
        "revenue": _round(revenue),
        "operating_expenses": _round(total),
        "operating_cash_earnings": _round(earnings),
    }
    if annual_debt_service:
        result["annual_debt_service"] = _round(annual_debt_service)
        result["dscr"] = earnings / annual_debt_service
        result["cash_after_debt_service"] = _round(earnings - annual_debt_service)
    return result


@tool(schema=CheckFinancialsInput)
def check_financials(params: CheckFinancialsInput) -> dict[str, Any]:
    """Run deterministic checks on a franchise application's stated financials.

    Calculates net worth, sources vs. uses, loan payments, monthly sales totals, and base and
    downside operating cash earnings with debt-service coverage. Reports missing inputs and flags
    for human review. It never approves a loan or franchise.
    """
    f = params.financials
    calculations: dict[str, Any] = {"currency": f.currency}
    missing: list[str] = []
    flags: list[str] = []

    if f.total_assets is not None and f.total_liabilities is not None:
        net_worth = f.total_assets - f.total_liabilities
        calculations["calculated_net_worth"] = _round(net_worth)
        if f.stated_net_worth is not None and abs(net_worth - f.stated_net_worth) > _TOLERANCE:
            flags.append(
                f"Stated net worth {f.stated_net_worth:,.2f} differs from assets − liabilities {net_worth:,.2f}."
            )
    else:
        missing.append("total_assets/total_liabilities")

    if f.liquid_assets is not None and f.equity_commitment is not None:
        reserve = f.liquid_assets - f.equity_commitment
        calculations["calculated_personal_reserve"] = _round(reserve)
        if f.remaining_personal_reserve is not None and abs(reserve - f.remaining_personal_reserve) > _TOLERANCE:
            flags.append("Stated remaining personal reserve does not equal liquid assets − equity commitment.")
        if reserve < 0:
            flags.append("Equity commitment exceeds stated liquid assets.")

    uses_total = sum(use.amount for use in params.startup_uses) if params.startup_uses else None
    calculations["startup_uses_total"] = _round(uses_total)
    if uses_total is None:
        missing.append("startup_uses")
    elif f.startup_budget is not None and abs(uses_total - f.startup_budget) > _TOLERANCE:
        flags.append(f"Itemized startup uses {uses_total:,.2f} differ from stated budget {f.startup_budget:,.2f}.")

    if f.equity_commitment is not None and f.loan_amount is not None:
        sources = f.equity_commitment + f.loan_amount
        calculations["total_sources"] = _round(sources)
        if uses_total is not None:
            gap = uses_total - sources
            calculations["funding_gap"] = _round(gap)
            if gap > _TOLERANCE:
                flags.append(f"Funding gap of {gap:,.2f}: sources do not cover startup uses.")
        if sources:
            calculations["equity_share_pct"] = round(f.equity_commitment / sources * 100, 2)
    else:
        missing.append("equity_commitment/loan_amount")

    if f.financing_status:
        calculations["financing_status"] = f.financing_status
    if f.loan_amount:
        flags.append("Loan financing requires lender underwriting and commitment evidence.")

    annual_debt_service: float | None = None
    if f.loan_amount and f.loan_interest_rate_pct is not None and f.loan_term_months:
        payment = _monthly_payment(f.loan_amount, f.loan_interest_rate_pct, f.loan_term_months)
        annual_debt_service = payment * 12
        calculations["loan_monthly_payment"] = _round(payment)
        calculations["annual_debt_service"] = _round(annual_debt_service)
    elif f.loan_amount:
        missing.append("loan_interest_rate_pct/loan_term_months")

    revenue: float | None = None
    if params.monthly_sales:
        monthly_total = sum(params.monthly_sales)
        calculations["monthly_sales_total"] = _round(monthly_total)
        calculations["monthly_sales_min"] = _round(min(params.monthly_sales))
        calculations["monthly_sales_max"] = _round(max(params.monthly_sales))
        if len(params.monthly_sales) != 12:
            flags.append(f"Expected 12 monthly sales amounts; received {len(params.monthly_sales)}.")
        if f.annual_revenue_projection is not None and abs(monthly_total - f.annual_revenue_projection) > _TOLERANCE:
            flags.append("Monthly sales do not sum to the stated annual revenue projection.")
        revenue = monthly_total
    else:
        missing.append("monthly_sales")
    if revenue is None:
        revenue = f.annual_revenue_projection

    if params.annual_expenses and revenue is not None:
        calculations["base_case"] = _scenario(revenue, params.annual_expenses, 1.0, annual_debt_service)
        assumed_fixed = [e.name for e in params.annual_expenses if _variable_amount(e) is None]
        if f.downside_sales_decline_pct is not None:
            factor = 1 - f.downside_sales_decline_pct / 100
            downside = _scenario(revenue * factor, params.annual_expenses, factor, annual_debt_service)
            downside["sales_decline_pct"] = f.downside_sales_decline_pct
            if assumed_fixed:
                downside["expenses_assumed_fixed"] = assumed_fixed
            calculations["downside_case"] = downside
        else:
            missing.append("downside_sales_decline_pct")
        for label in ("base_case", "downside_case"):
            case = calculations.get(label)
            if not case:
                continue
            if case["operating_cash_earnings"] < 0:
                flags.append(f"{label}: operating cash earnings are negative.")
            if "dscr" in case and case["dscr"] < _MIN_DSCR:
                flags.append(f"{label}: DSCR {case['dscr']} is below {_MIN_DSCR}.")
            if case.get("cash_after_debt_service", 0) < 0:
                flags.append(f"{label}: cash after debt service is negative.")
    elif not params.annual_expenses:
        missing.append("annual_expenses")
    else:
        missing.append("annual_revenue_projection")

    flags.append("Projections are applicant assumptions, not evidence of demand; human review required.")
    return {
        "calculations": calculations,
        "missing_information": missing,
        "review_flags": flags,
        "assumptions": {"minimum_dscr": _MIN_DSCR, "tolerance": _TOLERANCE},
    }
