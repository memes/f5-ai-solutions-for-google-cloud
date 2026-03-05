variable "name" {
  type        = string
  nullable    = false
  description = <<-EOD
  The common name (and prefix) to use for Google Cloud and GitHub resources (see also `github_options`).
  EOD
}

variable "labels" {
  type        = map(string)
  nullable    = true
  default     = {}
  description = <<-EOD
  An optional set of key:value string pairs that will be added to Google Cloud resources that accept labels.
  Alternative: Set common labels in the `google` provider configuration.
  EOD
}

variable "project_id" {
  type        = string
  nullable    = false
  description = <<-EOD
  The Google Cloud project that will host resources.
  EOD
}

variable "github_options" {
  type = object({
    private_repo       = optional(bool, false)
    name               = optional(string)
    description        = optional(string)
    template           = optional(string)
    archive_on_destroy = optional(bool, true)
    collaborators      = optional(set(string))
  })
  nullable = true
  default = {
    private_repo       = false
    name               = ""
    description        = "Bootstrapped automation repository"
    template           = "memes/terraform-google-f5-demo-bootstrap-template"
    archive_on_destroy = true
    collaborators      = []
  }
  description = <<-EOD
  Defines the parameters for the GitHub repository to create for the demo. By default the GitHub repo will be public,
  named from the `name` variable and populated from `memes/terraform-google-f5-demo-bootstrap-template` repo. Use this
  variable to override one or more of these defaults as needed.
  EOD
}

variable "iac_impersonators" {
  type        = list(string)
  nullable    = true
  default     = []
  description = <<-EOD
  A list of fully-qualified IAM accounts that will be allowed to impersonate the IaC automation service account. If no
  accounts are supplied, impersonation will not be setup by the script.
  E.g.
  impersonators = [
    "group:devsecops@example.com",
    "group:admins@example.com",
    "user:jane@example.com",
    "serviceAccount:ci-cd@project.iam.gserviceaccount.com",
  ]
  EOD
}

variable "nginx_jwt" {
  type        = string
  nullable    = true
  default     = null
  description = <<-EOD
  An optional NGINX+ JWT to store in Google Secret Manager, with read-only access granted to AR service account.
  EOD
}

variable "f5_ai_license" {
  type        = string
  nullable    = true
  default     = null
  description = <<-EOD
  An optional NGINX+ JWT to store in Google Secret Manager, with read-only access granted to AR service account.
  EOD
}

variable "dns" {
  type = object({
    base_domain     = string
    managed_zone_id = optional(string)
  })
  nullable = true
  validation {
    condition     = var.dns == null ? true : can(regex("^(?:[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]\\.)+[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]\\.?$", var.dns.base_domain)) && (coalesce(var.dns.managed_zone_id, "unspecified") == "unspecified" ? true : can(regex("projects/[a-z][a-z0-9-]{4,28}[a-z0-9]/managedZones/[a-z][a-z0-9-]{0,61}[a-z0-9]?$", var.dns.managed_zone_id)))
    error_message = "The base_domain field of dns must be a valid DNS zone name, and, if provided, the Cloud DNS Managed Zone id must be valid."
  }
  default     = null
  description = <<-EOD
  If provided, these values will be added to the GitHub repo as variables that can be used in automation actions. The
  `base_domain` field sets the root for TLS certificate creation and DNS challenges and is required if this variable is
  not null. The `managed_zone_id` value containing a Cloud DNS Managed Zone identifier can be provided to have the DNS
  challenge and reserved IP addresses added automatically.
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
  An optional list of CIDRs to be passed to Infra Manager and Cloud Deploy invocations. E.g. the foundations module will
  create a Cloud Armor policy blocking access unless this variable contains an allow list.
  EOD
}
