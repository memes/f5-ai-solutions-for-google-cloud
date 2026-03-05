output "ar_repo" {
  value       = one([for k, v in module.bootstrap.repo_identifiers : v if k == "oci"])
  description = <<-EOD
  The Artifact Registry created for OCI artifacts.
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

output "f5_ai_license" {
  value = {
    secret_id            = one([for k, v in module.f5_ai_license : v.secret_id])
    id                   = one([for k, v in module.f5_ai_license : v.id])
    expiration_timestamp = one([for k, v in module.f5_ai_license : v.expiration_timestamp])
  }
  description = <<-EOD
  If an F5 AI Guardrails/Red Team secret was created during bootstrap, return the fully-qualified and local identifiers,
  and expiration timestamp, if appropriate.
  EOD
}
