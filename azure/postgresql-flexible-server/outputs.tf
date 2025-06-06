output "fqdn" {
  description = "The FQDN of the PostgreSQL Flexible Server"
  value       = module.postgresql-flexible-server.fqdn
}

output "instance_id" {
  description = "The instance ID of the PostgreSQL Flexible Server"
  value       = module.postgresql-flexible-server.id
}

output "password" {
  description = "The admin password for the PostgreSQL Flexible Server"
  value       = module.postgresql-flexible-server.administrator_password
  sensitive   = true
}

output "username" {
  description = "The admin username for the PostgreSQL Flexible Server"
  value       = module.postgresql-flexible-server.administrator_login
}
