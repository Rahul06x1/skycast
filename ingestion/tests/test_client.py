"""Tests for the Open-Meteo client (HTTP mocked)."""

from __future__ import annotations

from unittest.mock import MagicMock

from skycast.client import API_URL, fetch_forecast


def test_fetch_forecast_calls_api_and_returns_json(sample_forecast):
    session = MagicMock()
    response = MagicMock()
    response.json.return_value = sample_forecast
    response.raise_for_status.return_value = None
    session.get.return_value = response

    result = fetch_forecast(51.5, -0.12, forecast_days=1, session=session)

    assert result == sample_forecast
    args, kwargs = session.get.call_args
    assert args[0] == API_URL
    assert kwargs["params"]["latitude"] == 51.5
    assert kwargs["params"]["hourly"] == "temperature_2m,precipitation"


def test_fetch_forecast_raises_on_http_error():
    session = MagicMock()
    response = MagicMock()
    response.raise_for_status.side_effect = RuntimeError("boom")
    session.get.return_value = response

    try:
        fetch_forecast(0, 0, session=session)
        assert False, "expected error"
    except RuntimeError as exc:
        assert "boom" in str(exc)
