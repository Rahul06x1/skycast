"""Open-Meteo API client.

Open-Meteo is a free, no-auth weather API (https://open-meteo.com/). We request hourly
temperature and precipitation for a city and return the raw JSON payload unchanged so the
warehouse stores the source of truth (schema-on-read / ELT).
"""

from __future__ import annotations

from typing import Any

import requests

API_URL = "https://api.open-meteo.com/v1/forecast"
TIMEOUT_SECONDS = 30


def fetch_forecast(
    latitude: float,
    longitude: float,
    forecast_days: int = 1,
    session: requests.Session | None = None,
) -> dict[str, Any]:
    """Fetch an hourly forecast for one location.

    Returns the raw API JSON. Raises requests.HTTPError on a non-2xx response.
    """
    params = {
        "latitude": latitude,
        "longitude": longitude,
        "hourly": "temperature_2m,precipitation",
        "forecast_days": forecast_days,
        "timezone": "UTC",
    }
    http = session or requests
    response = http.get(API_URL, params=params, timeout=TIMEOUT_SECONDS)
    response.raise_for_status()
    return response.json()
