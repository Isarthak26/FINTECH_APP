output "aks_cluster_name" {
  value = module.aks.cluster_name
}

output "acr_login_server" {
  value = module.aks.acr_login_server
}

output "postgres_fqdn" {
  value = module.postgres.postgres_fqdn
}
