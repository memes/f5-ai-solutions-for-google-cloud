# Since each cluster is isolated from public internet the models will be consumed by vLLM pods as ephemeral FUSE mounts.
resource "google_storage_bucket" "model_cache" {
  for_each                    = local.regional_names
  project                     = var.project_id
  name                        = format("%s-model-cache", each.value)
  force_destroy               = true
  location                    = each.key
  storage_class               = "REGIONAL"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  versioning {
    enabled = false
  }
  soft_delete_policy {
    retention_duration_seconds = 0
  }
}

resource "google_storage_bucket_iam_member" "bucket" {

  for_each = { for i, entry in setproduct([for k, v in google_storage_bucket.model_cache : v.name], coalescelist(var.model_cache_bucket_accessors == null ? [] : var.model_cache_bucket_accessors, ["vllm/vllm"])) : replace(format("%s-%s", entry[0], entry[1]), "/[^a-z0-9-]/", "-") => {
    name      = reverse(split("/", entry[1]))[0]
    namespace = try(reverse(split("/", entry[1]))[1], "default")
    bucket    = entry[0]
  } }
  bucket = each.value.bucket
  role   = "roles/storage.objectViewer"
  member = format("principal://iam.googleapis.com/projects/%s/locations/global/workloadIdentityPools/%s.svc.id.goog/subject/ns/%s/sa/%s", data.google_project.project.number, data.google_project.project.project_id, each.value.namespace, each.value.name)
}
