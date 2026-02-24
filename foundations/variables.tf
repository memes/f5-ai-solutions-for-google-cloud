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

variable "allowlist_cidrs" {
  type     = list(string)
  nullable = true
  validation {
    condition     = var.allowlist_cidrs == null ? true : alltrue([for cidr in var.allowlist_cidrs : can(cidrhost(cidr, 0))])
    error_message = "Each allowlist_cidrs entry mus be a valid IPv4 or IPv6 cidr."
  }
  default     = null
  description = <<-EOD
  An optional list of CIDRs to be included in source lists. If empty (default) or blank, the module will use the public
  IP address obtained from a third-party lookup service.
  EOD
}

variable "regions" {
  type     = list(string)
  nullable = false
  validation {
    condition     = length(var.regions) > 0 && alltrue([for region in var.regions : can(regex("^[a-z]{2,}-[a-z]{2,}[0-9]$", region))])
    error_message = "There must be at least one value in regions, and each entry must be a valid Google Cloud region name."
  }
  default     = ["us-central1"]
  description = <<-EOD
  The Compute Engine regions in which to create resources. Default is the single region 'us-central1'.
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

variable "f5_ai_license" {
  type        = string
  nullable    = true
  default     = null
  description = <<-EOD
  An optional F5 AI Guardrails/Red team license to store in Google Secret Manager. No access will be granted here.
  EOD
}

variable "hugging_face_token" {
  type        = string
  nullable    = true
  default     = null
  description = <<-EOD
  An optional Hugging Face token with access to Llama-3.1-8B-Instruct model to store in Google Secret Manager. No access
  will be granted here.
  EOD
}

variable "global_cidrs" {
  type = object({
    primary  = optional(string)
    pods     = optional(string)
    services = optional(string)
    proxy    = optional(string)
    psc      = optional(string)
  })
  nullable = true
  default  = null
}

variable "domain_name" {
  type     = string
  nullable = false
  default  = "strangelambda.com"
}

variable "nat_tags" {
  type     = list(string)
  nullable = true
  default  = null
}
