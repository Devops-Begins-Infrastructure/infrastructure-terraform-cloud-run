variable "vpc_name" {
  type        = string
  description = "VPC Name"
}

variable "rules" {
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
  description = "Map of firewall rules"
}

variable "rule_direction" {
  type        = string
  description = "Direction of the firewall rule (INGRESS or EGRESS)"
}
