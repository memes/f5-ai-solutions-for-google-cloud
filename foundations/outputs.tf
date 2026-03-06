output "regional_names" {
  value       = local.regional_names
  description = <<-EOD
  A map of Compute Engine region names to prefixes used in this foundations module, to keep a consistent naming standard
  for subordinate modules, like cluster creators.
  EOD
}

output "labels" {
  value       = local.effective_labels
  description = <<-EOD
  A map of the effective labels that were applied to Google Cloud resources that take labels. Can be reused by
  subordinate modules if needed.
  EOD
}

output "gke_service_account" {
  value       = module.sa.email
  description = <<-EOD
  The GKE Service Account to use for clusters, with minimal roles assigned to be effective.
  EOD
}

output "subnets" {
  value       = { for k, v in module.vpc.subnets_by_region : k => v.self_link }
  description = <<-EOD
  A map of Compute Engine region names to Compute Engine Subnetwork resource self-links.
  EOD
}

output "hugging_face_secret" {
  value       = one([for k, v in module.hugging_face_token : v.id])
  description = <<-EOD
  If a Hugging Face token was provided as input this output will contain the Secret Manager secret identifier that
  contains the token value.
  EOD
}

output "dns_challenges" {
  value       = { for k, v in module.cert : k => v.dns_challenges }
  description = <<-EOD
  A map of Compute Engine region names to DNS challenge records that may need to be inserted in a DNS zone to satisfy
  Certificate Manager and have it provision certificates. If the input variable `dns.managed_zone_id` was provided this
  may have already been completed. Provided anyway for manual verification of DNS CNAME records.
  EOD
}

output "cert_manager_certs" {
  value       = { for k, v in module.cert : k => v.certificate_manager_id }
  description = <<-EOD
  A map of Compute Engine region names to Certificate Manager certificate identifiers, if any were created.
  EOD
}

output "ssl_policies" {
  value       = { for k, v in module.cert : k => v.ssl_policy_self_link }
  description = <<-EOD
  A map of Compute Engine region names to Compute Engine SSL Policy self-links, if any were created.
  EOD
}

output "allowlist_policies" {
  value       = { for k, v in google_compute_region_security_policy.allowlist : k => v.self_link }
  description = <<-EOD
  A map of Compute Engine region names to Cloud Armor source CIDR policies, if any were created.
  EOD
}

output "model_cache_buckets" {
  value       = { for k, v in google_storage_bucket.model_cache : k => v.name }
  description = <<-EOD
  A map of Compute Engine region names to Storage bucket names to be used for model caching.
  EOD
}

output "pg_instances" {
  value = { for k, v in google_sql_database_instance.pg : v.region => {
    self_link          = v.self_link
    dns_name           = trimsuffix(v.dns_name, ".")
    ip_address         = google_compute_address.pg[k].address
    pg_admin_secret_id = module.pg_admin[k].id
    pg_admin_user      = google_sql_user.pg_admin[k].name
  } }
  description = <<-EOD
  A map of Compute Engine region names to Cloud SQL Postgresql instance attributes, admin user and Secret Manager secret
  identifier containing authentication details.
  EOD
}

output "clusters" {
  value       = { for k, v in module.cluster : k => v.id }
  description = <<-EOD
  A map of Compute Engine region names to GKE Autopilot cluster identifiers.
  EOD
}

output "gw_addresses" {
  value = { for k, v in google_compute_address.gw : k => {
    name = v.name
    ip   = v.address
  } }
  description = <<-EOD
  A map of Compute Engine region names to reserved public IP addresses for cluster Gateways, if provisioned.
  EOD
}

output "deploy_target_ids" {
  value       = { for k, v in google_clouddeploy_target.cluster : k => v.target_id }
  description = <<-EOD
  A map of Compute Engine region names to Cloud Deploy targets.
  EOD
}
