terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "eks-spoke1/terraform.tfstate"
  #   region         = "ap-south-1"
  #   dynamodb_table = "terraform-lock"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
      command     = "aws"
    }
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    command     = "aws"
  }
}

locals {
  cluster_name = "${var.project}-spoke1-${var.environment}"
  tags = {
    Project     = var.project
    Environment = var.environment
    Role        = "spoke1"
    ManagedBy   = "terraform"
  }
}

module "vpc" {
  source       = "../modules/vpc"
  vpc_name     = "${var.project}-spoke1-vpc"
  vpc_cidr     = var.vpc_cidr
  cluster_name = local.cluster_name
  tags         = local.tags
}

module "eks" {
  source              = "../modules/eks"
  cluster_name        = local.cluster_name
  kubernetes_version  = var.kubernetes_version
  vpc_id              = module.vpc.vpc_id
  public_subnet_ids   = module.vpc.public_subnet_ids
  private_subnet_ids  = module.vpc.private_subnet_ids
  node_instance_types = var.node_instance_types
  node_desired        = var.node_desired
  node_min            = var.node_min
  node_max            = var.node_max
  tags                = local.tags
}

module "addons" {
  source            = "../modules/addons"
  cluster_name      = module.eks.cluster_name
  vpc_id            = module.vpc.vpc_id
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  tags              = local.tags
}

module "databases" {
  source                = "../modules/databases"
  namespace             = "databases"
  storage_class         = "gp2"
  postgres_password     = var.postgres_password
  postgres_username     = var.postgres_username
  postgres_database     = var.postgres_database
  mongodb_root_password = var.mongodb_root_password
  mongodb_username      = var.mongodb_username
  mongodb_password      = var.mongodb_password
  mongodb_database      = var.mongodb_database

  depends_on = [module.addons]
}
