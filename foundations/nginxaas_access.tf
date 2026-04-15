# If managed access is not provisioned use F5 NGINXaaS for Google Cloud to expose services to public internet.

module "nginxaas" {
  for_each   = var.provision_managed_access ? {} : { enabled = true }
  source     = "git::https://github.com/memes/terraform-google-nginxaas?ref=release%2f0.1.0"
  project_id = var.project_id
  workload_identity = {
    pool_id = var.workload_identity_pool_id
    name    = format("%s-nginxaas", var.name)
  }
  attachments = {}
}
