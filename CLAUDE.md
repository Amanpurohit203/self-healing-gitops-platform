# Self-Healing GitOps Platform on EKS

## Project Overview
This project implements a self-healing GitOps platform on Amazon EKS using Infrastructure as Code (IaC) and GitOps principles. The platform includes:
- Multi-environment Terraform foundation for EKS clusters
- GitOps tooling (Argo Rollouts for progressive delivery)
- Chaos engineering (Chaos Mesh)
- Observability stack (Prometheus, Grafana, Loki)
- Policy enforcement (Kyverno/OPA)
- Self-healing remediation engine (Python-based)
- Automated cost alerts and chaos scheduling (AWS Lambda)
- Deployed workload: Open WebUI connected to Gemini API

## Directory Structure
- `terraform/` - Infrastructure as Code using Terraform
- `decisions/` - Architectural decision records
- `scripts/` - Utility scripts
- `docs/` - Documentation

## Getting Started
1. Review the implementation plan in `.claude/plans/project-goal-self-healing-gitops-delightful-gizmo.md`
2. Check `TODO.md` for current tasks
3. Refer to `decisions/` for architectural decisions

## Development Guidelines
- Follow the phased approach outlined in the plan
- Update decision records in `decisions/` for significant architectural choices
- Keep `TODO.md` updated with progress
- Ensure all infrastructure changes go through Terraform
- All Kubernetes resources should be managed via GitOps (Argo CD)
- **CRITICAL: Only write and edit files — never run any commands that execute, apply, deploy, or modify real infrastructure.**
  - Do NOT run `terraform init`, `terraform plan`, `terraform apply`, `terraform destroy`
  - Do NOT run `kubectl apply`, `kubectl delete`, or any command that talks to a real cluster
  - Do NOT run `aws` CLI commands that create, modify, or delete resources
  - Do NOT run `docker build`/`docker push` or anything that deploys containers
  - Read-only checks are fine if needed for context (e.g. `terraform fmt -check`, `cat`, `ls`, `git status`)

## Contact
For questions, refer to the project maintainers.