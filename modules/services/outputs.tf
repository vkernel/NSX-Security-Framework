output "services" {
  description = "Map of services created for this tenant"
  value = {
    for service_key, service in nsxt_policy_service.custom_services : service_key => service.path
  }
} 