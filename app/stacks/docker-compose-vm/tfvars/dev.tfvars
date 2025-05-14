project_id   = "953856153632" # dob-infra-dev-dck-compose-vm
vpc_project_id = "1098448580054" # dob-infra-dev-vpc
region       = "us-central1"
vpc_network_id = <%= output('vpc.vpc_id') %>


subnetworks = {
  gce-general-vms = {
    ip_cidr_range = "10.32.0.0/24"
    }
}

vm_config = {
  name                      = "docker-compose-vm"
  machine_type              = "e2-micro"  # Corrected: e2-micro is the cheapest option
  zone                      = "us-central1-c"  # Check for sustained use discounts in this zone
  tags                      = ["navigation","docker-compose","allow-ssh-remote"]  # Added allow-ssh-remote tag
  labels                    = {
    environment = "dev"
    managed-by  = "terraform"
  }
  metadata                  = {
    ssh-keys    = "rdocchio:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC+aCeSrD5NQggXdzjN4afxQoK/wqBE+5ILp1ObENdhEwpugltaFKiZyHYy6xHsThFaO3VAgiTNuEyGcE4t3rI+kdicLBu/ga5boFswhCnadMewlfGXSlCVcPmEbN+/0BthaOhq9NewmGBqDEKwe7YLUo2MX1CE49yTswiQX6IveK2ouB1YknHy6d52lSCEuf+xEdyXCuAtJf9K1dif/zCPti0pOJQxYrbA8OYxoHjEdFAhaX6VMoappJuIlUEmidG3WJ8VqQc7Ir4Ialu4P7nEpM7RLakesx4hJ5JuozloyauDoKdCBvqpEaJL3mk51R1RwVvQQshxCkxzlIqUALHd4Q/+C7rfoO/AdLU7CzEi83zOJdoT81FzJUBM1bMLQY/njsebyTd6D3hTKTtoczvfl6KUy1nxL51i8ZvTyYDCOl+mS7mttr4E9ja8/Xjs6EOnzy5BW/8PZSBlctHXZCA6PF/zMawSU4HW4navAHXFoRX+1suBXqutRzL/DGRV2R8="
    enable-oslogin = "FALSE"
    shutdown-script = "sudo shutdown -h now"  # Clean shutdown for preemptible VMs
  }
  metadata_startup_script   = <<-EOT
    #!/bin/bash
    # Minimal Docker installation
    apt-get update
    apt-get install -y ca-certificates curl
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    systemctl enable docker
  EOT
  allow_stopping_for_update = true
  description               = "Minimal Docker VM"
  desired_status            = "RUNNING"
  deletion_protection       = false
  
  boot_disk = {
    auto_delete             = true
    initialize_params = {
      size  = 20  # Minimum viable size
      type  = "pd-standard"
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }
  
  attached_disks = []
  
  network_interface = {
    subnetwork         = "gce-general-vms"
    subnetwork_project = "dob-infra-dev-vpc"
    network_ip         = null
    access_config      = [{
      nat_ip                 = null  # null means ephemeral IP will be assigned
      public_ptr_domain_name = null
      network_tier           = "STANDARD"  # STANDARD tier is cheaper than PREMIUM
    }]
    alias_ip_range     = null
  }
  
  scheduling = {
    preemptible         = true
    on_host_maintenance = "TERMINATE"
    automatic_restart   = false
    node_affinities     = null
  }
  
}