# BigQuery datasets for the three ELT tiers. Tables are created by the ingestion
# function (inbound) and by dbt (stage/marts), so only datasets are declared here.

resource "google_bigquery_dataset" "inbound" {
  dataset_id  = "inbound"
  location    = var.bq_location
  description = "Raw forecast payloads landed by the ingestion function."
}

resource "google_bigquery_dataset" "stage" {
  dataset_id  = "stage"
  location    = var.bq_location
  description = "Typed/cleaned dbt staging models."
}

resource "google_bigquery_dataset" "marts" {
  dataset_id  = "marts"
  location    = var.bq_location
  description = "Curated dbt marts for analytics/BI."
}
