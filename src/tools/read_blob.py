# tools/read_blob.py

import logging
import os
from azure_functions_agents import tool
from azure.storage.blob import BlobServiceClient

logger = logging.getLogger(__name__)

@tool
def read_blob(blob_name: str) -> str:
    """Read a Markdown file from the applications blob container."""
    connection_string = os.environ["AzureWebJobsStorage"]

    service = BlobServiceClient.from_connection_string(connection_string)

    container = "applications"
    # Callers may pass the full path including the container name
    blob_name = blob_name.removeprefix(f"{container}/").lstrip("/")
    logger.info("Reading blob: container=%s, blob_name=%s", container, blob_name)
    blob = service.get_blob_client(container=container, blob=blob_name)

    return blob.download_blob().content_as_text(encoding="utf-8")
