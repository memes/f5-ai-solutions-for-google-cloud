# locals {
#     re_service_identity = format("service-%s@gcp-sa-aiplatform-re.iam.gserviceaccount.com", data.google_project.project.number)
# }

# resource "google_artifact_registry_repository_iam_member" "ai" {
#   for_each   = var.repositories == null ? {} : { for name in var.repositories : name => { repo = regex("^.*-docker\\.pkg\\.dev/[^/]+/([^/]+)", name)[0], location = regex("^(.*)-docker", name)[0], project = regex("docker\\.pkg\\.dev/([^/]+)/", name)[0] } if can(regex("^.+-docker\\.pkg\\.dev/[^/]+/[^/]+", name)) }
#   project    = each.value.project
#   location   = each.value.location
#   repository = each.value.repo
#   role       = "roles/artifactregistry.reader"
#   member     = format("serviceAccount:%s", local.re_service_identity)
# }

resource "google_compute_network_attachment" "agent_gateway" {
  for_each    = local.regional_names
  project     = var.project_id
  name        = format("%s-agw", each.value)
  description = format("Agent Gateway attachment for %s in %s", var.name, each.key)
  region      = each.key
  subnetworks = [
    module.vpc.subnets_by_region[each.key].self_link
  ]
  # TODO(@memes): Review this with Google as prefer to explicitly list the producer projects
  connection_preference = "ACCEPT_AUTOMATIC"
}

# tflint-ignore: terraform_required_providers
resource "google_network_services_agent_gateway" "egress" {
  for_each    = google_compute_network_attachment.agent_gateway
  provider    = google-beta
  project     = var.project_id
  name        = each.value.name
  description = format("Egress Agent Gateway for %s in %s", var.name, each.key)
  location    = each.key
  protocols = [
    "MCP",
  ]
  google_managed {
    governed_access_path = "AGENT_TO_ANYWHERE"
  }

  network_config {
    egress {
      network_attachment = each.value.id
    }

    dns_peering_config {
      domains = [
        local.regional_cluster_domains[each.key],
      ]
      target_project = var.project_id
      target_network = module.vpc.id
    }
  }

  registries = [
    format("//agentregistry.googleapis.com/projects/%s/locations/%s", data.google_project.project.project_id, each.key),
  ]
}

resource "google_network_services_authz_extension" "iap" {
  for_each = google_network_services_agent_gateway.egress
  project  = var.project_id
  name     = format("%s-iap", each.value.name)
  location = each.key
  service  = "iap.googleapis.com"
  metadata = merge(
    {
      "iapPolicyVersion" = "V1"
    },
    try(var.agent_gateway.enforce_iap, true) ? {} : {
      "iamEnforcementMode" = "DRY_RUN"
    },
  )
  timeout = "1s"
}

resource "google_network_security_authz_policy" "iap" {
  for_each       = google_network_services_agent_gateway.egress
  project        = var.project_id
  name           = format("%s-iap", each.value.name)
  location       = each.key
  policy_profile = "REQUEST_AUTHZ"
  action         = "CUSTOM"
  target {
    resources = [
      each.value.id
    ]
  }
  custom_provider {
    authz_extension {
      resources = [
        google_network_services_authz_extension.iap[each.key].id,
      ]
    }
  }
}
