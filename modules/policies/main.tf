terraform {
  required_providers {
    nsxt = {
      source = "vmware/nsxt"
    }
  }
}

locals {
  tenant_key  = var.tenant_id
  tenant_data = var.authorized_flows[local.tenant_key]

  # Extract policy data
  environment_policy      = try(local.tenant_data.environment_policy, {})
  application_policy_map  = try(local.tenant_data.application_policy, {})
  
  # Read the YAML file as text to preserve original order
  authorized_flows_file_path = coalesce(var.authorized_flows_file, "./tenants/${local.tenant_key}/authorized-flows.yaml")
  authorized_flows_text = file(local.authorized_flows_file_path)
  
  # Extract application policy keys in their original YAML order using regex
  # This matches lines that start with exactly 4 spaces followed by policy keys (pol-xxx:)
  application_policy_keys_ordered = flatten([
    for match in regexall("(?m)^    (pol-[^:]+):", local.authorized_flows_text) : match
  ])

  # Create a map that includes the original order index for sequence numbering
  application_policy_order_map = {
    for idx, key in local.application_policy_keys_ordered : key => idx
  }

  # Create the application policies structure with order indices
  application_policies = {
    for policy_key in local.application_policy_keys_ordered : policy_key => {
      order_index = local.application_policy_order_map[policy_key]
      rules = [
        for rule in local.application_policy_map[policy_key] : {
          name         = try(rule.name, "app-rule-${index(local.application_policy_map[policy_key], rule) + 1}")
          sources      = rule.source
          destinations = rule.destination
          # Add predefined services if they exist
          service_keys = try(rule.services, [])
          # Add custom services if they exist (new format)
          custom_services = try(rule.custom_services, [])
          # Process both predefined and custom context profiles
          predefined_profiles = try(rule.context_profiles, [])
          # Get list of custom context profile references (new format)
          custom_profiles = try(rule.custom_context_profiles, [])
          # Check if we have any custom profiles
          has_custom_profiles = length(try(rule.custom_context_profiles, [])) > 0
          # Check if we have both predefined and custom profiles
          has_multiple_profiles = length(try(rule.context_profiles, [])) > 0 || length(try(rule.custom_context_profiles, [])) > 0
          action               = try(rule.action, "ALLOW")
          applied_to           = try(rule.applied_to, [])
          policy_key           = policy_key
        }
      ]
    }
  }

  # Emergency policy should not be used in project context
  emergency_policy = var.project_id == null ? try(local.tenant_data.emergency_policy, []) : []

  # Process allowed and blocked environment communications
  allowed_env_rules = [
    for rule in try(local.environment_policy.allowed_communications, []) : {
      name        = try(rule.name, "allow-${rule.source}-to-${rule.destination}")
      source      = rule.source
      destination = rule.destination
      action      = try(rule.action, "ALLOW")
      applied_to  = try(rule.applied_to, [])
    }
  ]

  blocked_env_rules = [
    for rule in try(local.environment_policy.blocked_communications, []) : {
      name        = try(rule.name, "block-${rule.source}-to-${rule.destination}")
      source      = rule.source
      destination = rule.destination
      action      = try(rule.action, "DROP")
      applied_to  = try(rule.applied_to, [])
    }
  ]

  # Combine environment rules
  environment_rules = concat(local.allowed_env_rules, local.blocked_env_rules)

  # Process emergency policy rules
  emergency_rules = [
    for rule in local.emergency_policy : {
      name         = try(rule.name, "emergency-rule-${index(local.emergency_policy, rule) + 1}")
      sources      = rule.source
      destinations = rule.destination
      action       = try(rule.action, "ALLOW")
      applied_to   = try(rule.applied_to, [])
    }
  ]
}

