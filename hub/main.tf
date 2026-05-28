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

  # Uncomment and configure for remote state
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "eks-hub/terraform.tfstate"
  #   region         = "ap-south-1"
  #   dynamodb_table = "terraform-lock"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region
  # Credentials via environment variables:
  # export AWS_ACCESS_KEY_ID=...
  # export AWS_SECRET_ACCESS_KEY=...
  # export AWS_SESSION_TOKEN=...
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
  cluster_name = "${var.project}-hub-${var.environment}"
  tags = {
    Project     = var.project
    Environment = var.environment
    Role        = "hub"
    ManagedBy   = "terraform"
  }
}

module "vpc" {
  source       = "../modules/vpc"
  vpc_name     = "${var.project}-hub-vpc"
  vpc_cidr     = var.vpc_cidr
  cluster_name = local.cluster_name
  tags         = local.tags
}

module "eks" {
  source               = "../modules/eks"
  cluster_name         = local.cluster_name
  kubernetes_version   = var.kubernetes_version
  vpc_id               = module.vpc.vpc_id
  public_subnet_ids    = module.vpc.public_subnet_ids
  private_subnet_ids   = module.vpc.private_subnet_ids
  node_instance_types  = var.node_instance_types
  node_desired         = var.node_desired
  node_min             = var.node_min
  node_max             = var.node_max
  tags                 = local.tags
}

module "addons" {
  source            = "../modules/addons"
  cluster_name      = module.eks.cluster_name
  vpc_id            = module.vpc.vpc_id
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  tags              = local.tags
}
