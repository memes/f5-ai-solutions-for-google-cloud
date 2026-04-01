# Create regional buckets for Hugging Face models; since each cluster is isolated from public internet the models will be
# consumed by vLLM pods as ephemeral FUSE mounts.

resource "google_storage_bucket" "model_cache" {
  for_each                    = { for region in var.regions : region => format("%s-cache-%s", var.name, module.region_detail.results[region].abbreviation) }
  project                     = var.project_id
  name                        = each.value
  force_destroy               = true
  location                    = each.key
  storage_class               = "STANDARD"
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
  for_each = { for i, entry in setproduct(var.regions, var.model_bucket_accessors == null ? [] : var.model_bucket_accessors) : replace(format("%s-%s", entry[0], entry[1]), "/[^a-z0-9-]/", "-") => {
    name      = reverse(split("/", entry[1]))[0]
    namespace = try(reverse(split("/", entry[1]))[1], "default")
    bucket    = google_storage_bucket.model_cache[entry[0]].name
  } }
  bucket = each.value.bucket
  role   = "roles/storage.objectViewer"
  member = format("principal://iam.googleapis.com/projects/%s/locations/global/workloadIdentityPools/%s.svc.id.goog/subject/ns/%s/sa/%s", data.google_project.project.number, data.google_project.project.project_id, each.value.namespace, each.value.name)
}
