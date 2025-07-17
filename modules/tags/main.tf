# NSX-T Provider
terraform {
  required_providers {
    nsxt = {
      source = "vmware/nsxt"
    }
    null = {
      source = "hashicorp/null"
    }
  }
}

locals {
  tenant_key = var.tenant_id

  # Get the tenant inventory data
  tenant_data = var.inventory[local.tenant_key]

  # Create tag format for tenant
  tenant_tag = "ten-${local.tenant_key}"

  # Extract environment data
  environments = local.tenant_data.internal

  # Process direct VMs (no sub-applications)
  direct_vms = flatten([
    for env_key, env in local.environments : [
      for app_key, app in env :
      # New structure: app has vms key
      can(app.vms) ? [
        for vm in tolist(app.vms) : {
          vm          = vm
          env_key     = env_key
          app_key     = app_key
          sub_app_key = null
        }
      ] : 
      # Old structure: app is a direct VM array
      can(app[0]) ? [
        for vm in tolist(app) : {
          vm          = vm
          env_key     = env_key
          app_key     = app_key
          sub_app_key = null
        }
      ] : []
    ]
  ])

  # Process VMs in sub-applications  
  sub_app_vms = flatten([
    for env_key, env in local.environments : [
      for app_key, app in env :
      # Only process if it's not a direct VM structure
      !can(app.vms) && !can(app[0]) ? flatten([
        for sub_app_key, sub_app in app : (
          # New structure: sub_app has vms key
          can(sub_app.vms) ? [
            for vm in tolist(sub_app.vms) : {
              vm          = vm
              env_key     = env_key
              app_key     = app_key
              sub_app_key = sub_app_key
            }
          ] :
          # Old structure: sub_app is VM array
          can(sub_app[0]) ? [
            for vm in tolist(sub_app) : {
              vm          = vm
              env_key     = env_key
              app_key     = app_key
              sub_app_key = sub_app_key
            }
          ] : []
        )
      ]) : []
    ]
  ])
  
  # Combine both types of VMs and deduplicate by VM name
  all_vm_data_combined = concat(local.direct_vms, local.sub_app_vms)

  # Set of all VM names (deduplicated)
  all_vms = toset([for vm_data in local.all_vm_data_combined : vm_data.vm])
  
  # Map VM→all application keys it belongs to
  app_tags_by_vm = {
    for vm in local.all_vms :
    vm => distinct([
      for d in local.all_vm_data_combined :
      d.app_key if d.vm == vm
    ])
  }
  
  # Map VM→all sub-application keys if any
  sub_app_tags_by_vm = {
    for vm in local.all_vms :
    vm => distinct([
      for d in local.all_vm_data_combined :
      d.sub_app_key if d.vm == vm && d.sub_app_key != null
    ])
  }

  # Get a single entry per VM for tenant and environment tags
  # We can use any entry since tenant/env should be the same regardless of app/sub-app
  vm_base_data = {
    for vm in local.all_vms : vm => (
      [for d in local.all_vm_data_combined : d if d.vm == vm][0]
    )
  }
  
  # Emergency stuff, if any
  emergency = try(local.tenant_data.emergency, {})

  # Create a mapping of VM name to emergency group keys - handle both new and old structure
  emergency_vm_tags = merge(
    [
      for emg_key, emg_data in local.emergency : merge(
        # New structure - explicit vms key
        {
          for vm in try(emg_data.vms, []) : tostring(vm) => emg_key
          if vm != null && vm != ""
        },
        # Fallback to old structure - flat array
        can(emg_data[0]) ? {
          for vm in tolist(emg_data) : tostring(vm) => emg_key
          if vm != null && vm != "" && can(tostring(vm))
        } : {}
      )
    ]...
  )

  # Derive the list of emergency VMs from the keys of the mapping
  emergency_vms = keys(local.emergency_vm_tags)

  # External services processing
  external_services = try(local.tenant_data.external, {})
  
  # Create a mapping of VM name to external service keys
  external_service_vm_tags = merge(
    [
      for ext_key, ext_data in local.external_services : merge(
        # New structure - explicit vms key
        {
          for vm in try(ext_data.vms, []) : vm => ext_key
        },
        # Fallback to old structure - detect VMs in flat array
        can(ext_data[0]) ? {
          for entry in ext_data : entry => ext_key
          # Only include entries that are NOT IP addresses/CIDRs (i.e., VM names)
          if !can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}(/[0-9]{1,2})?$", entry))
        } : {}
      )
    ]...
  )

  # Get external service VMs (VM names from external services)
  external_service_vms = keys(local.external_service_vm_tags)
  
  # Combine all VMs that need tagging (internal + external service VMs)
  all_vms_including_external = toset(concat(
    [for vm in local.all_vms : vm],
    local.external_service_vms
  ))
}

