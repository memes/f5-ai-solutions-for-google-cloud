# Create a global VPC network for clusters, with a /24 primary, /16 pod and /24 service CIDR per region, with restricted
# Google API access through PSC.

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
