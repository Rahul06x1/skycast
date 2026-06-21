"""Shared test fixtures. All external clients are mocked — no network or GCP access."""

from __future__ import annotations

import sys
from pathlib import Path
from unittest.mock import MagicMock

import pytest

# Make the `skycast` package importable without installing it.
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))


@pytest.fixture
def sample_forecast() -> dict:
    """A minimal Open-Meteo response with two parallel hourly arrays."""
    return {
        "latitude": 51.5,
        "longitude": -0.12,
        "hourly": {
            "time": ["2024-01-01T00:00", "2024-01-01T01:00"],
            "temperature_2m": [4.2, 3.8],
            "precipitation": [0.0, 0.1],
        },
    }


@pytest.fixture
def mock_bq_client() -> MagicMock:
    """A BigQuery client whose inserts succeed (empty error list)."""
    client = MagicMock()
    client.insert_rows_json.return_value = []
    return client
