# Create Secret Manager secrets for keys and items that may need to be consumed by deployments.
#

module "hugging_face_token" {
  for_each   = coalesce(try(var.hugging_face.token, null), "unspecified") == "unspecified" ? {} : { global = var.hugging_face.token }
  source     = "memes/secret-manager/google"
  version    = "2.2.2"
  project_id = var.project_id
  id         = format("%s-hugging-face", var.name)
  secret     = each.value
  accessors  = []
}

resource "google_secret_manager_secret_iam_member" "hugging_face" {
  for_each = { for i, entry in setproduct([for k, v in module.hugging_face_token : k], try(var.hugging_face.accessors, null) == null ? [] : var.hugging_face.accessors) : replace(format("%s-%s", entry[0], entry[1]), "/[^a-z0-9-]/", "-") => {
    name      = reverse(split("/", entry[1]))[0]
    namespace = try(reverse(split("/", entry[1]))[1], "default")
    secret_id = module.hugging_face_token[entry[0]].secret_id
  } }
  project   = var.project_id
  secret_id = each.value.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = format("principal://iam.googleapis.com/projects/%s/locations/global/workloadIdentityPools/%s.svc.id.goog/subject/ns/%s/sa/%s", data.google_project.project.number, data.google_project.project.project_id, each.value.namespace, each.value.name)
}

module "pg_admin" {
  for_each   = { for k, v in google_sql_user.pg_admin : k => v.name }
  source     = "memes/secret-manager/google"
  version    = "2.2.2"
  project_id = var.project_id
  id         = each.value
  secret     = null
  accessors  = []
}

resource "google_secret_manager_secret_version" "pg_admin" {
  for_each = { for k, v in module.pg_admin : k => {
    secret_id = v.id
    user      = google_sql_user.pg_admin[k].name
    password  = random_password.pg_admin[k].result
    host      = trimsuffix(google_sql_database_instance.pg[k].dns_name, ".")
  } }
  secret = each.value.secret_id
  secret_data = jsonencode({
    user     = each.value.user
    password = each.value.password
    pgpass   = format("%s:5432:postgres:%s:%s", each.value.host, each.value.user, each.value.password)
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
  project  = coalesce(try(reverse(split("/", var.f5_ai_license_secret.id))[2], null), var.project_id)
  secret   = reverse(split("/", var.f5_ai_license_secret.id))[0]
}

module "cai_moderator_auth" {
  for_each   = try(length(data.google_secret_manager_secret_version_access.f5_ai_license), 0) == 0 ? {} : local.regional_names
  source     = "memes/secret-manager/google"
  version    = "2.2.2"
  project_id = var.project_id
  id         = format("%s-cai-auth", each.key)
  secret     = <<-EOS
  CAI_MODERATOR_AUTH_IDP_CLIENT_ID: ""
  CAI_MODERATOR_AUTH_IDP_CLIENT_SECRET: ""
  CAI_MODERATOR_AUTH_IDP_ISSUER: ""
  CAI_MODERATOR_DB_ADMIN_PASSWORD: ${random_password.pg_admin[each.key].result}
  CAI_MODERATOR_DB_MODERATOR_PASSWORD: "moderator"
  CAI_MODERATOR_DEFAULT_LICENSE: ${data.google_secret_manager_secret_version_access.f5_ai_license["global"].secret_data}
  CAI_MODERATOR_EMAIL_PASSWORD: ""
  CAI_MODERATOR_EMAIL_USER: ""
  EOS
  accessors  = []
}

resource "google_secret_manager_secret_iam_member" "cai_moderator_auth" {
  for_each = { for i, entry in setproduct([for k, v in module.cai_moderator_auth : k], coalescelist(try(var.f5_ai_license_secret.accessors, null) == null ? [] : var.f5_ai_license_secret.accessors, ["cai-moderator/cai-moderator-sa"])) : replace(format("%s-%s", entry[0], entry[1]), "/[^a-z0-9-]/", "-") => {
    name      = reverse(split("/", entry[1]))[0]
    namespace = try(reverse(split("/", entry[1]))[1], "default")
    secret_id = module.cai_moderator_auth[entry[0]].secret_id
  } }
  project   = var.project_id
  secret_id = each.value.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = format("principal://iam.googleapis.com/projects/%s/locations/global/workloadIdentityPools/%s.svc.id.goog/subject/ns/%s/sa/%s", data.google_project.project.number, data.google_project.project.project_id, each.value.namespace, each.value.name)
}
