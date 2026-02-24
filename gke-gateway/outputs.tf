output "clusters" {
  value = { for k, v in module.cluster : k => v.id }
}

output "pg_instances" {
  # sensitive = true
  value = { for k, v in google_sql_database_instance.pg : v.region => {
    self_link          = v.self_link
    dns_name           = trimsuffix(v.dns_name, ".")
    ip_address         = google_compute_address.pg[k].address
    pg_admin_secret_id = module.pg_admin[k].id
    pg_admin_user      = google_sql_user.pg_admin[k].name
    # pg_admin_password = random_password.pg_admin[k].result
  } }
}

output "pub_addresses" {
  value = { for k, v in google_compute_address.pub : k => {
    name = v.name
    ip   = v.address
  } }
}

output "gw_addresses" {
  value = { for k, v in google_compute_address.gw : k => {
    name = v.name
    ip   = v.address
  } }
}

output "deploy_target_ids" {
  value = { for k, v in google_clouddeploy_target.cluster : k => v.target_id }
}
