variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "The Kubernetes version to use"
  type        = string
  default     = "1.27"
}

variable "vpc_id" {
  description = "The VPC ID where the cluster will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs where the cluster will be deployed"
  type        = list(string)
}

variable "node_group_name" {
  description = "The name of the node group"
  type        = string
}

variable "node_type" {
  description = "The EC2 instance type for worker nodes"
  type        = string
}

variable "node_desired_size" {
  description = "The desired number of worker nodes"
  type        = number
}

variable "node_max_size" {
  description = "The maximum number of worker nodes"
  type        = number
}

variable "node_min_size" {
  description = "The minimum number of worker nodes"
  type        = number
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}