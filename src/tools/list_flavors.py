"""list_flavors tool: full Froyo Foundry flavor catalog metadata."""

from __future__ import annotations

from typing import Any

from azure_functions_agents import tool

try:
    from ._catalog import FLAVORS, sku_for
except ImportError:  # loaded as a top-level module rather than a package member
    from _catalog import FLAVORS, sku_for


@tool
def list_flavors() -> list[dict[str, Any]]:
    """List every Froyo Foundry flavor with its id, SKU, description, and flavor profile.

    Stock levels are deliberately excluded. Use ``check_inventory`` or
    ``get_available_inventory`` for availability.
    """
    return [
        {
            "flavorId": flavor_id,
            "sku": sku_for(flavor_id),
            "productName": record["productName"],
            "description": record["description"],
            "profile": list(record["profile"]),
        }
        for flavor_id, record in sorted(FLAVORS.items())
    ]
