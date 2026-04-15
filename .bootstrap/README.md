# Bootstrap

This module created the GitHub repository hosting this source, enabled required Google Cloud APIs, and created basic
IAM, service account and workload identity for the running of this demo.

Redacted `terraform.tfvars` file that bootstrapped the current repo:

```hcl
# The name (or prefix) used for bootstrapped resources; should be unique within a Google Cloud project.
name = "ai-demo"

# The Google Cloud project that resources will be created in.
project_id = "TARGET_GCP_PROJECT"

# An effective demo needs published DNS endpoints; this value sets the base DNS zone to use for all created endpoints.
# E.g. this value will create a demo expecting application traffic to be exposed at `arcadia.example.com`, and the F5 AI
# Guardrails and/or Red Team console at `f5-ai.example.com`.
dns = {
  base_domain     = "example.com"
  managed_zone_id = "Cloud DNS Managed Zone identifier for above domain, or null/empty"
}

# Optional list of CIDRs to use in policies that restrict access to the *deployed* applications. This will be the
# initial value set in the GitHub variable "ALLOWLIST_CIDRS" sourced by Infra Manager actions.
# Recommendation is to set to explicit CIDRs as needed for limited access testing, then update in GitHub console to
# `["0.0.0.0/0"]`.
allowlist_cidrs = [
    "0.0.0.0/0",
]

# Optional labels to apply to Google Cloud resources.
labels = {
  owner = "emes"
  email = "m_dot_emes_at_f5_dot_com"
}

# Optional list of Google Cloud users, groups, or service accounts that will be permitted to impersonate the IaC service
# account.
iac_impersonators = [
  "user:person@example.com",
  "group:group-list@example.com",
]

# Options used to override the defaults when creating the GitHub repo for this demo. Mostly used when the repo name
# should be different than the name used for resource creation above.
github_options = {
  name        = "f5-ai-solutions-for-google-cloud"
  description = "Integration demo for F5 AI Guardrails and F5 AI Red-Team with NGINXaaS for Google Cloud."
  collaborators = [
    "memes-bot",
  ]
}

# These two are optional; if not empty a Secret Manager secret for each will be created in the project above and a
# GitHub variable will be populated with the identifier of the secret.
nginx_jwt     = "JWT Token associated with your NGINX+ subscription"
f5_ai_license = "License key associated with your F5 AI Guardrails and/or Red Team subscription"
```

