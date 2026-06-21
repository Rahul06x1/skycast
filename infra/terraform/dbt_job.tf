# dbt transformation as a Cloud Run job. Triggered after ingestion completes.

resource "google_cloud_run_v2_job" "dbt" {
  name     = "skycast-dbt"
  location = var.region

  template {
    template {
      service_account = google_service_account.dbt.email
      timeout         = "900s"
      max_retries     = 1

      containers {
        image = "${var.dbt_image}:${var.image_tag}"
        env {
          name  = "GCP_PROJECT"
          value = var.project_id
        }
        env {
          name  = "DBT_DATASET"
          value = "skycast"
        }
        env {
          name  = "BQ_LOCATION"
          value = var.bq_location
        }
        resources {
          limits = {
            cpu    = "1"
            memory = "2Gi"
          }
        }
      }
    }
  }
}
