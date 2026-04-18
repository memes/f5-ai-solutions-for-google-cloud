module "nginxaas" {
  for_each   = var.nginxaas == null ? {} : { enabled = true }
  source     = "git::https://github.com/memes/terraform-google-nginxaas?ref=release%2f0.1.0"
  project_id = var.project_id
  workload_identity = {
    pool_id = var.workload_identity_pool_id
    name    = format("%s-nginxaas", var.name)
  }
  attachments = { for k, v in local.regional_names : k => { # TODO(@memes): This should be v
    subnet             = module.vpc.subnets_by_region[k].self_link
    ports              = [80, 443]
    service_attachment = try(var.nginxaas.attachments[k], null)
    }
  }
  service_accounts = try(var.nginxaas.service_accounts, null)
  secrets          = try(var.nginxaas.secrets, null)
}

resource "google_compute_region_backend_service" "nginxaas" {
  for_each              = var.nginxaas == null ? {} : try(module.nginxaas["enabled"].network_endpoint_groups_by_name, {})
  project               = var.project_id
  name                  = replace(each.key, ":", "-")
  region                = reverse(split("/", each.value))[2]
  load_balancing_scheme = "EXTERNAL_MANAGED"
  locality_lb_policy    = "MAGLEV"
  protocol              = "TCP"
  session_affinity      = "NONE"
  backend {
    balancing_mode = "UTILIZATION"
    group          = each.value
  }

  depends_on = [
    module.nginxaas,
  ]
}

resource "google_compute_forwarding_rule" "nginxaas" {
  for_each              = google_compute_region_backend_service.nginxaas
  project               = var.project_id
  name                  = each.value.name
  description           = "Send HTTP traffic to NGINXaaS."
  region                = each.value.region
  backend_service       = each.value.id
  ip_address            = google_compute_address.ext[each.value.region].name
  ip_protocol           = "TCP"
  ip_version            = "IPV4"
  port_range            = split(":", each.key)[1]
  load_balancing_scheme = "EXTERNAL_MANAGED"

  depends_on = [
    google_compute_region_backend_service.nginxaas,
  ]
}
