terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "eks-peering/terraform.tfstate"
  #   region         = "ap-south-1"
  #   dynamodb_table = "terraform-lock"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region
}

##############################################
# Read state from Hub, Spoke1, Spoke2
##############################################
data "terraform_remote_state" "hub" {
  backend = "local"
  config  = { path = "../hub/terraform.tfstate" }
  # For S3 backend:
  # backend = "s3"
  # config = {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "eks-hub/terraform.tfstate"
  #   region = var.aws_region
  # }
}

data "terraform_remote_state" "spoke1" {
  backend = "local"
  config  = { path = "../spoke1/terraform.tfstate" }
}

data "terraform_remote_state" "spoke2" {
  backend = "local"
  config  = { path = "../spoke2/terraform.tfstate" }
}

locals {
  hub_vpc_id   = data.terraform_remote_state.hub.outputs.vpc_id
  hub_vpc_cidr = data.terraform_remote_state.hub.outputs.vpc_cidr
  hub_private_rts = data.terraform_remote_state.hub.outputs.private_route_table_ids
  hub_public_rt   = data.terraform_remote_state.hub.outputs.public_route_table_id

  spoke1_vpc_id   = data.terraform_remote_state.spoke1.outputs.vpc_id
  spoke1_vpc_cidr = data.terraform_remote_state.spoke1.outputs.vpc_cidr
  spoke1_private_rts = data.terraform_remote_state.spoke1.outputs.private_route_table_ids
  spoke1_public_rt   = data.terraform_remote_state.spoke1.outputs.public_route_table_id

  spoke2_vpc_id   = data.terraform_remote_state.spoke2.outputs.vpc_id
  spoke2_vpc_cidr = data.terraform_remote_state.spoke2.outputs.vpc_cidr
  spoke2_private_rts = data.terraform_remote_state.spoke2.outputs.private_route_table_ids
  spoke2_public_rt   = data.terraform_remote_state.spoke2.outputs.public_route_table_id
}

##############################################
# VPC Peering: Hub <-> Spoke1
##############################################
resource "aws_vpc_peering_connection" "hub_spoke1" {
  vpc_id        = local.hub_vpc_id
  peer_vpc_id   = local.spoke1_vpc_id
  auto_accept   = true

  tags = {
    Name      = "hub-to-spoke1"
    ManagedBy = "terraform"
  }
}

resource "aws_vpc_peering_connection_options" "hub_spoke1" {
  vpc_peering_connection_id = aws_vpc_peering_connection.hub_spoke1.id

  accepter  { allow_remote_vpc_dns_resolution = true }
  requester { allow_remote_vpc_dns_resolution = true }
}

# Hub -> Spoke1 routes (private)
resource "aws_route" "hub_to_spoke1_private" {
  count                     = length(local.hub_private_rts)
  route_table_id            = local.hub_private_rts[count.index]
  destination_cidr_block    = local.spoke1_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.hub_spoke1.id
}

# Hub -> Spoke1 routes (public)
resource "aws_route" "hub_to_spoke1_public" {
  route_table_id            = local.hub_public_rt
  destination_cidr_block    = local.spoke1_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.hub_spoke1.id
}

# Spoke1 -> Hub routes (private)
resource "aws_route" "spoke1_to_hub_private" {
  count                     = length(local.spoke1_private_rts)
  route_table_id            = local.spoke1_private_rts[count.index]
  destination_cidr_block    = local.hub_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.hub_spoke1.id
}

# Spoke1 -> Hub routes (public)
resource "aws_route" "spoke1_to_hub_public" {
  route_table_id            = local.spoke1_public_rt
  destination_cidr_block    = local.hub_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.hub_spoke1.id
}

##############################################
# VPC Peering: Hub <-> Spoke2
##############################################
resource "aws_vpc_peering_connection" "hub_spoke2" {
  vpc_id        = local.hub_vpc_id
  peer_vpc_id   = local.spoke2_vpc_id
  auto_accept   = true

  tags = {
    Name      = "hub-to-spoke2"
    ManagedBy = "terraform"
  }
}

resource "aws_vpc_peering_connection_options" "hub_spoke2" {
  vpc_peering_connection_id = aws_vpc_peering_connection.hub_spoke2.id

  accepter  { allow_remote_vpc_dns_resolution = true }
  requester { allow_remote_vpc_dns_resolution = true }
}

# Hub -> Spoke2 routes (private)
resource "aws_route" "hub_to_spoke2_private" {
  count                     = length(local.hub_private_rts)
  route_table_id            = local.hub_private_rts[count.index]
  destination_cidr_block    = local.spoke2_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.hub_spoke2.id
}

# Hub -> Spoke2 routes (public)
resource "aws_route" "hub_to_spoke2_public" {
  route_table_id            = local.hub_public_rt
  destination_cidr_block    = local.spoke2_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.hub_spoke2.id
}

# Spoke2 -> Hub routes (private)
resource "aws_route" "spoke2_to_hub_private" {
  count                     = length(local.spoke2_private_rts)
  route_table_id            = local.spoke2_private_rts[count.index]
  destination_cidr_block    = local.hub_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.hub_spoke2.id
}

# Spoke2 -> Hub routes (public)
resource "aws_route" "spoke2_to_hub_public" {
  route_table_id            = local.spoke2_public_rt
  destination_cidr_block    = local.hub_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.hub_spoke2.id
}
