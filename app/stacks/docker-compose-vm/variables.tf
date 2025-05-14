variable project_id {
  type = string
  description = "The ID of the project in which the VPC network will be created."
}
variable vpc_project_id {
  type = string
  description = "The ID of the project in which the VPC network will be created."
}
variable region {
  type = string
  description = "The region in which the VPC network will be created."
}
variable vpc_network_id {
  type = string
  description = "The ID of the VPC network to be created."
}

variable subnetworks {
  type = map(object({
    ip_cidr_range = string
  }))
  description = "A map of subnetworks to be created within the VPC network. The key is the name of the subnetwork, and the value is an object containing the IP CIDR range."
}

variable "vm_config" {
  description = "Configuration for the Docker Compose VM"
  type = object({
    name                      = string
    machine_type              = string
    zone                      = string
    tags                      = list(string)
    labels                    = map(string)
    metadata                  = map(string)
    metadata_startup_script   = optional(string)
    min_cpu_platform          = optional(string)
    allow_stopping_for_update = optional(bool)
    can_ip_forward            = optional(bool)
    description               = optional(string)
    desired_status            = optional(string)
    deletion_protection       = optional(bool)
    hostname                  = optional(string)
    enable_display            = optional(bool)
    
    boot_disk = object({
      auto_delete             = optional(bool)
      device_name             = optional(string)
      mode                    = optional(string)
      disk_encryption_key_raw = optional(string)
      kms_key_self_link       = optional(string)
      initialize_params = object({
        size  = optional(number)
        type  = optional(string)
        image = string
      })
    })
    
    attached_disks = optional(list(object({
      source                  = string
      device_name             = optional(string)
      mode                    = optional(string)
      disk_encryption_key_raw = optional(string)
      kms_key_self_link       = optional(string)
    })))
    
    network_interface = object({
      subnetwork         = string
      subnetwork_project = string
      network_ip         = optional(string)
      access_config = optional(list(object({
        nat_ip                 = optional(string)
        public_ptr_domain_name = optional(string)
        network_tier           = optional(string)
      })))
      alias_ip_range = optional(list(object({
        ip_cidr_range         = string
        subnetwork_range_name = optional(string)
      })))
    })
    
    scheduling = optional(object({
      preemptible         = optional(bool)
      on_host_maintenance = optional(string)
      automatic_restart   = optional(bool)
      node_affinities = optional(list(object({
        key      = string
        operator = string
        values   = list(string)
      })))
    }))
    
    service_account = optional(object({
      email  = optional(string)
      scopes = list(string)
    }))
    
    shielded_instance_config = optional(object({
      enable_secure_boot          = optional(bool)
      enable_vtpm                 = optional(bool)
      enable_integrity_monitoring = optional(bool)
    }))
    
    confidential_instance_config = optional(object({
      enable_confidential_compute = bool
    }))
    
    advanced_machine_features = optional(object({
      enable_nested_virtualization = optional(bool)
      threads_per_core             = optional(number)
    }))
    
    resource_policies = optional(list(string))
  })
}