# Monitoring Module - Deploys kube-prometheus-stack via Helm

# Kubernetes provider configuration (assumes cluster info is passed via eks module or similar)
data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

# Deploy kube-prometheus-stack Helm chart
resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  namespace  = var.namespace
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "45.24.0"  # Specify a specific version for consistency

  set {
    name  = "prometheus.enabled"
    value = var.prometheus_enabled
  }

  set {
    name  = "grafana.enabled"
    value = var.grafana_enabled
  }

  set {
    name  = "alertmanager.enabled"
    value = var.alertmanager_enabled
  }

  set {
    name  = "prometheus-node-exporter.enabled"
    value = var.prometheus_node_exporter_enabled
  }

  set {
    name  = "kubeStateMetrics.enabled"
    value = var.kube_state_metrics_enabled
  }

  set {
    name  = "prometheus.prometheusSpec.retention"
    value = var.prometheus_retention
  }

  set {
    name  = "grafana.adminPassword"
    value = var.grafana_admin_password
  }

  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage"
    value = var.prometheus_persistence_enabled ? "50Gi" : "0"
  }

  set {
    name  = "grafana.persistence.enabled"
    value = var.grafana_persistence_enabled
  }

  # Create namespace if it doesn't exist
  depends_on = [
    kubernetes_namespace.monitoring
  ]
}

# Ensure namespace exists
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.namespace
    labels = {
      app.kubernetes.io/name = "monitoring"
      app.kubernetes.io/instance = "monitoring-stack"
    }
  }
}

# Outputs
output "namespace" {
  description = "The namespace where monitoring is deployed"
  value       = kubernetes_namespace.monitoring.metadata[0].name
}

output "release_name" {
  description = "The name of the Helm release"
  value       = helm_release.kube_prometheus_stack.name
}

output "grafana_endpoint" {
  description = "Grafana service endpoint"
  value       = "http://${helm_release.kube_prometheus_stack.name}-grafana.${var.namespace}.svc.cluster.local:80"
}

output "prometheus_endpoint" {
  description = "Prometheus service endpoint"
  value       = "http://${helm_release.kube_prometheus_stack.name}-kube-prometheus-prometheus.${var.namespace}.svc.cluster.local:9090"
}