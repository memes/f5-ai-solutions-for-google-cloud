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
  The Compute Engine region names in which to create resources. Default is the single region 'us-central1'.
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

variable "hugging_face" {
  type = object({
    token     = string
    accessors = optional(list(string))
  })
  nullable = true
  validation {
    condition     = var.hugging_face == null ? true : coalesce(var.hugging_face.token, "unspecified") != "unspecified" && (try(length(var.hugging_face.accessors), 0) == 0 ? true : alltrue([for accessor in var.hugging_face.accessors : can(regex("^(?:[a-z](?:[a-z0-9-]{0,61}[a-z0-9])?/)?[a-z](?:[a-z0-9-]{0,61}[a-z0-9])?$", accessor))]))
    error_message = "If set, the hugging_face token field must not be empty, and each accessor must be a valid Kubernetes service account."
  }
  default     = null
  description = <<-EOD
  An optional Hugging Face token with access to models to store in Google Secret Manager. Each accessor must be a valid
  KSA name in default namespace, or a qualified namespace/name. Default is empty, because access to Hugging Face should
  not be required by deployments.
  EOD
}

variable "global_cidrs" {
  type = object({
    primary  = optional(string)
    pods     = optional(string)
    services = optional(string)
    peering  = optional(string)
    psc      = optional(string)
  })
  nullable = true
  validation {
    condition = var.global_cidrs == null ? true : (
      var.global_cidrs.primary == null ? true : can(cidrhost(var.global_cidrs.primary, 1))
      ) && (
      var.global_cidrs.pods == null ? true : can(cidrhost(var.global_cidrs.pods, 1))
      ) && (
      var.global_cidrs.services == null ? true : can(cidrhost(var.global_cidrs.services, 1))
      ) && (
      var.global_cidrs.peering == null ? true : can(cidrhost(var.global_cidrs.peering, 1))
      ) && (
      var.global_cidrs.psc == null ? true : can(cidrhost(var.global_cidrs.psc, 1))
    )
    error_message = "If any global_cidrs fields are provided they must be valid CIDRs."
  }
  default     = null
  description = <<-EOD
  An optional set of CIDRs to use for primary IP allocation, pods, etc. If null or empty, the default, then a fixed set
  of values will be used by the module.
  EOD
}

variable "dns" {
  type = object({
    base_domain     = string
    managed_zone_id = optional(string)
  })
  nullable = false
  validation {
    condition     = can(regex("^(?:[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]\\.)+[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]\\.?$", var.dns.base_domain)) && (coalesce(var.dns.managed_zone_id, "unspecified") == "unspecified" ? true : can(regex("projects/[a-z][a-z0-9-]{4,28}[a-z0-9]/managedZones/[a-z][a-z0-9-]{0,61}[a-z0-9]?$", var.dns.managed_zone_id)))
    error_message = "The base_domain field of dns must be a valid DNS zone name, and, if provided, the Cloud DNS Managed Zone id must be valid."
  }
  description = <<-EOD
  The `base_domain` sets the root for TLS certificate creation and DNS challenges, and is required. An optional
  `managed_zone_id` value containing a Cloud DNS Managed Zone identifier can be provided to have the DNS challenge and
  reserved IP addresses added automatically - if the executor of this module has rights to modify that zone.
  EOD
}

variable "nat_tags" {
  type        = list(string)
  nullable    = true
  default     = null
  description = <<-EOD
  An optional list of Compute Engine tags that will be permitted to NAT to public internet through Cloud NAT. Default is
  empty.
  NOTE: The intent of this demo is to show F5 AI solutions in an isolated environment without access to the internet so
  setting this value invalidates that assumption.
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
  An existing Secret Manager secret containing an NGINX+ JWT token, with an optional list of Kubernetes service
  accounts to which read-only access will be granted. Each accessor must be a valid KSA name in default namespace, or
  a qualified namespace/name. Default is empty.
  EOD
}