<!-- markdownlint-disable MD033 MD034 MD060 -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5 |
| <a name="requirement_github"></a> [github](#requirement\_github) | >= 6.10 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 7.16 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.6 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_bootstrap"></a> [bootstrap](#module\_bootstrap) | registry.terraform.io/memes/f5-demo-bootstrap/google | 0.5.1 |
| <a name="module_f5_ai_license"></a> [f5\_ai\_license](#module\_f5\_ai\_license) | memes/secret-manager/google | 2.2.2 |
| <a name="module_nginxaas_combined_pem"></a> [nginxaas\_combined\_pem](#module\_nginxaas\_combined\_pem) | memes/secret-manager/google | 2.2.2 |

## Resources

| Name | Type |
|------|------|
| [github_actions_variable.allowlist_cidrs](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_variable) | resource |
| [github_actions_variable.dns](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_variable) | resource |
| [github_actions_variable.f5_ai_license](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_variable) | resource |
| [github_actions_variable.model_cache_bucket](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_variable) | resource |
| [github_actions_variable.nginxaas_combined_pem_secrets](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_variable) | resource |
| [google_storage_bucket.model_cache](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name"></a> [name](#input\_name) | The common name (and prefix) to use for Google Cloud and GitHub resources (see also `github_options`). | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The Google Cloud project that will host resources. | `string` | n/a | yes |
| <a name="input_allowlist_cidrs"></a> [allowlist\_cidrs](#input\_allowlist\_cidrs) | An optional list of CIDRs to be passed to Infra Manager and Cloud Deploy invocations. E.g. the foundations module will<br/>create a Cloud Armor policy blocking access unless this variable contains an allow list. | `list(string)` | `null` | no |
| <a name="input_dns"></a> [dns](#input\_dns) | If provided, these values will be added to the GitHub repo as variables that can be used in automation actions. The<br/>`base_domain` field sets the root for TLS certificate creation and DNS challenges and is required if this variable is<br/>not null. The `managed_zone_id` value containing a Cloud DNS Managed Zone identifier can be provided to have the DNS<br/>challenge and reserved IP addresses added automatically. | <pre>object({<br/>    base_domain     = string<br/>    managed_zone_id = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_f5_ai_license"></a> [f5\_ai\_license](#input\_f5\_ai\_license) | An optional NGINX+ JWT to store in Google Secret Manager, with read-only access granted to AR service account. | `string` | `null` | no |
| <a name="input_github_options"></a> [github\_options](#input\_github\_options) | Defines the parameters for the GitHub repository to create for the demo. By default the GitHub repo will be public,<br/>named from the `name` variable and populated from `memes/terraform-google-f5-demo-bootstrap-template` repo. Use this<br/>variable to override one or more of these defaults as needed. | <pre>object({<br/>    private_repo       = optional(bool, false)<br/>    name               = optional(string)<br/>    description        = optional(string)<br/>    template           = optional(string)<br/>    archive_on_destroy = optional(bool, true)<br/>    collaborators      = optional(set(string))<br/>  })</pre> | <pre>{<br/>  "archive_on_destroy": true,<br/>  "collaborators": [],<br/>  "description": "Bootstrapped automation repository",<br/>  "name": "",<br/>  "private_repo": false,<br/>  "template": "memes/terraform-google-f5-demo-bootstrap-template"<br/>}</pre> | no |
| <a name="input_iac_impersonators"></a> [iac\_impersonators](#input\_iac\_impersonators) | A list of fully-qualified IAM accounts that will be allowed to impersonate the IaC automation service account. If no<br/>accounts are supplied, impersonation will not be setup by the script.<br/>E.g.<br/>impersonators = [<br/>  "group:devsecops@example.com",<br/>  "group:admins@example.com",<br/>  "user:jane@example.com",<br/>  "serviceAccount:ci-cd@project.iam.gserviceaccount.com",<br/>] | `list(string)` | `[]` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | An optional set of key:value string pairs that will be added to Google Cloud resources that accept labels.<br/>Alternative: Set common labels in the `google` provider configuration. | `map(string)` | `{}` | no |
| <a name="input_nginx_jwt"></a> [nginx\_jwt](#input\_nginx\_jwt) | An optional NGINX+ JWT to store in Google Secret Manager, with read-only access granted to AR service account. | `string` | `null` | no |
| <a name="input_nginxaas_combined_pems"></a> [nginxaas\_combined\_pems](#input\_nginxaas\_combined\_pems) | An optional map of names to combined TLS certificate and key PEMs to add to Google Secret Manager. | `map(string)` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ar_repo"></a> [ar\_repo](#output\_ar\_repo) | The Artifact Registry created for OCI artifacts. |
| <a name="output_cloud_deploy_sa"></a> [cloud\_deploy\_sa](#output\_cloud\_deploy\_sa) | The fully-qualified email address of the Cloud Deploy execution service account. |
| <a name="output_f5_ai_license"></a> [f5\_ai\_license](#output\_f5\_ai\_license) | If an F5 AI Guardrails/Red Team secret was created during bootstrap, return the fully-qualified and local identifiers,<br/>and expiration timestamp, if appropriate. |
| <a name="output_model_cache_bucket"></a> [model\_cache\_bucket](#output\_model\_cache\_bucket) | The Google Cloud Storage bucket names to be used for model caching. |
| <a name="output_nginx_jwt"></a> [nginx\_jwt](#output\_nginx\_jwt) | If an NGINX JWT secret was created during bootstrap, return the fully-qualified and local identifiers, and expiration<br/>timestamp, if appropriate. |
| <a name="output_nginxaas_combined_pems"></a> [nginxaas\_combined\_pems](#output\_nginxaas\_combined\_pems) | n/a |
<!-- END_TF_DOCS -->
<!-- markdownlint-enable MD033 MD034 MD060 -->
