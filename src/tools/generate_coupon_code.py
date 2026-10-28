"""generate_coupon_code tool: deterministic 25% discount coupons."""

from __future__ import annotations

import hashlib
from typing import Any

from azure_functions_agents import tool

DISCOUNT_PERCENT = 25
COUPON_PREFIX = "FROYO25"


@tool
def generate_coupon_code(order_id: str) -> dict[str, Any]:
    """Generate a 25% discount coupon for an order that cannot be fully fulfilled.

    The code is derived deterministically from the order id, so calling this tool
    twice for the same order always yields the same coupon.

    Args:
        order_id: The canonical order id the coupon is issued against.
    """
    normalized = (order_id or "").strip()
    digest = hashlib.sha256(normalized.encode("utf-8")).hexdigest()[:8].upper()
    return {
        "orderId": normalized,
        "code": f"{COUPON_PREFIX}-{digest}",
        "discountPercent": DISCOUNT_PERCENT,
    }
