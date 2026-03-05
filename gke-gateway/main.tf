terraform {
  required_version = ">= 1.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 7.16"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.8"
    }
  }
}

data "terraform_remote_state" "foundations" {
  backend = "local" # TODO(@memes): Change
  config = {
    path = format("%s/../foundations/terraform.tfstate", path.module)
  }
}

provider "google" {
  default_labels = merge(try(data.terraform_remote_state.foundations.outputs.labels, {}), var.labels)
}

data "google_project" "project" {
  project_id = var.project_id
}

data "google_compute_subnetwork" "subnets" {
  for_each  = { for subnet in try(data.terraform_remote_state.foundations.outputs.subnets, {}) : reverse(split("/", subnet))[2] => subnet }
  self_link = each.value
}

locals {
  regions = [for k, v in data.google_compute_subnetwork.subnets : v.region]
}

module "region_detail" {
  source  = "memes/region-detail/google"
  version = "1.1.7"
  regions = local.regions
}


module "sa" {
  # TODO: @memes - pin version on release, still testing updates
  source       = "git::https://github.com/memes/terraform-google-private-gke-cluster//modules/sa?ref=feat%2fv3_refactor"
  project_id   = var.project_id
  name         = var.name
  description  = "Service account for F5 AI Solutions example GKE clusters"
  display_name = "F5 AI Solutions example cluster"
  repositories = [
    var.repository,
  ]
}

module "cluster" {
  for_each = { for i, region in local.regions : region => {
    name                = format("%s-%s", var.name, module.region_detail.results[region].abbreviation)
    subnet              = data.google_compute_subnetwork.subnets[region].self_link
    master_cidr         = cidrsubnet("192.168.0.0/24", 4, i)
    description         = format("Example application cluster for GKE Inference Gateway in %s", region)
    external_dns_domain = format("%s.%s", var.name, module.region_detail.results[region].abbreviation)
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
    gateway_api           = true
    managed_opentelemetry = true
  }
}

resource "google_project_iam_member" "deploy_gke" {
  for_each = { for sa in compact([var.cloud_deploy_service_account]) : sa => true }
  project  = var.project_id
  role     = "roles/container.developer"
  member   = format("serviceAccount:%s", each.key)
}

resource "google_clouddeploy_target" "cluster" {
  for_each = { for k, v in module.cluster : k => {
    name       = v.name
    cluster_id = v.id
    }
  }
  project          = var.project_id
  name             = each.value.name
  location         = var.deployment_pipeline_location
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

resource "google_compute_address" "pub" {
  for_each     = { for k, v in module.cluster : k => v.name }
  project      = var.project_id
  name         = format("%s-pub", each.value)
  description  = format("External IP for %s", each.value)
  address_type = "EXTERNAL"
  region       = each.key
}

resource "google_compute_address" "gw" {
  for_each     = { for k, v in module.cluster : k => v.name if k == "foo" } # TODO(@memes): Enable once access to NGINXaaS console resolved
  project      = var.project_id
  name         = format("%s-gw", each.value)
  description  = format("Internal IP for %s cluster Gateway", each.value)
  address_type = "INTERNAL"
  subnetwork   = data.google_compute_subnetwork.subnets[each.key]
  region       = each.key
}

resource "google_secret_manager_secret_iam_member" "nginx_jwt" {
  for_each = var.nginx_jwt_secret == null ? {} : { for ksa in try(var.nginx_jwt_secret.accessors, null) == null ? [] : var.nginx_jwt_secret.accessors : ksa => {
    name       = reverse(split("/", ksa))[0]
    namespace  = try(reverse(split("/", ksa))[1], "default")
    project_id = coalesce(try(reverse(split("/", var.nginx_jwt_secret.id))[2], null), var.project_id)
    secret_id  = reverse(split("/", var.nginx_jwt_secret.id))[0]
  } }
  project   = each.value.project_id
  secret_id = each.value.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = format("principal://iam.googleapis.com/projects/%s/locations/global/workloadIdentityPools/%s.svc.id.goog/subject/ns/%s/sa/%s", data.google_project.project.number, data.google_project.project.project_id, each.value.namespace, each.value.name)
}

resource "google_secret_manager_secret_iam_member" "hugging_face" {
  for_each = var.hugging_face_secret == null ? {} : { for ksa in try(var.hugging_face_secret.accessors, null) == null ? [] : var.hugging_face_secret.accessors : ksa => {
    name       = reverse(split("/", ksa))[0]
    namespace  = try(reverse(split("/", ksa))[1], "default")
    project_id = coalesce(try(reverse(split("/", coalesce(try(var.hugging_face_secret.id, null), data.terraform_remote_state.foundations.outputs.hugging_face_secret)))[2], null), var.project_id)
    secret_id  = reverse(split("/", coalesce(try(var.hugging_face_secret.id, null), data.terraform_remote_state.foundations.outputs.hugging_face_secret)))[0]
  } }
  project   = each.value.project_id
  secret_id = each.value.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = format("principal://iam.googleapis.com/projects/%s/locations/global/workloadIdentityPools/%s.svc.id.goog/subject/ns/%s/sa/%s", data.google_project.project.number, data.google_project.project.project_id, each.value.namespace, each.value.name)
}
