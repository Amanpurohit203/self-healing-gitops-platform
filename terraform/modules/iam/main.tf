# IAM Module for Self-Healing GitOps Platform
# Creates IAM roles and policies for EKS and other services

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

# IAM Role for EKS Service Accounts (if OIDC provider is enabled)
resource "aws_iam_openid_connect_provider" "eks" {
  count = var.create_oidc_provider ? 1 : 0

  url = "https://oidc.eks.${data.aws_region.current.name}.amazonaws.com/id/${data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer}"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    "9e99a48a9960b14926bb7f3b02e22da2b0ab7280" # Amazon root CA 1
  ]

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-oidc-provider"
    }
  )
}

# IAM Role for AWS Load Balancer Controller
data "aws_iam_policy_document" "alb_ingress_controller_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "alb_ingress_controller" {
  name = "${var.name_prefix}-alb-ingress-controller"

  assume_role_policy = data.aws_iam_policy_document.alb_ingress_controller_assume_role.json

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-alb-ingress-controller"
    }
  )
}

# Attach AWS managed policies for ALB Ingress Controller
resource "aws_iam_role_policy_attachment" "alb_ingress_controller_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.alb_ingress_controller.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "alb_ingress_controller_AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.alb_ingress_controller.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "alb_ingress_controller_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.alb_ingress_controller.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# IAM Role for Autoscaler
data "aws_iam_policy_document" "autoscaler_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "autoscaler" {
  name = "${var.name_prefix}-cluster-autoscaler"

  assume_role_policy = data.aws_iam_policy_document.autoscaler_assume_role.json

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-cluster-autoscaler"
    }
  )
}

# Attach AWS managed policies for Cluster Autoscaler
resource "aws_iam_role_policy_attachment" "autoscaler_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.autoscaler.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "autoscaler_AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.autoscaler.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "autoscaler_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.autoscaler.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# IAM Role for ExternalDNS
data "aws_iam_policy_document" "externaldns_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "externaldns" {
  name = "${var.name_prefix}-external-dns"

  assume_role_policy = data.aws_iam_policy_document.externaldns_assume_role.json

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-external-dns"
    }
  )
}

# Attach AWS managed policies for ExternalDNS
resource "aws_iam_role_policy_attachment" "externaldns_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.externaldns.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "externaldns_AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.externaldns.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "externaldns_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.externaldns.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Custom policy for ExternalDNS to manage Route53 records
data "aws_iam_policy_document" "externaldns_route53" {
  statement {
    effect = "Allow"

    actions = [
      "route53:ChangeResourceRecordSets",
    ]

    resources = [
      "arn:aws:route53:::hostedzone/*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "externaldns_route53" {
  name        = "${var.name_prefix}-external-dns-route53"
  description = "Policy for ExternalDNS to manage Route53 records"
  policy      = data.aws_iam_policy_document.externaldns_route53.json

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-external-dns-route53"
    }
  )
}

resource "aws_iam_role_policy_attachment" "externaldns_route53_attachment" {
  role       = aws_iam_role.externaldns.name
  policy_arn = aws_iam_policy.externaldns_route53.arn
}

# IAM Role for Cert-Manager
data "aws_iam_policy_document" "cert_manager_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cert_manager" {
  name = "${var.name_prefix}-cert-manager"

  assume_role_policy = data.aws_iam_policy_document.cert_manager_assume_role.json

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-cert-manager"
    }
  )
}

# Attach AWS managed policies for Cert-Manager
resource "aws_iam_role_policy_attachment" "cert_manager_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.cert_manager.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "cert_manager_AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.cert_manager.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "cert_manager_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.cert_manager.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# IAM Role for Prometheus
data "aws_iam_policy_document" "prometheus_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "prometheus" {
  name = "${var.name_prefix}-prometheus"

  assume_role_policy = data.aws_iam_policy_document.prometheus_assume_role.json

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-prometheus"
    }
  )
}

# Attach AWS managed policies for Prometheus
resource "aws_iam_role_policy_attachment" "prometheus_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.prometheus.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "prometheus_AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.prometheus.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "prometheus_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.prometheus.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# IAM Role for Grafana
data "aws_iam_policy_document" "grafana_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "grafana" {
  name = "${var.name_prefix}-grafana"

  assume_role_policy = data.aws_iam_policy_document.grafana_assume_role.json

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-grafana"
    }
  )
}

# Attach AWS managed policies for Grafana
resource "aws_iam_role_policy_attachment" "grafana_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.grafana.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "grafana_AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.grafana.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "grafana_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.grafana.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# IAM Role for Loki
data "aws_iam_policy_document" "loki_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "loki" {
  name = "${var.name_prefix}-loki"

  assume_role_policy = data.aws_iam_policy_document.loki_assume_role.json

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-loki"
    }
  )
}

# Attach AWS managed policies for Loki
resource "aws_iam_role_policy_attachment" "loki_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role_policy_attachment" "loki_AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.loki.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "loki_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.loki.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# IAM Role for Kafka
data "aws_iam_policy_document" "kafka_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "kafka" {
  name = "${var.name_prefix}-kafka"

  assume_role_policy = data.aws_iam_policy_document.kafka_assume_role.json

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-kafka"
    }
  )
}

# Attach AWS managed policies for Kafka
resource "aws_iam_role_policy_attachment" "kafka_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.kafka.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
}

resource "aws_iam_role_policy_attachment" "kafka_AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.kafka.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "kafka_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.kafka.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Outputs
output "oidc_issuer_url" {
  description = "The URL of the OIDC provider"
  value       = aws_iam_openid_connect_provider.eks[0].url
}

output "oidc_issuer_arn" {
  description = "The ARN of the OIDC provider"
  value       = aws_iam_openid_connect_provider.eks[0].arn
}

output "alb_ingress_controller_role_arn" {
  description = "The ARN of the ALB Ingress Controller IAM role"
  value       = aws_iam_role.alb_ingress_controller.arn
}

output "autoscaler_role_arn" {
  description = "The ARN of the Cluster Autoscaler IAM role"
  value       = aws_iam_role.autoscaler.arn
}

output "externaldns_role_arn" {
  description = "The ARN of the ExternalDNS IAM role"
  value       = aws_iam_role.externaldns.arn
}

output "cert_manager_role_arn" {
  description = "The ARN of the Cert-Manager IAM role"
  value       = aws_iam_role.cert_manager.arn
}

output "prometheus_role_arn" {
  description = "The ARN of the Prometheus IAM role"
  value       = aws_iam_role.prometheus.arn
}

output "grafana_role_arn" {
  description = "The ARN of the Grafana IAM role"
  value       = aws_iam_role.grafana.arn
}

output "loki_role_arn" {
  description = "The ARN of the Loki IAM role"
  value       = aws_iam_role.loki.arn
}

output "kafka_role_arn" {
  description = "The ARN of the Kafka IAM role"
  value       = aws_iam_role.kafka.arn
}