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

# This assumes the provider is mostly configured via environment variables GITHUB_TOKEN, GITHUB_OWNER,
# GITHUB_ORGANIZATION, etc.
# See https://registry.terraform.io/providers/integrations/github/latest/docs
provider "github" {
  owner = try(var.github_options.org, null)
}

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
  source                 = "registry.terraform.io/memes/f5-demo-bootstrap/google"
  version                = "0.7.0"
  project_id             = var.project_id
  name                   = var.name
  github_options         = var.github_options
  iac_impersonators      = var.iac_impersonators
  nginx_jwt              = var.nginx_jwt
  f5_ai_repo_credentials = var.f5_ai_repo_credentials
  bootstrap_apis = [
    "agentregistry.googleapis.com",
    "aiplatform.googleapis.com",
    "apphub.googleapis.com",
    "apptopology.googleapis.com",
    "certificatemanager.googleapis.com",
    "cloudapiregistry.googleapis.com",
    "cloudtrace.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "discoveryengine.googleapis.com",
    "dns.googleapis.com",
    "iam.googleapis.com",
    "kubernetesmetadata.googleapis.com",
    "logging.googleapis.com",
    "modelarmor.googleapis.com",
    "monitoring.googleapis.com",
    "networksecurity.googleapis.com",
    "networkservices.googleapis.com",
    "observability.googleapis.com",
    "redis.googleapis.com",
    "secretmanager.googleapis.com",
    "servicedirectory.googleapis.com",
    "serviceusage.googleapis.com",
    "sql-component.googleapis.com",
    "sqladmin.googleapis.com",
    "telemetry.googleapis.com",
  ]
  iac_roles = [
    "roles/aiplatform.user",
    "roles/certificatemanager.owner",
    "roles/clouddeploy.operator",
    "roles/cloudsql.admin",
    "roles/compute.loadBalancerAdmin",
    "roles/compute.networkAdmin",
    "roles/compute.securityAdmin",
    "roles/container.admin",
    "roles/dns.admin",
    "roles/iam.securityAdmin",
    "roles/iam.serviceAccountAdmin",
    "roles/iam.serviceAccountUser",
    "roles/iam.serviceAccountTokenCreator",
    "roles/modelarmor.editor",
    "roles/networksecurity.editor",
    "roles/networkservices.editor",
    "roles/redis.admin",
    "roles/secretmanager.admin",
    "roles/servicedirectory.editor",
    "roles/serviceusage.serviceUsageAdmin",
    "roles/storage.admin",
  ]
  cloud_deploy_roles = [
    "roles/container.developer",
  ]
  iac_options = {
    enable_workload_identity_pool_admin = true
  }
  gcp_options = {
    enable_cloud_deploy  = true
    enable_infra_manager = true
    create_state_bucket  = false
  }
  secrets = var.secrets
  virtual_repo = {
    enable     = true
    docker_hub = true
  }
}

locals {
  repo_name = reverse(split("/", module.bootstrap.github_repo))[0]
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

# For NGINXaaS integration the workload identity pool identifier is needed.
resource "github_actions_secret" "pool_id" {
  repository  = local.repo_name
  secret_name = "WORKLOAD_IDENTITY_POOL_ID"
  value       = module.bootstrap.workload_identity_pool_id

  depends_on = [
    module.bootstrap,
  ]
}
