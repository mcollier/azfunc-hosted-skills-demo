"""Hardcoded Froyo Foundry flavor catalog and inventory.

This module intentionally contains no ``@tool`` functions so that it is not
surfaced to the model as a callable tool. The tool modules in this package
import their data and helpers from here.
"""

from __future__ import annotations

from typing import Any

SKU_SUFFIX = "-TUB"

FLAVORS: dict[str, dict[str, Any]] = {
    "RRB": {
        "productName": "Recursive Raspberry",
        "description": "Tart raspberry swirl that keeps calling itself until the tub is empty.",
        "profile": ["fruity", "berry", "tart"],
        "availableQty": 42,
    },
    "VNE": {
        "productName": "Vanilla Exception",
        "description": "Classic Madagascar vanilla, thrown whenever something unexpectedly good happens.",
        "profile": ["classic", "creamy", "vanilla"],
        "availableQty": 120,
    },
    "MNT": {
        "productName": "Mint Condition",
        "description": "Cool peppermint froyo with dark chocolate shards, preserved in pristine state.",
        "profile": ["mint", "refreshing", "chocolate"],
        "availableQty": 18,
    },
    "BBB": {
        "productName": "Berry Blockchain Blast",
        "description": "An immutable chain of blueberry, blackberry, and strawberry blocks.",
        "profile": ["fruity", "berry", "mixed-berry"],
        "availableQty": 7,
    },
    "CKC": {
        "productName": "Cookie Container",
        "description": "Cookie dough chunks packaged in a sweet cream base, fully portable.",
        "profile": ["cookie", "chocolate", "sweet"],
        "availableQty": 0,
    },
    "NPP": {
        "productName": "Null Pointer Pistachio",
        "description": "Roasted pistachio cream that dereferences straight into your heart.",
        "profile": ["nutty", "pistachio", "creamy"],
        "availableQty": 0,
    },
    "JVJ": {
        "productName": "Java Jolt",
        "description": "Bold cold-brew coffee froyo with a garbage-collected espresso ribbon.",
        "profile": ["coffee", "roasted", "bold"],
        "availableQty": 65,
    },
    "PBP": {
        "productName": "Peanut Butter Protocol",
        "description": "Rich peanut butter base negotiated over a salted handshake.",
        "profile": ["nutty", "peanut", "rich"],
        "availableQty": 30,
    },
    "CCC": {
        "productName": "Cloud Caramel Cache",
        "description": "Salted caramel froyo with buttery ribbons cached in every scoop.",
        "profile": ["caramel", "sweet", "creamy"],
        "availableQty": 9,
    },
    "GMG": {
        "productName": "Git Merge Mango",
        "description": "Sunny mango froyo swirled with passionfruit, resolving every conflict into sweetness.",
        "profile": ["fruity", "mango", "tropical", "tangy"],
        "availableQty": 55,
    },
}


def normalize_flavor_id(flavor_id: str) -> str:
    """Normalize a flavor identifier to its canonical three-letter form.

    Accepts a bare flavor id (``vne``) or a full inventory SKU (``VNE-TUB``).
    """
    if not isinstance(flavor_id, str):
        return ""
    candidate = flavor_id.strip().upper()
    return candidate.removesuffix(SKU_SUFFIX)


def sku_for(flavor_id: str) -> str:
    """Return the inventory SKU for a canonical flavor id."""
    return f"{flavor_id}{SKU_SUFFIX}"


def get_flavor(flavor_id: str) -> dict[str, Any] | None:
    """Look up a flavor record by raw flavor id or SKU, or ``None`` if unknown."""
    return FLAVORS.get(normalize_flavor_id(flavor_id))
