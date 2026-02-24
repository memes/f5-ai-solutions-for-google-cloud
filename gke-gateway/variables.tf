variable "project_id" {
  type     = string
  nullable = false
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "The project_id value must be a valid Google Cloud project identifier"
  }
  description = <<-EOD
  The Google Cloud project identifier that will contain the resources.
  EOD
}

variable "name" {
  type     = string
  nullable = false
  validation {
    # The generated service account names has a limit of 30 characters, including
    # the '-bot' suffix. Validate that var.name is 1 <= length(var.name) <=26.
    condition     = can(regex("^[a-z][a-z0-9-]{0,24}[a-z0-9]$", var.name))
    error_message = "The name variable must be RFC1035 compliant and between 1 and 26 characters in length."
  }
  description = <<-EOD
  The common name to use for resources.
  EOD
}

variable "labels" {
  type     = map(string)
  nullable = true
  validation {
    # GCP resource labels must be lowercase alphanumeric, underscore or hyphen,
    # and the key must be <= 63 characters in length
    condition     = var.labels == null ? true : alltrue([for k, v in var.labels : can(regex("^[a-z][a-z0-9_-]{0,62}$", k)) && can(regex("^[a-z0-9_-]{0,63}$", v))])
    error_message = "Each label key:value pair must match expectations."
  }
  default     = {}
  description = <<-EOD
  An optional map of key:value labels to apply to the resources. Default value is an empty map.
  EOD
}

variable "nginx_jwt_secret" {
  type = object({
    id        = string
    accessors = optional(list(string))
  })
  nullable = true
  validation {
    condition     = var.nginx_jwt_secret == null ? true : can(regex("projects/[a-z][a-z0-9-]{4,28}[a-z0-9]/secrets/[a-zA-Z0-9_-]{1,255}$", var.nginx_jwt_secret.id)) && (try(length(var.nginx_jwt_secret.accessors), 0) == 0 ? true : alltrue([for accessor in var.nginx_jwt_secret.accessors : can(regex("^(?:[a-z](?:[a-z0-9-]{0,61}[a-z0-9])?/)?[a-z](?:[a-z0-9-]{0,61}[a-z0-9])?$", accessor))]))
    error_message = "The nginx_jwt_secret id field must be a valid Secret Manager self-link or name."
  }
  default     = null
  description = <<-EOD
  An optional Secret Manager secret containing an NGINX+ JWT token, with an optional list of Kubernetes service
  accounts to which read-only access will be granted. Each reader must be a valid KSA name in default namespace, or
  a qualified namespace/name.
  EOD
}


variable "repository" {
  type     = string
  nullable = false
  validation {
    condition     = can(regex("^[a-z]{2,}(?:-[a-z]+[1-9])?-docker.pkg.dev/[^/]+/[^/]+", var.repository))
    error_message = "Repository must be a valid Artifact Registry repository."
  }
  description = <<-EOD
  The private Artifact Registry that will be used for deployments.
  EOD
}

variable "cloud_deploy_service_account" {
  type     = string
  nullable = true
  validation {
    condition     = can(regex("(?:[a-z][a-z0-9-]{4,28}[a-z0-9]@[a-z][a-z0-9-]{4,28}\\.iam|[1-9][0-9]+-compute@developer)\\.gserviceaccount\\.com$", var.cloud_deploy_service_account))
    error_message = "The cloud_deploy_service_account variable must be a valid GCP service account email address."
  }
  default     = null
  description = <<-EOD
  Optional Cloud Deploy execution service account that will deploy resources to GKE.
  EOD
}

variable "deployment_pipeline_location" {
  type     = string
  nullable = false
  validation {
    condition     = can(regex("^[a-z]{2,}-[a-z]{2,}[0-9]$", var.deployment_pipeline_location))
    error_message = "The deployment_pipeline_location variable must be a valid Google Cloud region name."
  }
  default     = "us-central1"
  description = <<-EOD
  The Compute Engine regions in which to create resources. Default is the single region 'us-central1'.
  EOD
}

variable "hugging_face_secret" {
  type = object({
    id        = optional(string)
    accessors = optional(list(string))
  })
  nullable = true
  validation {
    condition     = var.hugging_face_secret == null ? true : (coalesce(try(var.hugging_face_secret.secret_id, null), "unspecified") == "unspecified" ? true : can(regex("projects/[a-z][a-z0-9-]{4,28}[a-z0-9]/secrets/[a-zA-Z0-9_-]{1,255}$", var.hugging_face_secret.id))) && (try(length(var.hugging_face_secret.accessors), 0) == 0 ? true : alltrue([for accessor in var.hugging_face_secret.accessors : can(regex("^(?:[a-z](?:[a-z0-9-]{0,61}[a-z0-9])?/)?[a-z](?:[a-z0-9-]{0,61}[a-z0-9])?$", accessor))]))
    error_message = "If provided, the hugging_face_secret id field must be a valid Secret Manager self-link or name."
  }
  default     = null
  description = <<-EOD
  An optional Secret Manager secret containing a Hugging Face token, with an optional list of Kubernetes service
  accounts to which read-only access will be granted. Each reader must be a valid KSA name in default namespace, or
  a qualified namespace/name.
  EOD
}

variable "pg_admin_accessors" {
  type     = list(string)
  nullable = true
  validation {
    condition     = var.pg_admin_accessors == null ? true : alltrue([for accessor in var.pg_admin_accessors : can(regex("^(?:[a-z](?:[a-z0-9-]{0,61}[a-z0-9])?/)?[a-z](?:[a-z0-9-]{0,61}[a-z0-9])?$", accessor))])
    error_message = "If provided, each pg_admin_accessors value must be a valid Kubernetes service account"
  }
  default = [
    "shared-services/pg-admin",
  ]
  description = <<-EOD
  An optional list of Kubernetes service accounts to which read-only access will be granted. Each reader must be a valid
  KSA name in default namespace, or a qualified namespace/name.
  EOD
}
