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
  description = "The ARN of the Loki IAM role
  value       = aws_iam_role.loki.arn
}

output "kafka_role_arn" {
  description = "The ARN of the Kafka IAM role"
  value       = aws_iam_role.kafka.arn
}