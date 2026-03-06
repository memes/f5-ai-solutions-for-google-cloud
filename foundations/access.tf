#
# If direct external provisioning is enabled through the `provision_external_gw_address` variable, create resources to
# expose and control access to the applications via Google ALBs.
#
# NOTE: The ALBs will be provisioned through GatewayClass selection in kubernetes manifest(s).

# Create a VPC subnet for Google ALBs with /23 CIDR.
resource "google_compute_subnetwork" "proxy_subnet" {
  for_each = var.provision_external_gw_address ? { for i, region in var.regions :
    format("%s-proxy", local.regional_names[region]) => {
      region            = region
      primary_ipv4_cidr = cidrsubnet(local.global_proxy_cidr, 23 - tonumber(split("/", local.global_proxy_cidr)[1]), i)
    }
  } : {}
  project       = var.project_id
  name          = each.key
  network       = module.vpc.self_link
  ip_cidr_range = each.value.primary_ipv4_cidr
  region        = each.value.region
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}

resource "google_compute_region_security_policy" "allowlist" {
  for_each    = var.provision_external_gw_address ? local.regional_names : {}
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

module "managed_cert" {
  for_each   = var.provision_external_gw_address ? local.regional_names : {}
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
  for_each = coalesce(var.dns.managed_zone_id, "unspecified") == "unspecified" ? {} : { for entry in setproduct(keys(local.regional_names), local.effective_domains) : replace(format("%s-%s", entry[0], entry[1]), "/[^a-z0-9-]/", "-") => {
    region = entry[0]
    domain = entry[1]
  } }
  project      = coalesce(reverse(split("/", var.dns.managed_zone_id))[2], var.project_id)
  managed_zone = reverse(split("/", var.dns.managed_zone_id))[0]
  name         = one(distinct([for challenge in try(module.managed_cert[each.value.region].dns_challenges[each.value.domain], []) : challenge.name]))
  type         = one(distinct([for challenge in try(module.managed_cert[each.value.region].dns_challenges[each.value.domain], []) : challenge.type]))
  ttl          = 300
  rrdatas      = [for challenge in try(module.managed_cert[each.value.region].dns_challenges[each.value.domain], []) : challenge.data]
}

resource "google_compute_address" "gw" {
  for_each     = var.provision_external_gw_address ? local.regional_names : {}
  project      = var.project_id
  name         = format("%s-gw", each.value)
  description  = format("External IP for %s cluster Gateway", each.value)
  address_type = "EXTERNAL"
  region       = each.key
}

# If a Cloud DNS managed zone identifier has been provided we can add the supporting A records for each public reserved
# address.
resource "google_dns_record_set" "gw" {
  for_each     = var.provision_external_gw_address && coalesce(var.dns.managed_zone_id, "unspecified") != "unspecified" ? local.effective_domains : []
  project      = coalesce(reverse(split("/", var.dns.managed_zone_id))[2], var.project_id)
  managed_zone = reverse(split("/", var.dns.managed_zone_id))[0]
  name         = format("%s.", each.key)
  type         = "A"
  ttl          = 300
  rrdatas      = compact([for k, v in local.regional_names : try(google_compute_address.gw[k].address, null)])
}
