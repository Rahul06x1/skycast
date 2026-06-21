# Remote state in GCS. Bucket + prefix are injected at init time, e.g.:
#   terraform init \
#     -backend-config="bucket=skycast-dev-tfstate" \
#     -backend-config="prefix=terraform/state"
terraform {
  backend "gcs" {}
}
