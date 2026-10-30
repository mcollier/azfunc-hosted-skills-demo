# tools/read_blob.py

import logging
import os
from typing import Any

from azure.storage.blob import BlobServiceClient
from azure_functions_agents import tool, workflow_tool

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

_CONTAINER = "applications"


def _read_application(blob_name: str) -> tuple[str, str]:
    connection_string = os.environ["AzureWebJobsStorage"]
    service = BlobServiceClient.from_connection_string(connection_string)

    # Blob trigger metadata includes the container name in the path
    blob_name = blob_name.strip().lstrip("/").removeprefix(f"{_CONTAINER}/")
    logger.info("Reading blob: container=%s, blob_name=%s", _CONTAINER, blob_name)
    blob = service.get_blob_client(container=_CONTAINER, blob=blob_name)

    return blob_name, blob.download_blob().content_as_text(encoding="utf-8")


@tool
def read_blob(blob_name: str) -> str:
    """Read a Markdown file from the applications blob container."""
    return _read_application(blob_name)[1]


@workflow_tool(
    description=(
        "Read a franchise application Markdown file from the applications blob "
        "container. Args: {\"blob_name\": \"<name or applications/<name>>\"}. "
        "Returns {\"blob_name\", \"text\"}."
    )
)
def read_application_blob(args: dict[str, Any]) -> dict[str, Any]:
    value = args.get("blob_name")
    if not isinstance(value, str) or not value.strip():
        raise ValueError("blob_name must be a non-empty string")
    blob_name, text = _read_application(value)
    return {"blob_name": blob_name, "text": text}
