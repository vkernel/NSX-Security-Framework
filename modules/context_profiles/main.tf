terraform {
  required_providers {
    nsxt = {
      source = "vmware/nsxt"
    }
  }
}

# Data source for predefined NSX context profiles
data "nsxt_policy_context_profile" "predefined_profiles" {
  for_each     = toset(local.predefined_profile_names)
  display_name = each.value
}

locals {
  tenant_key       = var.tenant_id
  tenant_data      = var.authorized_flows[local.tenant_key]
  tenant_inventory = var.inventory[local.tenant_key]

  # Get application policies from authorized flows (not inventory)
  authorized_flows_data = var.authorized_flows[local.tenant_key]
  application_policies = try(local.authorized_flows_data.application_policy, {})

  # Extract all predefined context profile names from application policies
  predefined_profile_names = distinct(flatten([
    for policy_key, rules in local.application_policies : [
      for rule in rules :
      try(rule.context_profiles, [])
    ]
  ]))

  # Extract custom context profile references from application policies
  custom_profile_references = distinct(flatten([
    for policy_key, rules in local.application_policies : [
      for rule in rules :
      try(rule.custom_context_profiles, [])
    ]
  ]))

  # Get custom context profile definitions from inventory file
  custom_profile_definitions = [
    for profile_name, profile_attrs in try(local.tenant_inventory.custom_context_profiles, {}) : {
      name    = profile_name
      app_ids = try(profile_attrs.app_id, [])
      domains = try(profile_attrs.domain, [])
    }
    if profile_attrs != null && (
      try(length(profile_attrs.app_id), 0) > 0 ||
      try(length(profile_attrs.domain), 0) > 0
    )
  ]
}

# Create NSX context profiles for each custom profile definition
resource "nsxt_policy_context_profile" "custom_profile" {
  for_each = {
    for profile in local.custom_profile_definitions :
    profile.name => profile
  }

  display_name = each.key
  description  = "Custom context profile for ${each.key}"

  dynamic "context" {
    for_each = var.project_id != null ? [1] : []
    content {
      project_id = var.project_id
    }
  }

  # Add App IDs if specified - only one app_id block is allowed with multiple values
  dynamic "app_id" {
    for_each = length(each.value.app_ids) > 0 ? [1] : []
    content {
      value = toset(each.value.app_ids)
    }
  }

  # Add Domain names if specified - only one domain_name block is allowed with multiple values
  dynamic "domain_name" {
    for_each = length(each.value.domains) > 0 ? [1] : []
    content {
      value = toset(each.value.domains)
    }
  }
} 