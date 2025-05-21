terraform {
  required_providers {
    nsxt = {
      source = "vmware/nsxt"
    }
  }
}

locals {
  tenant_key = var.tenant_id
  tenant_data = var.inventory[local.tenant_key]
  tenant_tag = var.tenant_tag
  
  # Extract environment data
  environments = local.tenant_data.internal
  
  # Get the set of all environment keys (names) 
  environment_keys = toset(keys(local.environments))
  
  # Get the set of all application keys (names)
  application_keys = toset(flatten([
    for env_key, env in local.environments : [
      for app_key, app in env : app_key
    ]
  ]))
  
  # Create a mapping of application key to its environment key
  app_to_env = {
    for app_key in local.application_keys : app_key => [
      for env_key, env in local.environments : 
      env_key if contains(keys(env), app_key)
    ][0]
  }
  
  # Get the set of all sub-application keys (names)
  sub_application_data = flatten([
    for env_key, env in local.environments : [
      for app_key, app in env : 
      # Only process apps that have sub-applications (can't index with [0])
      !can(app[0]) ? [
        for sub_app_key, sub_app in app : {
          sub_app_key = sub_app_key
          app_key = app_key
          env_key = env_key
        }
      ] : []
    ]
  ])
  
  sub_application_keys = toset([
    for sa in local.sub_application_data : sa.sub_app_key
  ])
  
  # Create a mapping of sub-application key to its application and environment keys
  sub_app_to_app_env = {
    for sa in local.sub_application_data : sa.sub_app_key => {
      app_key = sa.app_key
      env_key = sa.env_key
    }
  }
  
  # Get the external services data
  external_services = try(local.tenant_data.external, {})
  
  # Get the set of all external service keys (names)
  external_service_keys = toset(keys(local.external_services))
  
  # Emergency groups
  emergency_keys = toset(keys(try(local.tenant_data.emergency, {})))
  
  # Set up context block for NSX projects
  context_block = var.project_id != null ? {
    context = {
      project_id = var.project_id
    }
  } : {}
}

# Create group for the tenant
resource "nsxt_policy_group" "tenant_group" {
  display_name = "ten-${local.tenant_key}"
  description = "Group for all resources in tenant ${local.tenant_key}"
  domain = "default"
  
  dynamic "context" {
    for_each = var.project_id != null ? [1] : []
    content {
      project_id = var.project_id
    }
  }
  
  criteria {
    condition {
      key         = "Tag"
      member_type = "VirtualMachine"
      operator    = "EQUALS"
      value       = local.tenant_tag
    }
  }
}

# Create a group for each environment
resource "nsxt_policy_group" "environment_groups" {
  for_each = local.environment_keys

  display_name = "${each.key}"
  description = "Group for environment ${each.key} in tenant ${local.tenant_key}"
  domain = "default"
  
  dynamic "context" {
    for_each = var.project_id != null ? [1] : []
    content {
      project_id = var.project_id
    }
  }
  
  criteria {
    condition {
      key         = "Tag"
      member_type = "VirtualMachine"
      operator    = "EQUALS"
      value       = each.key
    }
  }
  
  # Also require that VM is part of the tenant
  conjunction {
    operator = "AND"
  }
  
  criteria {
    condition {
      key         = "Tag"
      member_type = "VirtualMachine"
      operator    = "EQUALS"
      value       = local.tenant_tag
    }
  }
}

# Create a group for each application
resource "nsxt_policy_group" "application_groups" {
  for_each = local.application_keys

  display_name = "${each.key}"
  description = "Group for application ${each.key} in tenant ${local.tenant_key}"
  domain = "default"
  
  dynamic "context" {
    for_each = var.project_id != null ? [1] : []
    content {
      project_id = var.project_id
    }
  }
  
  criteria {
    condition {
      key         = "Tag"
      member_type = "VirtualMachine"
      operator    = "EQUALS"
      value       = each.key
    }
  }
  
  # Also require that VM is part of the tenant and in the correct environment
  conjunction {
    operator = "AND"
  }
  
  criteria {
    condition {
      key         = "Tag"
      member_type = "VirtualMachine"
      operator    = "EQUALS"
      value       = local.tenant_tag
    }
  }
  
  conjunction {
    operator = "AND"
  }
  
  criteria {
    condition {
      key         = "Tag"
      member_type = "VirtualMachine"
      operator    = "EQUALS"
      value       = local.app_to_env[each.key]
    }
  }
}

# Create a group for each sub-application
resource "nsxt_policy_group" "sub_application_groups" {
  for_each = local.sub_application_keys

  display_name = "${each.key}"
  description = "Group for sub-application ${each.key} in tenant ${local.tenant_key}"
  domain = "default"
  
  dynamic "context" {
    for_each = var.project_id != null ? [1] : []
    content {
      project_id = var.project_id
    }
  }
  
  criteria {
    condition {
      key         = "Tag"
      member_type = "VirtualMachine"
      operator    = "EQUALS"
      value       = each.key
    }
  }
  
  # Also require that VM is part of the tenant, in the correct environment, and part of the parent application
  conjunction {
    operator = "AND"
  }
  
  criteria {
    condition {
      key         = "Tag"
      member_type = "VirtualMachine"
      operator    = "EQUALS"
      value       = local.tenant_tag
    }
  }
  
  conjunction {
    operator = "AND"
  }
  
  criteria {
    condition {
      key         = "Tag"
      member_type = "VirtualMachine"
      operator    = "EQUALS"
      value       = local.sub_app_to_app_env[each.key].env_key
    }
  }
  
  conjunction {
    operator = "AND"
  }
  
  criteria {
    condition {
      key         = "Tag"
      member_type = "VirtualMachine"
      operator    = "EQUALS"
      value       = local.sub_app_to_app_env[each.key].app_key
    }
  }
}

# Create a group for each external service
resource "nsxt_policy_group" "external_service_groups" {
  for_each = local.external_service_keys

  display_name = "${each.key}"
  description = "Group for external service ${each.key} in tenant ${local.tenant_key}"
  domain = "default"
  
  dynamic "context" {
    for_each = var.project_id != null ? [1] : []
    content {
      project_id = var.project_id
    }
  }
  
  dynamic "criteria" {
    for_each = toset(local.external_services[each.key])
    
    content {
      ipaddress_expression {
        ip_addresses = [criteria.value]
      }
    }
  }
}

# Create a group for each emergency
resource "nsxt_policy_group" "emergency_groups" {
  for_each = local.emergency_keys

  display_name = "${each.key}"
  description = "Emergency group ${each.key} in tenant ${local.tenant_key}"
  domain = "default"
  
  dynamic "context" {
    for_each = var.project_id != null ? [1] : []
    content {
      project_id = var.project_id
    }
  }
  
  criteria {
    condition {
      key         = "Tag"
      member_type = "VirtualMachine"
      operator    = "EQUALS"
      value       = each.key
    }
  }
  
  # Also require that VM is part of the tenant
  conjunction {
    operator = "AND"
  }
  
  criteria {
    condition {
      key         = "Tag"
      member_type = "VirtualMachine"
      operator    = "EQUALS"
      value       = local.tenant_tag
    }
  }
} 