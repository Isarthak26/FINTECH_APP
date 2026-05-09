variable "location" { type = string }
variable "prefix" { type = string }
variable "resource_group_id" { type = string }
variable "vnet_subnet_id" { type = string }

resource "azurerm_postgresql_flexible_server" "pg" {
  name                = "${var.prefix}-pg"
  resource_group_name = element(split("/", var.resource_group_id), 4)
  location            = var.location
  sku_name            = "B_Standard_B1ms"
  version             = "14"
  storage_mb          = 32768
  administrator_login = "pgadmin"
  administrator_password = random_password.pw.result

  lifecycle {
    ignore_changes = [zone]
  }
}

resource "random_password" "pw" {
  length  = 16
  special = true
}

output "postgres_fqdn" {
  value = azurerm_postgresql_flexible_server.pg.fqdn
}
