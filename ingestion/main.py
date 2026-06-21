"""Cloud Function entry point for SkyCast weather ingestion.

Triggered by Cloud Scheduler over HTTP. Pulls forecasts for every configured city from
Open-Meteo and lands the raw JSON in BigQuery. Designed to be idempotent at the day grain
(re-running appends a new snapshot; dbt deduplicates downstream).

Run locally:
    functions-framework --target=ingest_weather --debug
    curl http://localhost:8080
"""

from __future__ import annotations

import functions_framework

from skycast.backend import write_forecasts
from skycast.client import fetch_forecast
from skycast.config import load_config
from skycast.logger import get_logger

log = get_logger("skycast-ingestion")


@functions_framework.http
def ingest_weather(request):  # noqa: ANN001 - framework-provided Flask request
    """HTTP entry point. Returns a JSON summary of the ingestion run."""
    config = load_config()
    log.info(
        "ingestion started",
        extra={"context": {"cities": len(config.cities), "table": config.table_ref}},
    )

    rows = []
    failures = []
    for city in config.cities:
        try:
            payload = fetch_forecast(city.latitude, city.longitude, config.forecast_days)
            rows.append({"city": city.name, "payload": payload})
        except Exception as exc:  # noqa: BLE001 - collect and continue per city
            log.error("fetch failed", extra={"context": {"city": city.name, "error": str(exc)}})
            failures.append(city.name)

    written = write_forecasts(config.table_ref, rows) if rows else 0
    log.info(
        "ingestion finished",
        extra={"context": {"written": written, "failures": failures}},
    )

    status = 200 if not failures else 207
    return ({"written": written, "failures": failures}, status)
