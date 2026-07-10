# Task List - Self-Healing GitOps Platform on EKS

## Phase 1: Terraform Foundation (Multi-Environment)
- [ ] Create terraform/versions.tf (provider versions)
- [ ] Create terraform/environments/dev/main.tf (root module for dev)
- [ ] Create terraform/environments/staging/main.tf (root module for staging)
- [ ] Create terraform/environments/prod/main.tf (root module for production)
- [ ] Create terraform/modules/vpc/main.tf
- [ ] Create terraform/modules/eks/main.tf
- [ ] Create terraform/modules/iam/main.tf
- [ ] Create terraform/modules/rds/main.tf (PostgreSQL for Open WebUI)
- [ ] Create Makefile (for Terraform commands: init, plan, apply per environment)
- [ ] Configure Terraform backend per environment (separate S3 bucket/prefix or workspaces)

## Phase 2: Kubernetes Base Setup & GitOps
- [ ] Create clusters/dev/argocd/bootstrap.yaml (Argo CD bootstrap)
- [ ] Create apps/argocd/application.yaml (Argo CD self-app)
- [ ] Create apps/monitoring/kustomization.yaml (Prometheus/Grafana/Loki)
- [ ] Create apps/policy/kyverno/install.yaml
- [ ] Create apps/chaos-mesh/install.yaml
- [ ] Create apps/aws-load-balancer-controller/kustomization.yaml (or HelmRelease)
- [ ] Establish GitOps repository structure: clusters/, apps/, base/

## Phase 3: Application Deployment & Remediation Engine
- [ ] Create apps/openwebui/deployment.yaml (with Rollouts custom resource, referencing external DB secret)
- [ ] Create apps/openwebui/service.yaml
- [ ] Create apps/openwebui/horizontalpodautoscaler.yaml
- [ ] Create apps/remediation-engine/remediation.py (main engine)
- [ ] Create apps/remediation-engine/requirements.txt
- [ ] Create apps/remediation-engine/Dockerfile
- [ ] Create apps/remediation-engine/deployment.yaml

## Phase 4: Automation & Observability Enhancements
- [x] Create terraform/modules/lambda/cost-alerts/main.tf
- [x] Create terraform/modules/lambda/chaos-scheduler/main.tf
- [x] Create apps/remediation-engine/alert-rules.yaml (Prometheus rules)
- [x] Create terraform/modules/monitoring/ directory (enhanced alerting)
- [x] Document cost-guard procedures

## Phase 5: Validation, Testing, & Documentation
- [ ] Document chaos engineering experiments procedures
- [ ] Create runbooks and operational guides
- [ ] Create decisions/001-terraform-backend.md
- [ ] Create decisions/002-kyverno-vs-opa.md
- [ ] Finalize testing procedures and handoff documentation

## Initial Setup (Completed)
- [x] Created task.md
- [x] Created decisions/ directory
- [x] Updated CLAUDE.md with project-specific context and instructions