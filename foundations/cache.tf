# Setup regional Memorystore cache in each region.

# resource "google_compute_global_address" "cache" {
#   project       = var.project_id
#   name          = format("%s-cache", var.name)
#   description   = "Reserved range for Redis peering"
#   purpose       = "VPC_PEERING"
#   ip_version    = "IPV4"
#   address_type  = "INTERNAL"
#   network       = module.vpc.id
#   address       = cidrhost(local.global_cache_cidr, 0)
#   prefix_length = tonumber(split("/", local.global_cache_cidr)[1])
# }

# resource "google_service_networking_connection" "cache" {
#   network = module.vpc.id
#   service = "servicenetworking.googleapis.com"
#   reserved_peering_ranges = [
#     google_compute_global_address.cache.name,
#   ]
# }

# resource "google_redis_instance" "cache" {
#   for_each                = local.regional_names
#   project                 = var.project_id
#   name                    = format("%s-cache", each.value)
#   display_name            = ""
#   region                  = each.key
#   redis_version           = "REDIS_7_2"
#   tier                    = "STANDARD_HA"
#   memory_size_gb          = 8
#   authorized_network      = module.vpc.id
#   connect_mode            = "PRIVATE_SERVICE_ACCESS"
#   deletion_protection     = false
#   location_id             = element(data.google_compute_zones.zones[each.key].names, 0)
#   alternative_location_id = element(data.google_compute_zones.zones[each.key].names, 1)
#   persistence_config {
#     persistence_mode = "DISABLED"
#   }
#   replica_count      = 1
#   read_replicas_mode = "READ_REPLICAS_DISABLED"
#   depends_on = [
#     google_service_networking_connection.cache,
#   ]
# }
