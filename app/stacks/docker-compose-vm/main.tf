provider "google" {
  project = var.project_id
  region  = var.region
}

# Verify the existence of the host project
data "google_project" "host_project" {
  project_id = var.vpc_project_id
}

# Verify the existence of the service project
data "google_project" "service_project" {
  project_id = var.project_id
}

# Configure the current project as a service project
resource "google_compute_shared_vpc_service_project" "service_project" {
  host_project    = data.google_project.host_project.project_id
  service_project = data.google_project.service_project.project_id
}

# Create a dedicated service account for the VM
resource "google_service_account" "vm_service_account" {
  account_id   = "docker-compose-vm-sa"
  display_name = "Docker Compose VM Service Account"
  project      = var.project_id
}

# Grant Network User role to the service account for the subnet in the host project
resource "google_compute_subnetwork_iam_member" "network_user_binding" {
  for_each = var.subnetworks
  
  project    = var.vpc_project_id
  region     = var.region
  subnetwork = each.key
  role       = "roles/compute.networkUser"
  member     = "serviceAccount:${google_service_account.vm_service_account.email}"
  
  depends_on = [google_compute_shared_vpc_service_project.service_project]
}

# Also grant project-level network user permissions if needed
resource "google_project_iam_member" "project_network_user" {
  project = var.vpc_project_id
  role    = "roles/compute.networkUser"
  member  = "serviceAccount:${google_service_account.vm_service_account.email}"
  
  depends_on = [google_compute_shared_vpc_service_project.service_project]
}

resource "google_compute_subnetwork" "vpc_subnetwork" {
  for_each = var.subnetworks

  project      = var.vpc_project_id
  name         = each.key
  ip_cidr_range = each.value.ip_cidr_range
  region       = var.region
  network      = var.vpc_network_id
  
  # Ensure the subnetworks are created after the service project is connected to the host project
  depends_on = [google_compute_shared_vpc_service_project.service_project]
}

# Create the docker compose VM instance
resource "google_compute_instance" "docker_compose_vm" {
  name                      = var.vm_config.name
  machine_type              = var.vm_config.machine_type
  zone                      = var.vm_config.zone
  tags                      = var.vm_config.tags
  labels                    = var.vm_config.labels
  metadata                  = var.vm_config.metadata
  metadata_startup_script   = var.vm_config.metadata_startup_script
  min_cpu_platform          = var.vm_config.min_cpu_platform
  allow_stopping_for_update = var.vm_config.allow_stopping_for_update
  can_ip_forward            = var.vm_config.can_ip_forward
  description               = var.vm_config.description
  desired_status            = var.vm_config.desired_status
  deletion_protection       = var.vm_config.deletion_protection
  hostname                  = var.vm_config.hostname
  enable_display            = var.vm_config.enable_display
  
  boot_disk {
    auto_delete             = var.vm_config.boot_disk.auto_delete
    device_name             = var.vm_config.boot_disk.device_name
    mode                    = var.vm_config.boot_disk.mode
    disk_encryption_key_raw = var.vm_config.boot_disk.disk_encryption_key_raw
    kms_key_self_link       = var.vm_config.boot_disk.kms_key_self_link
    
    initialize_params {
      size  = var.vm_config.boot_disk.initialize_params.size
      type  = var.vm_config.boot_disk.initialize_params.type
      image = var.vm_config.boot_disk.initialize_params.image
    }
  }
  
  dynamic "attached_disk" {
    for_each = var.vm_config.attached_disks != null ? var.vm_config.attached_disks : []
    content {
      source                  = attached_disk.value.source
      device_name             = attached_disk.value.device_name
      mode                    = attached_disk.value.mode
      disk_encryption_key_raw = attached_disk.value.disk_encryption_key_raw
      kms_key_self_link       = attached_disk.value.kms_key_self_link
    }
  }
  
  network_interface {
    subnetwork         = var.vm_config.network_interface.subnetwork
    subnetwork_project = var.vm_config.network_interface.subnetwork_project
    network_ip         = var.vm_config.network_interface.network_ip
    
    dynamic "access_config" {
      for_each = var.vm_config.network_interface.access_config != null ? var.vm_config.network_interface.access_config : []
      content {
        nat_ip                 = access_config.value.nat_ip
        public_ptr_domain_name = access_config.value.public_ptr_domain_name
        network_tier           = access_config.value.network_tier
      }
    }
    
    dynamic "alias_ip_range" {
      for_each = var.vm_config.network_interface.alias_ip_range != null ? var.vm_config.network_interface.alias_ip_range : []
      content {
        ip_cidr_range         = alias_ip_range.value.ip_cidr_range
        subnetwork_range_name = alias_ip_range.value.subnetwork_range_name
      }
    }
  }
  
  dynamic "scheduling" {
    for_each = var.vm_config.scheduling != null ? [var.vm_config.scheduling] : []
    content {
      preemptible         = scheduling.value.preemptible
      on_host_maintenance = scheduling.value.on_host_maintenance
      automatic_restart   = scheduling.value.automatic_restart
      
      dynamic "node_affinities" {
        for_each = scheduling.value.node_affinities != null ? scheduling.value.node_affinities : []
        content {
          key      = node_affinities.value.key
          operator = node_affinities.value.operator
          values   = node_affinities.value.values
        }
      }
    }
  }
  
  # Update the VM to use our dedicated service account
  service_account {
    email  = google_service_account.vm_service_account.email
    scopes = ["cloud-platform"]
  }
  
  dynamic "shielded_instance_config" {
    for_each = var.vm_config.shielded_instance_config != null ? [var.vm_config.shielded_instance_config] : []
    content {
      enable_secure_boot          = shielded_instance_config.value.enable_secure_boot
      enable_vtpm                 = shielded_instance_config.value.enable_vtpm
      enable_integrity_monitoring = shielded_instance_config.value.enable_integrity_monitoring
    }
  }
  
  dynamic "confidential_instance_config" {
    for_each = var.vm_config.confidential_instance_config != null ? [var.vm_config.confidential_instance_config] : []
    content {
      enable_confidential_compute = confidential_instance_config.value.enable_confidential_compute
    }
  }
  
  dynamic "advanced_machine_features" {
    for_each = var.vm_config.advanced_machine_features != null ? [var.vm_config.advanced_machine_features] : []
    content {
      enable_nested_virtualization = advanced_machine_features.value.enable_nested_virtualization
      threads_per_core             = advanced_machine_features.value.threads_per_core
    }
  }
  
  resource_policies = var.vm_config.resource_policies
  
  # Ensure the VM is created after the service project is connected to the host project
  depends_on = [google_compute_shared_vpc_service_project.service_project]
}


