variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "network_name" {
  description = "The name of the VPC network to which the firewall rules will be applied."
  type        = string
}

variable "ingress_rules" {
  type = map(object({
    rule_number        = number
    rule_name          = string
    disabled           = string
    priority           = number
    action             = string
    protocol           = string
    target_tag         = string
    source_destination = string
    ports              = string
    description        = string
  }))
  description = "Map of ingress firewall rules"
}

variable "egress_rules" {
  type = map(object({
    rule_number        = number
    rule_name          = string
    disabled           = string
    priority           = number
    action             = string
    protocol           = string
    target_tag         = string
    source_destination = string
    ports              = string
    description        = string
  }))
  description = "Map of egress firewall rules"
}