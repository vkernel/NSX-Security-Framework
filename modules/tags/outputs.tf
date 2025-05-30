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

output "vm_tag_assignments" {
  description = "Detailed mapping of all tag assignments by VM"
  value = {
    for vm, vm_data in local.vm_base_data : vm => {
      instance_id  = try(data.nsxt_policy_vm.vms[vm].instance_id, null)
      display_name = vm
      tenant_tag = {
        scope = "tenant"
        tag   = local.tenant_tag
      }
      environment_tag = {
        scope = "environment"
        tag   = vm_data.env_key
      }
      application_tags = [
        for app_tag in local.app_tags_by_vm[vm] : {
          scope = "application"
          tag   = app_tag
        }
      ]
      sub_application_tags = [
        for sub_app_tag in local.sub_app_tags_by_vm[vm] : {
          scope = "sub-application"
          tag   = sub_app_tag
        }
        if sub_app_tag != null
      ]
      emergency_tag = lookup(local.emergency_vm_tags, vm, null) != null ? {
        scope = "emergency"
        tag   = local.emergency_vm_tags[vm]
      } : null
    }
  }
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