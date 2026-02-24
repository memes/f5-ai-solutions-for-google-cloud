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

data "http" "my_address" {
  url = "https://checkip.amazonaws.com"
  lifecycle {
    postcondition {
      condition     = self.status_code == 200
      error_message = "Failed to get local IP address"
    }
  }
}

provider "google" {
  default_labels = var.labels
}

locals {
  global_proxy_cidr        = coalesce(try(var.global_cidrs.proxy, null), "198.18.0.0/15")
  restricted_apis_psc_host = cidrhost(coalesce(try(var.global_cidrs.psc, null), "203.0.113.0/24"), 10)
  allowlist_cidrs          = coalescelist(try(length(var.allowlist_cidrs), 0) > 0 ? var.allowlist_cidrs : [], [format("%s/32", trimspace(data.http.my_address.response_body))])
}

module "region_detail" {
  source  = "memes/region-detail/google"
  version = "1.1.7"
  regions = var.regions
}

module "vpc" {
  source      = "memes/multi-region-private-network/google"
  version     = "5.2.0"
  project_id  = var.project_id
  name        = var.name
  description = "Foundational VPC for F5 AI Solutions for Google Cloud"
  regions     = var.regions
  cidrs = {
    primary_ipv4_cidr = coalesce(try(var.global_cidrs.primary, null), "172.16.0.0/12")
    secondaries = {
      pods = {
        ipv4_cidr        = coalesce(try(var.global_cidrs.pods, null), "10.0.0.0/9")
        ipv4_subnet_size = 16
      }
      services = {
        ipv4_cidr        = coalesce(try(var.global_cidrs.services, null), "10.128.0.0/9")
        ipv4_subnet_size = 24
      }
    }
  }
  psc = {
    address = local.restricted_apis_psc_host
  }
  nat = try(length(var.nat_tags), 0) > 0 ? { tags = var.nat_tags } : null
}

resource "google_compute_region_security_policy" "allowlist" {
  for_each    = { for i, region in var.regions : region => format("%s-%s", var.name, module.region_detail.results[region].abbreviation) }
  project     = var.project_id
  name        = each.value
  description = "Security policy to allow access from permitted CIDRs."
  region      = each.key
  type        = "CLOUD_ARMOR"
  rules {
    description = "Allow matching source CIDRs"
    action      = "allow"
    priority    = 1000
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = try(length(local.allowlist_cidrs), 0) > 0 ? local.allowlist_cidrs : ["0.0.0.0/0"]
      }
    }
  }
  rules {
    description = "Deny by default"
    action      = "deny(403)"
    priority    = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = [
          "*",
        ]
      }
    }
  }
}

resource "google_compute_subnetwork" "proxy_subnet" {
  for_each = { for i, region in var.regions :
    format("%s-proxy-%s", var.name, module.region_detail.results[region].abbreviation) => {
      region            = region
      primary_ipv4_cidr = cidrsubnet(local.global_proxy_cidr, 23 - tonumber(split("/", local.global_proxy_cidr)[1]), i)
    }
  }
  project       = var.project_id
  name          = each.key
  network       = module.vpc.self_link
  ip_cidr_range = each.value.primary_ipv4_cidr
  region        = each.value.region
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}

module "googleapis-dns" {
  source      = "memes/restricted-apis-dns/google"
  version     = "2.0.1"
  project_id  = var.project_id
  name        = var.name
  description = "Cloud DNS resolution for Google services via restricted endpoints."
  network_self_links = [
    module.vpc.self_link,
  ]
  addresses = {
    ipv4 = [
      local.restricted_apis_psc_host,
    ]
    ipv6 = null
  }
}

resource "google_dns_managed_zone" "pg" {
  project     = var.project_id
  name        = format("%s-sql-goog", var.name)
  description = "Override Cloud SQL sql.goog"
  dns_name    = "sql.goog."
  visibility  = "private"
  private_visibility_config {
    networks {
      network_url = module.vpc.self_link
    }
  }
}

module "f5_ai_license" {
  for_each   = coalesce(var.f5_ai_license, "unspecified") == "unspecified" ? {} : { secret = var.f5_ai_license }
  source     = "memes/secret-manager/google"
  version    = "2.2.2"
  project_id = var.project_id
  id         = format("%s-f5-ai-license", var.name)
  secret     = each.value
  accessors  = []
}

module "hugging_face_token" {
  for_each   = coalesce(var.hugging_face_token, "unspecified") == "unspecified" ? {} : { secret = var.hugging_face_token }
  source     = "memes/secret-manager/google"
  version    = "2.2.2"
  project_id = var.project_id
  id         = format("%s-hugging-face", var.name)
  secret     = each.value
  accessors  = []
}

module "cert" {
  for_each   = { for region in var.regions : region => format("%s-%s", var.name, module.region_detail.results[region].abbreviation) }
  source     = "registry.terraform.io/memes/tls-certificate/google//modules/managed"
  version    = "0.1.0"
  project_id = var.project_id
  domains = [
    format("arcadia.%s", var.domain_name),
    format("f5-ai.%s", var.domain_name)
  ]
  certificate_manager = {
    name        = each.value
    description = "Certificate for F5 AI Solutions for Google Cloud"
    region      = each.key
  }
  ssl_policy = {
    name            = each.value
    region          = each.key
    description     = "SSL Policy for F5 AI Solutions for Google Cloud"
    profile         = "RESTRICTED"
    min_tls_version = "TLS_1_2"
  }
}
