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
  # google_vertex_ai_endpoint_with_model_garden_deployment resource does not expose a `region` or `zone` field as it
  # uses `location` but the underlying implementation fails if a region or zone is not provided. Use the first region
  # in provided as the default, even though all resources explicitly declare which one to use.
  region = var.regions[0]
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

data "google_compute_zones" "zones" {
  for_each = { for region in var.regions : region => "UP" }
  project  = var.project_id
  region   = each.key
  status   = each.value
}

module "region_detail" {
  source  = "memes/region-detail/google"
  version = "1.1.7"
  regions = var.regions
}

resource "google_compute_address" "ext" {
  for_each     = var.nginxaas == null || !try(var.nginxaas.has_managed_public_endpoint, false) ? local.regional_names : {}
  project      = var.project_id
  name         = format("%s-ext", each.value)
  description  = format("External IP for public access to %s cluster", each.value)
  address_type = "EXTERNAL"
  region       = each.key
}

# If a Cloud DNS managed zone identifier has been provided we can add the supporting A records for each public reserved
# address.
resource "google_dns_record_set" "ext" {
  for_each     = coalesce(var.dns.managed_zone_id, "unspecified") != "unspecified" ? toset(local.effective_domains) : []
  project      = coalesce(reverse(split("/", var.dns.managed_zone_id))[2], var.project_id)
  managed_zone = reverse(split("/", var.dns.managed_zone_id))[0]
  name         = format("%s.", each.key)
  type         = "A"
  ttl          = 300
  rrdatas      = compact([for k, v in local.regional_names : try(google_compute_address.ext[k].address, null)])
}
