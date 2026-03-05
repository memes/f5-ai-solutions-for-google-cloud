#
# Provide

# Create a VPC subnet for Google ALBs with /23 CIDR.
resource "google_compute_subnetwork" "proxy_subnet" {
  for_each = { for i, region in var.regions :
    format("%s-proxy", local.regional_names[region]) => {
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

resource "google_compute_region_security_policy" "allowlist" {
  for_each    = local.regional_names
  project     = var.project_id
  name        = each.value
  description = "Security policy to allow access to applications from permitted CIDRs."
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

module "cert" {
  for_each   = local.regional_names
  source     = "registry.terraform.io/memes/tls-certificate/google//modules/managed"
  version    = "0.1.1"
  project_id = var.project_id
  domains    = local.effective_domains
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

# If a Cloud DNS managed zone identifier has been provided we can add the supporting entries for Certificate Manager DNS
# challenges.
resource "google_dns_record_set" "challenges" {
  for_each     = coalesce(var.dns.managed_zone_id, "unspecified") == "unspecified" ? {} : { for i, entry in setproduct(keys(local.regional_names), local.effective_domains) : replace(format("%s-%s", entry[0], entry[1]), "/[^a-z0-9-]/", "-") => module.cert[entry[0]].dns_challenges[entry[1]] }
  project      = coalesce(reverse(split("/", var.dns.managed_zone_id))[2], var.project_id)
  managed_zone = reverse(split("/", var.dns.managed_zone_id))[0]
  name         = one(distinct([for challenge in each.value : challenge.name]))
  type         = one(distinct([for challenge in each.value : challenge.type]))
  ttl          = 300
  rrdatas      = [for challenge in each.value : challenge.data]
}
