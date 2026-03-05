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
  global_proxy_cidr        = coalesce(try(var.global_cidrs.proxy, null), "198.18.0.0/15")
  restricted_apis_psc_host = cidrhost(coalesce(try(var.global_cidrs.psc, null), "203.0.113.0/24"), 10)
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

module "region_detail" {
  source  = "memes/region-detail/google"
  version = "1.1.7"
  regions = var.regions
}

module "sa" {
  # TODO(@memes): Pin version on release, still testing updates
  source       = "git::https://github.com/memes/terraform-google-private-gke-cluster//modules/sa?ref=feat%2fv3_refactor"
  project_id   = var.project_id
  name         = format("%s-gke", var.name)
  description  = "Service account for F5 AI Solutions example GKE clusters"
  display_name = "F5 AI Solutions cluster service account"
  repositories = compact([var.repository])
}
