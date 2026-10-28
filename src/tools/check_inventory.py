"""check_inventory tool: stock lookup for a single flavor."""

from __future__ import annotations

from typing import Any

from azure_functions_agents import tool

try:
    from ._catalog import get_flavor, normalize_flavor_id, sku_for
except ImportError:  # loaded as a top-level module rather than a package member
    from _catalog import get_flavor, normalize_flavor_id, sku_for


@tool
def check_inventory(flavor_id: str) -> dict[str, Any]:
    """Check the on-hand stock level for a single flavor.

    Args:
        flavor_id: The canonical three-letter flavor id, such as ``VNE``. A full
            inventory SKU such as ``VNE-TUB`` is also accepted.
    """
    canonical = normalize_flavor_id(flavor_id)
    record = get_flavor(canonical)

    if record is None:
        return {
            "flavorId": canonical,
            "found": False,
            "availableQty": 0,
            "inStock": False,
            "error": f"Unknown flavor id '{flavor_id}'. Call list_flavors for valid flavor ids.",
        }

    available_qty = record["availableQty"]
    return {
        "flavorId": canonical,
        "found": True,
        "sku": sku_for(canonical),
        "productName": record["productName"],
        "availableQty": available_qty,
        "inStock": available_qty > 0,
        "profile": list(record["profile"]),
    }
