# Foundations

This module establishes the foundational Google Cloud resources used by clusters and their deployments.

<!-- markdownlint-disable MD033 MD034 MD060 -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 7.16 |
| <a name="requirement_http"></a> [http](#requirement\_http) | >= 3.5 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.8 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cluster"></a> [cluster](#module\_cluster) | git::https://github.com/memes/terraform-google-private-gke-cluster//modules/autopilot | feat%2fv3_refactor |
| <a name="module_googleapis-dns"></a> [googleapis-dns](#module\_googleapis-dns) | memes/restricted-apis-dns/google | 2.0.1 |
| <a name="module_managed_cert"></a> [managed\_cert](#module\_managed\_cert) | registry.terraform.io/memes/tls-certificate/google//modules/managed | 0.1.1 |
| <a name="module_region_detail"></a> [region\_detail](#module\_region\_detail) | memes/region-detail/google | 1.1.7 |
| <a name="module_sa"></a> [sa](#module\_sa) | git::https://github.com/memes/terraform-google-private-gke-cluster//modules/sa | feat%2fv3_refactor |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | memes/multi-region-private-network/google | 5.2.0 |

## Resources

| Name | Type |
|------|------|
| [google_clouddeploy_target.cluster](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/clouddeploy_target) | resource |
| [google_compute_address.ext](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_address) | resource |
| [google_compute_address.pg](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_address) | resource |
| [google_compute_forwarding_rule.pg](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_forwarding_rule) | resource |
| [google_compute_global_address.cache](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_global_address) | resource |
| [google_compute_region_security_policy.allowlist](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_security_policy) | resource |
| [google_compute_subnetwork.proxy_subnet](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) | resource |
| [google_dns_managed_zone.pg](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dns_managed_zone) | resource |
| [google_dns_record_set.challenges](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dns_record_set) | resource |
| [google_dns_record_set.ext](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dns_record_set) | resource |
| [google_dns_record_set.pg](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dns_record_set) | resource |
| [google_redis_instance.cache](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/redis_instance) | resource |
| [google_secret_manager_secret.cai_moderator_auth](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret) | resource |
| [google_secret_manager_secret.cai_workflows_auth](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret) | resource |
| [google_secret_manager_secret.hugging_face](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret) | resource |
| [google_secret_manager_secret.pgpass](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret) | resource |
| [google_secret_manager_secret.prefect_server_auth](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret) | resource |
| [google_secret_manager_secret_iam_member.cai_moderator_auth](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_iam_member) | resource |
| [google_secret_manager_secret_iam_member.cai_workflows_auth](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_iam_member) | resource |
| [google_secret_manager_secret_iam_member.hugging_face](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_iam_member) | resource |
| [google_secret_manager_secret_iam_member.nginx_jwt](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_iam_member) | resource |
| [google_secret_manager_secret_iam_member.pgpass](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_iam_member) | resource |
| [google_secret_manager_secret_iam_member.prefect_server_auth](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_iam_member) | resource |
| [google_secret_manager_secret_version.cai_moderator_auth](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_version) | resource |
| [google_secret_manager_secret_version.cai_workflows_auth](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_version) | resource |
| [google_secret_manager_secret_version.hugging_face](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_version) | resource |
| [google_secret_manager_secret_version.pgpass](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_version) | resource |
| [google_secret_manager_secret_version.prefect_server_auth](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_version) | resource |
| [google_service_networking_connection.cache](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_networking_connection) | resource |
| [google_sql_database_instance.pg](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_database_instance) | resource |
| [google_sql_user.pg_admin](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_user) | resource |
| [google_storage_bucket_iam_member.bucket](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam_member) | resource |
| [random_password.pg_admin](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [google_compute_zones.zones](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_zones) | data source |
| [google_project.project](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/project) | data source |
| [google_secret_manager_secret_version_access.f5_ai_license](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/secret_manager_secret_version_access) | data source |
| [http_http.my_address](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_dns"></a> [dns](#input\_dns) | The `base_domain` sets the root for TLS certificate creation and DNS challenges, and is required. An optional<br/>`managed_zone_id` value containing a Cloud DNS Managed Zone identifier can be provided to have the DNS challenge and<br/>reserved IP addresses added automatically - if the executor of this module has rights to modify that zone. | <pre>object({<br/>    base_domain     = string<br/>    managed_zone_id = optional(string)<br/>  })</pre> | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | The common name to use as-is, or as a prefix with an abbreviated region name, for resources created by this module.<br/>E.g. if `name = "ai-demo"`, global resources will be named "ai-demo" (or have a name prefix of "ai-demo-XXX"), and<br/>regional resources will be named "ai-demo-xx-xxN" (or prefixed with "ai-demo-xx-xxN-") where xx-xxN is an abbreviation<br/>of the region name. | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The Google Cloud project identifier that will contain the resources. | `string` | n/a | yes |
| <a name="input_repository"></a> [repository](#input\_repository) | An existing private Artifact Registry that will be used for deployments. The service account for the clusters will be<br/>given automatic IAM role to pull from this registry if it is not empty. | `string` | n/a | yes |
| <a name="input_allowlist_cidrs"></a> [allowlist\_cidrs](#input\_allowlist\_cidrs) | An optional list of CIDRs to be included in source lists. If empty (default) or blank, the module will use the public<br/>IP address obtained from a third-party lookup service. | `list(string)` | `null` | no |
| <a name="input_cai_moderator_auth_accessors"></a> [cai\_moderator\_auth\_accessors](#input\_cai\_moderator\_auth\_accessors) | An optional list of Kubernetes service accounts to which read-only access will be granted to the `cai-moderator-auth`<br/>secret. Each reader must be a valid KSA name in default namespace, or a qualified namespace/name. The default allows<br/>Kubernetes service account `cai-moderator-sa` in namespace `f5-ai-moderator` to read the secret value. | `list(string)` | <pre>[<br/>  "f5-ai-moderator/cai-moderator-sa"<br/>]</pre> | no |
| <a name="input_cai_workflows_auth_accessors"></a> [cai\_workflows\_auth\_accessors](#input\_cai\_workflows\_auth\_accessors) | An optional list of Kubernetes service accounts to which read-only access will be granted to the `cai-moderator-auth`<br/>secret. Each reader must be a valid KSA name in default namespace, or a qualified namespace/name. The default allows<br/>Kubernetes service account `default` in namespace `f5-ai-redteam` to read the secret value. | `list(string)` | <pre>[<br/>  "f5-ai-redteam/default"<br/>]</pre> | no |
| <a name="input_cloud_deploy_service_account"></a> [cloud\_deploy\_service\_account](#input\_cloud\_deploy\_service\_account) | An optional Cloud Deploy execution service account that will deploy resources to GKE. If null or empty, Cloud Deploy<br/>pipelines will not be created. | `string` | `null` | no |
| <a name="input_f5_ai_license_secret"></a> [f5\_ai\_license\_secret](#input\_f5\_ai\_license\_secret) | An existing Secret Manager secret containing an F5 AI Guardrails/Red Team license token; appropriate secrets for F5 AI<br/>Guardrails/Red Team deployments will be created if this value is not empty or null(default). | `string` | `null` | no |
| <a name="input_global_cidrs"></a> [global\_cidrs](#input\_global\_cidrs) | An optional set of CIDRs to use for primary IP allocation, pods, etc. If null or empty, the default, then a fixed set<br/>of values will be used by the module. | <pre>object({<br/>    primary  = optional(string)<br/>    pods     = optional(string)<br/>    services = optional(string)<br/>    peering  = optional(string)<br/>    psc      = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_hugging_face"></a> [hugging\_face](#input\_hugging\_face) | An optional Hugging Face token with access to models to store in Google Secret Manager. Each accessor must be a valid<br/>KSA name in default namespace, or a qualified namespace/name. Default is empty, because access to Hugging Face should<br/>not be required by deployments. | <pre>object({<br/>    token     = string<br/>    accessors = optional(list(string))<br/>  })</pre> | `null` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | An optional map of key:value labels to apply to the resources. Default value is an empty map.<br/>NOTE: The effective set of labels will include some fixed values in addition to these. | `map(string)` | `{}` | no |
| <a name="input_model_cache_bucket"></a> [model\_cache\_bucket](#input\_model\_cache\_bucket) | An optional list of Kubernetes service accounts to which read-only access will be granted to objects in the bucket.<br/>Each reader must be a valid KSA name in default namespace, or a qualified namespace/name. If none are provided the<br/>module will grant access to Kubernetes service account `vllm` in namespace `vllm` to read the bucket contents. | <pre>object({<br/>    name      = string<br/>    accessors = optional(list(string))<br/>  })</pre> | `null` | no |
| <a name="input_nat_tags"></a> [nat\_tags](#input\_nat\_tags) | An optional list of Compute Engine tags that will be permitted to NAT to public internet through Cloud NAT. Default is<br/>empty.<br/>NOTE: The intent of this demo is to show F5 AI solutions in an isolated environment without access to the internet so<br/>setting this value invalidates that assumption. | `list(string)` | `null` | no |
| <a name="input_nginx_jwt_secret"></a> [nginx\_jwt\_secret](#input\_nginx\_jwt\_secret) | An existing Secret Manager secret containing an NGINX+ JWT token, with an optional list of Kubernetes service<br/>accounts to which read-only access will be granted. Each accessor must be a valid KSA name in default namespace, or<br/>a qualified namespace/name. Default is empty. | <pre>object({<br/>    id        = string<br/>    accessors = optional(list(string))<br/>  })</pre> | `null` | no |
| <a name="input_pgpass_accessors"></a> [pgpass\_accessors](#input\_pgpass\_accessors) | An optional list of Kubernetes service accounts to which read-only access will be granted. Each reader must be a valid<br/>KSA name in default namespace, or a qualified namespace/name. The default allows Kubernetes service account `pg-admin`<br/>in namespace `shared-services` to read the secret value. | `list(string)` | <pre>[<br/>  "shared-services/pg-admin"<br/>]</pre> | no |
| <a name="input_prefect_server_auth_accessors"></a> [prefect\_server\_auth\_accessors](#input\_prefect\_server\_auth\_accessors) | An optional list of Kubernetes service accounts to which read-only access will be granted to the `cai-moderator-auth`<br/>secret. Each reader must be a valid KSA name in default namespace, or a qualified namespace/name. The default allows<br/>Kubernetes service account `prefect-server` in namespace `f5-ai-redteam` to read the secret value. | `list(string)` | <pre>[<br/>  "f5-ai-redteam/prefect-server"<br/>]</pre> | no |
| <a name="input_provision_managed_access"></a> [provision\_managed\_access](#input\_provision\_managed\_access) | If true, public IP addresses will be reserved for cluster Gateways, along with Cloud Armor policies for access. If<br/>false (default), no public IP addresses will be reserved. | `bool` | `false` | no |
| <a name="input_regions"></a> [regions](#input\_regions) | The Compute Engine region names in which to create resources. Default is the single region 'us-central1'. | `list(string)` | <pre>[<br/>  "us-central1"<br/>]</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_allowlist_policies"></a> [allowlist\_policies](#output\_allowlist\_policies) | A map of Compute Engine region names to Cloud Armor source CIDR policies, if any were created. |
| <a name="output_cache_hosts"></a> [cache\_hosts](#output\_cache\_hosts) | A map of Compute Engine region names to a Redis host name. |
| <a name="output_cai_moderator_auth_secret"></a> [cai\_moderator\_auth\_secret](#output\_cai\_moderator\_auth\_secret) | A map of Compute Engine region names to the Secret Manager secret identifiers for cai-moderator-auth secret injection. |
| <a name="output_cai_workflows_auth"></a> [cai\_workflows\_auth](#output\_cai\_workflows\_auth) | A map of Compute Engine region names to the Secret Manager secret identifiers for cai-workflows-auth secret injection. |
| <a name="output_cert_manager_certs"></a> [cert\_manager\_certs](#output\_cert\_manager\_certs) | A map of Compute Engine region names to Certificate Manager certificate identifiers, if any were created. |
| <a name="output_clusters"></a> [clusters](#output\_clusters) | A map of Compute Engine region names to GKE Autopilot cluster identifiers. |
| <a name="output_deploy_target_ids"></a> [deploy\_target\_ids](#output\_deploy\_target\_ids) | A map of Compute Engine region names to Cloud Deploy targets. |
| <a name="output_dns_challenges"></a> [dns\_challenges](#output\_dns\_challenges) | A map of Compute Engine region names to DNS challenge records that may need to be inserted in a DNS zone to satisfy<br/>Certificate Manager and have it provision certificates. If the input variable `dns.managed_zone_id` was provided this<br/>may have already been completed. Provided anyway for manual verification of DNS CNAME records. |
| <a name="output_ext_addresses"></a> [ext\_addresses](#output\_ext\_addresses) | A map of Compute Engine region names to reserved public IP addresses.. |
| <a name="output_gke_service_account"></a> [gke\_service\_account](#output\_gke\_service\_account) | The GKE Service Account to use for clusters, with minimal roles assigned to be effective. |
| <a name="output_hugging_face_secret"></a> [hugging\_face\_secret](#output\_hugging\_face\_secret) | If a Hugging Face token was provided as input this output will contain the Secret Manager secret identifier that<br/>contains the token value. |
| <a name="output_labels"></a> [labels](#output\_labels) | A map of the effective labels that were applied to Google Cloud resources that take labels. Can be reused by<br/>subordinate modules if needed. |
| <a name="output_pg_instances"></a> [pg\_instances](#output\_pg\_instances) | A map of Compute Engine region names to Cloud SQL Postgresql instance attributes, admin user and Secret Manager secret<br/>identifier containing .pgpass authentication details. |
| <a name="output_prefect_server_auth_secret"></a> [prefect\_server\_auth\_secret](#output\_prefect\_server\_auth\_secret) | A map of Compute Engine region names to the Secret Manager secret identifiers for prefect-server-auth secret injection. |
| <a name="output_regional_names"></a> [regional\_names](#output\_regional\_names) | A map of Compute Engine region names to prefixes used in this foundations module, to keep a consistent naming standard<br/>for subordinate modules, like cluster creators. |
| <a name="output_ssl_policies"></a> [ssl\_policies](#output\_ssl\_policies) | A map of Compute Engine region names to Compute Engine SSL Policy self-links, if any were created. |
| <a name="output_subnets"></a> [subnets](#output\_subnets) | A map of Compute Engine region names to Compute Engine Subnetwork resource self-links. |
<!-- END_TF_DOCS -->
<!-- markdownlint-enable MD033 MD034 MD060 -->
