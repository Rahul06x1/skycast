# Cloud Scheduler triggers ingestion hourly; a Workflow chains ingest -> dbt.

resource "google_workflows_workflow" "pipeline" {
  name            = "skycast-pipeline"
  region          = var.region
  service_account = google_service_account.orchestrator.email
  source_contents = templatefile("${path.module}/workflow.yaml.tftpl", {
    function_url = google_cloudfunctions2_function.ingestion.url
    job_name     = google_cloud_run_v2_job.dbt.name
    project_id   = var.project_id
    region       = var.region
  })
}

resource "google_cloud_scheduler_job" "hourly" {
  name      = "skycast-hourly"
  region    = var.region
  schedule  = var.schedule
  time_zone = "Etc/UTC"
  # Pause automatically outside production-style runs to control cost.
  paused = false

  http_target {
    uri         = "https://workflowexecutions.googleapis.com/v1/${google_workflows_workflow.pipeline.id}/executions"
    http_method = "POST"
    oauth_token {
      service_account_email = google_service_account.orchestrator.email
    }
  }

  retry_config {
    retry_count = 3
  }
}
