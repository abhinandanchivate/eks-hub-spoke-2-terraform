output "postgres_service" {
  value = "postgresql.${var.namespace}.svc.cluster.local"
}
output "postgres_port" { value = 5432 }

output "mongodb_service" {
  value = "mongodb.${var.namespace}.svc.cluster.local"
}
output "mongodb_port" { value = 27017 }
