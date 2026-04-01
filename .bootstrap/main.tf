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
  default_labels = merge({
    demo_id = "f5-ai-solutions-for-google-cloud"
    module  = "dot_bootstrap"
    },
  var.labels == null ? {} : var.labels)
}


module "bootstrap" {
  source            = "registry.terraform.io/memes/f5-demo-bootstrap/google"
  version           = "0.5.1"
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
    "modelarmor.googleapis.com",
    "monitoring.googleapis.com",
    "networkservices.googleapis.com",
    "redis.googleapis.com",
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
    "roles/compute.networkAdmin",
    "roles/compute.securityAdmin",
    "roles/container.admin",
    "roles/dns.admin",
    "roles/iam.securityAdmin",
    "roles/iam.serviceAccountAdmin",
    "roles/iam.serviceAccountUser",
    "roles/iam.serviceAccountTokenCreator",
    "roles/redis.admin",
    "roles/secretmanager.admin",
    "roles/serviceusage.serviceUsageAdmin",
    "roles/storage.admin",
  ]
  cloud_deploy_roles = [
    "roles/container.developer",
  ]
}

# F5 AI Guardrails and Red Team deployments need the license token; if provided, create a secret containing the token
# but do not assign any accessors.
module "f5_ai_license" {
  for_each   = coalesce(try(var.f5_ai_license, null), "unspecified") == "unspecified" ? {} : { global = var.f5_ai_license }
  source     = "memes/secret-manager/google"
  version    = "2.2.2"
  project_id = var.project_id
  id         = format("%s-f5-ai-license", var.name)
  secret     = each.value
  accessors  = []
}

locals {
  repo_name = reverse(split("/", module.bootstrap.github_repo))[0]
}

resource "github_actions_variable" "f5_ai_license" {
  for_each      = { for secret in module.f5_ai_license : "F5_AI_LICENSE_SECRET" => secret.id }
  repository    = local.repo_name
  variable_name = each.key
  value         = each.value
}

# Add the base domain to the GitHub repo as a variable, but let the value be changed from the initial value as needed.
resource "github_actions_variable" "dns" {
  for_each = merge(
    coalesce(try(var.dns.base_domain, null), "unspecified") == "unspecified" ? {} : { "DNS_BASE_DOMAIN" = var.dns.base_domain },
    coalesce(try(var.dns.managed_zone_id, null), "unspecified") == "unspecified" ? {} : { "DNS_MANAGED_ZONE_ID" = var.dns.managed_zone_id },
  )
  repository    = local.repo_name
  variable_name = each.key
  value         = each.value
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}


# Add the initial CIDR allow list to the GitHub repo as a variable, but let the value be changed from the initial value
# as needed.
resource "github_actions_variable" "allowlist_cidrs" {
  repository    = local.repo_name
  variable_name = "ALLOWLIST_CIDRS"
  value         = jsonencode(try(length(var.allowlist_cidrs), 0) == 0 ? [] : var.allowlist_cidrs)
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "google_storage_bucket" "model_cache" {
  project                     = var.project_id
  name                        = format("%s-model-cache", var.name)
  force_destroy               = true
  location                    = "US"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  versioning {
    enabled = false
  }
  soft_delete_policy {
    retention_duration_seconds = 0
  }
}

# Add the model cache bucket to the GitHub repo as a variable,  but let the
# value be changed from the initial value as needed.
resource "github_actions_variable" "model_cache_bucket" {
  repository    = local.repo_name
  variable_name = "MODEL_CACHE_BUCKET"
  value         = google_storage_bucket.model_cache.name
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}
