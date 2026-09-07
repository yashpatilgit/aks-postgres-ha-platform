variable "resource_group_name" {
  type        = string
  description = "resource group name"

}

variable "location" {
  type    = string
  default = "eastus"
}

variable "service_principal_name" {
  type = string
}

variable "keyvault_name" {
  type = string
}

variable "subscription_id" {
  type = string
}

variable "node_pool_name" {
  
}
variable "cluster_name" {
  
}