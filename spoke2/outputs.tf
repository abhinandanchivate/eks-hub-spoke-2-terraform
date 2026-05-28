output "cluster_name"     { value = module.eks.cluster_name }
output "cluster_endpoint" { value = module.eks.cluster_endpoint }
output "vpc_id"           { value = module.vpc.vpc_id }
output "vpc_cidr"         { value = module.vpc.vpc_cidr }
output "private_route_table_ids" { value = module.vpc.private_route_table_ids }
output "public_route_table_id"   { value = module.vpc.public_route_table_id }
output "postgres_endpoint"       { value = module.databases.postgres_service }
output "mongodb_endpoint"        { value = module.databases.mongodb_service }
