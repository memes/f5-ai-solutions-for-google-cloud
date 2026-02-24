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
    prefix = "bootstrap/f5-ai-solutions-for-google-cloud"
  }
}

# This assumes the provider is configured via environment variables GITHUB_TOKEN and GITHUB_OWNER; change as necessary.
# See https://registry.terraform.io/providers/integrations/github/latest/docs
provider "github" {}

# This assumes the provider is configured via ADC credentials and/or environment variables; change as necessary.
# See https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference
provider "google" {
  default_labels = var.labels
}


module "bootstrap" {
  source  = "registry.terraform.io/memes/f5-demo-bootstrap/google"
  version = "0.4.2"
  # source = "git::https://github.com/memes/terraform-google-f5-demo-bootstrap?ref=fix%2foutput_nginx_jwt_secret_id"
  project_id        = var.project_id
  name              = var.name
  github_options    = var.github_options
  iac_impersonators = var.iac_impersonators
  nginx_jwt         = var.nginx_jwt
  bootstrap_apis = [
    "aiplatform.googleapis.com",
    "certificatemanager.googleapis.com",
    "cloudtrace.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "dns.googleapis.com",
    "iam.googleapis.com",
    "kubernetesmetadata.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "secretmanager.googleapis.com",
    "serviceusage.googleapis.com",
    "sql-component.googleapis.com",
    "sqladmin.googleapis.com",
    "telemetry.googleapis.com",
  ]
  iac_roles = [
    "roles/certificatemanager.owner",
    "roles/clouddeploy.operator",
    "roles/cloudsql.admin",
    "roles/compute.instanceAdmin", # TODO(@memes): Needed for bastion module, can be removed later
    "roles/compute.networkAdmin",
    "roles/compute.securityAdmin", # TODO(@memes): Required for bastion module, can be removed later
    "roles/container.admin",
    "roles/dns.admin",
    "roles/iam.securityAdmin",
    "roles/iam.serviceAccountAdmin",
    "roles/iam.serviceAccountUser",
    "roles/iam.serviceAccountTokenCreator",
    "roles/secretmanager.admin",
    "roles/serviceusage.serviceUsageAdmin",
  ]
}