# Create emergency security policy
resource "nsxt_policy_security_policy" "emergency_policy" {
  count = length(local.emergency_rules) > 0 ? 1 : 0

  display_name    = "emergency-${local.tenant_key}-policy"
  description     = "Emergency security policy for tenant ${local.tenant_key}"
  category        = "Emergency"
  locked          = false
  stateful        = true
  sequence_number = 1 # Highest priority

  dynamic "rule" {
    for_each = local.emergency_rules
    content {
      display_name = rule.value.name
      # Convert applied_to groups to group IDs, empty list if no applied_to specified (DFW scope)
      scope = length(rule.value.applied_to) > 0 ? flatten([
        for group in rule.value.applied_to : [
          # Look up the group path based on the prefix
          startswith(group, "app-") ? (
            contains(keys(var.groups.sub_application_groups), group) ?
            var.groups.sub_application_groups[group] :
            var.groups.application_groups[group]
          ) :
          startswith(group, "env-") ? var.groups.environment_groups[group] :
          startswith(group, "ext-") ? var.groups.external_service_groups[group] :
          startswith(group, "ten-") ? var.groups.tenant_group_id :
          startswith(group, "cons-") ? var.groups.consumer_groups[group] :
          startswith(group, "prov-") ? var.groups.provider_groups[group] :
          contains(keys(var.groups.emergency_groups), group) ? var.groups.emergency_groups[group] : ""
        ]
        if(
          (startswith(group, "app-") && (contains(keys(var.groups.sub_application_groups), group) || contains(keys(var.groups.application_groups), group))) ||
          (startswith(group, "env-") && contains(keys(var.groups.environment_groups), group)) ||
          (startswith(group, "ext-") && contains(keys(var.groups.external_service_groups), group)) ||
          (startswith(group, "ten-")) ||
          (startswith(group, "cons-") && contains(keys(var.groups.consumer_groups), group)) ||
          (startswith(group, "prov-") && contains(keys(var.groups.provider_groups), group)) ||
          (contains(keys(var.groups.emergency_groups), group))
        )
      ]) : []

      # Handle source groups with appropriate lookup based on format
      source_groups = flatten([
        for src in(
          # Try to treat as list first, if not possible use as a single string
          try(tolist(rule.value.sources), [rule.value.sources])
          ) : [
          # Look up the group path based on the prefix
          startswith(src, "app-") ? (
            contains(keys(var.groups.sub_application_groups), src) ?
            var.groups.sub_application_groups[src] :
            var.groups.application_groups[src]
          ) :
          startswith(src, "env-") ? var.groups.environment_groups[src] :
          startswith(src, "ext-") ? var.groups.external_service_groups[src] :
          startswith(src, "ten-") ? var.groups.tenant_group_id :
          startswith(src, "cons-") ? var.groups.consumer_groups[src] :
          startswith(src, "prov-") ? var.groups.provider_groups[src] :
          contains(keys(var.groups.emergency_groups), src) ? var.groups.emergency_groups[src] : ""
        ]
        if(
          (startswith(src, "app-") && (contains(keys(var.groups.sub_application_groups), src) || contains(keys(var.groups.application_groups), src))) ||
          (startswith(src, "env-") && contains(keys(var.groups.environment_groups), src)) ||
          (startswith(src, "ext-") && contains(keys(var.groups.external_service_groups), src)) ||
          (startswith(src, "ten-")) ||
          (startswith(src, "cons-") && contains(keys(var.groups.consumer_groups), src)) ||
          (startswith(src, "prov-") && contains(keys(var.groups.provider_groups), src)) ||
          (contains(keys(var.groups.emergency_groups), src))
        )
      ])

      # Handle any as destination or specific destination
      destination_groups = contains(
        try(tolist(rule.value.destinations), [rule.value.destinations]),
        "any"
        ) ? [] : flatten([
          for dst in(
            # Try to treat as list first, if not possible use as a single string
            try(tolist(rule.value.destinations), [rule.value.destinations])
            ) : [
            # Look up the group path based on the prefix
            startswith(dst, "app-") ? (
              contains(keys(var.groups.sub_application_groups), dst) ?
              var.groups.sub_application_groups[dst] :
              var.groups.application_groups[dst]
            ) :
            startswith(dst, "env-") ? var.groups.environment_groups[dst] :
            startswith(dst, "ext-") ? var.groups.external_service_groups[dst] :
            startswith(dst, "ten-") ? var.groups.tenant_group_id :
            startswith(dst, "cons-") ? var.groups.consumer_groups[dst] :
            startswith(dst, "prov-") ? var.groups.provider_groups[dst] :
            contains(keys(var.groups.emergency_groups), dst) ? var.groups.emergency_groups[dst] : ""
          ]
          if(
            (startswith(dst, "app-") && (contains(keys(var.groups.sub_application_groups), dst) || contains(keys(var.groups.application_groups), dst))) ||
            (startswith(dst, "env-") && contains(keys(var.groups.environment_groups), dst)) ||
            (startswith(dst, "ext-") && contains(keys(var.groups.external_service_groups), dst)) ||
            (startswith(dst, "ten-")) ||
            (startswith(dst, "cons-") && contains(keys(var.groups.consumer_groups), dst)) ||
            (startswith(dst, "prov-") && contains(keys(var.groups.provider_groups), dst)) ||
            (contains(keys(var.groups.emergency_groups), dst))
          )
      ])

      action = rule.value.action
      logged = true
    }
  }
}

