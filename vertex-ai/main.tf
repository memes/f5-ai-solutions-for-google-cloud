terraform {
  required_version = ">= 1.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 7.28"
    }
  }
}

provider "google" {
  default_labels = merge({
    demo_id = "f5-ai-solutions-for-google-cloud"
    module  = "vertex-ai"
    },
  var.labels == null ? {} : var.labels)
  # google_vertex_ai_endpoint_with_model_garden_deployment resource does not expose a `region` or `zone` field as it
  # uses `location` but the underlying implementation fails if a region or zone is not provided. Use the first region
  # in provided as the default, even though all resources explicitly declare which one to use.
  region = try(keys(var.subnets)[0], null)
}

data "google_project" "project" {
  project_id = var.project_id
}

data "google_compute_subnetwork" "subnets" {
  for_each  = var.subnets == null ? {} : var.subnets
  self_link = each.value
}

module "region_detail" {
  source  = "memes/region-detail/google"
  version = "1.1.7"
  regions = [for subnet in data.google_compute_subnetwork.subnets : subnet.region]
}

locals {
  regional_names = { for k, v in data.google_compute_subnetwork.subnets : v.region => format("%s-%s", var.name, module.region_detail.results[v.region].abbreviation) }
  regional_models = { for entry in setproduct(keys(local.regional_names), var.publisher_models == null ? [] : var.publisher_models) : format("%s-%s", local.regional_names[entry[0]], endswith(entry[1], "@001") ? trimsuffix(reverse(split("/", entry[1]))[0], "@001") : reverse(split("@", entry[1]))[0]) => {
    location = entry[0]
    model    = entry[1]
  } }
}

# Deploy model(s) to Vertex AI endpoints with PSC

resource "google_vertex_ai_endpoint_with_model_garden_deployment" "model" {
  for_each             = local.regional_models
  project              = var.project_id
  publisher_model_name = each.value.model
  location             = each.value.location

  model_config {
    accept_eula                = true
    hugging_face_cache_enabled = true
    model_display_name         = each.key
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

resource "google_project_iam_member" "vertex_user" {
  project = var.project_id
  member  = format("principal://iam.googleapis.com/projects/%s/locations/global/workloadIdentityPools/%s.svc.id.goog/subject/ns/shared-services/sa/auth-proxy", data.google_project.project.number, data.google_project.project.project_id)
  role    = "roles/aiplatform.user"
}

resource "google_compute_address" "model" {
  for_each = { for k, v in google_vertex_ai_endpoint_with_model_garden_deployment.model : k => {
    subnet = data.google_compute_subnetwork.subnets[v.location].self_link
    region = v.location
  } }
  project      = var.project_id
  name         = each.key
  description  = "PSC endpoint for Vertex AI model"
  subnetwork   = each.value.subnet
  region       = each.value.region
  address_type = "INTERNAL"
  purpose      = "GCE_ENDPOINT"

  depends_on = [
    google_vertex_ai_endpoint_with_model_garden_deployment.model,
  ]
}

resource "google_compute_forwarding_rule" "gemma" {
  for_each = { for k, v in google_vertex_ai_endpoint_with_model_garden_deployment.model : k => {
    subnet  = data.google_compute_subnetwork.subnets[v.location].self_link
    network = data.google_compute_subnetwork.subnets[v.location].network
    region  = v.location
    address = google_compute_address.model[k].id
    target  = v.endpoint_config[0].private_service_connect_config[0].service_attachment
  } }
  project               = var.project_id
  name                  = each.key
  description           = "PSC endpoint for Vertex AI model"
  region                = each.value.region
  ip_address            = each.value.address
  network               = each.value.network
  load_balancing_scheme = ""
  no_automate_dns_zone  = true
  target                = each.value.target

  depends_on = [
    google_vertex_ai_endpoint_with_model_garden_deployment.model,
    google_compute_address.model,
  ]
}

resource "google_dns_managed_zone" "vertex_ai" {
  project     = var.project_id
  name        = format("%s-vai-goog", var.name)
  description = "Override DNS resolution for Vertex AI prediction endpoints"
  dns_name    = "prediction.p.vertexai.goog."
  visibility  = "private"
  private_visibility_config {
    dynamic "networks" {
      for_each = data.google_compute_subnetwork.subnets
      content {
        network_url = networks.value.network
      }
    }
  }
}

resource "google_dns_record_set" "model" {
  for_each = { for k, v in google_vertex_ai_endpoint_with_model_garden_deployment.model : k => {
    name    = format("%s.%s", k, google_dns_managed_zone.vertex_ai.dns_name)
    address = google_compute_address.model[k].address
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
    google_vertex_ai_endpoint_with_model_garden_deployment.model,
    google_compute_address.model,
    google_dns_managed_zone.vertex_ai,
  ]
}
