output "vertex_ai_endpoints" {
  value = { for k, v in google_vertex_ai_endpoint_with_model_garden_deployment.model : v.deployed_model_display_name => {
    dns_name = trimsuffix(google_dns_record_set.model[k].name, ".")
    address  = google_compute_address.model[k].address
    url      = format("https://%s/v1/%s", trimsuffix(google_dns_record_set.model[k].name, "."), v.id)
  } }
  description = <<-EOD
  A map of Vertex AI model endpoint display names to resolver values.
  EOD
}
