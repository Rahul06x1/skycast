<div align="center">

# SkyCast

### Serverless weather analytics on Google Cloud — a scheduled ELT pipeline

[![CI](https://github.com/Rahul06x1/skycast/actions/workflows/ci.yaml/badge.svg)](https://github.com/Rahul06x1/skycast/actions/workflows/ci.yaml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

</div>

SkyCast pulls hourly weather forecasts for a set of cities from the free
[Open-Meteo API](https://open-meteo.com/) (no API key), lands the raw JSON in BigQuery,
and transforms it with dbt into clean analytics marts. It is a self-contained portfolio
project demonstrating the canonical **scheduled ELT** pattern on GCP.

> Standalone learning project. No private data, no secrets, no external dependencies —
> the only data source is a public, keyless API.

---

## Architecture

```
Cloud Scheduler (hourly)
      │  POST execution
      ▼
Cloud Workflow ──► Cloud Function (Python) ──► BigQuery  inbound.raw_forecasts (raw JSON)
      │                                                          │
      └──────────► Cloud Run job (dbt) ──────────────────────────┘
                          │  dbt run + test (tag:weather)
                          ▼
            stage.weather_typed ──► marts.daily_weather
                                    marts.forecast_accuracy
Observability: log-based error metric + Cloud Monitoring alert
```

**Flow:** Scheduler triggers a Workflow → the Workflow invokes the ingestion Function
(raw JSON → `inbound`) → then runs the dbt Cloud Run job (`inbound` → `stage` → `marts`).

---

## Tech stack

| Layer | Technology |
|-------|-----------|
| Ingestion | Python 3.12, functions-framework, Cloud Functions (gen2) |
| Warehouse | BigQuery (`inbound` / `stage` / `marts`) |
| Transformation | dbt (dbt-bigquery), Cloud Run job |
| Orchestration | Cloud Workflows + Cloud Scheduler |
| IaC | Terraform (GCS remote state) |
| CI/CD | GitHub Actions + Workload Identity Federation |
| Tooling | uv, ruff, pytest |

---

## Repository layout

```
skycast/
├── ingestion/        # Cloud Function: Open-Meteo -> BigQuery inbound
│   ├── main.py
│   ├── skycast/      # client, backend, config, logger
│   ├── config.yaml   # cities + BQ target
│   └── tests/        # pytest, all clients mocked
├── dbt/              # stage + marts models, macros, runner.sh
├── infra/terraform/  # BQ, function, dbt job, workflow, scheduler, monitoring, IAM
├── Dockerfile        # dbt image for the Cloud Run job
└── .github/workflows # ci.yaml (lint/test/validate), deploy.yaml (WIF)
```

---

## Run it locally

**Ingestion function** (writes to a real BigQuery project):

```bash
cd ingestion
uv sync --dev
uv run ruff check .
uv run pytest -m "not integration"

# run the function locally against your own GCP project
export GCP_PROJECT=your-gcp-project
uv run functions-framework --target=ingest_weather --debug
curl http://localhost:8080
```

**dbt models** (needs `gcloud auth application-default login`):

```bash
cd dbt
export GCP_PROJECT=your-gcp-project
dbt deps --profiles-dir .
dbt run  --profiles-dir . --select tag:weather
dbt test --profiles-dir . --select tag:weather
```

---

## Deploy

1. Create a GCP project, enable APIs (BigQuery, Cloud Functions, Cloud Run, Workflows,
   Scheduler, Artifact Registry), and create: an Artifact Registry repo `skycast`, a
   function-source GCS bucket, a Terraform-state GCS bucket, and a Workload Identity
   Federation pool bound to this GitHub repo.
2. Set repo Actions **variables**: `GCP_PROJECT_ID`, `WIF_PROVIDER`, `DEPLOYER_SA`,
   `FUNCTION_SOURCE_BUCKET`, `TFSTATE_BUCKET`.
3. Push to `main` — `deploy.yaml` builds the dbt image, packages the function, and runs
   `terraform plan`/`apply`.

---

## Design notes

- **ELT, not ETL** — raw API JSON is stored verbatim in a `data` JSON column; all typing
  and shaping happens in dbt, so the warehouse keeps the source of truth.
- **Idempotent + deduplicated** — re-runs append snapshots; `weather_typed` keeps the
  latest row per `(city, forecast_ts)` via a reusable `dedup` macro.
- **Keyless** — no service-account keys anywhere; CI uses Workload Identity Federation and
  dbt uses OAuth / Application Default Credentials.
- **Cost-aware** — marts are partitioned by date and clustered by city; datasets live in
  one region; pause the scheduler when idle and `terraform destroy` between sessions.
- **Observable from day one** — a log-based error metric and an alert policy ship with the
  infrastructure.

---

## Key decisions & what I learned

- **ELT, not ETL.** Ingestion stores raw API JSON verbatim and dbt does all typing/shaping.
  *Why:* schema changes never break ingestion and history can be reprocessed by re-running
  dbt. *Lesson:* keep the loader dumb; put logic in the warehouse.
- **Cloud Workflows to sequence ingest → dbt** rather than gluing functions with Pub/Sub.
  *Tradeoff:* one more service, but built-in retries and a clear run history.
- **Idempotent by design.** Re-runs append snapshots; `weather_typed` keeps the latest row
  per `(city, forecast_ts)` via `ROW_NUMBER() … QUALIFY 1`. *Lesson:* design for
  at-least-once delivery and deduplicate downstream instead of chasing exactly-once.
- **Keyless everywhere.** GitHub OIDC → Workload Identity Federation for CI, OAuth/ADC for
  dbt — no service-account keys in the repo. *Learned:* how to wire WIF end-to-end.
- **`source()` + dbt tests over hardcoded table strings**, so lineage and source freshness
  actually work (a deliberate fix to a pattern I saw drift in the reference codebase).

## Skills demonstrated

GCP serverless data engineering (Cloud Functions, Cloud Run jobs, Workflows, Scheduler) ·
BigQuery ELT with layered datasets · dbt modelling, testing, macros · partitioning &
clustering · Terraform with remote state · GitHub Actions CI/CD with Workload Identity
Federation · structured logging & alerting · tested, linted, reproducible Python.

---

## Teardown

```bash
cd infra/terraform && terraform destroy
```
