# Since each cluster is isolated from public internet the models will be consumed by vLLM pods as ephemeral FUSE mounts.

resource "google_storage_bucket_iam_member" "bucket" {
  for_each = var.model_cache_bucket == null ? {} : { for ksa in coalescelist(try(var.model_cache_bucket.accessors, []), ["vllm/vllm"]) : ksa => {
    name      = reverse(split("/", ksa))[0]
    namespace = try(reverse(split("/", ksa))[1], "default")
    bucket    = var.model_cache_bucket.name
  } }
  bucket = each.value.bucket
  role   = "roles/storage.objectViewer"
  member = format("principal://iam.googleapis.com/projects/%s/locations/global/workloadIdentityPools/%s.svc.id.goog/subject/ns/%s/sa/%s", data.google_project.project.number, data.google_project.project.project_id, each.value.namespace, each.value.name)
}
