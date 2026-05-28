variable "namespace" {
  type    = string
  default = "databases"
}

variable "storage_class" {
  type    = string
  default = "gp2"
}

# PostgreSQL
variable "postgres_username" {
  type    = string
  default = "appuser"
}

variable "postgres_password" {
  type      = string
  sensitive = true
}

variable "postgres_database" {
  type    = string
  default = "appdb"
}

variable "postgres_storage_size" {
  type    = string
  default = "20Gi"
}

variable "postgres_replicas" {
  type    = number
  default = 1
}

# MongoDB
variable "mongodb_root_password" {
  type      = string
  sensitive = true
}

variable "mongodb_username" {
  type    = string
  default = "appuser"
}

variable "mongodb_password" {
  type      = string
  sensitive = true
}

variable "mongodb_database" {
  type    = string
  default = "appdb"
}

variable "mongodb_storage_size" {
  type    = string
  default = "20Gi"
}

variable "mongodb_replicas" {
  type    = number
  default = 1
}

variable "mongodb_architecture" {
  type    = string
  default = "standalone"
}
