module "sa" {
  # TODO(@memes): Pin version on release, still testing updates
  source       = "git::https://github.com/memes/terraform-google-private-gke-cluster//modules/sa?ref=feat%2fv3_refactor"
  project_id   = var.project_id
  name         = format("%s-gke", var.name)
  description  = "Service account for F5 AI Solutions example GKE clusters"
  display_name = "F5 AI Solutions cluster service account"
  repositories = compact([var.repository])
}

module "cluster" {
  for_each = { for k, v in local.regional_names : k => {
    name        = v
    subnet      = module.vpc.subnets_by_region[k].self_link
    master_cidr = cidrsubnet("192.168.0.0/24", 4, index(keys(local.regional_names), k))
    description = format("F5 AI Solutions for Google Cloud in %s", k)
    # external_dns_domain = format("%s.%s", var.name, module.region_detail.results[region].abbreviation)
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
}

resource "google_clouddeploy_target" "cluster" {
  for_each = { for k, v in module.cluster : k => {
    name       = v.name
    cluster_id = v.id
    }
  }
  project          = var.project_id
  name             = each.value.name
  location         = each.key
  description      = "F5 AI Solutions for Google Cloud target cluster"
  require_approval = false
  gke {
    cluster = each.value.cluster_id
  }
}

# resource "google_clouddeploy_target" "all" {
#   project          = var.project_id
#   name             = var.name
#   location         = var.deployment_pipeline_location
#   description      = "Deploy resources to all targets"
#   require_approval = false
#   execution_configs {
#     service_account = var.cloud_deploy_service_account
#     usages = [
#       "RENDER",
#       "PREDEPLOY",
#       "DEPLOY",
#       "VERIFY",
#       "POSTDEPLOY",
#     ]
#   }
#   multi_target {
#     target_ids = [for k, v in google_clouddeploy_target.cluster : v.target_id]
#   }
# }

# resource "google_clouddeploy_delivery_pipeline" "apps" {
#   project     = var.project_id
#   name        = var.name
#   location    = var.deployment_pipeline_location
#   annotations = {}
#   description = "Deployment pipeline for F5 AI Solutions for GKE Inference Gateway"
#   labels      = var.labels
#   suspended   = false
#   serial_pipeline {
#     stages {
#       target_id = google_clouddeploy_target.all.target_id
#       deploy_parameters {
#         values = {
#           "image.repository" = format("%s/calypsoai/cai_moderator", var.repository)
#         }
#       }
#       profiles = []
#     }
#   }
# }
