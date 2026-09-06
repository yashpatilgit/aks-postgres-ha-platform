output "aks_subnet_id" {
  value = azurerm_subnet.aks_subnet.id
}
output "endpoints_subnet_id" {
  value = azurerm_subnet.endpoints_subnet.id
}
output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}