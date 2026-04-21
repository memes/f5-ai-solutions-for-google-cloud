# Create Secret Manager secrets for keys and items that may need to be consumed by deployments.
#

resource "google_secret_manager_secret" "hugging_face" {
  for_each  = coalesce(try(var.hugging_face.token, null), "unspecified") == "unspecified" ? {} : { global = format("%s-hugging-face", var.name) }
  project   = var.project_id
  secret_id = each.value
  replication {
    auto {}
  }
  lifecycle {
    ignore_changes = [
      version_aliases,
    ]
  }
}

resource "google_secret_manager_secret_version" "hugging_face" {
  for_each    = { for k, v in google_secret_manager_secret.hugging_face : k => var.hugging_face.token }
  project     = each.value.project
  secret      = each.value.secret_id
  secret_data = each.value
}

resource "google_secret_manager_secret_iam_member" "hugging_face" {
  for_each = { for i, entry in setproduct([for k, v in google_secret_manager_secret.hugging_face : k], try(var.hugging_face.accessors, null) == null ? [] : var.hugging_face.accessors) : replace(format("%s-%s", entry[0], entry[1]), "/[^a-z0-9-]/", "-") => {
    name      = reverse(split("/", entry[1]))[0]
    namespace = try(reverse(split("/", entry[1]))[1], "default")
    secret_id = google_secret_manager_secret.hugging_face[entry[0]].secret_id
  } }
  project   = var.project_id
  secret_id = each.value.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = format("principal://iam.googleapis.com/projects/%s/locations/global/workloadIdentityPools/%s.svc.id.goog/subject/ns/%s/sa/%s", data.google_project.project.number, data.google_project.project.project_id, each.value.namespace, each.value.name)
}

resource "google_secret_manager_secret" "pgpass" {
  for_each  = { for k, v in google_sql_user.pg_admin : k => v.name }
  project   = var.project_id
  secret_id = each.value
  replication {
    auto {}
  }
  lifecycle {
    ignore_changes = [
      version_aliases,
    ]
  }
}

resource "google_secret_manager_secret_version" "pgpass" {
  for_each = { for k, v in google_secret_manager_secret.pgpass : k => {
    secret_id = v.id
    project   = v.project
    user      = google_sql_user.pg_admin[k].name
    password  = random_password.pg_admin[k].result
    host      = trimsuffix(google_sql_database_instance.pg[k].dns_name, ".")
  } }
  project = each.value.project
  secret  = each.value.secret_id
  secret_data = jsonencode({
    user     = each.value.user
    password = each.value.password
    host     = each.value.host
    pgpass   = format("%s:5432:postgres:%s:%s", each.value.host, each.value.user, each.value.password)
  })
}

resource "google_secret_manager_secret_iam_member" "pgpass" {
  for_each = { for i, entry in setproduct([for k, v in google_secret_manager_secret.pgpass : k], var.pgpass_accessors == null ? [] : var.pgpass_accessors) : replace(format("%s-%s", entry[0], entry[1]), "/[^a-z0-9-]/", "-") => {
    name      = reverse(split("/", entry[1]))[0]
    namespace = try(reverse(split("/", entry[1]))[1], "default")
    secret_id = google_secret_manager_secret.pgpass[entry[0]].secret_id
    project   = google_secret_manager_secret.pgpass[entry[0]].project
  } }
  project   = each.value.project
  secret_id = each.value.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = format("principal://iam.googleapis.com/projects/%s/locations/global/workloadIdentityPools/%s.svc.id.goog/subject/ns/%s/sa/%s", data.google_project.project.number, data.google_project.project.project_id, each.value.namespace, each.value.name)
}

resource "google_secret_manager_secret_iam_member" "nginx_jwt" {
  for_each = var.nginx_jwt_secret == null ? {} : { for ksa in try(var.nginx_jwt_secret.accessors, null) == null ? [] : var.nginx_jwt_secret.accessors : ksa => {
    name       = reverse(split("/", ksa))[0]
    namespace  = try(reverse(split("/", ksa))[1], "default")
    project_id = coalesce(try(reverse(split("/", var.nginx_jwt_secret.id))[2], null), var.project_id)
    secret_id  = reverse(split("/", var.nginx_jwt_secret.id))[0]
  } }
  project   = each.value.project_id
  secret_id = each.value.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = format("principal://iam.googleapis.com/projects/%s/locations/global/workloadIdentityPools/%s.svc.id.goog/subject/ns/%s/sa/%s", data.google_project.project.number, data.google_project.project.project_id, each.value.namespace, each.value.name)
}

data "google_secret_manager_secret_version_access" "f5_ai_license" {
  for_each = var.f5_ai_license_secret == null ? {} : { global = true }
  project  = coalesce(try(reverse(split("/", var.f5_ai_license_secret))[2], null), var.project_id)
  secret   = reverse(split("/", var.f5_ai_license_secret))[0]
}

resource "google_secret_manager_secret" "cai_moderator_auth" {
  for_each  = { for k, v in local.regional_names : k => format("%s-cai-moderator-auth", v) }
  project   = var.project_id
  secret_id = each.value
  replication {
    auto {}
  }
  lifecycle {
    ignore_changes = [
      version_aliases,
    ]
  }
}