variable "f5_ai_license_secret" {
  type     = string
  nullable = true
  validation {
    condition     = var.f5_ai_license_secret == null ? true : can(regex("projects/[a-z][a-z0-9-]{4,28}[a-z0-9]/secrets/[a-zA-Z0-9_-]{1,255}$", var.f5_ai_license_secret))
    error_message = "The f5_ai_license_secret must be a valid Secret Manager self-link or name."
  }
  default     = null
  description = <<-EOD
  An existing Secret Manager secret containing an F5 AI Guardrails/Red Team license token; appropriate secrets for F5 AI
  Guardrails/Red Team deployments will be created if this value is not empty or null(default).
  EOD
}

variable "cai_moderator_auth_accessors" {
  type     = list(string)
  nullable = true
  validation {
    condition     = var.cai_moderator_auth_accessors == null ? true : alltrue([for accessor in var.cai_moderator_auth_accessors : can(regex("^(?:[a-z](?:[a-z0-9-]{0,61}[a-z0-9])?/)?[a-z](?:[a-z0-9-]{0,61}[a-z0-9])?$", accessor))])
    error_message = "If provided, each cai_moderator_auth_accessors value must be a valid Kubernetes service account"
  }
  default = [
    "f5-ai-moderator/cai-moderator-sa",
  ]
  description = <<-EOD
  An optional list of Kubernetes service accounts to which read-only access will be granted to the `cai-moderator-auth`
  secret. Each reader must be a valid KSA name in default namespace, or a qualified namespace/name. The default allows
  Kubernetes service account `cai-moderator-sa` in namespace `f5-ai-moderator` to read the secret value.
  EOD
}

variable "prefect_server_auth_accessors" {
  type     = list(string)
  nullable = true
  validation {
    condition     = var.prefect_server_auth_accessors == null ? true : alltrue([for accessor in var.prefect_server_auth_accessors : can(regex("^(?:[a-z](?:[a-z0-9-]{0,61}[a-z0-9])?/)?[a-z](?:[a-z0-9-]{0,61}[a-z0-9])?$", accessor))])
    error_message = "If provided, each prefect_server_auth_accessors value must be a valid Kubernetes service account"
  }
  default = [
    "f5-ai-redteam/prefect-server",
  ]
  description = <<-EOD
  An optional list of Kubernetes service accounts to which read-only access will be granted to the `cai-moderator-auth`
  secret. Each reader must be a valid KSA name in default namespace, or a qualified namespace/name. The default allows
  Kubernetes service account `prefect-server` in namespace `f5-ai-redteam` to read the secret value.
  EOD
}

variable "cai_workflows_auth_accessors" {
  type     = list(string)
  nullable = true
  validation {
    condition     = var.cai_workflows_auth_accessors == null ? true : alltrue([for accessor in var.cai_workflows_auth_accessors : can(regex("^(?:[a-z](?:[a-z0-9-]{0,61}[a-z0-9])?/)?[a-z](?:[a-z0-9-]{0,61}[a-z0-9])?$", accessor))])
    error_message = "If provided, each cai_workflows_auth_accessors value must be a valid Kubernetes service account"
  }
  default = [
    "f5-ai-redteam/default",
  ]
  description = <<-EOD
  An optional list of Kubernetes service accounts to which read-only access will be granted to the `cai-moderator-auth`
  secret. Each reader must be a valid KSA name in default namespace, or a qualified namespace/name. The default allows
  Kubernetes service account `default` in namespace `f5-ai-redteam` to read the secret value.
  EOD
}

variable "pgpass_accessors" {
  type     = list(string)
  nullable = true
  validation {
    condition     = var.pgpass_accessors == null ? true : alltrue([for accessor in var.pgpass_accessors : can(regex("^(?:[a-z](?:[a-z0-9-]{0,61}[a-z0-9])?/)?[a-z](?:[a-z0-9-]{0,61}[a-z0-9])?$", accessor))])
    error_message = "If provided, each pgpass_accessors value must be a valid Kubernetes service account"
  }
  default = [
    "shared-services/pg-admin",
  ]
  description = <<-EOD
  An optional list of Kubernetes service accounts to which read-only access will be granted. Each reader must be a valid
  KSA name in default namespace, or a qualified namespace/name. The default allows Kubernetes service account `pg-admin`
  in namespace `shared-services` to read the secret value.
  EOD
}

