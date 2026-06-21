# Ingestion Cloud Function (gen2, HTTP-triggered).

resource "google_cloudfunctions2_function" "ingestion" {
  name     = "skycast-ingest-weather"
  location = var.region

  build_config {
    runtime     = "python312"
    entry_point = "ingest_weather"
    source {
      storage_source {
        bucket = var.function_source_bucket
        object = var.function_source_object
      }
    }
  }

  service_config {
    available_memory      = "512Mi"
    timeout_seconds       = 300
    service_account_email = google_service_account.ingestion.email
    environment_variables = {
      GCP_PROJECT     = var.project_id
      INBOUND_DATASET = google_bigquery_dataset.inbound.dataset_id
      LOGLEVEL        = "INFO"
    }
  }
}
