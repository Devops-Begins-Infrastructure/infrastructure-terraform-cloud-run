resource "google_compute_firewall" "firewall_rule" {
  for_each = var.rules

  name        = "${var.vpc_name}-fw-rule-${each.value.rule_number}-${each.key}"
  network     = var.vpc_name
  description = each.value.description
  disabled    = each.value.disabled
  priority    = each.value.priority
  direction   = var.rule_direction

  target_tags = each.value.target_tag == "" ? null : [each.value.target_tag]

  destination_ranges = var.rule_direction == "EGRESS" ? split(",", each.value.source_destination) : null

  source_ranges = var.rule_direction == "INGRESS" && length(regexall(".*./..*", each.value.source_destination)) > 0 ? (each.value.source_destination == "" ? null : split(",", each.value.source_destination)) : null

  source_tags = var.rule_direction == "INGRESS" && length(regexall(".*./..*", each.value.source_destination)) == 0 ? [each.value.source_destination] : null

  dynamic "allow" {
    for_each = each.value.action == "allow" ? [""] : []
    content {
      protocol = each.value.protocol
      ports    = contains(["all", "icmp", "esp"], each.value.protocol) ? null : split(",", each.value.ports)
    }
  }

  dynamic "deny" {
    for_each = each.value.action == "deny" ? [""] : []
    content {
      protocol = each.value.protocol
      ports    = contains(["all", "icmp", "esp"], each.value.protocol) ? null : split(",", each.value.ports)
    }
  }
}
