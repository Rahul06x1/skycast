variable "project_id" {
  type        = string
  description = "GCP project id."
}

variable "region" {
  type        = string
  default     = "europe-west2"
  description = "GCP region for serverless resources."
}

variable "bq_location" {
  type        = string
  default     = "EU"
  description = "BigQuery dataset location."
}

variable "image_tag" {
  type        = string
  description = "Container tag for the dbt image (commit SHA)."
}

variable "dbt_image" {
  type        = string
  description = "Full dbt image path in Artifact Registry (without tag)."
}

variable "function_source_bucket" {
  type        = string
  description = "GCS bucket holding the zipped Cloud Function source."
}

variable "function_source_object" {
  type        = string
  description = "GCS object path of the zipped Cloud Function source."
}

variable "schedule" {
  type        = string
  default     = "0 * * * *"
  description = "Cron schedule for ingestion (hourly by default)."
}

variable "alert_notification_channel" {
  type        = string
  default     = ""
  description = "Optional Monitoring notification channel id for alerts."
}
