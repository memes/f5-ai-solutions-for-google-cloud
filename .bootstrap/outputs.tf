output "ar_repos" {
  value       = module.bootstrap.repo_identifiers
  description = <<-EOD
  The Artifact Registries created by the module.
  EOD
}

output "iac_sa" {
  value       = module.bootstrap.iac_sa
  description = <<-EOD
  The fully-qualified email address of the Infrastructure as Code execution service account.
  EOD
}

output "cloud_deploy_sa" {
  value       = module.bootstrap.deploy_sa
  description = <<-EOD
  The fully-qualified email address of the Cloud Deploy execution service account.
  EOD
}

output "nginx_jwt" {
  value       = module.bootstrap.nginx_jwt
  description = <<-EOD
  If an NGINX JWT secret was created during bootstrap, return the fully-qualified and local identifiers, and expiration
  timestamp, if appropriate.
  EOD
}

output "secrets" {
  value       = module.bootstrap.secrets
  description = <<-EOD
  A map of Secret Manager secrets created during bootstrap, if any.
  EOD
}

output "workload_identity_pool_id" {
  value       = module.bootstrap.workload_identity_pool_id
  description = <<-EOD
  The fully-qualified workload identity pool identifier created during bootstrap.
  EOD
}
