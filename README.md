# Terraform Infrastructure Stack

AWS infrastructure with VPC, IAM, and CI/CD using modular Terraform and GitHub Actions.

## Prerequisites

- Terraform >= 1.13.5
- AWS CLI configured
- GitHub repository with Actions enabled
- **Optional**: Docker for containerized development

## Features

- Modular architecture with reusable components
- VPC with public/private subnets across AZs
- IAM users, roles, and GitHub OIDC authentication
- State management with S3 backend
- Go-based state migration system
- GitHub Actions CI/CD with plan/apply workflow

## Usage

### Native Installation

1. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` with your desired values

3. Initialize Terraform:
   ```bash
   terraform init
   ```

4. Review the planned changes:
   ```bash
   terraform plan
   ```

5. Apply the configuration:
   ```bash
   terraform apply
   ```

6. Destroy resources when needed:
   ```bash
   terraform destroy
   ```

### Docker Usage

Run Terraform in a containerized environment:

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

## Key Variables

| Name | Description | Default |
|------|-------------|----------|
| aws_region | AWS region | us-east-1 |
| environment | Environment name | dev |
| vpc_cidr | VPC CIDR block | 10.0.0.0/16 |
| az_count | Number of AZs | 2 |
| github_org | GitHub organization | ecoutu |
| github_repo | GitHub repository | terraform-stack |
| terraform_state_bucket | S3 bucket for state | "" |

See [variables.tf](variables.tf) for complete list.

## Outputs

Key outputs include:
- VPC ID, subnet IDs, and NAT Gateway IPs
- IAM user ARN, access keys, and admin role
- GitHub Actions role ARN and OIDC provider
- Terraform state bucket and lock table

See [outputs.tf](outputs.tf) for complete list.

## State Migrations

This project includes a Go-based migration system for managing Terraform state changes, similar to database migrations.

### Quick Start

```bash
# Check migration status
./migrate.sh status

# Apply all pending migrations
./migrate.sh up

# Rollback last migration
./migrate.sh down

# Create new migration
./migrate.sh create my_migration_name
```

See [migrations/README.md](migrations/README.md) for complete documentation.

### Using Make

```bash
# Show available commands
make help

# Check migration status
make migrate-status

# Apply migrations
make migrate-up

# Create new migration
make migrate-create NAME=my_migration
```

### When to Use Migrations

Use migrations when you need to:
- Move resources between modules
- Rename resources without destroying them
- Import existing AWS resources
- Remove resources from state management
- Refactor module structure

### Learn More

- [migrations/README.md](migrations/README.md) - Complete migration system documentation
- [migrations/MIGRATION-SYSTEM.md](migrations/MIGRATION-SYSTEM.md) - Migration system overview and comparison
- [STATE-MIGRATION.md](STATE-MIGRATION.md) - Migration guide

## CI/CD Pipeline

GitHub Actions workflow with:
- Validation and format checking
- Terraform plan on pull requests
- Manual approval for production apply
- OIDC authentication (no stored credentials)

See [.github/workflows/terraform.yml](.github/workflows/terraform.yml) and [OIDC-SETUP.md](OIDC-SETUP.md).

## Documentation

- [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - Common commands
- [DOCKER.md](DOCKER.md) - Docker usage
- [PASSWORD-SETUP.md](PASSWORD-SETUP.md) - IAM password setup
- [OIDC-SETUP.md](OIDC-SETUP.md) - GitHub OIDC setup
- [GITHUB-SECRETS-SETUP.md](GITHUB-SECRETS-SETUP.md) - Secrets configuration
- [STATE-MIGRATION.md](STATE-MIGRATION.md) - State migrations
- [migrations/README.md](migrations/README.md) - Migration system
