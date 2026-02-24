output "github_deploy_pubkey" {
  sensitive = true
  value     = trimspace(module.bootstrap.deploy_public_key)
}

output "github_deploy_privkey" {
  sensitive = true
  value     = trimspace(module.bootstrap.deploy_private_key)
}

output "ar_repo" {
  value = one([for k, v in module.bootstrap.repo_identifiers : v if k == "oci"])
}

output "cloud_deploy_sa" {
  value = module.bootstrap.deploy_sa
}

output "nginx_jwt" {
  value = module.bootstrap.nginx_jwt
}
