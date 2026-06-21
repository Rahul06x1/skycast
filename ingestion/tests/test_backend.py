"""Tests for the BigQuery backend (client mocked)."""

from __future__ import annotations

from skycast.backend import SOURCE, write_forecasts

TABLE = "proj.inbound.raw_forecasts"


def test_write_forecasts_inserts_rows(mock_bq_client, sample_forecast):
    rows = [{"city": "London", "payload": sample_forecast}]

    count = write_forecasts(TABLE, rows, client=mock_bq_client)

    assert count == 1
    mock_bq_client.create_dataset.assert_called_once()
    mock_bq_client.create_table.assert_called_once()
    inserted = mock_bq_client.insert_rows_json.call_args[0][1]
    assert inserted[0]["city"] == "London"
    assert inserted[0]["source"] == SOURCE
    assert inserted[0]["data"] == sample_forecast


def test_write_forecasts_raises_on_insert_errors(mock_bq_client, sample_forecast):
    mock_bq_client.insert_rows_json.return_value = [{"index": 0, "errors": ["bad row"]}]

    try:
        write_forecasts(TABLE, [{"city": "X", "payload": sample_forecast}], client=mock_bq_client)
        assert False, "expected error"
    except RuntimeError as exc:
        assert "insert failed" in str(exc)
