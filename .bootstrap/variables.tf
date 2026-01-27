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
