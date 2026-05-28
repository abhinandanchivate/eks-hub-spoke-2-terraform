variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "project" {
  type    = string
  default = "myapp"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "vpc_cidr" {
  type    = string
  default = "10.2.0.0/16"
}

variable "kubernetes_version" {
  type    = string
  default = "1.29"
}

variable "node_instance_types" {
  type    = list(string)
  default = ["t3.large"]
}

variable "node_desired" {
  type    = number
  default = 2
}

variable "node_min" {
  type    = number
  default = 1
}

variable "node_max" {
  type    = number
  default = 5
}

# Database secrets — pass via TF_VAR_ env vars or Vault
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
