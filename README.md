# Kubernetes Infrastructure

This repository provides a complete, production-ready infrastructure stack for self-hosting media services (such as Jellyfin, Sonarr, Radarr, Bazarr, SABnzbd, etc.) on AWS and Kubernetes. It leverages modular Terraform for AWS provisioning, Helm charts for Kubernetes deployments, and robust CI/CD with GitHub Actions.

**Key Features:**

- Modular AWS infrastructure (VPC, IAM, Route53, S3, EC2, etc.)
- Kubernetes-ready: Helm charts for media services
- Secure GitHub OIDC authentication and secrets management
- Automated state migrations (Go-based)
- Containerized development and deployment (Docker)
- Pre-commit hooks and CI/CD for code quality

## Prerequisites

- Terraform >= 1.13.5
- AWS CLI configured and authenticated
- GitHub repository with Actions enabled
- Docker (optional, for containerized workflows)
- pre-commit (optional, for code quality)

## Stack Overview

**Infrastructure:**

- AWS: VPC, subnets, IAM, Route53, S3, EC2, and more (via Terraform modules)
- Kubernetes: Helm charts for media services (see `helm/media-stack`)
- State: S3 backend for Terraform state, Go-based migration system

**DevOps:**

- GitHub Actions for CI/CD (plan, apply, OIDC auth)
- Pre-commit hooks for Terraform, YAML, and Go code
- Docker-based workflows for local development

## Quick Start

### 1. Configure Variables

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edit terraform/terraform.tfvars with your values
```

### 2. Initialize & Deploy

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### 3. (Optional) Use Docker

```bash
# Build and enter a container shell
make docker-build
make docker-shell
# Or run Terraform directly
make docker-terraform CMD="plan"
```

See [DOCKER.md](DOCKER.md) for full Docker usage.

```bash
# Build Docker images
make docker-build

# Open interactive shell
make docker-shell

# Run commands directly
make docker-terraform CMD="init"
make docker-terraform CMD="plan"
make docker-terraform CMD="apply"

# Run migrations
make docker-migrate CMD="status"
```

See [DOCKER.md](DOCKER.md) for complete Docker documentation.

## Configuration

Key variables (see `terraform/variables.tf` for all options):

| Name                   | Description         | Default     |
| ---------------------- | ------------------- | ----------- |
| aws_region             | AWS region          | us-east-1   |
| environment            | Environment name    | dev         |
| vpc_cidr               | VPC CIDR block      | 10.0.0.0/16 |
| az_count               | Number of AZs       | 2           |
| github_org             | GitHub organization | ecoutu      |
| github_repo            | GitHub repository   | media-stack |
| terraform_state_bucket | S3 bucket for state | ""          |

## Outputs

Provisioning outputs include:

- VPC/subnet IDs, NAT Gateway IPs
- IAM user/role ARNs, GitHub OIDC role
- Terraform state bucket/lock table

See [`terraform/outputs.tf`](terraform/outputs.tf) for details.

## State Migrations

This project includes a Go-based migration system for safe, versioned changes to Terraform state (move, import, refactor, etc.).

**Quick usage:**

```bash
./migrate.sh status   # Check migration status
./migrate.sh up       # Apply all pending migrations
./migrate.sh down     # Rollback last migration
./migrate.sh create my_migration_name
```

See [`migrations/README.md`](migrations/README.md) for full docs.

## Development & Quality

### Pre-commit Hooks

Automated checks for Terraform, YAML, and Go code. Enforces conventional commit messages.

**Setup:**

```bash
pip install pre-commit  # or: brew install pre-commit
make pre-commit-install
```

**Checks:**

- Terraform fmt/validate/lint/docs
- YAML syntax
- Go lint (for migrations)
- Commit message style

**Bypass:**

```bash
git commit --no-verify
SKIP=terraform_validate git commit -m "feat: wip"
```

See [`GIT-HOOKS.md`](GIT-HOOKS.md) for details.

### Troubleshooting

**Hook fails on terraform validate:**

- Ensure Terraform is initialized: `cd terraform && terraform init`
- The hook will auto-initialize if needed

**Hook fails on terraform fmt:**

- Run manually to see specific issues: `terraform fmt -recursive`
- The hook will auto-format files for you

**tflint errors:**

- Install tflint: `brew install tflint` or see [tflint installation](https://github.com/terraform-linters/tflint)
- Initialize tflint plugins: `tflint --init`

## CI/CD Pipeline

GitHub Actions automate validation, planning, and deployment. OIDC authentication means no long-lived AWS credentials are required.

See [OIDC-SETUP.md](OIDC-SETUP.md) and `.github/workflows/terraform.yml`.

## Documentation & References

- [QUICK-REFERENCE.md](QUICK-REFERENCE.md) – Common commands
- [DOCKER.md](DOCKER.md) – Docker usage
- [GIT-HOOKS.md](GIT-HOOKS.md) – Git hooks and pre-commit
- [PASSWORD-SETUP.md](PASSWORD-SETUP.md) – IAM password setup
- [OIDC-SETUP.md](OIDC-SETUP.md) – GitHub OIDC setup
- [GITHUB-SECRETS-SETUP.md](GITHUB-SECRETS-SETUP.md) – Secrets configuration
- [STATE-MIGRATION.md](STATE-MIGRATION.md) – State migrations
- [migrations/README.md](migrations/README.md) – Migration system

---

**This project is maintained by [ecoutu](https://github.com/ecoutu). Contributions welcome!**
