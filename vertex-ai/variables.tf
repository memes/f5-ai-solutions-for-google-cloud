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
  The common name to use as-is, or as a prefix with an abbreviated region name, for resources created by this module.
  E.g. if `name = "ai-demo"`, global resources will be named "ai-demo" (or have a name prefix of "ai-demo-XXX"), and
  regional resources will be named "ai-demo-xx-xxN" (or prefixed with "ai-demo-xx-xxN-") where xx-xxN is an abbreviation
  of the region name.
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
  NOTE: The effective set of labels will include some fixed values in addition to these.
  EOD
}

variable "subnets" {
  type     = map(string)
  nullable = true
  validation {
    condition     = var.subnets == null ? true : alltrue([for k, v in var.subnets : can(regex("^(?:https://www.googleapis.com/compute/v1/)?projects/[a-z][a-z0-9-]{4,28}[a-z0-9]/regions/[a-z]{2,}-[a-z]{2,}[0-9]/subnetworks/[a-z]([a-z0-9-]+[a-z0-9])?$", v))])
    error_message = "Each subnets entry must be a valid Compute Engine region and subnetwork self-link."
  }
  default     = null
  description = <<-EOD
  A map of Compute Engine region names to subnetwork self-links for which Vertex AI models will be provisioned.
  EOD
}

variable "publisher_models" {
  type     = list(string)
  nullable = true
  validation {
    condition     = var.publisher_models == null ? true : alltrue([for model in var.publisher_models : can(regex("^publishers/[^/]+/models/[^/]+$", model))])
    error_message = "Each publisher_models entry must be a valid Model Garden name."
  }
  default = [
    "publishers/google/models/gemma3@gemma-3-4b-it",
  ]
  description = <<-EOD
  A list of Model Garden models to provision on Vertex AI.
  EOD
}
