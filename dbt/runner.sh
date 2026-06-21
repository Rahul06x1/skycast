#!/usr/bin/env sh
# Entry point for the dbt Cloud Run job. Runs and tests the weather-tagged models.
set -e

cd /dbt
dbt deps --profiles-dir .
dbt run --profiles-dir . --select tag:weather
dbt test --profiles-dir . --select tag:weather

echo "COMPLETED_SKYCAST_DBT_JOB"
