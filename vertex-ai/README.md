# Vertex AI

This module provisions Vertex AI models for demo.

<!-- markdownlint-disable MD033 MD034 -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 7.28 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_region_detail"></a> [region\_detail](#module\_region\_detail) | memes/region-detail/google | 1.1.7 |

## Resources

| Name | Type |
| ---- | ---- |
| [google_compute_address.model](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_address) | resource |
| [google_compute_forwarding_rule.gemma](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_forwarding_rule) | resource |
| [google_dns_managed_zone.vertex_ai](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dns_managed_zone) | resource |
| [google_dns_record_set.model](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dns_record_set) | resource |
| [google_project_iam_member.vertex_user](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_vertex_ai_endpoint_with_model_garden_deployment.model](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/vertex_ai_endpoint_with_model_garden_deployment) | resource |
| [google_compute_subnetwork.subnets](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_subnetwork) | data source |
| [google_project.project](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/project) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_name"></a> [name](#input\_name) | The common name to use as-is, or as a prefix with an abbreviated region name, for resources created by this module.<br/>E.g. if `name = "ai-demo"`, global resources will be named "ai-demo" (or have a name prefix of "ai-demo-XXX"), and<br/>regional resources will be named "ai-demo-xx-xxN" (or prefixed with "ai-demo-xx-xxN-") where xx-xxN is an abbreviation<br/>of the region name. | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The Google Cloud project identifier that will contain the resources. | `string` | n/a | yes |
| <a name="input_labels"></a> [labels](#input\_labels) | An optional map of key:value labels to apply to the resources. Default value is an empty map.<br/>NOTE: The effective set of labels will include some fixed values in addition to these. | `map(string)` | `{}` | no |
| <a name="input_publisher_models"></a> [publisher\_models](#input\_publisher\_models) | A list of Model Garden models to provision on Vertex AI. | `list(string)` | <pre>[<br/>  "publishers/google/models/gemma3@gemma-3-4b-it"<br/>]</pre> | no |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | A map of Compute Engine region names to subnetwork self-links for which Vertex AI models will be provisioned. | `map(string)` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_vertex_ai_endpoints"></a> [vertex\_ai\_endpoints](#output\_vertex\_ai\_endpoints) | A map of Vertex AI model endpoint display names to resolver values. |
<!-- END_TF_DOCS -->
<!-- markdownlint-enable MD033 MD034 -->
