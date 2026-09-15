# Remote state in an OCI Object Storage bucket via its S3-compatible endpoint.
# OpenTofu's native "oci" backend does NOT exist (that's Terraform-only), so
# this uses the "s3" backend pointed at OCI instead.
#
# Backend config blocks can't reference variables, so the placeholders below
# must be filled in by hand (or overridden with -backend-config flags) before
# the first `tofu init`. The bucket itself must already exist — see
# docs/bootstrap.md for the one-time manual creation steps. Credentials come
# from AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY env vars, set to an OCI
# Customer Secret Key (NOT your OCI API key) — never hardcode them here.
terraform {
  backend "s3" {
    bucket = "colini-dev-tfstate"
    key    = "colini-dev/terraform.tfstate"
    region = "sa-saopaulo-1"

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true
    use_lockfile                = true # verify this actually works against OCI before relying on it (see docs/bootstrap.md)

    endpoints = {
      s3 = "https://grial0cmovcg.compat.objectstorage.sa-saopaulo-1.oraclecloud.com"
    }
  }
}
