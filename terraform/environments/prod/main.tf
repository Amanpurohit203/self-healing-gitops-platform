terraform {
  backend "s3" {
    bucket = "self-healing-gitops-terraform-state"
    key    = "prod/terraform.tfstate"
    region = "us-east-1"

    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

# Configure providers
provider "aws" {
  region = "us-east-1"
}

# Module configurations
module "vpc" {
  source = "../../../modules/vpc"

  name           = "prod-vpc"
  cidr           = "10.2.0.0/16"
  azs            = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
  public_subnets  = ["10.2.101.0/24", "10.2.102.0/24", "10.2.103.0/24"]

  enable_nat_gateway   = true
  enable_vpn_gateway   = false

  tags = {
    Environment = "prod"
    Terraform   = "true"
  }
}

module "eks" {
  source = "../../../modules/eks"

  cluster_name    = "prod-eks-cluster"
  cluster_version = "1.29"
  subnets         = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id

  node_group_name   = "prod-node-group"
  node_type         = "m5.large"
  node_desired_size = 3
  node_max_size     = 10
  node_min_size     = 2

  tags = {
    Environment = "prod"
    Terraform   = "true"
  }
}

module "iam" {
  source = "../../../modules/iam"

  name_prefix = "prod"

  # Create IAM role for EKS service accounts (OIDC provider)
  create_oidc_provider = true

  tags = {
    Environment = "prod"
    Terraform   = "true"
  }
}

module "rds" {
  source = "../../../modules/rds"

  identifier = "prod-openwebui-db"

  engine           = "postgres"
  engine_version   = "15.4"
  instance_class   = "db.t3.medium"
  allocated_storage = 100
  name             = "openwebui"
  username         = "dbadmin"
  password         = random_password.db.password

  vpc_security_group_ids = [module.vpc.default_security_group_id]
  subnet_ids             = slice(module.vpc.private_subnets, 0, 2)

  # Production settings
  skip_final_snapshot = false
  deletion_protection = true
  backup_retention_period = 7
  backup_window = "03:00-04:00"

  tags = {
    Environment = "prod"
    Terraform   = "true"
  }
}

# Generate a random password for the RDS instance
resource "random_password" "db" {
  length  = 16
  special = true

  # Special characters to avoid in RDS passwords
  override_special  = "_%@"
}

# Outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "eks_cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "The endpoint for the EKS cluster"
  value       = module.eks.cluster_endpoint
}

output "rds_endpoint" {
  description = "The endpoint for the RDS instance"
  value       = module.rds.endpoint
}

output "rds_password" {
  description = "The password for the RDS instance"
  value       = random_password.db.result
  sensitive   = true
}