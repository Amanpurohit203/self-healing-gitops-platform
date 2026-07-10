# EKS Module for Self-Healing GitOps Platform
# Creates an EKS cluster with node groups

variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID to deploy the cluster in"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs to deploy the cluster in"
  type        = list(string)
}

variable "instance_types" {
  description = "List of instance types for node groups"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "desired_capacity" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}

variable "min_capacity" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_subnet_ids" {
  description = "Subnet IDs for worker nodes"
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# IAM Role for EKS Cluster
data "aws_iam_policy_document" "eks_cluster_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks_cluster" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume_role.json

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-cluster-role"
    }
  )
}

# Attach managed policies for EKS cluster
resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSServicePolicy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

# IAM Role for EKS Node Groups
data "aws_iam_policy_document" "eks_nodegroup_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks_nodegroup" {
  name = "${var.cluster_name}-nodegroup-role"

  assume_role_policy = data.aws_iam_policy_document.eks_nodegroup_assume_role.json

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-nodegroup-role"
    }
  )
}

# Attach managed policies for EKS node groups
resource "aws_iam_role_policy_attachment" "eks_nodegroup_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.eks_nodegroup.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_nodegroup_AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.eks_nodegroup.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_nodegroup_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.eks_nodegroup.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# EKS Cluster
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = "1.27"

  vpc_config {
    subnet_ids = var.subnet_ids
    # Security groups will be created below
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSServicePolicy,
  ]

  tags = merge(
    var.tags,
    {
      Name = var.cluster_name
    }
  )
}

# EKS Node Group
resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "primary"
  node_role_arn   = aws_iam_role.eks_nodegroup.arn
  subnet_ids      = var.node_subnet_ids

  scaling_config {
    desired_size = var.desired_capacity
    max_size     = var.max_capacity
    min_size     = var.min_capacity
  }

  instance_types = var.instance_types

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_nodegroup_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks_nodegroup_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks_nodegroup_AmazonEC2ContainerRegistryReadOnly,
  ]

  tags = merge(
    var.tags,
    {
      "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
      "k8s.io/cluster-autoscaler/enabled"            = "true"
    }
  )
}

# Create security group for EKS cluster control plane
resource "aws_security_group" "cluster" {
  name        = "${var.cluster_name}-cluster-sg"
  description = "Security group for EKS cluster control plane communication"
  vpc_id      = var.vpc_id

  ingress {
    description      = "HTTPS from worker nodes"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    security_groups  = [aws_security_group.nodes.id]
  }

  ingress {
    description      = "HTTPS from control plane to worker nodes"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    self             = true
  }

  egress {
    description      = "HTTPS to worker nodes"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    security_groups  = [aws_security_group.nodes.id]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-cluster-sg"
    }
  )
}

# Create security group for EKS worker nodes
resource "aws_security_group" "nodes" {
  name        = "${var.cluster_name}-nodes-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  # Allow inbound from cluster control plane on ports 443 and 10250
  ingress {
    description      = "HTTPS from cluster control plane"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    security_groups  = [aws_security_group.cluster.id]
  }

  ingress {
    description      = "HTTPS from cluster control plane"
    from_port        = 10250
    to_port          = 10250
    protocol         = "tcp"
    security_groups  = [aws_security_group.cluster.id]
  }

  # Allow worker nodes to communicate with each other
  ingress {
    description      = "Worker node communication"
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    self             = true
  }

  # Allow outbound to the internet (for pulling images, etc.)
  egress {
    description      = "Internet access"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-nodes-sg"
    }
  )
}

# Update the cluster's VPC config to include the security groups
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = "1.27"

  vpc_config {
    subnet_ids          = var.subnet_ids
    security_group_ids  = [aws_security_group.cluster.id]
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSServicePolicy,
    aws_security_group.cluster,
    aws_security_group.nodes,
  ]

  tags = merge(
    var.tags,
    {
      Name = var.cluster_name
    }
  )
}

# Outputs
output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "The endpoint URL for the EKS cluster"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_security_group_id" {
  description = "The security group ID for the EKS cluster"
  value       = aws_security_group.cluster.id
}

output "node_group_role_arn" {
  description = "The IAM role ARN for the node group"
  value       = aws_iam_role.eks_nodegroup.arn
}