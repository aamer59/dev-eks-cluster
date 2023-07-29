terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.10.0"
    }
  }
  backend "s3" {
    bucket  = "psinc-state"
    key     = "infra.tf"
    region  = "ap-south-2"
    encrypt = true

    dynamodb_table         = "psinc-state"
    skip_region_validation = true
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

provider "aws" {
  region = "ap-south-2"
  default_tags {
    tags = {
      Project   = "EKS"
      ManagedBy = "Aamer"
      Company   = "Primesoft Inc"
      Location  = "Hyderabad"
    }
  }
}

locals {
  vpc_cidr        = "171.23.0.0/16"
  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 4)]
}

module "network" {
  source          = "./modules/network"
  name            = "eks-vpc"
  cluster_name    = "dev-eks"
  vpc_cidr        = local.vpc_cidr
  azs             = local.azs
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets
}

module "eks" {
  source          = "./modules/kubernetes"
  cluster_name    = "dev-eks"
  vpc_id          = module.network.vpc_id
  subnet_ids      = module.network.private_subnets
  cluster_version = "1.27"
  eks_managed_node_groups = {
    "eks-ondemand" = {
      ami_type     = "AL2_x86_64"
      min_size     = 1
      max_size     = 4
      desired_size = 1
      instance_types = [
        "m5.xlarge",
      ]
      capacity_type = "ON_DEMAND"
      network_interfaces = [{
        delete_on_termination       = true
        associate_public_ip_address = true
      }]
    }
  }
}
