output "tenant_tag" {
  description = "The tenant tag used for this tenant"
  value       = local.tenant_tag
}

output "tenant_vms" {
  description = "List of all VMs in the tenant"
  value = flatten([
    for env_key, env_data in local.environments : [
      for app_key, app_data in env_data : [
        for sub_app_key, sub_app_vms in app_data : [
          for vm in sub_app_vms : vm
          if can(sub_app_vms[0])
        ]
        if can(sub_app_vms[0])
      ]
    ]
  ])
}

output "external_service_vms" {
  description = "List of all external service VMs"
  value       = local.external_service_vms
}

output "vm_tag_assignments" {
  value = {
    for vm in local.all_vms_including_external : vm => {
      vm_name      = vm
      instance_id  = try(local.found_vms[vm], null)
      tenant_tag   = local.tenant_tag
      environment_tag = contains(local.all_vms, vm) ? local.vm_base_data[vm].env_key : null
      application_tags = contains(local.all_vms, vm) ? local.app_tags_by_vm[vm] : []
      sub_application_tags = contains(local.all_vms, vm) ? local.sub_app_tags_by_vm[vm] : []
      emergency_tag = contains(local.all_vms, vm) ? lookup(local.emergency_vm_tags, vm, null) : null
      external_service_tag = lookup(local.external_service_vm_tags, vm, null)
    }
  }
  description = "List of VMs and their tag assignments"
}

output "tag_hierarchy_summary" {
  description = "Summary of the tag hierarchy structure showing the relationship between environments, applications, and sub-applications"
  value = {
    for env_key, env_data in local.environments : env_key => {
      applications = {
        for app_key, app_data in env_data : app_key => {
          is_direct_vm_list = can(app_data[0])
          sub_applications  = can(app_data[0]) ? null : keys(app_data)
          vm_count = can(app_data[0]) ? length(app_data) : sum([
            for sub_app_key, sub_app_data in app_data : length(sub_app_data)
          ])
        }
      }
    }
  }
}

output "emergency_vm_assignments" {
  description = "Mapping of emergency groups to their assigned VMs"
  value = {
    for emg_key, emg_list in local.emergency : emg_key => {
      vms      = compact(coalesce(emg_list, []))
      vm_count = length(compact(coalesce(emg_list, [])))
    }
    if try(local.tenant_data.emergency, null) != null
  }
} 