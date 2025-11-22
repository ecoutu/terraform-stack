# Terraform Infrastructure Stack

AWS infrastructure with VPC, IAM, and CI/CD using modular Terraform and GitHub Actions.

## Prerequisites

- Terraform >= 1.13.5
- AWS CLI configured
- GitHub repository with Actions enabled
- **Optional**: Docker for containerized development
- **Optional**: pre-commit for automated code quality checks (recommended)

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
   cp terraform/terraform.tfvars.example terraform/terraform.tfvars
   ```

2. Edit `terraform/terraform.tfvars` with your desired values

3. Initialize Terraform:
   ```bash
   cd terraform && terraform init
   ```

4. Review the planned changes:
   ```bash
   cd terraform && terraform plan
   ```

5. Apply the configuration:
   ```bash
   cd terraform && terraform apply
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

See [terraform/variables.tf](terraform/variables.tf) for complete list.

## Outputs

Key outputs include:
- VPC ID, subnet IDs, and NAT Gateway IPs
- IAM user ARN, access keys, and admin role
- GitHub Actions role ARN and OIDC provider
- Terraform state bucket and lock table

See [terraform/outputs.tf](terraform/outputs.tf) for complete list.

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

## Git Hooks

This project uses pre-commit hooks to enforce code quality and commit message standards before code enters the repository.

### Setup

1. Install pre-commit:
   ```bash
   pip install pre-commit
   # or
   brew install pre-commit
   ```

2. Install the git hooks:
   ```bash
   make pre-commit-install
   ```

### What Gets Checked

When you commit code, the following checks run automatically:

**Pre-commit checks:**
- Terraform formatting (`terraform fmt`)
- Terraform validation (`terraform validate`)
- Terraform documentation generation
- Terraform linting with tflint
- YAML syntax validation
- Trailing whitespace removal
- End-of-file fixes
- Large file detection
- Go code linting (for migrations) (**temporarily disabled due to Go version compatibility issues**)

**Commit message checks:**
- Enforces conventional commit format
- Valid prefixes: `feat:`, `fix:`, `docs:`, `style:`, `refactor:`, `perf:`, `test:`, `build:`, `ci:`, `chore:`, `revert:`

### Example Commit Messages

✅ Good:
```
feat: add VPC peering module
fix: correct IAM policy for S3 access
docs: update README with new module
refactor: reorganize terraform module structure
```

❌ Bad:
```
added new feature
Fixed bug
updated documentation
```

### Bypassing Hooks

Sometimes you need to bypass hooks (use sparingly):

```bash
# Skip pre-commit hooks
git commit --no-verify

# Skip specific hooks
SKIP=terraform_validate git commit -m "feat: work in progress"
```

### Maintenance

```bash
# Update hooks to latest versions
make pre-commit-update

# Run hooks manually on all files
make pre-commit-run

# Uninstall hooks
make pre-commit-uninstall
```

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

GitHub Actions workflow with:
- Validation and format checking
- Terraform plan on pull requests
- Manual approval for production apply
- OIDC authentication (no stored credentials)

See [.github/workflows/terraform.yml](.github/workflows/terraform.yml) and [OIDC-SETUP.md](OIDC-SETUP.md).

## Documentation

- [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - Common commands
- [DOCKER.md](DOCKER.md) - Docker usage
- [GIT-HOOKS.md](GIT-HOOKS.md) - Git hooks and pre-commit setup
- [PASSWORD-SETUP.md](PASSWORD-SETUP.md) - IAM password setup
- [OIDC-SETUP.md](OIDC-SETUP.md) - GitHub OIDC setup
- [GITHUB-SECRETS-SETUP.md](GITHUB-SECRETS-SETUP.md) - Secrets configuration
- [STATE-MIGRATION.md](STATE-MIGRATION.md) - State migrations
- [migrations/README.md](migrations/README.md) - Migration system
