output "predefined_context_profiles" {
  description = "Map of predefined context profiles"
  value = {
    for name, profile in data.nsxt_policy_context_profile.predefined_profiles : name => profile.path
  }
}

output "custom_context_profiles" {
  description = "Map of custom context profiles"
  value = {
    for key, profile in nsxt_policy_context_profile.custom_profile : key => profile.path
  }
}

output "all_context_profiles" {
  description = "Map of all context profiles (predefined and custom)"
  value = merge(
    {
      for name, profile in data.nsxt_policy_context_profile.predefined_profiles : name => profile.path
    },
    {
      for key, profile in nsxt_policy_context_profile.custom_profile : 
        replace(key, "profile-${var.tenant_id}-", "") => profile.path
    }
  )
} 