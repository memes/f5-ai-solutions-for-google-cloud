module "sa" {
  # TODO(@memes): Pin version on release, still testing updates
  source       = "git::https://github.com/memes/terraform-google-private-gke-cluster//modules/sa?ref=feat%2fv3_refactor"
  project_id   = var.project_id
  name         = format("%s-gke", var.name)
  description  = "Service account for F5 AI Solutions example GKE clusters"
  display_name = "F5 AI Solutions cluster service account"
  repositories = var.repositories
}

module "cluster" {
  for_each = { for k, v in local.regional_names : k => {
    name        = v
    subnet      = module.vpc.subnets_by_region[k].self_link
    description = format("F5 AI Solutions for Google Cloud in %s", k)
    dns_domain  = format("cluster.%s.%s", module.region_detail.results[k].abbreviation, coalesce(try(var.dns.base_domain, null), "arpa"))
    }
  }
  # TODO: @memes - pin version on release, still testing updates
  source          = "git::https://github.com/memes/terraform-google-private-gke-cluster//modules/autopilot?ref=feat%2fv3_refactor"
  project_id      = var.project_id
  name            = each.value.name
  description     = each.value.description
  service_account = module.sa.email
  subnet = {
    self_link = each.value.subnet
  }
  features = {
    secret_manager        = true
    secret_sync           = true
    gateway_api           = true
    managed_opentelemetry = true
  }
  dns = {
    additive_vpc_scope_dns_domain = each.value.dns_domain
  }
  labels = local.effective_labels
}
