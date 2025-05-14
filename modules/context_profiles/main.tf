terraform {
  required_providers {
    nsxt = {
      source = "vmware/nsxt"
    }
  }
}

# Data source for predefined NSX context profiles
data "nsxt_policy_context_profile" "predefined_profiles" {
  for_each = toset(local.predefined_profile_names)
  display_name = each.value
}

locals {
  tenant_key = var.tenant_id
  tenant_data = var.authorized_flows[local.tenant_key]
  
  # Extract all predefined context profile names from application policies
  predefined_profile_names = distinct(flatten([
    for rule in try(local.tenant_data.application_policy, []) : 
      try(rule.context_profiles, [])
  ]))
  
  # Extract custom context profile definitions from application policies
  custom_profile_definitions = [
    for rule in try(local.tenant_data.application_policy, []) : {
      name = rule.name
      app_ids = try(rule.context_profile_attributes.app_id, [])
      domains = try(rule.context_profile_attributes.domain, [])
    }
    if try(rule.context_profile_attributes, null) != null && 
      (try(length(rule.context_profile_attributes.app_id), 0) > 0 || 
       try(length(rule.context_profile_attributes.domain), 0) > 0)
  ]
}

# Create NSX context profiles for each custom profile definition
resource "nsxt_policy_context_profile" "custom_profile" {
  for_each = {
    for idx, profile in local.custom_profile_definitions : 
      "profile-${local.tenant_key}-${profile.name}" => profile
  }
  
  display_name = "cp-${local.tenant_key}-${each.value.name}"
  description  = "Custom context profile for ${each.value.name}"
  
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

# Output map of all context profiles (both predefined and custom)
# The key is the profile name used in YAML and the value is the NSX path
output "context_profiles" {
  description = "Map of context profile names to NSX paths"
  value = merge(
    # For predefined profiles, map name -> path 
    {
      for name, profile in data.nsxt_policy_context_profile.predefined_profiles :
      name => profile.path
    },
    # For custom profiles, map name -> path
    {
      for name, profile in nsxt_policy_context_profile.custom_profile :
      trimsuffix(trimprefix(name, "profile-${local.tenant_key}-"), "") => profile.path
    }
  )
} 