# Data source to get all VMs in NSX - this avoids prefix matching issues
data "nsxt_policy_vms" "all_vms" {}

# Additional locals that depend on the data source
locals {
  # Find exact matches from all VMs in NSX
  found_vms = {
    for vm_name in local.all_vms_including_external :
    vm_name => data.nsxt_policy_vms.all_vms.items[vm_name]
    if contains(keys(data.nsxt_policy_vms.all_vms.items), vm_name)
  }

  # Check for missing VMs
  missing_vms = [
    for vm_name in local.all_vms_including_external :
    vm_name
    if !contains(keys(data.nsxt_policy_vms.all_vms.items), vm_name)
  ]
}

# Validation resource to check for missing VMs
resource "null_resource" "vm_name_validation" {
  count = length(local.missing_vms) > 0 ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      echo "ERROR: The following VM names are not found in NSX Manager:"
      echo "${join("\n", local.missing_vms)}"
      echo ""
      echo "Please ensure that:"
      echo "1. The VM names in your YAML files match exactly with the display names in NSX Manager"
      echo "2. The VMs are powered on and visible in NSX"
      echo ""
      echo "Available VMs in NSX Manager:"
      echo "${join("\n", keys(data.nsxt_policy_vms.all_vms.items))}"
      exit 1
    EOT
  }

  lifecycle {
    precondition {
      condition     = length(local.missing_vms) == 0
      error_message = "VM name validation failed: ${length(local.missing_vms)} VM(s) not found in NSX Manager: ${join(", ", local.missing_vms)}. Ensure VM names in YAML match exactly with NSX Manager display names."
    }
  }
}

# Apply all hierarchy tags to VMs using the found VMs
resource "nsxt_policy_vm_tags" "hierarchy_tags" {
  for_each = local.found_vms

  instance_id = each.value

  depends_on = [null_resource.vm_name_validation]

  # Tenant tag (for all VMs)
  tag {
    scope = "tenant"
    tag   = local.tenant_tag
  }

  # Environment tag (only for internal VMs)
  dynamic "tag" {
    for_each = contains(local.all_vms, each.key) ? [local.vm_base_data[each.key].env_key] : []
    content {
      scope = "environment"
      tag   = tag.value
    }
  }

  # Application tags - one per app this VM belongs to (only for internal VMs)
  dynamic "tag" {
    for_each = contains(local.all_vms, each.key) ? local.app_tags_by_vm[each.key] : []
    content {
      scope = "application"
      tag   = tag.value
    }
  }

  # Sub-application tags - one per sub-app this VM belongs to (only for internal VMs)
  dynamic "tag" {
    for_each = contains(local.all_vms, each.key) ? local.sub_app_tags_by_vm[each.key] : []
    content {
      scope = "sub-application"
      tag   = tag.value
    }
  }

  # Emergency tag (if present, only for internal VMs)
  dynamic "tag" {
    for_each = contains(local.all_vms, each.key) && lookup(local.emergency_vm_tags, each.key, null) != null ? [local.emergency_vm_tags[each.key]] : []
    content {
      scope = "emergency"
      tag   = tag.value
    }
  }

  # External service tag (for external service VMs)
  dynamic "tag" {
    for_each = lookup(local.external_service_vm_tags, each.key, null) != null ? [local.external_service_vm_tags[each.key]] : []
    content {
      scope = "external-service"
      tag   = tag.value
    }
  }
} 