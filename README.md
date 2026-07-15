# Terraform CI/CD Pipeline

Production-ready GitHub Actions CI/CD pipeline for Terraform infrastructure with multi-environment support, security scanning, and policy enforcement.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        GitHub Actions Pipeline                      │
├─────────────┬───────────────┬──────────────┬───────────────┬────────┤
│  Validate   │ Security Scan │     Plan     │  Apply (dev)  │ Apply  │
│  & Lint     │               │              │               │(staging│
│             │               │              │               │ & prod)│
├─────────────┼───────────────┼──────────────┼───────────────┼────────┤
│ terraform   │ tfsec         │ terraform    │ terraform     │ Manual │
│ fmt         │ trivy         │ plan         │ apply         │ Gate   │
│ validate    │ checkov       │ PR Comment   │ (auto)        │        │
│ tflint      │               │              │               │        │
└─────────────┴───────────────┴──────────────┴───────────────┴────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    │               │               │
                ┌───┴───┐       ┌───┴───┐       ┌───┴───┐
                │  Dev  │       │Staging│       │ Prod  │
                └───────┘       └───────┘       └───────┘
```

## Directory Structure

```
terraform-cicd-pipeline/
├── .github/workflows/
│   ├── terraform.yml          # Main CI/CD pipeline
│   └── security-scan.yml      # Security scanning workflow
├── terraform/
│   ├── modules/
│   │   ├── vpc/               # VPC with public/private subnets, NAT, flow logs
│   │   ├── s3/                # S3 bucket with encryption, versioning, public block
│   │   ├── eks/               # EKS cluster with managed node groups
│   │   └── iam/               # IAM users, groups, and scoped policies
│   └── environments/
│       ├── dev/               # Development environment
│       ├── staging/           # Staging environment
│       └── prod/              # Production environment
├── policies/
│   ├── s3_no_public_access.rego
│   ├── s3_encryption.rego
│   ├── required_tags.rego
│   ├── iam_no_wildcard.rego
│   ├── vpc_flow_logs.rego
│   └── eks_no_public_api.rego
├── scripts/
│   └── validate.sh            # Local validation script
├── Dockerfile                 # Sample app container (Trivy demo)
├── .pre-commit-config.yaml    # Pre-commit hooks
├── .tflint.hcl                # TFLint configuration
├── Makefile                   # Build automation targets
└── README.md
```

## Pipeline Stages

### 1. Validate & Lint
- **terraform fmt** — enforces consistent formatting
- **terraform validate** — checks syntax and internal consistency
- **tflint** — catches common mistakes and best practice violations
- **tfsec** — identifies security misconfigurations in Terraform code

### 2. Security Scan
- **tfsec** — Terraform-specific security analysis
- **Trivy** — container filesystem vulnerability scanning
- **Checkov** — policy-as-code scanning for infrastructure

### 3. Plan
- Runs `terraform plan` for all three environments in parallel
- Posts plan output as PR comments for review
- Gates: must pass validation and security scan first

### 4. Apply (Dev → Staging → Prod)
- Sequential rollout: dev applies first, then staging, then prod
- **Dev**: automatic on merge to main
- **Staging**: automatic after dev succeeds
- **Prod**: requires manual approval via GitHub environment protection rules

## Quick Start

### Prerequisites
- Terraform >= 1.5.0
- tflint >= 0.45.0
- tfsec >= 1.28.0
- AWS CLI configured with appropriate credentials
- GitHub repository with Actions enabled

### Local Development

```bash
# Validate everything locally
make validate

# Initialize a specific environment
make init ENV=dev

# Run security scan
make scan

# Plan changes
make plan ENV=dev
```

### Setup

1. **Clone and configure**:
   ```bash
   git clone <repo-url>
   cd terraform-cicd-pipeline
   ```

2. **Create S3 backend** (one-time):
   ```bash
   aws s3 mb s3://terraform-state-cicd-pipeline --region us-east-1
   aws dynamodb create-table \
     --table-name terraform-locks \
     --attribute-definitions AttributeName=LockID,AttributeType=S \
     --key-schema AttributeName=LockID,KeyType=HASH \
     --billing-mode PAY_PER_REQUEST \
     --region us-east-1
   ```

3. **Configure GitHub Secrets**:
   - `AWS_ROLE_ARN` — IAM role ARN for GitHub OIDC authentication

4. **Set up environments** in GitHub Settings:
   - Create `dev`, `staging`, and `production` environments
   - Add required reviewers to `production` for manual approval

5. **Install pre-commit hooks**:
   ```bash
   pip install pre-commit
   pre-commit install
   ```

## OPA/Rego Policies

| Policy | Purpose |
|--------|---------|
| `s3_no_public_access.rego` | Blocks S3 buckets without public access blocks and encryption |
| `required_tags.rego` | Enforces Project, Environment, and ManagedBy tags on all resources |
| `iam_no_wildcard.rego` | Prevents wildcard IAM policies (Action: *, Resource: *) |
| `vpc_flow_logs.rego` | Requires VPC flow logs on all VPCs |
| `eks_no_public_api.rego` | Blocks EKS clusters with public API endpoints |

## Security Features

- **Encryption at rest**: S3 buckets use AES256 by default
- **Public access blocked**: All S3 buckets have public access blocked
- **Flow logs**: All VPCs have flow logs enabled (30-day retention)
- **Least privilege**: IAM policies scoped to specific resources and regions
- **Container scanning**: Trivy scans for OS and library vulnerabilities
- **Infrastructure scanning**: tfsec + Checkov catch misconfigurations

## Decision Rationale

### Why OIDC over static credentials?
OIDC eliminates long-lived AWS credentials in GitHub Secrets. The workflow assumes a pre-configured IAM role, getting short-lived credentials per job run.

### Why sequential environment rollout?
Dev → Staging → Prod sequencing catches issues before they reach production. If dev fails, staging and prod never attempt to apply.

### Why manual approval only for prod?
Dev and staging are low-risk environments where rapid iteration matters. Prod requires human review because changes affect real users and data.

### Why separate security-scan.yml?
Running security scans in parallel with the main pipeline reduces overall run time. The security workflow focuses specifically on vulnerability scanning without blocking the Terraform pipeline.

## Contributing

1. Create a feature branch
2. Install pre-commit hooks: `pre-commit install`
3. Make changes following the existing module patterns
4. Run `make validate` before pushing
5. Open a PR — the pipeline will run automatically
