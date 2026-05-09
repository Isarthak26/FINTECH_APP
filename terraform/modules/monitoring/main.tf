variable "location" { type = string }
variable "prefix" { type = string }
variable "resource_group_name" { type = string }

resource "azurerm_log_analytics_workspace" "law" {
  name                = "${var.prefix}-law"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

output "law_id" {
  value = azurerm_log_analytics_workspace.law.id
}
