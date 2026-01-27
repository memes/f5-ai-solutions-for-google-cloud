#

terraform {
  required_version = ">= 1.5"
  required_providers {
    github = {
      source  = "integrations/github"
      version = ">= 6.10"
    }
    google = {
      source  = "hashicorp/google"
      version = ">= 7.16"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.6"
    }
  }
  # Change this to match the target GCS bucket that is managing Tofu/Terraform state
  backend "gcs" {
    bucket = "emes-stuff"
    prefix = "bootstrap/f5-google-next2026"
  }
}

# This assumes the provider is configured via environment variables GITHUB_TOKEN and GITHUB_OWNER; change as necessary.
# See https://registry.terraform.io/providers/integrations/github/latest/docs
provider "github" {}

# This assumes the provider is configured via ADC credentials and/or environment variables; change as necessary.
# See https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference
provider "google" {}


module "bootstrap" {
  source            = "registry.terraform.io/memes/f5-demo-bootstrap/google"
  version           = "0.4.1"
  project_id        = var.project_id
  name              = var.name
  labels            = var.labels
  github_options    = var.github_options
  gcp_options       = var.gcp_options
  bootstrap_apis    = var.bootstrap_apis
  iac_roles         = var.iac_roles
  iac_impersonators = var.iac_impersonators
  nginx_jwt         = var.nginx_jwt
}
