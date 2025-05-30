output "emergency_policy_id" {
  description = "ID of the emergency security policy, if created"
  value       = length(nsxt_policy_security_policy.emergency_policy) > 0 ? nsxt_policy_security_policy.emergency_policy[0].id : null
}

output "environment_policy_id" {
  description = "ID of the environment security policy, if created"
  value       = length(nsxt_policy_security_policy.environment_policy) > 0 ? nsxt_policy_security_policy.environment_policy[0].id : null
}

output "application_policy_ids" {
  description = "Map of application security policy IDs by application key"
  value = {
    for key, policy in nsxt_policy_security_policy.application_policy :
    key => policy.id
  }
}

output "policy_count" {
  description = "Count of policies created for this tenant"
  value = {
    emergency   = length(nsxt_policy_security_policy.emergency_policy)
    environment = length(nsxt_policy_security_policy.environment_policy)
    application = length(nsxt_policy_security_policy.application_policy)
  }
}

output "rule_count" {
  description = "Count of rules created for each policy type"
  value = {
    emergency   = length(local.emergency_rules)
    environment = length(local.environment_rules)
    application = {
      for key, rules in local.application_policies :
      key => length(rules)
    }
  }
} 