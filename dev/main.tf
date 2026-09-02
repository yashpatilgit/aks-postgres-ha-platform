resource "azurerm_resource_group" "rg1" {
  name= var.resource_group_name
  location = var.location
}

module "Service_Principal" {
  source = "../modules/serviceprincipal"
  service_principal_name = var.service_principal_name

  depends_on = [ azurerm_resource_group.rg1 ]

}

resource "azurerm_role_assignment" "rolespn" {
    scope = "/subscriptions/${var.subscription_id}"
    principal_id = module.Service_Principal.service_principal_object_id
    role_definition_name = "Contributor"

    depends_on = [ module.Service_Principal ]
}

module "keyvault" {
  source                      = "./modules/keyvault"
  keyvault_name               = var.keyvault_name
  resource_group_name         = var.resource_group_name
  location                    = var.location
  service_principal_name      = var.service_principal_name
  service_principal_object_id = module.Service_Principal.service_principal_object_id
  service_principal_tenant_id = module.Service_Principal.service_principal_tenant_id

  depends_on = [module.Service_Principal]

}

resource "azurerm_key_vault_secret" "kv-secret" {
  name         = module.Service_Principal.client_id
  value        = module.Service_Principal.client_secret
  key_vault_id = module.keyvault.keyvault_id

  depends_on = [module.keyvault]
}

module "aks" {
  source                 = "./modules/aks"
  service_principal_name = module.Service_Principal.service_principal_name
  client_id              = module.Service_Principal.client_id
  client_secret          = module.Service_Principal.client_secret
  location               = var.location
  resource_group_name    = var.resource_group_name
  cluster_name = var.cluster_name
  node_pool_name =  var.node_pool_name

  depends_on = [module.Service_Principal]

}

resource "local_file" "kubeconfig" {
  depends_on = [module.aks]
  filename   = "./kubeconfig"
  content    = module.aks.config
}
