variable "tenant_id" {
  description = "ID of the tenant (e.g., wld09)"
  type        = string
}

variable "tenant_tag" {
  description = "Tag for the tenant (e.g., ten-wld09)"
  type        = string
}

variable "inventory" {
  description = "Parsed tenant inventory from YAML file"
  type        = any
}

variable "project_id" {
  description = "Project ID to use for NSX project context"
  type        = string
  default     = null
} 