# Service accounts and least-privilege roles for the ingestion function and dbt job.

resource "google_service_account" "ingestion" {
  account_id   = "skycast-ingestion"
  display_name = "SkyCast ingestion Cloud Function"
}

resource "google_service_account" "dbt" {
  account_id   = "skycast-dbt"
  display_name = "SkyCast dbt Cloud Run job"
}

# The Cloud Workflow / Scheduler identity that invokes the function and the job.
resource "google_service_account" "orchestrator" {
  account_id   = "skycast-orchestrator"
  display_name = "SkyCast scheduler/orchestrator"
}

# Ingestion needs to write to BigQuery.
resource "google_project_iam_member" "ingestion_bq" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.ingestion.email}"
}

resource "google_project_iam_member" "ingestion_bq_jobs" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.ingestion.email}"
}

# dbt needs to read inbound and write stage/marts.
resource "google_project_iam_member" "dbt_bq" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.dbt.email}"
}

resource "google_project_iam_member" "dbt_bq_jobs" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.dbt.email}"
}

# Orchestrator may invoke the function and run the job.
resource "google_cloud_run_v2_job_iam_member" "orchestrator_run" {
  name     = google_cloud_run_v2_job.dbt.name
  location = var.region
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.orchestrator.email}"
}

# A gen2 Cloud Function is backed by a Cloud Run v2 service whose name matches the
# function name. Invocation (incl. via the Workflow's OIDC call) requires run.invoker
# on that backing service.
resource "google_cloud_run_v2_service_iam_member" "orchestrator_invoke" {
  name     = google_cloudfunctions2_function.ingestion.name
  location = var.region
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.orchestrator.email}"
}
