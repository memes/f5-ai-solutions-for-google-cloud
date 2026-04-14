# Deploy model(s) to Vertex AI endpoints with PSC

resource "google_vertex_ai_endpoint_with_model_garden_deployment" "gemma" {
  for_each             = local.regional_names
  project              = var.project_id
  publisher_model_name = "publishers/google/models/gemma3@gemma-3-4b-it"
  location             = each.key

  model_config {
    accept_eula = true
  }

  endpoint_config {
    private_service_connect_config {
      enable_private_service_connect = true
      project_allowlist = [
        var.project_id,
      ]
    }
  }
}

resource "google_compute_address" "gemma" {
  for_each = { for k, v in google_vertex_ai_endpoint_with_model_garden_deployment.gemma : k => {
    name   = format("%s-gemma", local.regional_names[v.location])
    subnet = module.vpc.subnets_by_region[v.location].name
    region = v.location
  } }
  project      = var.project_id
  name         = each.value.name
  description  = "PSC endpoint for gemma model on Vertex AI"
  subnetwork   = each.value.subnet
  region       = each.value.region
  address_type = "INTERNAL"
  purpose      = "GCE_ENDPOINT"

  depends_on = [
    google_vertex_ai_endpoint_with_model_garden_deployment.gemma,
  ]
}

resource "google_compute_forwarding_rule" "gemma" {
  for_each = { for k, v in google_vertex_ai_endpoint_with_model_garden_deployment.gemma : k => {
    name    = format("%s-gemma", local.regional_names[v.location])
    subnet  = module.vpc.subnets_by_region[v.location].name
    region  = v.location
    address = google_compute_address.gemma[k].id
    target  = v.endpoint_config[0].private_service_connect_config[0].service_attachment
  } }
  project               = var.project_id
  name                  = each.value.name
  description           = "PSC endpoint for gemma model on Vertex AI"
  region                = each.value.region
  ip_address            = each.value.address
  network               = module.vpc.self_link
  load_balancing_scheme = ""
  no_automate_dns_zone  = true
  target                = each.value.target

  depends_on = [
    google_vertex_ai_endpoint_with_model_garden_deployment.gemma,
    google_compute_address.gemma,
  ]
}

resource "google_dns_managed_zone" "vertex_ai" {
  project     = var.project_id
  name        = format("%s-vai-goog", var.name)
  description = "Override DNS resolution for Vertex AI prediction endpoints"
  dns_name    = "prediction.p.vertexai.goog."
  visibility  = "private"
  private_visibility_config {
    networks {
      network_url = module.vpc.self_link
    }
  }
}

resource "google_dns_record_set" "gemma" {
  for_each = { for k, v in google_vertex_ai_endpoint_with_model_garden_deployment.gemma : k => {
    name    = format("%s-gemma.%s", local.regional_names[v.location], google_dns_managed_zone.vertex_ai.dns_name)
    address = google_compute_address.gemma[k].address
  } }
  project      = var.project_id
  managed_zone = google_dns_managed_zone.vertex_ai.name
  name         = each.value.name
  type         = "A"
  ttl          = 60
  rrdatas = [
    each.value.address,
  ]

  depends_on = [
    google_vertex_ai_endpoint_with_model_garden_deployment.gemma,
    google_compute_address.gemma,
    google_dns_managed_zone.vertex_ai,
  ]
}
