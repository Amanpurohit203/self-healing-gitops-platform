# Makefile for Terraform operations
# Provides convenient commands for managing Terraform infrastructure

# Variables
TF_VERSION ?= 1.5.0
TERRAFORM = terraform
ENVIRONMENTS = dev staging prod

# Default target
.DEFAULT_GOAL := help

# Help target
help:
	@echo "Available targets:"
	@echo "  init-all          Initialize Terraform for all environments"
	@echo "  init-<env>        Initialize Terraform for specific environment"
	@echo "  fmt               Format Terraform files"
	@echo "  validate-all      Validate Terraform configuration for all environments"
	@echo "  validate-<env>    Validate Terraform configuration for specific environment"
	@echo "  plan-all          Create execution plan for all environments"
	@echo "  plan-<env>        Create execution plan for specific environment"
	@echo "  apply-all         Apply changes for all environments"
	@echo "  apply-<env>       Apply changes for specific environment"
	@echo "  destroy-all       Destroy all resources for all environments"
	@echo "  destroy-<env>     Destroy all resources for specific environment"
	@echo "  output-<env>      Show outputs for specific environment"
	@echo "  clean             Remove .terraform directories and lock files"

# Initialize all environments
init-all: $(addprefix init-, $(ENVIRONMENTS))

init-%:
	@echo "Initializing Terraform for $* environment..."
	@cd environments/$* && $(TERRAFORM) init

# Format Terraform files
fmt:
	@echo "Formatting Terraform files..."
	@find . -name "*.tf" -not -path "./.terraform/*" -exec $(TERRAFORM) fmt {} \;

# Validate all environments
validate-all: $(addprefix validate-, $(ENVIRONMENTS))

validate-%:
	@echo "Validating Terraform configuration for $* environment..."
	@cd environments/$* && $(TERRAFORM) validate

# Plan all environments
plan-all: $(addprefix plan-, $(ENVIRONMENTS))

plan-%:
	@echo "Creating execution plan for $* environment..."
	@cd environments/$* && $(TERRAFORM) plan -out=tfplan

# Apply all environments
apply-all: $(addprefix apply-, $(ENVIRONMENTS))

apply-%:
	@echo "Applying changes for $* environment..."
	@cd environments/$* && $(TERRAFORM) apply -auto-approve tfplan

# Destroy all environments
destroy-all: $(addprefix destroy-, $(ENVIRONMENTS))

destroy-%:
	@echo "Destroying resources for $* environment..."
	@cd environments/$* && $(TERRAFORM) destroy -auto-approve

# Show outputs
output-%:
	@echo "Outputs for $* environment:"
	@cd environments/$* && $(TERRAFORM) output

# Clean up Terraform files
clean:
	@echo "Cleaning up Terraform files..."
	@find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
	@find . -name ".terraform.lock.hcl" -type f -exec rm -f {} + 2>/dev/null || true
	@find . -name "tfplan" -type f -exec rm -f {} + 2>/dev/null || true

# Validate Terraform version
version:
	@$(TERRAFORM) version

.PHONY: help init-all init-% fmt validate-all validate-% plan-all plan-% apply-all apply-% destroy-all destroy-% output-% clean version