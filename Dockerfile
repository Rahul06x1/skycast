# dbt image for the SkyCast Cloud Run job.
FROM python:3.12-slim-bookworm

ENV PYTHONUNBUFFERED=1
WORKDIR /dbt

RUN pip install --no-cache-dir "dbt-bigquery==1.8.*"

COPY dbt/ /dbt/
RUN chmod +x /dbt/runner.sh && dbt deps --profiles-dir .

ENTRYPOINT ["/dbt/runner.sh"]
