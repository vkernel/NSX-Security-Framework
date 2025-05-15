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
      for key, profile in nsxt_policy_context_profile.custom_profile : key => profile.path
    }
  )
}

# This is the main output used by other modules - it matches the previous output in main.tf
output "context_profiles" {
  description = "Map of context profile names to NSX paths"
  value = merge(
    {
      for name, profile in data.nsxt_policy_context_profile.predefined_profiles : name => profile.path
    },
    {
      for name, profile in nsxt_policy_context_profile.custom_profile : name => profile.path
    }
  )
} 