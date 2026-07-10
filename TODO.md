# TODO List

## Phase 1: Terraform Foundation (Multi-Environment)
- [ ] Set up Terraform backend (S3 bucket, DynamoDB table)
- [ ] Create directory structure: `terraform/environments/{dev,staging,prod}`
- [ ] Create shared modules: VPC, EKS, IAM, RDS
- [ ] Create root modules for each environment
- [ ] Write Makefile for Terraform commands
- [ ] Test deployment of a single environment (dev)

## Phase 2: Kubernetes Base Setup & GitOps
- [ ] Install Argo CD and Argo Rollouts
- [ ] Deploy Chaos Mesh
- [ ] Set up monitoring stack (Prometheus, Grafana, Loki)
- [ ] Install policy engine (Kyverno)
- [ ] Install AWS Load Balancer Controller
- [ ] Configure Argo CD applications for each component
- [ ] Set up GitOps repository structure

## Phase 3: Application Deployment & Remediation Engine
- [ ] Deploy Open WebUI using official image
- [ ] Configure connection to RDS PostgreSQL and Gemini API
- [ ] Set up Argo Rollouts for progressive delivery
- [ ] Develop Python remediation agent
- [ ] Deploy remediation engine as Kubernetes job/deployment

## Phase 4: Automation & Observability Enhancements
- [x] Create Lambda functions for cost alerts and chaos scheduling
- [x] Set up Prometheus alerting rules
- [x] Configure log retention and indexing
- [x] Implement health checks in applications
- [x] Document cost-guard procedures

## Phase 5: Validation, Testing, & Documentation
- [ ] Conduct chaos engineering experiments
- [ ] Verify remediation responses
- [ ] Test application recovery
- [ ] Create runbooks and operational guides
- [ ] Finalize documentation

## Ongoing
- [ ] Update decision records in `decisions/` directory
- [ ] Keep `TODO.md` current
- [ ] Ensure code quality and testing