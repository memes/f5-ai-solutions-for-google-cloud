terraform {
  required_version = ">= 1.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 7.16"
    }
    http = {
      source  = "hashicorp/http"
      version = ">= 3.5"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.8"
    }
  }
}

locals {
  regional_names = { for region in var.regions : region => format("%s-%s", var.name, module.region_detail.results[region].abbreviation) }
  effective_labels = merge({
    demo_id = "f5-ai-solutions-for-google-cloud"
    module  = "foundations"
    },
  var.labels == null ? {} : var.labels)
  effective_domains = formatlist("%s.%s", [
    "arcadia",
    "f5-ai",
  ], var.dns.base_domain)
  global_peering_cidr      = coalesce(try(var.global_cidrs.peering, null), "198.18.0.0/15")
  global_proxy_cidr        = cidrsubnet(local.global_peering_cidr, 20 - tonumber(split("/", local.global_peering_cidr)[1]), 0)
  global_cache_cidr        = cidrsubnet(local.global_peering_cidr, 20 - tonumber(split("/", local.global_peering_cidr)[1]), 1)
  global_psc_cidr          = coalesce(try(var.global_cidrs.psc, null), "203.0.113.0/24")
  restricted_apis_psc_host = cidrhost(local.global_psc_cidr, 10)
  allowlist_cidrs          = coalescelist(try(length(var.allowlist_cidrs), 0) > 0 ? var.allowlist_cidrs : [], [format("%s/32", trimspace(data.http.my_address.response_body))])
}

provider "google" {
  default_labels = local.effective_labels
}

data "google_project" "project" {
  project_id = var.project_id
}

data "http" "my_address" {
  url = "https://checkip.amazonaws.com"
  lifecycle {
    postcondition {
      condition     = self.status_code == 200
      error_message = "Failed to get local IP address"
    }
  }
}

# data "google_compute_zones" "zones" {
#   for_each = { for region in var.regions : region => "UP" }
#   project  = var.project_id
#   region   = each.key
#   status   = each.value
# }

module "region_detail" {
  source  = "memes/region-detail/google"
  version = "1.1.7"
  regions = var.regions
}
