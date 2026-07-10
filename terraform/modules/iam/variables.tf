variable "name_prefix" {
  description = "Prefix to use for all IAM resources"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "create_oidc_provider" {
  description = "Whether to create an OIDC provider for EKS service accounts"
  type        = bool
  default     = true
}