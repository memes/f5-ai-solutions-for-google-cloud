data "google_dns_managed_zone" "pg" {
  project = coalesce(try(reverse(split("/", data.terraform_remote_state.foundations.outputs.cloud_dns_sql_zone_id))[2], null), var.project_id)
  name    = reverse(split("/", data.terraform_remote_state.foundations.outputs.cloud_dns_sql_zone_id))[0]
}

# Setup regional postgresQL in each region
resource "google_sql_database_instance" "pg" {
  for_each = { for region in local.regions : format("%s-%s", var.name, module.region_detail.results[region].abbreviation) => {
    region = region
    }
  }
  project             = var.project_id
  name                = each.key
  region              = each.value.region
  deletion_protection = false
  database_version    = "POSTGRES_15"
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
    tier = "db-custom-2-8192"
  }
}

resource "google_compute_address" "pg" {
  for_each     = { for k, v in google_sql_database_instance.pg : k => v.region }
  project      = var.project_id
  name         = each.key
  subnetwork   = data.google_compute_subnetwork.subnets[each.value].name
  region       = each.value
  address_type = "INTERNAL"
}

resource "google_compute_forwarding_rule" "pg" {
  for_each = { for k, v in google_sql_database_instance.pg : k => {
    region  = v.region
    address = google_compute_address.pg[k].self_link
    target  = v.psc_service_attachment_link
    }
  }
  project                 = var.project_id
  name                    = each.key
  region                  = each.value.region
  network                 = data.google_compute_subnetwork.subnets[each.value.region].network
  ip_address              = each.value.address
  load_balancing_scheme   = ""
  target                  = each.value.target
  allow_psc_global_access = true
}

resource "google_dns_record_set" "pg" {
  for_each = { for k, v in google_sql_database_instance.pg : k => {
    name    = v.dns_name
    address = google_compute_address.pg[k].address
    }
  }
  project      = var.project_id
  managed_zone = data.google_dns_managed_zone.pg.name
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
  name     = format("%s-admin", each.key)
  instance = each.value
  password = random_password.pg_admin[each.key].result
}

module "pg_admin" {
  for_each   = { for k, v in google_sql_database_instance.pg : k => format("%s-admin", k) }
  source     = "memes/secret-manager/google"
  version    = "2.2.2"
  project_id = var.project_id
  id         = each.value
  secret     = null
  accessors  = []
}

resource "google_secret_manager_secret_version" "pg_admin" {
  for_each = { for k, v in module.pg_admin : k => v.id }
  secret   = each.value
  secret_data = jsonencode({
    user     = google_sql_user.pg_admin[each.key].name
    password = random_password.pg_admin[each.key].result
    pgpass = format("%s:5432:postgres:%s:%s",
      trimsuffix(google_sql_database_instance.pg[each.key].dns_name, "."),
      google_sql_user.pg_admin[each.key].name,
      random_password.pg_admin[each.key].result
    )
  })
}

resource "google_secret_manager_secret_iam_member" "pg_admin" {
  for_each = { for i, entry in setproduct([for k, v in module.pg_admin : k], var.pg_admin_accessors == null ? [] : var.pg_admin_accessors) : replace(format("%s-%s", entry[0], entry[1]), "/[^a-z0-9-]/", "-") => {
    name      = reverse(split("/", entry[1]))[0]
    namespace = try(reverse(split("/", entry[1]))[1], "default")
    secret_id = module.pg_admin[entry[0]].secret_id
  } }
  project   = var.project_id
  secret_id = each.value.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = format("principal://iam.googleapis.com/projects/%s/locations/global/workloadIdentityPools/%s.svc.id.goog/subject/ns/%s/sa/%s", data.google_project.project.number, data.google_project.project.project_id, each.value.namespace, each.value.name)
}
