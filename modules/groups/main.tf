terraform {
  required_providers {
    nsxt = {
      source = "vmware/nsxt"
    }
  }
}

locals {
  tenant_key  = var.tenant_id
  tenant_data = var.inventory[local.tenant_key]
  tenant_tag  = var.tenant_tag

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
      # Only process apps that have sub-applications (not direct VM arrays and not new structure with vms/ips)
      !can(app[0]) && !can(app.vms) ? [
        for sub_app_key, sub_app in app : {
          sub_app_key = sub_app_key
          app_key     = app_key
          env_key     = env_key
        }
        # Exclude vms and ips keys from being treated as sub-applications
        if sub_app_key != "vms" && sub_app_key != "ips"
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

  # Extract IP addresses from applications (both direct apps and sub-applications)
  application_ips = {
    for env_key, env in local.environments :
    env_key => {
      for app_key, app in env :
      app_key => {
        # Handle new structure with explicit ips key
        ips = try(app.ips, [])
        # Handle direct app case (can index with [0])
        has_direct_structure = can(app[0])
        # Handle new structure case (has vms/ips keys)
        has_new_structure = can(app.vms)
      }
      # Only include applications that actually exist and have the new structure
      if can(app.ips)
    }
  }

  # Extract IP addresses from sub-applications
  sub_application_ips = {
    for sa in local.sub_application_data :
    sa.sub_app_key => try(local.environments[sa.env_key][sa.app_key][sa.sub_app_key].ips, [])
    # Only include if the sub-application actually has IPs
    if can(local.environments[sa.env_key][sa.app_key][sa.sub_app_key].ips)
  }

  # Get the external services data
  external_services = try(local.tenant_data.external, {})

  # Get the set of all external service keys (names)
  external_service_keys = toset(keys(local.external_services))

  # Emergency groups and IP processing
  emergency_data = try(local.tenant_data.emergency, {})
  emergency_keys = toset(keys(local.emergency_data))
  
  # Extract IP addresses from emergency groups
  emergency_ips = {
    for emg_key, emg_data in local.emergency_data :
    emg_key => try(emg_data.ips, [])
    # Only include if the emergency group actually has IPs
    if can(emg_data.ips)
  }

  # Consumer and provider groups
  consumer_data = try(local.tenant_data.consumer, {})
  provider_data = try(local.tenant_data.provider, {})

  # Get the set of all consumer and provider keys (names)
  consumer_keys = toset(keys(local.consumer_data))
  provider_keys = toset(keys(local.provider_data))

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
  description  = "Group for all resources in tenant ${local.tenant_key}"
  domain       = "default"

  dynamic "context" {
    for_each = var.project_id != null ? [1] : []
    content {
      project_id = var.project_id
    }
  }

  # Add tags to identify the group
  tag {
    scope = "type"
    tag   = "tenant-group"
  }

  tag {
    scope = "tenant"
    tag   = local.tenant_tag
  }

  tag {
    scope = "managed-by"
    tag   = "terraform"
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

  display_name = each.key
  description  = "Group for environment ${each.key} in tenant ${local.tenant_key}"
  domain       = "default"

  dynamic "context" {
    for_each = var.project_id != null ? [1] : []
    content {
      project_id = var.project_id
    }
  }

  # Add tags to identify the group
  tag {
    scope = "type"
    tag   = "environment-group"
  }

  tag {
    scope = "tenant"
    tag   = local.tenant_tag
  }

  tag {
    scope = "environment"
    tag   = each.key
  }

  tag {
    scope = "managed-by"
    tag   = "terraform"
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

  display_name = each.key
  description  = "Group for application ${each.key} in tenant ${local.tenant_key}"
  domain       = "default"

  dynamic "context" {
    for_each = var.project_id != null ? [1] : []
    content {
      project_id = var.project_id
    }
  }

  # Add tags to identify the group
  tag {
    scope = "type"
    tag   = "application-group"
  }

  tag {
    scope = "tenant"
    tag   = local.tenant_tag
  }

  tag {
    scope = "environment"
    tag   = local.app_to_env[each.key]
  }

  tag {
    scope = "application"
    tag   = each.key
  }

  tag {
    scope = "managed-by"
    tag   = "terraform"
  }

  # Create criteria for IP addresses (if any exist)
  dynamic "criteria" {
    for_each = length(try(local.application_ips[local.app_to_env[each.key]][each.key].ips, [])) > 0 ? [1] : []
    
    content {
      ipaddress_expression {
        ip_addresses = toset(flatten([try(local.application_ips[local.app_to_env[each.key]][each.key].ips, [])]))
      }
    }
  }

  # Add conjunction if both IP addresses and VMs exist
  dynamic "conjunction" {
    for_each = length(try(local.application_ips[local.app_to_env[each.key]][each.key].ips, [])) > 0 ? [1] : []
    
    content {
      operator = "OR"
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

  display_name = each.key
  description  = "Group for sub-application ${each.key} in tenant ${local.tenant_key}"
  domain       = "default"

  dynamic "context" {
    for_each = var.project_id != null ? [1] : []
    content {
      project_id = var.project_id
    }
  }

  # Add tags to identify the group
  tag {
    scope = "type"
    tag   = "sub-application-group"
  }

  tag {
    scope = "tenant"
    tag   = local.tenant_tag
  }

  tag {
    scope = "environment"
    tag   = local.sub_app_to_app_env[each.key].env_key
  }

  tag {
    scope = "application"
    tag   = local.sub_app_to_app_env[each.key].app_key
  }

  tag {
    scope = "sub-application"
    tag   = each.key
  }

  tag {
    scope = "managed-by"
    tag   = "terraform"
  }

  # Create criteria for IP addresses (if any exist)
  dynamic "criteria" {
    for_each = length(try(local.sub_application_ips[each.key], [])) > 0 ? [1] : []
    
    content {
      ipaddress_expression {
        ip_addresses = toset(flatten([try(local.sub_application_ips[each.key], [])]))
      }
    }
  }

  # Add conjunction if both IP addresses and VMs exist
  dynamic "conjunction" {
    for_each = length(try(local.sub_application_ips[each.key], [])) > 0 ? [1] : []
    
    content {
      operator = "OR"
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

  display_name = each.key
  description  = "Group for external service ${each.key} in tenant ${local.tenant_key}"
  domain       = "default"

  dynamic "context" {
    for_each = var.project_id != null ? [1] : []
    content {
      project_id = var.project_id
    }
  }

  # Add tags to identify the group
  tag {
    scope = "type"
    tag   = "external-service-group"
  }

  tag {
    scope = "tenant"
    tag   = local.tenant_tag
  }

  tag {
    scope = "external-service"
    tag   = each.key
  }

  tag {
    scope = "managed-by"
    tag   = "terraform"
  }

  # Create criteria for IP addresses/CIDRs (if any exist)
  dynamic "criteria" {
    for_each = length(try(local.external_services[each.key].ips, [])) > 0 || length([
      for entry in try(local.external_services[each.key], []) : entry
      if can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}(/[0-9]{1,2})?$", entry))
    ]) > 0 ? [1] : []
    
    content {
      ipaddress_expression {
        ip_addresses = toset(concat(
          # New structure - explicit ips key
          try(local.external_services[each.key].ips, []),
          # Fallback to old structure - detect IPs in flat array
          [
            for entry in try(local.external_services[each.key], []) : entry
            if can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}(/[0-9]{1,2})?$", entry))
          ]
        ))
      }
    }
  }

  # Add conjunction if both IP addresses and VMs exist
  dynamic "conjunction" {
    for_each = (length(try(local.external_services[each.key].ips, [])) > 0 || length([
      for entry in try(local.external_services[each.key], []) : entry
      if can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}(/[0-9]{1,2})?$", entry))
    ]) > 0) && (length(try(local.external_services[each.key].vms, [])) > 0 || length([
      for entry in try(local.external_services[each.key], []) : entry
      if !can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}(/[0-9]{1,2})?$", entry))
    ]) > 0) ? [1] : []
    
    content {
      operator = "OR"
    }
  }

  # Create criteria for VM names (if any exist)
  dynamic "criteria" {
    for_each = length(try(local.external_services[each.key].vms, [])) > 0 || length([
      for entry in try(local.external_services[each.key], []) : entry
      if !can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}(/[0-9]{1,2})?$", entry))
    ]) > 0 ? [1] : []
    
    content {
      condition {
        key         = "Tag"
        member_type = "VirtualMachine"
        operator    = "EQUALS"
        value       = each.key
      }
    }
  }
}

# Create a group for each emergency
resource "nsxt_policy_group" "emergency_groups" {
  for_each = local.emergency_keys

  display_name = each.key
  description  = "Emergency group ${each.key} in tenant ${local.tenant_key}"
  domain       = "default"

  dynamic "context" {
    for_each = var.project_id != null ? [1] : []
    content {
      project_id = var.project_id
    }
  }

  # Add tags to identify the group
  tag {
    scope = "type"
    tag   = "emergency-group"
  }

  tag {
    scope = "tenant"
    tag   = local.tenant_tag
  }

  tag {
    scope = "emergency"
    tag   = each.key
  }

  tag {
    scope = "managed-by"
    tag   = "terraform"
  }

  # Create criteria for IP addresses (if any exist)
  dynamic "criteria" {
    for_each = length(try(local.emergency_ips[each.key], [])) > 0 ? [1] : []
    
    content {
      ipaddress_expression {
        ip_addresses = toset(flatten([try(local.emergency_ips[each.key], [])]))
      }
    }
  }

  # Add conjunction if both IP addresses and VMs exist
  dynamic "conjunction" {
    for_each = length(try(local.emergency_ips[each.key], [])) > 0 ? [1] : []
    
    content {
      operator = "OR"
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

# Create a group for each consumer group
resource "nsxt_policy_group" "consumer_groups" {
  for_each = local.consumer_keys

  display_name = each.key
  description  = "Consumer group ${each.key} in tenant ${local.tenant_key}"
  domain       = "default"

  dynamic "context" {
    for_each = var.project_id != null ? [1] : []
    content {
      project_id = var.project_id
    }
  }

  # Add tags to identify the group
  tag {
    scope = "type"
    tag   = "consumer-group"
  }

  tag {
    scope = "tenant"
    tag   = local.tenant_tag
  }

  tag {
    scope = "consumer"
    tag   = each.key
  }

  tag {
    scope = "managed-by"
    tag   = "terraform"
  }

  # Create single criteria block with all member group paths
  criteria {
    path_expression {
      member_paths = [
        for member in local.consumer_data[each.key] :
        # Check if it's an external service group
        contains(local.external_service_keys, member) ? nsxt_policy_group.external_service_groups[member].path :
        # Check if it's an application group  
        contains(local.application_keys, member) ? nsxt_policy_group.application_groups[member].path :
        # Check if it's an environment group
        contains(local.environment_keys, member) ? nsxt_policy_group.environment_groups[member].path :
        # Check if it's a sub-application group
        contains(local.sub_application_keys, member) ? nsxt_policy_group.sub_application_groups[member].path :
        # Default to treating as external service if not found
        "/infra/domains/default/groups/${member}"
      ]
    }
  }

  depends_on = [
    nsxt_policy_group.external_service_groups,
    nsxt_policy_group.application_groups,
    nsxt_policy_group.environment_groups,
    nsxt_policy_group.sub_application_groups
  ]
}

# Create a group for each provider group
resource "nsxt_policy_group" "provider_groups" {
  for_each = local.provider_keys

  display_name = each.key
  description  = "Provider group ${each.key} in tenant ${local.tenant_key}"
  domain       = "default"

  dynamic "context" {
    for_each = var.project_id != null ? [1] : []
    content {
      project_id = var.project_id
    }
  }

  # Add tags to identify the group
  tag {
    scope = "type"
    tag   = "provider-group"
  }

  tag {
    scope = "tenant"
    tag   = local.tenant_tag
  }

  tag {
    scope = "provider"
    tag   = each.key
  }

  tag {
    scope = "managed-by"
    tag   = "terraform"
  }

  # Create single criteria block with all member group paths
  criteria {
    path_expression {
      member_paths = [
        for member in local.provider_data[each.key] :
        # Check if it's an external service group
        contains(local.external_service_keys, member) ? nsxt_policy_group.external_service_groups[member].path :
        # Check if it's an application group  
        contains(local.application_keys, member) ? nsxt_policy_group.application_groups[member].path :
        # Check if it's an environment group
        contains(local.environment_keys, member) ? nsxt_policy_group.environment_groups[member].path :
        # Check if it's a sub-application group
        contains(local.sub_application_keys, member) ? nsxt_policy_group.sub_application_groups[member].path :
        # Default to treating as external service if not found
        "/infra/domains/default/groups/${member}"
      ]
    }
  }

  depends_on = [
    nsxt_policy_group.external_service_groups,
    nsxt_policy_group.application_groups,
    nsxt_policy_group.environment_groups,
    nsxt_policy_group.sub_application_groups
  ]
} 