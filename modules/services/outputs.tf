output "services" {
  description = "Map of all services (both predefined and custom) for this tenant"
  value = merge(
    # Include predefined services with their paths
    {
      for service_key, service in data.nsxt_policy_service.predefined_services : service_key => service.path
    },
    # Include custom services with their paths
    {
      for service_key, service in nsxt_policy_service.custom_services : service_key => service.path
    }
  )
} 