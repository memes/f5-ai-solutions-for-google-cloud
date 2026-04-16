module "nginxaas" {
  for_each   = var.nginxaas == null ? {} : { enabled = true }
  source     = "git::https://github.com/memes/terraform-google-nginxaas?ref=release%2f0.1.0"
  project_id = var.project_id
  workload_identity = {
    pool_id = var.workload_identity_pool_id
    name    = format("%s-nginxaas", var.name)
  }
  attachments = merge({
    for k, v in local.regional_names : format("%s-https", k) => {
      subnet             = module.vpc.subnets_by_region[k].self_link
      port               = 443
      service_attachment = try(var.nginxaas.attachments[k].service_attachment, null)
    }
    }, {
    for k, v in local.regional_names : format("%s-http", k) => {
      subnet             = module.vpc.subnets_by_region[k].self_link
      port               = 80
      service_attachment = try(var.nginxaas.attachments[k].service_attachment, null)
    }
  })
  service_accounts = try(var.nginxaas.service_accounts, null)
  secrets          = try(var.nginxaas.secrets, null)
}
