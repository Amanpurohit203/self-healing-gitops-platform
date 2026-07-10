# Decision 002: Policy Engine Selection (Kyverno vs OPA/Gatekeeper)

## Context
We need to choose a policy enforcement mechanism for Kubernetes that integrates well with our GitOps workflow and provides the capabilities we need for validation, mutation, and verification of resources.

## Decision
Choose Kyverno as the primary policy engine.

## Rationale
- Native Kubernetes resource format (no need to learn Rego)
- Excellent integration with kubectl and GitOps workflows
- Built-in validation, mutation, and verification capabilities
- Better performance for many use cases compared to OPA
- Active community and good documentation
- Native webhook architecture that integrates smoothly with Kubernetes

## Consequences
- Positive: Easier for team to adopt, less learning curve
- Negative: Less flexibility than OPA for highly custom policies (but sufficient for our needs)

## Status
Proposed

## Related Decisions
- May revisit if complex custom policies are needed that are better suited to Rego