resource "google_secret_manager_secret_version" "cai_moderator_auth" {
  for_each               = google_secret_manager_secret.cai_moderator_auth
  project                = each.value.project
  secret                 = each.value.secret_id
  secret_data_wo_version = 1
  secret_data_wo = jsonencode({
    CAI_MODERATOR_AUTH_ADMIN_PASSWORD        = "keycloak"
    CAI_MODERATOR_AUTH_IDP_CLIENT_ID         = ""
    CAI_MODERATOR_AUTH_IDP_CLIENT_SECRET     = ""
    CAI_MODERATOR_AUTH_IDP_ISSUER            = ""
    CAI_MODERATOR_DB_ADMIN_PASSWORD          = random_password.pg_admin[each.key].result
    CAI_MODERATOR_DB_MODERATOR_PASSWORD      = "moderator"
    CAI_MODERATOR_DEFAULT_LICENSE            = try(data.google_secret_manager_secret_version_access.f5_ai_license["global"].secret_data, "")
    CAI_MODERATOR_EMAIL_PASSWORD             = ""
    CAI_MODERATOR_EMAIL_USER                 = ""
    CAI_MODERATOR_ENCRYPTION_KEY             = "gtcktxD8M-hkUAdj7Pk22khjC2Bv8xSA2oyNCEG0ZpQ="
    CAI_MODERATOR_JOB_MANAGER_ENCRYPTION_KEY = "ISJ9GCvWB3l1YUXjw4jvTeuFDHlcsD_W77VvM9QpLgE="
  })
}

resource "google_secret_manager_secret_iam_member" "cai_moderator_auth" {
  for_each = { for i, entry in setproduct([for k, v in google_secret_manager_secret.cai_moderator_auth : k], coalescelist(var.cai_moderator_auth_accessors == null ? [] : var.cai_moderator_auth_accessors, ["f5-ai-moderator/cai-moderator-sa"])) : replace(format("%s-%s", entry[0], entry[1]), "/[^a-z0-9-]/", "-") => {
    name      = reverse(split("/", entry[1]))[0]
    namespace = try(reverse(split("/", entry[1]))[1], "default")
    secret_id = google_secret_manager_secret.cai_moderator_auth[entry[0]].secret_id
  } }
  project   = var.project_id
  secret_id = each.value.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = format("principal://iam.googleapis.com/projects/%s/locations/global/workloadIdentityPools/%s.svc.id.goog/subject/ns/%s/sa/%s", data.google_project.project.number, data.google_project.project.project_id, each.value.namespace, each.value.name)
}

resource "google_secret_manager_secret" "prefect_server_auth" {
  for_each  = { for k, v in local.regional_names : k => format("%s-prefect-server-auth", v) }
  project   = var.project_id
  secret_id = each.value
  replication {
    auto {}
  }
  lifecycle {
    ignore_changes = [
      version_aliases,
    ]
  }
}

resource "google_secret_manager_secret_version" "prefect_server_auth" {
  for_each = google_secret_manager_secret.prefect_server_auth
  project  = each.value.project
  secret   = each.value.secret_id
  secret_data = jsonencode({
    connection-string = format("postgresql+asyncpg://prefect:prefect@%s:5432/prefect", trimsuffix(google_sql_database_instance.pg[each.key].dns_name, "."))
  })
}

resource "google_secret_manager_secret_iam_member" "prefect_server_auth" {
  for_each = { for i, entry in setproduct([for k, v in google_secret_manager_secret.prefect_server_auth : k], coalescelist(var.prefect_server_auth_accessors == null ? [] : var.prefect_server_auth_accessors, ["f5-ai-redteam/prefect-server"])) : replace(format("%s-%s", entry[0], entry[1]), "/[^a-z0-9-]/", "-") => {
    name      = reverse(split("/", entry[1]))[0]
    namespace = try(reverse(split("/", entry[1]))[1], "default")
    secret_id = google_secret_manager_secret.prefect_server_auth[entry[0]].secret_id
  } }
  project   = var.project_id
  secret_id = each.value.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = format("principal://iam.googleapis.com/projects/%s/locations/global/workloadIdentityPools/%s.svc.id.goog/subject/ns/%s/sa/%s", data.google_project.project.number, data.google_project.project.project_id, each.value.namespace, each.value.name)
}

resource "google_secret_manager_secret" "cai_workflows_auth" {
  for_each  = { for k, v in local.regional_names : k => format("%s-cai-workflows-auth", v) }
  project   = var.project_id
  secret_id = each.value
  replication {
    auto {}
  }
  lifecycle {
    ignore_changes = [
      version_aliases,
    ]
  }
}

resource "google_secret_manager_secret_version" "cai_workflows_auth" {
  for_each = google_secret_manager_secret.cai_workflows_auth
  project  = each.value.project
  secret   = each.value.secret_id
  secret_data = jsonencode({
    CAI_WORKFLOWS_ENCRYPTION_KEY = "ISJ9GCvWB3l1YUXjw4jvTeuFDHlcsD_W77VvM9QpLgE="
    connection-string            = format("postgresql+asyncpg://prefect:prefect@%s:5432/prefect", trimsuffix(google_sql_database_instance.pg[each.key].dns_name, "."))
  })
}

resource "google_secret_manager_secret_iam_member" "cai_workflows_auth" {
  for_each = { for i, entry in setproduct([for k, v in google_secret_manager_secret.cai_workflows_auth : k], coalescelist(var.cai_workflows_auth_accessors == null ? [] : var.cai_workflows_auth_accessors, ["f5-ai-redteam/default"])) : replace(format("%s-%s", entry[0], entry[1]), "/[^a-z0-9-]/", "-") => {
    name      = reverse(split("/", entry[1]))[0]
    namespace = try(reverse(split("/", entry[1]))[1], "default")
    secret_id = google_secret_manager_secret.cai_workflows_auth[entry[0]].secret_id
  } }
  project   = var.project_id
  secret_id = each.value.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = format("principal://iam.googleapis.com/projects/%s/locations/global/workloadIdentityPools/%s.svc.id.goog/subject/ns/%s/sa/%s", data.google_project.project.number, data.google_project.project.project_id, each.value.namespace, each.value.name)
}
