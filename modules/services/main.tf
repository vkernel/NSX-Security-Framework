terraform {
  required_providers {
    nsxt = {
      source = "vmware/nsxt"
    }
  }
}

# Data source for predefined NSX services
data "nsxt_policy_service" "predefined_services" {
  for_each     = toset(local.predefined_service_names)
  display_name = each.value
}

locals {
  tenant_key  = var.tenant_id
  tenant_data = var.inventory[local.tenant_key]
  
  # Get application policies from authorized flows (not inventory)
  authorized_flows_data = var.authorized_flows[local.tenant_key]
  application_policies = try(local.authorized_flows_data.application_policy, {})

  # Get custom services from both authorized flows and inventory
  # Depending on the version, they could be in either place
  custom_services_in_authorized_flows = try(var.authorized_flows[local.tenant_key].custom_services, {})
  custom_services_in_inventory        = try(local.tenant_data.custom_services, {})

  # Combine both maps, with inventory taking precedence if duplicates exist
  custom_services = merge(local.custom_services_in_authorized_flows, local.custom_services_in_inventory)

  # Extract all predefined service names from application policies in authorized flows
  predefined_service_names = distinct(flatten([
    for policy_key, rules in local.application_policies : [
      for rule in rules :
      try(rule.services, [])
    ]
  ]))

  # Extract custom service references from application policies in authorized flows
  custom_service_references = distinct(flatten([
    for policy_key, rules in local.application_policies : [
      for rule in rules :
      try(rule.custom_services, [])
    ]
  ]))

  # Get custom service definitions from inventory file
  custom_service_definitions = [
    for service_name, service_attrs in try(local.tenant_data.custom_services, {}) : {
      name     = service_name
      protocol = try(service_attrs.protocol, "tcp")
      ports    = try(service_attrs.ports, [])
    }
    if service_attrs != null && try(length(service_attrs.ports), 0) > 0
  ]
}

# Create custom services
resource "nsxt_policy_service" "custom_services" {
  for_each = local.custom_services

  display_name = each.key
  description  = "Custom service for ${each.key}"

  dynamic "context" {
    for_each = var.project_id != null ? [1] : []
    content {
      project_id = var.project_id
    }
  }

  # TCP/UDP services
  dynamic "l4_port_set_entry" {
    for_each = each.value.protocol == "tcp" || each.value.protocol == "udp" ? [1] : []
    content {
      display_name      = "port-${each.key}"
      protocol          = upper(each.value.protocol)
      destination_ports = [for port in each.value.ports : tostring(port)]
    }
  }

  # ICMPv4 services
  dynamic "icmp_entry" {
    for_each = each.value.protocol == "icmp" || each.value.protocol == "icmpv4" ? [1] : []
    content {
      display_name = "icmp-${each.key}"
      protocol     = "ICMPv4"
      icmp_type    = try(each.value.icmp_type, null)
      icmp_code    = try(each.value.icmp_code, null)
    }
  }

  # ICMPv6 services
  dynamic "icmp_entry" {
    for_each = each.value.protocol == "icmpv6" ? [1] : []
    content {
      display_name = "icmpv6-${each.key}"
      protocol     = "ICMPv6"
      icmp_type    = try(each.value.icmp_type, null)
      icmp_code    = try(each.value.icmp_code, null)
    }
  }

  # IP protocol services
  dynamic "ip_protocol_entry" {
    for_each = each.value.protocol == "ip" ? [1] : []
    content {
      display_name = "ip-${each.key}"
      protocol     = tonumber(each.value.protocol_number)
    }
  }

  # IGMP services
  dynamic "igmp_entry" {
    for_each = each.value.protocol == "igmp" ? [1] : []
    content {
      display_name = "igmp-${each.key}"
    }
  }

  # ALG (Application Layer Gateway) services
  # Note: ALG services may require specific NSX versions and provider support
  # For now, ALG services can be created as L4 port services with TCP/UDP protocols
  dynamic "l4_port_set_entry" {
    for_each = each.value.protocol == "alg" ? [1] : []
    content {
      display_name      = "alg-${each.key}"
      protocol          = "TCP"
      destination_ports = [tostring(try(each.value.destination_port, 80))]
    }
  }
} 