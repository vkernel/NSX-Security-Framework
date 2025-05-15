terraform {
  required_providers {
    nsxt = {
      source = "vmware/nsxt"
    }
  }
}

# Data source for predefined NSX services
data "nsxt_policy_service" "predefined_services" {
  for_each = toset(local.predefined_service_names)
  display_name = each.value
}

locals {
  tenant_key = var.tenant_id
  tenant_data = var.authorized_flows[local.tenant_key]
  tenant_inventory = var.inventory[local.tenant_key]
  
  # Extract all predefined service names from application policies
  predefined_service_names = distinct(flatten([
    for rule in try(local.tenant_data.application_policy, []) : 
      try(rule.services, [])
  ]))
  
  # Extract custom service references from application policies
  custom_service_references = distinct(flatten([
    for rule in try(local.tenant_data.application_policy, []) :
      try(rule.custom_services, [])
  ]))
  
  # Get custom service definitions from inventory file
  custom_service_definitions = [
    for service_name, service_attrs in try(local.tenant_inventory.custom_services, {}) : {
      name = service_name
      protocol = try(service_attrs.protocol, "tcp")
      ports = try(service_attrs.ports, [])
    }
    if service_attrs != null && try(length(service_attrs.ports), 0) > 0
  ]
}

# Create NSX services for each custom service definition
resource "nsxt_policy_service" "custom_service" {
  for_each = {
    for service in local.custom_service_definitions : 
      service.name => service
  }
  
  display_name = each.key
  description  = "Custom service for ${each.key}"
  
  dynamic "l4_port_set_entry" {
    for_each = each.value.protocol == "tcp" || each.value.protocol == "udp" ? [each.value] : []
    content {
      display_name      = "port-${each.key}"
      protocol          = upper(each.value.protocol)
      destination_ports = [for port in each.value.ports : tostring(port)]
    }
  }
  
  dynamic "icmp_entry" {
    for_each = each.value.protocol == "icmp" ? [each.value] : []
    content {
      display_name = "icmp-${each.key}"
      protocol     = "ICMPv4"
    }
  }
} 