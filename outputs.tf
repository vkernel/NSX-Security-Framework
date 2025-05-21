output "tenant_tags" {
  description = "Tenant tags created for each deployment"
  value       = { for tenant_id, tag in module.tags : tenant_id => tag.tenant_tag }
}

output "tenant_vms" {
  description = "List of VMs in each tenant"
  value       = { for tenant_id, tag in module.tags : tenant_id => tag.tenant_vms }
}

output "vm_tag_details" {
  description = "Detailed mapping of tag assignments for each VM in each tenant"
  value       = { for tenant_id, tag in module.tags : tenant_id => tag.vm_tag_assignments }
}

output "tag_hierarchy" {
  description = "Hierarchical structure of tags showing relationships between environments, applications, and sub-applications"
  value       = { for tenant_id, tag in module.tags : tenant_id => tag.tag_hierarchy_summary }
}

output "emergency_vm_assignments" {
  description = "Mapping of emergency groups to their assigned VMs for each tenant"
  value       = { for tenant_id, tag in module.tags : tenant_id => tag.emergency_vm_assignments }
}

output "tenant_group_ids" {
  description = "ID of each tenant group"
  value       = { for tenant_id, group in module.groups : tenant_id => group.tenant_group_id }
}

output "tenant_group_details" {
  description = "Detailed configuration of each tenant group"
  value       = { for tenant_id, group in module.groups : tenant_id => group.tenant_group_details }
}

output "environment_groups" {
  description = "Map of environment group IDs for each tenant"
  value       = { for tenant_id, group in module.groups : tenant_id => group.environment_groups }
}

output "environment_groups_details" {
  description = "Detailed configuration of environment groups for each tenant"
  value       = { for tenant_id, group in module.groups : tenant_id => group.environment_groups_details }
}

output "application_groups" {
  description = "Map of application group IDs for each tenant"
  value       = { for tenant_id, group in module.groups : tenant_id => group.application_groups }
}

output "application_groups_details" {
  description = "Detailed configuration of application groups for each tenant"
  value       = { for tenant_id, group in module.groups : tenant_id => group.application_groups_details }
}

output "sub_application_groups_details" {
  description = "Detailed configuration of sub-application groups for each tenant"
  value       = { for tenant_id, group in module.groups : tenant_id => group.sub_application_groups_details }
}

output "external_service_groups_details" {
  description = "Detailed configuration of external service groups with IP addresses for each tenant"
  value       = { for tenant_id, group in module.groups : tenant_id => group.external_service_groups_details }
}

output "emergency_groups_details" {
  description = "Detailed configuration of emergency groups for each tenant"
  value       = { for tenant_id, group in module.groups : tenant_id => group.emergency_groups_details }
}

output "services" {
  description = "Services created for each tenant"
  value       = { for tenant_id, service in module.services : tenant_id => service.services }
}

output "context_profiles" {
  description = "Context profiles created for each tenant"
  value       = { for tenant_id, profile in module.context_profiles : tenant_id => profile.context_profiles }
}

output "policy_ids" {
  description = "IDs of security policies created for each tenant"
  value       = {
    for tenant_id, policy in module.policies : tenant_id => {
      emergency_policy   = policy.emergency_policy_id
      environment_policy = policy.environment_policy_id
      application_policy = policy.application_policy_id
    }
  }
}

output "rule_counts" {
  description = "Number of rules created for each policy type and tenant"
  value       = { for tenant_id, policy in module.policies : tenant_id => policy.rule_count }
} 