# Create environment security policy
resource "nsxt_policy_security_policy" "environment_policy" {
  count = length(local.environment_rules) > 0 ? 1 : 0

  display_name    = "env-${local.tenant_key}-policy"
  description     = "Environment security policy for tenant ${local.tenant_key}"
  category        = "Environment"
  locked          = false
  stateful        = true
  sequence_number = 2 # Second priority after emergency

  dynamic "context" {
    for_each = var.project_id != null ? [1] : []
    content {
      project_id = var.project_id
    }
  }

  dynamic "rule" {
    for_each = local.environment_rules
    content {
      display_name = rule.value.name
      # Convert applied_to groups to group IDs, empty list if no applied_to specified (DFW scope)
      scope = length(rule.value.applied_to) > 0 ? flatten([
        for group in rule.value.applied_to : [
          var.groups.environment_groups[group]
        ]
        if contains(keys(var.groups.environment_groups), group)
      ]) : []

      # Handle source as either string or list
      source_groups = flatten([
        for src in try(tolist(rule.value.source), [rule.value.source]) : [
          var.groups.environment_groups[src]
        ]
        if contains(keys(var.groups.environment_groups), src)
      ])

      # Handle destination as either string or list
      destination_groups = flatten([
        for dst in try(tolist(rule.value.destination), [rule.value.destination]) : [
          var.groups.environment_groups[dst]
        ]
        if contains(keys(var.groups.environment_groups), dst)
      ])

      action = rule.value.action
      logged = true
    }
  }

  depends_on = [nsxt_policy_security_policy.emergency_policy]
}

