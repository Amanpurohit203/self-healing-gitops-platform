# Outputs for Monitoring Module

output "namespace" {
  description = "The Kubernetes namespace where monitoring is deployed"
  value       = kubernetes_namespace.monitoring.metadata[0].name
}

output "release_name" {
  description = "The name of the Helm release for kube-prometheus-stack"
  value       = helm_release.kube_prometheus_stack.name
}

output "grafana_service" {
  description = "Grafana Kubernetes service details"
  value       = {
    name      = "${helm_release.kube_prometheus_stack.name}-grafana"
    namespace = var.namespace
    port      = 80
  }
}

output "prometheus_service" {
  description = "Prometheus Kubernetes service details"
  value       = {
    name      = "${helm_release.kube_prometheus_stack.name}-kube-prometheus-prometheus"
    namespace = var.namespace
    port      = 9090
  }
}

output "alertmanager_service" {
  description = "Alertmanager Kubernetes service details"
  value       = {
    name      = "${helm_release.kube_prometheus_stack.name}-kube-prometheus-alertmanager"
    namespace = var.namespace
    port      = 9093
  }
}