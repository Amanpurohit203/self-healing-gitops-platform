variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace to deploy monitoring stack"
  type        = string
  default     = "monitoring"
}

variable "prometheus_enabled" {
  description = "Enable Prometheus deployment"
  type        = bool
  default     = true
}

variable "grafana_enabled" {
  description = "Enable Grafana deployment"
  type        = bool
  default     = true
}

variable "alertmanager_enabled" {
  description = "Enable Alertmanager deployment"
  type        = bool
  default     = true
}

variable "prometheus_node_exporter_enabled" {
  description = "Enable Prometheus node-exporter"
  type        = bool
  default     = true
}

variable "kube_state_metrics_enabled" {
  description = "Enable kube-state-metrics"
  type        = bool
  default     = true
}

variable "prometheus_persistence_enabled" {
  description = "Enable persistent storage for Prometheus"
  type        = bool
  default     = false
}

variable "grafana_persistence_enabled" {
  description = "Enable persistent storage for Grafana"
  type        = bool
  default     = false
}

variable "prometheus_retention" {
  description = "Prometheus data retention time"
  type        = string
  default     = "15d"
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  default     = "grafana"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}