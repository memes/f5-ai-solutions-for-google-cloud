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

variable "gcp_options" {
  type = object({
    enable_infra_manager        = optional(bool, true)
    enable_cloud_deploy         = optional(bool, true)
    services_disable_on_destroy = optional(bool, false)
    disable_dependent_services  = optional(bool, false)
    bucket = optional(object({
      class          = string
      location       = string
      force_destroy  = bool
      uniform_access = bool
      versioning     = bool
    }))
    ar = optional(object({
      location = string
      oci      = bool
      deb      = bool
      rpm      = bool
    }))
    kms = optional(bool, false)
  })
  nullable = true
  default = {
    enable_infra_manager        = true
    enable_cloud_deploy         = true
    services_disable_on_destroy = false
    disable_dependent_services  = false
    bucket = {
      class          = "STANDARD"
      location       = "US"
      force_destroy  = true
      uniform_access = true
      versioning     = true
    }
    ar = {
      location = "us"
      oci      = true
      deb      = false
      rpm      = false
    }
    kms = false
  }
  description = <<-EOD
  Defines the parameters for the supporting Google Cloud resources that may not be essential to the demo. By default
  service accounts and resources to support Infrastructure Manager (managed Terraform IaC) and Cloud Deploy (managed GKE
  and Cloud Run deployments) are created, along with a US Cloud Storage bucket to contain the Terraform state. An
  Artifact Repository will be created for OCI containers, but not DEB or RPM repos. Use this variable to override one or
  more of these defaults as needed.
  EOD
}

variable "bootstrap_apis" {
  type        = set(string)
  nullable    = false
  default     = []
  description = <<-EOD
  An optional set of Google Cloud APIs to enable during bootstrap, in addition
  to those required for bootstrap resources. Default is an empty set.
  EOD
}

variable "iac_roles" {
  type        = set(string)
  nullable    = false
  default     = []
  description = <<-EOD
  An optional set of IAM roles to assign to the IaC automation service account.
  Default is an empty set.
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
