project_id   = "dob-infra-dev-vpc"
region       = "us-central1"
network_name = "dob-infra-dev-vpc-network"

egress_rules = {
  allow-navigation = {
    rule_number        = 1
    rule_name          = "allow-navigation"
    disabled           = "false"
    priority           = 65533
    action             = "allow"
    protocol           = "all"
    target_tag         = "navigation"
    source_destination = "0.0.0.0/0"
    ports              = ""
    description        = "Internet Navigation rule"
  },
  deny-all = {
    rule_number        = 2
    rule_name          = "deny-all"
    disabled           = "false"
    priority           = 65534
    action             = "deny"
    protocol           = "all"
    target_tag         = ""
    source_destination = "0.0.0.0/0"
    ports              = ""
    description        = "Deny all traffic rule"
  }
}

ingress_rules = {
  allow-ssh-access = {
    rule_number        = 1
    rule_name          = "allow-ssh-access"
    disabled           = "false"
    priority           = 1000
    action             = "allow"
    protocol           = "tcp"
    target_tag         = "allow-ssh-remote"
    source_destination = "190.18.66.158/32"
    ports              = "22"
    description        = "Allow SSH access from specific IP address"
  }
}