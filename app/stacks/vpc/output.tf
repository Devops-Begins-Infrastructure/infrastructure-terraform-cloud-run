output vpc_id {
  value = google_compute_network.vpc_network.id
}

output vpc_name {
  value = google_compute_network.vpc_network.name
}

output vpc_connector_id {
  value = google_vpc_access_connector.connector.id
  description = "The ID of the VPC connector for Cloud Run services"
}

output vpc_connector_name {
  value = google_vpc_access_connector.connector.name
  description = "The name of the VPC connector for Cloud Run services"
}

output vpc_connector_self_link {
  value = google_vpc_access_connector.connector.self_link
  description = "The self link of the VPC connector for Cloud Run services"
}