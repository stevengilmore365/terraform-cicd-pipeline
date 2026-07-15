.PHONY: init validate lint scan plan clean help

ENV ?= dev
ROOT_DIR := $(shell pwd)

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

init: ## Initialize Terraform for specified environment (ENV=dev)
	cd terraform/environments/$(ENV) && terraform init

validate: ## Run terraform validate on all environments
	@bash scripts/validate.sh

lint: ## Run tflint on all modules
	tflint --init --config "$(ROOT_DIR)/.tflint.hcl"
	@find terraform -name '*.tf' -printf '%h\n' | sort -u | xargs -I {} sh -c 'echo "  Linting: {}"; tflint --config "$(ROOT_DIR)/.tflint.hcl" --chdir {} || exit 1'

scan: ## Run tfsec security scan
	tfsec terraform --format wide

plan: ## Run terraform plan (ENV=dev)
	cd terraform/environments/$(ENV) && terraform plan -out=tfplan

apply: ## Run terraform apply (ENV=dev) — requires prior plan
	cd terraform/environments/$(ENV) && terraform apply tfplan

fmt: ## Format all terraform files
	terraform fmt -recursive terraform

format: fmt ## Alias for fmt

clean: ## Remove local terraform state
	find terraform -type d -name .terraform -exec rm -rf {} + 2>/dev/null || true
	find terraform -name "*.tfplan" -delete 2>/dev/null || true
