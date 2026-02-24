output "subnets" {
  value = { for k, v in module.vpc.subnets_by_region : k => v.self_link }
}

output "proxy_subnets" {
  value = { for k, v in google_compute_subnetwork.proxy_subnet : v.region => v.self_link }
}

output "cloud_dns_sql_zone_id" {
  value = google_dns_managed_zone.pg.id
}

output "f5_ai_license" {
  value = one([for k, v in module.f5_ai_license : v.id])
}

output "hugging_face_secret" {
  value = one([for k, v in module.hugging_face_token : v.id])
}

output "dns_challenges" {
  sensitive = true
  value     = [for k, v in module.cert : v.dns_challenges]
}

output "cert_manager_certs" {
  value = { for k, v in module.cert : k => v.certificate_manager_id }
}

output "ssl_policies" {
  value = { for k, v in module.cert : k => v.ssl_policy_self_link }
}

output "labels" {
  value = var.labels
}

output "allowlist_policies" {
  value = { for k, v in google_compute_region_security_policy.allowlist : k => v.self_link }
}