# Create application security policy
resource "nsxt_policy_security_policy" "application_policy" {
  for_each = local.application_policies

  display_name    = each.key
  description     = "Application security policy for tenant ${local.tenant_key} - ${each.key}"
  category        = "Application"
  locked          = false
  stateful        = true
  sequence_number = 3 + each.value.order_index # Use YAML order index for proper sequencing

  dynamic "context" {
    for_each = var.project_id != null ? [1] : []
    content {
      project_id = var.project_id
    }
  }

  dynamic "rule" {
    for_each = each.value.rules
    content {
      display_name = rule.value.name
      # Convert applied_to groups to group IDs, empty list if no applied_to specified (DFW scope)
      scope = length(rule.value.applied_to) > 0 ? flatten([
        for group in rule.value.applied_to : [
          # Look up the group path based on the prefix
          startswith(group, "app-") ? (
            contains(keys(var.groups.sub_application_groups), group) ?
            var.groups.sub_application_groups[group] :
            var.groups.application_groups[group]
          ) :
          startswith(group, "env-") ? var.groups.environment_groups[group] :
          startswith(group, "ext-") ? var.groups.external_service_groups[group] :
          startswith(group, "ten-") ? var.groups.tenant_group_id :
          startswith(group, "cons-") ? var.groups.consumer_groups[group] :
          startswith(group, "prov-") ? var.groups.provider_groups[group] :
          contains(keys(var.groups.emergency_groups), group) ? var.groups.emergency_groups[group] : ""
        ]
        if(
          (startswith(group, "app-") && (contains(keys(var.groups.sub_application_groups), group) || contains(keys(var.groups.application_groups), group))) ||
          (startswith(group, "env-") && contains(keys(var.groups.environment_groups), group)) ||
          (startswith(group, "ext-") && contains(keys(var.groups.external_service_groups), group)) ||
          (startswith(group, "ten-")) ||
          (startswith(group, "cons-") && contains(keys(var.groups.consumer_groups), group)) ||
          (startswith(group, "prov-") && contains(keys(var.groups.provider_groups), group)) ||
          (contains(keys(var.groups.emergency_groups), group))
        )
      ]) : []

      # Handle source groups with appropriate lookup based on format - handle ANY case-insensitively
      source_groups = contains(
        [for src in try(tolist(rule.value.sources), [rule.value.sources]) : lower(src)],
        "any"
        ) ? [] : flatten([
        for src in(
          # Try to treat as list first, if not possible use as a single string
          try(tolist(rule.value.sources), [rule.value.sources])
          ) : [
          # Look up the group path based on the prefix
          startswith(src, "app-") ? (
            contains(keys(var.groups.sub_application_groups), src) ?
            var.groups.sub_application_groups[src] :
            var.groups.application_groups[src]
          ) :
          startswith(src, "env-") ? var.groups.environment_groups[src] :
          startswith(src, "ext-") ? var.groups.external_service_groups[src] :
          startswith(src, "ten-") ? var.groups.tenant_group_id :
          startswith(src, "cons-") ? var.groups.consumer_groups[src] :
          startswith(src, "prov-") ? var.groups.provider_groups[src] :
          contains(keys(var.groups.emergency_groups), src) ? var.groups.emergency_groups[src] : ""
        ]
        if(
          (startswith(src, "app-") && (contains(keys(var.groups.sub_application_groups), src) || contains(keys(var.groups.application_groups), src))) ||
          (startswith(src, "env-") && contains(keys(var.groups.environment_groups), src)) ||
          (startswith(src, "ext-") && contains(keys(var.groups.external_service_groups), src)) ||
          (startswith(src, "ten-")) ||
          (startswith(src, "cons-") && contains(keys(var.groups.consumer_groups), src)) ||
          (startswith(src, "prov-") && contains(keys(var.groups.provider_groups), src)) ||
          (contains(keys(var.groups.emergency_groups), src))
        )
      ])

      # Handle any as destination or specific destination groups - handle ANY case-insensitively
      destination_groups = contains(
        [for dst in try(tolist(rule.value.destinations), [rule.value.destinations]) : lower(dst)],
        "any"
        ) ? [] : flatten([
          for dst in(
            # Try to treat as list first, if not possible use as a single string
            try(tolist(rule.value.destinations), [rule.value.destinations])
            ) : [
            # Look up the group path based on the prefix
            startswith(dst, "app-") ? (
              contains(keys(var.groups.sub_application_groups), dst) ?
              var.groups.sub_application_groups[dst] :
              var.groups.application_groups[dst]
            ) :
            startswith(dst, "env-") ? var.groups.environment_groups[dst] :
            startswith(dst, "ext-") ? var.groups.external_service_groups[dst] :
            startswith(dst, "ten-") ? var.groups.tenant_group_id :
            startswith(dst, "cons-") ? var.groups.consumer_groups[dst] :
            startswith(dst, "prov-") ? var.groups.provider_groups[dst] :
            contains(keys(var.groups.emergency_groups), dst) ? var.groups.emergency_groups[dst] : ""
          ]
          if(
            (startswith(dst, "app-") && (contains(keys(var.groups.sub_application_groups), dst) || contains(keys(var.groups.application_groups), dst))) ||
            (startswith(dst, "env-") && contains(keys(var.groups.environment_groups), dst)) ||
            (startswith(dst, "ext-") && contains(keys(var.groups.external_service_groups), dst)) ||
            (startswith(dst, "ten-")) ||
            (startswith(dst, "cons-") && contains(keys(var.groups.consumer_groups), dst)) ||
            (startswith(dst, "prov-") && contains(keys(var.groups.provider_groups), dst)) ||
            (contains(keys(var.groups.emergency_groups), dst))
          )
      ])

      # Add services - combine both predefined and custom services
      services = flatten([
        # Predefined services - look up paths in var.services
        [
          for svc in rule.value.service_keys :
          var.services[svc] 
          if contains(keys(var.services), svc)
        ],
        # Custom services - look up paths in var.services
        [
          for custom_svc in rule.value.custom_services :
          var.services[custom_svc] 
          if contains(keys(var.services), custom_svc)
        ]
      ])

      # Add application profiles if any are defined - only set if there are valid profiles, otherwise use empty list
      profiles = length(flatten([
        # Add predefined profiles
        [
          for profile in rule.value.predefined_profiles :
          contains(keys(var.context_profiles), profile) ? var.context_profiles[profile] : null
          if profile != "" && contains(keys(var.context_profiles), profile)
        ],
        # Add custom profiles
        [
          for profile in rule.value.custom_profiles :
          contains(keys(var.context_profiles), profile) ? var.context_profiles[profile] : null
          if profile != "" && contains(keys(var.context_profiles), profile)
        ]
      ])) > 0 ? flatten([
        # Add predefined profiles
        [
          for profile in rule.value.predefined_profiles :
          var.context_profiles[profile]
          if profile != "" && contains(keys(var.context_profiles), profile)
        ],
        # Add custom profiles
        [
          for profile in rule.value.custom_profiles :
          var.context_profiles[profile]
          if profile != "" && contains(keys(var.context_profiles), profile)
        ]
      ]) : []

      action = rule.value.action
      logged = true
    }
  }

  depends_on = [nsxt_policy_security_policy.environment_policy]
}
