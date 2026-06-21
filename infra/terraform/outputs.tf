output "function_url" {
  value       = google_cloudfunctions2_function.ingestion.url
  description = "HTTP URL of the ingestion function."
}

output "dbt_job_name" {
  value       = google_cloud_run_v2_job.dbt.name
  description = "Name of the dbt Cloud Run job."
}

output "workflow_id" {
  value       = google_workflows_workflow.pipeline.id
  description = "Cloud Workflow id orchestrating the pipeline."
}
