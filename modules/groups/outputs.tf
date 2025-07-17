output "tenant_group_id" {
  description = "ID of the tenant group"
  value       = nsxt_policy_group.tenant_group.path
}

output "tenant_group_details" {
  description = "Detailed information about the tenant group configuration"
  value = {
    display_name = nsxt_policy_group.tenant_group.display_name
    description  = nsxt_policy_group.tenant_group.description
    path         = nsxt_policy_group.tenant_group.path
    criteria = {
      tag_criteria = {
        key         = "Tag"
        member_type = "VirtualMachine"
        operator    = "EQUALS"
        value       = local.tenant_tag
      }
    }
  }
}

output "environment_groups" {
  description = "Map of environment group paths"
  value = {
    for env_key, env in nsxt_policy_group.environment_groups : env_key => env.path
  }
}

output "environment_groups_details" {
  description = "Detailed information about environment groups configuration"
  value = {
    for env_key, env in nsxt_policy_group.environment_groups : env_key => {
      display_name = env.display_name
      description  = env.description
      path         = env.path
      criteria = {
        tag_criteria = {
          key         = "Tag"
          member_type = "VirtualMachine"
          operator    = "EQUALS"
          value       = env_key
        }
      }
    }
  }
}

output "application_groups" {
  description = "Map of application group paths"
  value = {
    for app_key, app in nsxt_policy_group.application_groups : app_key => app.path
  }
}

output "application_groups_details" {
  description = "Detailed information about application groups configuration"
  value = {
    for app_key, app in nsxt_policy_group.application_groups : app_key => {
      display_name = app.display_name
      description  = app.description
      path         = app.path
      criteria = {
        tag_criteria = {
          key         = "Tag"
          member_type = "VirtualMachine"
          operator    = "EQUALS"
          value       = app_key
        }
      }
    }
  }
}

output "sub_application_groups" {
  description = "Map of sub-application group paths"
  value = {
    for sub_app_key, sub_app in nsxt_policy_group.sub_application_groups : sub_app_key => sub_app.path
  }
}

output "sub_application_groups_details" {
  description = "Detailed information about sub-application groups configuration"
  value = {
    for sub_app_key, sub_app in nsxt_policy_group.sub_application_groups : sub_app_key => {
      display_name = sub_app.display_name
      description  = sub_app.description
      path         = sub_app.path
      criteria = {
        tag_criteria = {
          key         = "Tag"
          member_type = "VirtualMachine"
          operator    = "EQUALS"
          value       = sub_app_key
        }
      }
    }
  }
}

output "external_service_groups" {
  description = "Map of external service group paths"
  value = {
    for ext_key, ext in nsxt_policy_group.external_service_groups : ext_key => ext.path
  }
}

output "external_service_groups_details" {
  description = "Detailed information about external service groups configuration with IP addresses"
  value = {
    for ext_key, ext in nsxt_policy_group.external_service_groups : ext_key => {
      display_name = ext.display_name
      description  = ext.description
      path         = ext.path
      ip_addresses = local.external_services[ext_key]
    }
  }
}

output "emergency_groups" {
  description = "Map of emergency group paths"
  value = {
    for emergency_key, emergency in nsxt_policy_group.emergency_groups : emergency_key => emergency.path
  }
}

output "emergency_groups_details" {
  description = "Detailed information about emergency groups configuration"
  value = {
    for emergency_key, emergency in nsxt_policy_group.emergency_groups : emergency_key => {
      display_name  = emergency.display_name
      description   = emergency.description
      path          = emergency.path
      vm_members    = try(local.emergency_data[emergency_key].vms, try(tolist(local.emergency_data[emergency_key]), []))
      ip_members    = try(local.emergency_data[emergency_key].ips, [])
      criteria_type = length(try(local.emergency_data[emergency_key].vms, try(tolist(local.emergency_data[emergency_key]), []))) > 0 || length(try(local.emergency_data[emergency_key].ips, [])) > 0 ? "mixed" : "empty"
    }
  }
}

output "consumer_groups" {
  description = "Map of consumer group paths"
  value = {
    for consumer_key, consumer in nsxt_policy_group.consumer_groups : consumer_key => consumer.path
  }
}

output "consumer_groups_details" {
  description = "Detailed information about consumer groups configuration"
  value = {
    for consumer_key, consumer in nsxt_policy_group.consumer_groups : consumer_key => {
      display_name    = consumer.display_name
      description     = consumer.description
      path            = consumer.path
      member_groups   = try(local.consumer_data[consumer_key], [])
      criteria_type   = "path_expression"
    }
  }
}

output "provider_groups" {
  description = "Map of provider group paths"
  value = {
    for provider_key, provider in nsxt_policy_group.provider_groups : provider_key => provider.path
  }
}

output "provider_groups_details" {
  description = "Detailed information about provider groups configuration"
  value = {
    for provider_key, provider in nsxt_policy_group.provider_groups : provider_key => {
      display_name    = provider.display_name
      description     = provider.description
      path            = provider.path
      member_groups   = try(local.provider_data[provider_key], [])
      criteria_type   = "path_expression"
    }
  }
} 