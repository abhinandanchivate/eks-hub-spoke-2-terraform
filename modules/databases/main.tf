##############################################
# Namespace
##############################################
resource "kubernetes_namespace" "databases" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

##############################################
# PostgreSQL – Bitnami Helm Chart
##############################################
resource "helm_release" "postgresql" {
  name       = "postgresql"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "postgresql"
  namespace  = kubernetes_namespace.databases.metadata[0].name
  version    = "14.3.3"

  values = [
    yamlencode({
      auth = {
        postgresPassword = var.postgres_password
        username         = var.postgres_username
        password         = var.postgres_password
        database         = var.postgres_database
      }
      primary = {
        persistence = {
          enabled      = true
          storageClass = var.storage_class
          size         = var.postgres_storage_size
        }
        resources = {
          requests = { memory = "256Mi", cpu = "250m" }
          limits   = { memory = "512Mi", cpu = "500m" }
        }
      }
      metrics = {
        enabled = true
      }
      replication = {
        enabled      = var.postgres_replicas > 1
        readReplicas = var.postgres_replicas - 1
      }
    })
  ]
}

##############################################
# MongoDB – Bitnami Helm Chart
##############################################
resource "helm_release" "mongodb" {
  name       = "mongodb"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "mongodb"
  namespace  = kubernetes_namespace.databases.metadata[0].name
  version    = "15.6.18"

  values = [
    yamlencode({
      auth = {
        enabled          = true
        rootPassword     = var.mongodb_root_password
        username         = var.mongodb_username
        password         = var.mongodb_password
        database         = var.mongodb_database
      }
      architecture = var.mongodb_architecture  # "standalone" or "replicaset"
      replicaCount = var.mongodb_replicas
      persistence = {
        enabled      = true
        storageClass = var.storage_class
        size         = var.mongodb_storage_size
      }
      resources = {
        requests = { memory = "256Mi", cpu = "250m" }
        limits   = { memory = "512Mi", cpu = "500m" }
      }
      metrics = {
        enabled = true
      }
    })
  ]
}
