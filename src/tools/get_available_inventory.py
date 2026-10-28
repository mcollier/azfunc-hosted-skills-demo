"""get_available_inventory tool: in-stock flavors for alternative recommendations."""

from __future__ import annotations

from typing import Any

from azure_functions_agents import tool

try:
    from ._catalog import FLAVORS, sku_for
except ImportError:  # loaded as a top-level module rather than a package member
    from _catalog import FLAVORS, sku_for


@tool
def get_available_inventory(profile_tag: str = "", min_qty: int = 1) -> list[dict[str, Any]]:
    """List flavors that are currently in stock, optionally filtered by flavor profile.

    Use this to recommend substitutes for line items that cannot be fulfilled.
    Results are ordered by available quantity (descending), then by flavor id.

    Args:
        profile_tag: Optional flavor profile tag to filter on, such as ``fruity``,
            ``nutty``, ``chocolate``, ``creamy``, or ``coffee``. Leave empty for all
            in-stock flavors.
        min_qty: Minimum available quantity a flavor must have to be included.
            Defaults to 1, which excludes out-of-stock flavors.
    """
    try:
        threshold = max(int(min_qty), 1)
    except (TypeError, ValueError):
        threshold = 1

    tag = profile_tag.strip().lower() if isinstance(profile_tag, str) else ""

    matches = [
        {
            "flavorId": flavor_id,
            "sku": sku_for(flavor_id),
            "productName": record["productName"],
            "availableQty": record["availableQty"],
            "profile": list(record["profile"]),
        }
        for flavor_id, record in FLAVORS.items()
        if record["availableQty"] >= threshold
        and (not tag or tag in [t.lower() for t in record["profile"]])
    ]

    matches.sort(key=lambda item: (-item["availableQty"], item["flavorId"]))
    return matches
