terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.10.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.10.1"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
  backend "s3" {
    bucket  = "psinc-state"
    key     = "base.tf"
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
  source          = "./modules/base"
  name            = "eks-vpc"
  cluster_name    = "abyaz"
  vpc_cidr        = local.vpc_cidr
  azs             = local.azs
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets
}

module "eks" {
  source          = "./modules/cluster"
  cluster_name    = "abyaz"
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

data "aws_eks_cluster_auth" "cluster" {
  name = "abyaz"
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", "abyaz"]
    command     = "aws"
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", "abyaz"]
      command     = "aws"
    }
  }
}

data "aws_caller_identity" "current" {
}

module "argocd" {
  source = "./modules/api/argocd"
  values = [
    templatefile("./templates/values.yaml.tpl",
      {
        "argocd_ingress_enabled"          = true
        "argocd_ingress_class"            = "alb"
        "argocd_server_host"              = "argocd.psinc.click"
        "argocd_load_balancer_name"       = "argocd-alb-ingress"
        "argocd_ingress_tls_acme_enabled" = true
      }
    )
  ]
}

module "alb" {
  source                       = "./modules/api/aws-load-balancer-controller"
  vpc_id                       = module.network.vpc_id
  cluster_name                 = "abyaz"
  public_subnets               = module.network.public_subnets
  alb_controller_chart_name    = "aws-load-balancer-controller"
  alb_controller_chart_repo    = "https://aws.github.io/eks-charts"
  alb_controller_chart_version = "1.5.5"
}
