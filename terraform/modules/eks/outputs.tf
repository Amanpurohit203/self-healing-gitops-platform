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

output "cluster_id" {
  description = "The ID of the EKS cluster"
  value       = aws_eks_cluster.this.id
}

output "node_group_role_arn" {
  description = "The IAM role ARN for the node group"
  value       = aws_iam_role.eks_nodegroup.arn
}

output "vpc_id" {
  description = "The VPC ID where the cluster is deployed"
  value       = var.vpc_id
}

output "subnet_ids" {
  description = "The subnet IDs where the cluster is deployed"
  value       = var.subnet_ids
}