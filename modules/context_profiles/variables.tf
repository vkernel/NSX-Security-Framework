variable "tenant_id" {
  description = "The tenant ID"
  type        = string
}

variable "authorized_flows" {
  description = "Authorized flows configuration"
  type        = any
}

variable "inventory" {
  description = "Inventory configuration"
  type        = any
} 