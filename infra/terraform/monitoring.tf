# Observability: a log-based error metric on the ingestion function plus an alert.
# Built in from day one — the area the reference architecture under-invested in.

resource "google_logging_metric" "ingestion_errors" {
  name   = "skycast_ingestion_errors"
  filter = <<-EOT
    resource.type="cloud_run_revision"
    resource.labels.service_name="skycast-ingest-weather"
    severity>=ERROR
  EOT
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}

resource "google_monitoring_alert_policy" "ingestion_errors" {
  display_name = "SkyCast ingestion errors"
  combiner     = "OR"

  conditions {
    display_name = "Ingestion error logs > 0"
    condition_threshold {
      filter          = "resource.type=\"cloud_run_revision\" AND metric.type=\"logging.googleapis.com/user/${google_logging_metric.ingestion_errors.name}\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0
      duration        = "0s"
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_SUM"
      }
    }
  }

  # Only attach notification channels if one was provided.
  notification_channels = var.alert_notification_channel == "" ? [] : [var.alert_notification_channel]

  documentation {
    content = "The SkyCast ingestion function logged an error. Check Cloud Logging for the failing city/API call."
  }
}
