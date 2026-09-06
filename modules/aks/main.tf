# Datasource to get Latest Azure AKS latest Version
# Check if there is a var with the version name , if not , use the 
# latest version, if there is a var, use that version
# make sure the version specified in var is valid


#here it is checking the latest available version from azure
data "azurerm_kubernetes_service_versions" "current" {
  location = var.location
  include_preview = false  
}

# Generate SSH key pair for AKS
resource "tls_private_key" "aks_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}


resource "azurerm_kubernetes_cluster" "aks-cluster" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${var.resource_group_name}-cluster"
  kubernetes_version =  data.azurerm_kubernetes_service_versions.current.latest_version
  node_resource_group = "${var.resource_group_name}-nrg"
  oidc_issuer_enabled = true

  node_provisioning_profile {
  mode = "Manual"
}


  default_node_pool {
    name       = var.node_pool_name
    node_count = 1
    vm_size    = "Standard_D2as_v7"
    zones   = [1, 2, 3]
    auto_scaling_enabled = true
    max_count            = 3
    min_count            = 1
    os_disk_size_gb      = 30
    type                 = "VirtualMachineScaleSets"
    node_labels = {
      "nodepool-type"    = "system"
      "environment"      = "prod"
      "nodepoolos"       = "linux"
     } 
   tags = {
      "nodepool-type"    = "system"
      "environment"      = "prod"
      "nodepoolos"       = "linux"
   } 
  }

  service_principal  {
    client_id = var.client_id
    client_secret = var.client_secret
  }

# to do: generate the ssh keys using tls_private_key
# upload the key to key vault

  linux_profile {
    admin_username = "ubuntu"
    ssh_key {
        key_data = tls_private_key.aks_ssh.public_key_openssh
    }
  }

  network_profile {
      network_plugin = "azure"
      load_balancer_sku = "standard"
  }

}

