# Self-Healing GitOps Platform

A production-style, self-healing infrastructure platform built on AWS EKS. The platform combines GitOps-based continuous delivery with automated chaos engineering and remediation — when failures are injected into the cluster, a custom Python-based remediation engine detects and responds automatically, without manual intervention.

## Overview

This project demonstrates end-to-end platform reliability engineering practices across infrastructure provisioning, progressive delivery, observability, policy enforcement, and automated incident response — built and deployed on real AWS infrastructure.

**Application layer:** [Open WebUI](https://github.com/open-webui/open-webui), connected to a Gemini-backed LLM, deployed as the platform's running workload.

## Architecture

```
                    ┌─────────────────────────────────────────┐
                    │              AWS (Terraform)             │
                    │  ┌─────────────────────────────────┐    │
                    │  │        Amazon EKS Cluster         │    │
                    │  │                                   │    │
                    │  │  ┌───────────┐   ┌─────────────┐ │    │
                    │  │  │ Open WebUI│   │  Chaos Mesh │ │    │
                    │  │  │  (LLM app)│◄──┤  (failure    │ │    │
                    │  │  └───────────┘   │   injection) │ │    │
                    │  │        ▲          └─────────────┘ │    │
                    │  │        │                 │         │    │
                    │  │  ┌─────┴──────┐   ┌──────▼──────┐ │    │
                    │  │  │ ArgoCD +   │   │  Python      │ │    │
                    │  │  │ Argo       │   │  Remediation │ │    │
                    │  │  │ Rollouts   │   │  Engine      │ │    │
                    │  │  └────────────┘   └─────────────┘ │    │
                    │  │        ▲                 │         │    │
                    │  │  ┌─────┴─────────────────▼──────┐ │    │
                    │  │  │  Prometheus · Grafana · Loki  │ │    │
                    │  │  └───────────────────────────────┘ │    │
                    │  │  ┌───────────────────────────────┐ │    │
                    │  │  │   Kyverno / OPA (Policy)      │ │    │
                    │  │  └───────────────────────────────┘ │    │
                    │  └─────────────────────────────────────┘    │
                    │              ▲                              │
                    │       ┌──────┴───────┐                     │
                    │       │  AWS Lambda   │                     │
                    │       │ (cost/chaos   │                     │
                    │       │  scheduling)  │                     │
                    │       └───────────────┘                     │
                    └─────────────────────────────────────────┘
```

## Features

- **Multi-environment infrastructure** (dev/staging/prod) provisioned via Terraform on AWS EKS
- **GitOps continuous delivery** using ArgoCD, with progressive rollouts via Argo Rollouts
- **Automated chaos engineering** — failure injection via Chaos Mesh (pod kills, network latency, resource stress)
- **Self-healing remediation** — a custom Python engine watches cluster state and automatically remediates injected failures
- **Full observability stack** — Prometheus for metrics, Grafana for dashboards, Loki for log aggregation
- **Policy-as-code enforcement** — Kyverno/OPA guardrails applied cluster-wide
- **Cost & chaos scheduling** — AWS Lambda functions manage scheduled chaos experiments and cost-saving teardown/scale-down routines
- **LLM-backed application workload** — Open WebUI connected to the Gemini API, running as the platform's live application

## Tech Stack

| Layer | Tools |
|---|---|
| Infrastructure as Code | Terraform |
| Container Orchestration | Kubernetes (Amazon EKS) |
| GitOps / Delivery | ArgoCD, Argo Rollouts |
| Chaos Engineering | Chaos Mesh |
| Remediation | Python |
| Observability | Prometheus, Grafana, Loki |
| Policy Enforcement | Kyverno, OPA |
| Automation | AWS Lambda |
| Application | Open WebUI (Gemini API) |

## Repository Structure

```
self-healing-gitops-platform/
├── terraform/              # Multi-environment infra (VPC, EKS, IAM, networking)
│   ├── environments/
│   │   ├── dev/
│   │   ├── staging/
│   │   └── prod/
│   └── modules/
├── argocd/                 # ArgoCD application manifests & Argo Rollouts specs
├── chaos-mesh/             # Chaos experiment definitions
├── remediation-engine/     # Python-based self-healing engine
├── monitoring/             # Prometheus, Grafana, Loki configs & dashboards
├── policies/               # Kyverno / OPA policy definitions
├── lambda/                 # AWS Lambda functions for scheduling & cost automation
└── README.md
```

## How It Works

1. **Provision infrastructure** — Terraform provisions VPC, EKS cluster, and supporting AWS resources per environment.
2. **Deploy via GitOps** — ArgoCD syncs application and platform manifests from this repo; Argo Rollouts manages progressive delivery (canary/blue-green).
3. **Inject failure** — Chaos Mesh experiments simulate real-world failure conditions (pod crashes, network issues, resource exhaustion).
4. **Detect & remediate** — The remediation engine continuously watches cluster health signals and automatically takes corrective action (e.g., restarting failed workloads, scaling resources) without manual intervention.
5. **Observe** — Prometheus, Grafana, and Loki provide real-time metrics, dashboards, and logs to verify system health and remediation actions.
6. **Enforce policy** — Kyverno/OPA policies validate that all deployed resources meet security and compliance guardrails.
7. **Automate cost/chaos scheduling** — Lambda functions run scheduled chaos experiments and scale infrastructure down during idle periods to control cloud costs.

## Getting Started

### Prerequisites
- AWS account with configured CLI credentials
- Terraform >= 1.x
- kubectl
- ArgoCD CLI
- Helm

### Setup

```bash
# 1. Clone the repository
git clone https://github.com/Amanpurohit203/self-healing-gitops-platform.git
cd self-healing-gitops-platform

# 2. Provision infrastructure
cd terraform/environments/dev
terraform init
terraform plan
terraform apply

# 3. Configure kubectl
aws eks update-kubeconfig --name <cluster-name> --region <region>

# 4. Bootstrap ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 5. Apply ArgoCD applications
kubectl apply -f argocd/

# 6. Deploy monitoring stack
helm install monitoring ./monitoring

# 7. Deploy Chaos Mesh
helm repo add chaos-mesh https://charts.chaos-mesh.org
helm install chaos-mesh chaos-mesh/chaos-mesh -n chaos-testing --create-namespace

# 8. Run the remediation engine
kubectl apply -f remediation-engine/
```

## Notes

This project was built as a hands-on platform engineering exercise to demonstrate GitOps, chaos engineering, and automated remediation practices on real AWS infrastructure — not a tutorial walkthrough. Design decisions, debugging, and tool selection were driven by practical constraints encountered during the build (documented in commit history).

## Author

**Aman Purohit**
Cloud DevOps Engineer | AWS · Terraform · Kubernetes · GitOps
[LinkedIn](https://www.linkedin.com/in/aman-purohit-795ab4211/) · [GitHub](https://github.com/Amanpurohit203)
