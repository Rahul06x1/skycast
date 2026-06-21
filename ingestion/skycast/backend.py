"""BigQuery backend: persists raw forecast payloads to the inbound table.

Follows the ELT pattern: store the raw API JSON in a `data` JSON column and let dbt do
the typing/transformation downstream. The table is created on first use if missing.
"""

from __future__ import annotations

from datetime import datetime, timezone
from typing import Any

from google.cloud import bigquery

SOURCE = "open-meteo"


def _ensure_table(client: bigquery.Client, table_ref: str) -> None:
    """Create the inbound table (and its dataset) if they do not exist."""
    dataset_id = ".".join(table_ref.split(".")[:2])
    client.create_dataset(dataset_id, exists_ok=True)

    schema = [
        bigquery.SchemaField("loaded_at", "TIMESTAMP", mode="REQUIRED"),
        bigquery.SchemaField("source", "STRING", mode="REQUIRED"),
        bigquery.SchemaField("city", "STRING", mode="REQUIRED"),
        bigquery.SchemaField("data", "JSON", mode="REQUIRED"),
    ]
    table = bigquery.Table(table_ref, schema=schema)
    table.time_partitioning = bigquery.TimePartitioning(field="loaded_at")
    client.create_table(table, exists_ok=True)


def write_forecasts(
    table_ref: str,
    rows: list[dict[str, Any]],
    client: bigquery.Client | None = None,
) -> int:
    """Insert forecast rows into the inbound table. Returns the row count written.

    Each row in `rows` must contain `city` and `payload` (the raw API dict).
    """
    bq = client or bigquery.Client()
    _ensure_table(bq, table_ref)

    loaded_at = datetime.now(timezone.utc).isoformat()
    bq_rows = [
        {"loaded_at": loaded_at, "source": SOURCE, "city": r["city"], "data": r["payload"]}
        for r in rows
    ]

    errors = bq.insert_rows_json(table_ref, bq_rows)
    if errors:
        raise RuntimeError(f"BigQuery insert failed: {errors}")
    return len(bq_rows)
