variable "tenant_id" {
  description = "ID of the tenant (e.g., wld09)"
  type        = string
}

variable "authorized_flows" {
  description = "Parsed tenant authorized flows from YAML file. The application_policy should be a map where keys are application firewall names (e.g., app-wld01-app01) and values are lists of rule objects."
  type        = any
}

variable "inventory" {
  description = "Parsed tenant inventory from YAML file"
  type        = any
}

variable "groups" {
  description = "Map of group IDs by type"
  type = object({
    tenant_group_id         = string
    environment_groups      = map(string)
    application_groups      = map(string)
    sub_application_groups  = map(string)
    external_service_groups = map(string)
    emergency_groups        = map(string)
    consumer_groups         = map(string)
    provider_groups         = map(string)
  })
}

variable "services" {
  description = "Map of service paths by name"
  type        = map(string)
}

variable "context_profiles" {
  description = "Map of context profile paths by name"
  type        = map(string)
}

variable "project_id" {
  description = "Project ID to use for NSX project context"
  type        = string
  default     = null
} 