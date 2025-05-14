provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_network" "vpc_network" {
  project                 = var.project_id
  name                    = var.network_name
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "google_compute_shared_vpc_host_project" "vpc_host_project" {
  project = var.project_id
}

# Subnet specifically for the Serverless VPC Access connector infrastructure
# This subnet is NOT where Cloud Run containers run - it's only used by the connector infrastructure
# The connector allows Cloud Run services to access resources in your VPC network
resource "google_compute_subnetwork" "connector_subnet" {
  name          = "${var.network_name}-connector-subnet"
  ip_cidr_range = "10.8.0.0/28"  # Small CIDR range only for connector infrastructure
  region        = var.region
  network       = google_compute_network.vpc_network.id
}

# Serverless VPC Access connector for Cloud Run
# This connector acts as a bridge between Cloud Run services and VPC resources
resource "google_vpc_access_connector" "connector" {
  name          = "${var.network_name}-connector"
  region        = var.region
  ip_cidr_range = google_compute_subnetwork.connector_subnet.ip_cidr_range
  network       = google_compute_network.vpc_network.name
  
  # Specify a minimum and maximum number of instances
  min_throughput = 200
  max_throughput = 300
}

