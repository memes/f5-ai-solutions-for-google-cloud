# If NGINXaaS configuration variable is null, create resources to expose and control access to the applications via
# Google L7 ALBs.
#
# NOTE: The actual ALBs will be provisioned through GatewayClass selection in kubernetes manifest(s).

resource "google_compute_region_security_policy" "allowlist" {
  for_each    = var.nginxaas == null ? local.regional_names : {}
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
  for_each   = var.nginxaas == null ? local.regional_names : {}
  source     = "registry.terraform.io/memes/tls-certificate/google//modules/managed"
  version    = "0.2.0"
  project_id = var.project_id
  domains = merge(
    { for k, v in local.regional_domains : v => { managed_zone_id = try(var.dns.managed_zone_id, null) } },
    { for k, v in local.regional_cluster_domains : v => { managed_zone_id = try(var.dns.managed_zone_id, null) } },
  )
  certificate_manager = {
    name         = each.value
    description  = "Certificate for F5 AI Solutions for Google Cloud"
    region       = each.key
    add_wildcard = true
  }
  ssl_policy = {
    name            = each.value
    region          = each.key
    description     = "SSL Policy for F5 AI Solutions for Google Cloud"
    profile         = "RESTRICTED"
    min_tls_version = "TLS_1_2"
  }
}
