module "nginxaas" {
  for_each   = var.nginxaas == null ? {} : { enabled = true }
  source     = "git::https://github.com/memes/terraform-google-nginxaas?ref=release%2f0.1.0"
  project_id = var.project_id
  workload_identity = {
    pool_id = var.workload_identity_pool_id
    name    = format("%s-nginxaas", var.name)
  }
  attachments = { for k, v in local.regional_names : k => {
    subnet             = module.vpc.subnets_by_region[k].self_link
    ports              = [80, 443]
    service_attachment = try(var.nginxaas.attachments[k], null)
    }
  }
  service_accounts = try(var.nginxaas.service_accounts, null)
  secrets          = try(var.nginxaas.secrets, null)
}

resource "google_compute_region_health_check" "readyz" {
  for_each            = var.nginxaas == null ? {} : local.regional_names
  project             = var.project_id
  name                = each.value
  region              = each.key
  check_interval_sec  = 10
  timeout_sec         = 1
  healthy_threshold   = 1
  unhealthy_threshold = 2
  http_health_check {
    request_path       = "/readyz"
    port_specification = "USE_SERVING_PORT"
  }
}

resource "google_compute_region_backend_service" "nginxaas" {
  for_each = var.nginxaas == null ? {} : try(module.nginxaas["enabled"].network_endpoint_groups_by_region, {})
  project  = var.project_id
  name     = local.regional_names[each.key]
  region   = each.key
  health_checks = [
    google_compute_region_health_check.readyz[each.key].self_link,
  ]
  load_balancing_scheme = "EXTERNAL_MANAGED"
  locality_lb_policy    = "MAGLEV"
  protocol              = "TCP"
  dynamic "backend" {
    for_each = each.value
    content {
      balancing_mode               = "CONNECTION"
      capacity_scaler              = 1.0
      max_connections_per_endpoint = 1000
      group                        = backend.value
    }
  }

  depends_on = [
    module.nginxaas,
  ]
}

resource "google_compute_forwarding_rule" "http" {
  for_each              = google_compute_region_backend_service.nginxaas
  project               = var.project_id
  name                  = local.regional_names[each.key]
  description           = "Send HTTP traffic to NGINXaaS."
  region                = each.key
  backend_service       = each.value.id
  ip_address            = google_compute_address.ext[each.key].name
  ip_protocol           = "TCP"
  ip_version            = "IPV4"
  port_range            = "80"
  load_balancing_scheme = "EXTERNAL_MANAGED"

  depends_on = [
    google_compute_region_backend_service.nginxaas,
  ]
}

resource "google_compute_forwarding_rule" "https" {
  for_each              = google_compute_region_backend_service.nginxaas
  project               = var.project_id
  name                  = local.regional_names[each.key]
  description           = "Send HTTPS traffic to NGINXaaS."
  region                = each.key
  backend_service       = each.value.id
  ip_address            = google_compute_address.ext
  ip_protocol           = "TCP"
  ip_version            = "IPV4"
  port_range            = "443"
  load_balancing_scheme = "EXTERNAL_MANAGED"

  depends_on = [
    google_compute_region_backend_service.nginxaas,
  ]
}
