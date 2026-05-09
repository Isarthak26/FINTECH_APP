variable "location" { type = string }
variable "prefix" { type = string }
variable "resource_group_id" { type = string }

resource "random_string" "acr_suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.prefix}-aks"
  location            = var.location
  resource_group_name = element(split("/", var.resource_group_id), 4)
  dns_prefix          = "${var.prefix}-dns"
  oidc_issuer_enabled = true

  default_node_pool {
    name       = "agentpool"
    node_count = 1
    vm_size    = "Standard_B2s_v2"
    enable_auto_scaling = true
    min_count = 1
    max_count = 2
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
  }
}

resource "azurerm_container_registry" "acr" {
  name                = substr(replace(lower("${var.prefix}acr${random_string.acr_suffix.result}"), "-", ""), 0, 50)
  resource_group_name = element(split("/", var.resource_group_id), 4)
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = true
}

output "cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}
