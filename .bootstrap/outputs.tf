output "github_deploy_pubkey" {
  sensitive = true
  value     = trimspace(module.bootstrap.deploy_public_key)
}

output "github_deploy_privkey" {
  sensitive = true
  value     = trimspace(module.bootstrap.deploy_private_key)
}
