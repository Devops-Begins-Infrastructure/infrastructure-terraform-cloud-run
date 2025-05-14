provider "google" {
  project = var.project_id
  region  = var.region
}

module "vpc_firewall_rules_outbound" {
  source         = "../../modules/firewall-module"
  vpc_name       = var.network_name
  rules          = var.egress_rules
  rule_direction = "EGRESS"
}

module "vpc_firewall_rules_inbound" {
  source         = "../../modules/firewall-module"
  vpc_name       = var.network_name
  rules          = var.ingress_rules
  rule_direction = "INGRESS"
}