variable "model_cache_bucket" {
  type = object({
    name      = string
    accessors = optional(list(string))
  })
  nullable = true
  validation {
    condition     = var.model_cache_bucket == null ? true : can(regex("^[a-z][a-z0-9-_]{2,62}$", var.model_cache_bucket.name)) && (try(length(var.model_cache_bucket.accessors), 0) == 0 ? true : alltrue([for accessor in var.model_cache_bucket.accessors : can(regex("^(?:[a-z](?:[a-z0-9-]{0,61}[a-z0-9])?/)?[a-z](?:[a-z0-9-]{0,61}[a-z0-9])?$", accessor))]))
    error_message = "The model_cache_bucket name field must be a valid GCS Bucket name."
  }
  default     = null
  description = <<-EOD
  An optional list of Kubernetes service accounts to which read-only access will be granted to objects in the bucket.
  Each reader must be a valid KSA name in default namespace, or a qualified namespace/name. If none are provided the
  module will grant access to Kubernetes service account `vllm` in namespace `vllm` to read the bucket contents.
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
  An existing private Artifact Registry that will be used for deployments. The service account for the clusters will be
  given automatic IAM role to pull from this registry if it is not empty.
  EOD
}

# tflint-ignore: terraform_unused_declarations # TODO(@memes): This will be used when pipelines are ready
variable "cloud_deploy_service_account" {
  type     = string
  nullable = true
  validation {
    condition     = coalesce(var.cloud_deploy_service_account, "unspecified") == "unspecified" ? true : can(regex("(?:[a-z][a-z0-9-]{4,28}[a-z0-9]@[a-z][a-z0-9-]{4,28}\\.iam|[1-9][0-9]+-compute@developer)\\.gserviceaccount\\.com$", var.cloud_deploy_service_account))
    error_message = "The cloud_deploy_service_account variable must be a valid GCP service account email address."
  }
  default     = null
  description = <<-EOD
  An optional Cloud Deploy execution service account that will deploy resources to GKE. If null or empty, Cloud Deploy
  pipelines will not be created.
  EOD
}

variable "workload_identity_pool_id" {
  type     = string
  nullable = true
  default  = null
  validation {
    condition     = coalesce(var.workload_identity_pool_id, "unspecified") == "unspecified" ? true : can(regex("^projects/[a-z][a-z0-9-]{4,28}[a-z0-9]/locations/global/workloadIdentityPools/[a-z0-9-]{4,32}$", var.workload_identity_pool_id))
    error_message = "The workload_identity_pool_id must be empty or a valid Workload Identity name or id."
  }
  description = <<-EOD
    An optional identifier of an *existing* Workload Identity pool to which a new provider for NGINXaaS will be created.
    EOD
}

variable "nginxaas" {
  type = object({
    attachments      = map(string)
    secrets          = optional(set(string))
    service_accounts = optional(set(string))
  })
  nullable = true
  validation {
    condition = var.nginxaas == null ? true : (
      var.nginxaas.attachments == null ? true :
      alltrue([
        for k, v in var.nginxaas.attachments :
        can(regex("^[a-z]{2,}-[a-z]{2,}[0-9]$", k)) &&
        coalesce(v.service_attachment, "unspecified") == "unspecified" ? true : can(regex("^(?:https://www.googleapis.com/compute/v1/)?projects/[a-z][a-z0-9-]{4,28}[a-z0-9]/regions/[a-z]{2,}-[a-z]{2,}[0-9]/serviceAttachments/[a-z][a-z0-9-]{0,62}[a-z0-9]$", v.service_attachment))
      ])) && (
      var.nginxaas.secrets == null ? true :
      alltrue([for secret in var.nginxaas.secrets : can(regex("projects/[a-z][a-z0-9-]{4,28}[a-z0-9]/secrets/[a-zA-Z0-9_-]{1,255}$", secret))])
      ) && (
      var.nginxaas.service_accounts == null ? true :
      alltrue([for service_account in var.nginxaas.service_accounts : can(regex("^[1-9][0-9]+$", service_account))])
    )
    error_message = "Each attachments key must be a valid name, and the value must be a valid subnet self-link, Any secrets and service_accounts entries must be valid."
  }
  default     = null
  description = <<-EOD
  If not null, the properties will be used to attach NGINXaaS for Google Cloud. If null, resources to support Google
  managed load balancers and certificates will be provisioned.
  EOD
}
