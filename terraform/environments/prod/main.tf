module "network" {
  source   = "../../modules/network"
  location = var.location
  prefix   = var.prefix
}

module "monitoring" {
  source   = "../../modules/monitoring"
  location = var.location
  prefix   = var.prefix
  resource_group_name = module.network.rg_name
}

module "aks" {
  source            = "../../modules/aks"
  location          = var.location
  prefix            = var.prefix
  resource_group_id = module.network.rg_id
}

module "postgres" {
  source            = "../../modules/postgres"
  location          = var.location
  prefix            = var.prefix
  resource_group_id = module.network.rg_id
  vnet_subnet_id    = module.network.db_subnet_id
}
