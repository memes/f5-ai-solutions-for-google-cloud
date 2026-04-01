# Setup regional postgresQL in each region
resource "google_sql_database_instance" "pg" {
  for_each            = local.regional_names
  project             = var.project_id
  name                = each.value
  region              = each.key
  deletion_protection = false
  database_version    = "POSTGRES_17"
  settings {
    availability_type = "REGIONAL"
    backup_configuration {
      enabled = true
    }
    ip_configuration {
      psc_config {
        psc_enabled = true
        allowed_consumer_projects = [
          var.project_id,
        ]
      }
      ipv4_enabled = false
    }
    edition = "ENTERPRISE"
    tier    = "db-custom-2-8192"
  }
}

resource "google_compute_address" "pg" {
  for_each = { for k, v in google_sql_database_instance.pg : k => {
    name   = format("%s-pg", v.name)
    subnet = module.vpc.subnets_by_region[v.region].name
  } }
  project      = var.project_id
  name         = each.value.name
  subnetwork   = each.value.subnet
  region       = each.key
  address_type = "INTERNAL"
}

resource "google_compute_forwarding_rule" "pg" {
  for_each = { for k, v in google_sql_database_instance.pg : k => {
    name    = format("%s-pg", v.name)
    region  = v.region
    address = google_compute_address.pg[k].self_link
    target  = v.psc_service_attachment_link
    }
  }
  project                 = var.project_id
  name                    = each.value.name
  region                  = each.key
  network                 = module.vpc.self_link
  ip_address              = each.value.address
  load_balancing_scheme   = ""
  target                  = each.value.target
  allow_psc_global_access = false
}

resource "google_dns_managed_zone" "pg" {
  project     = var.project_id
  name        = format("%s-sql-goog", var.name)
  description = "Override DNS resolution for Cloud SQL instances"
  dns_name    = "sql.goog."
  visibility  = "private"
  private_visibility_config {
    networks {
      network_url = module.vpc.self_link
    }
  }
}

resource "google_dns_record_set" "pg" {
  for_each = { for k, v in google_sql_database_instance.pg : k => {
    name    = v.dns_name
    address = google_compute_address.pg[k].address
    }
  }
  project      = var.project_id
  managed_zone = google_dns_managed_zone.pg.name
  name         = each.value.name
  type         = "A"
  rrdatas = [
    each.value.address,
  ]
}

resource "random_password" "pg_admin" {
  for_each = { for k, v in google_sql_database_instance.pg : k => true }
  length   = 16
  special  = false
}

resource "google_sql_user" "pg_admin" {
  for_each = { for k, v in google_sql_database_instance.pg : k => v.name }
  project  = var.project_id
  name     = format("%s-pg-admin", each.value)
  instance = each.value
  password = random_password.pg_admin[each.key].result
}
