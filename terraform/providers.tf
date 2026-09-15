# Authenticates via the standard ~/.oci/config file, created once locally by
# running `oci setup config` (see docs/bootstrap.md). No credentials live in
# this repo.
provider "oci" {
  region              = var.region
  config_file_profile = "DEFAULT"
}
