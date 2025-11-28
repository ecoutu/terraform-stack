# Quick Reference Guide

## Common Commands

### Local Development

```bash
# Terraform (run from terraform/ directory)
cd terraform && terraform init    # Initialize Terraform
cd terraform && terraform plan    # Preview changes
cd terraform && terraform apply   # Apply changes
cd terraform && terraform destroy # Destroy infrastructure

# Migrations
./migrate.sh status               # Check migration status
./migrate.sh up                   # Apply migrations
./migrate.sh down                 # Rollback migration
./migrate.sh create <name>        # Create new migration

# Git Hooks
./scripts/setup-dev-env.sh        # Quick setup for git hooks
make pre-commit-install           # Install pre-commit hooks
make pre-commit-run               # Run hooks on all files
make pre-commit-update            # Update hook versions
make pre-commit-uninstall         # Uninstall hooks

# Make shortcuts
make help                         # Show all commands
make build                        # Build migration tool
make test                         # Test migration tool
make init                         # Terraform init
make plan                         # Terraform plan
make apply                        # Terraform apply
```

### Docker

```bash
# Build & Run
make docker-build                 # Build Docker images
make docker-shell                 # Open shell in container
make docker-dev                   # Start dev container

# Terraform in Docker
make docker-terraform CMD="init"
make docker-terraform CMD="plan"
make docker-terraform CMD="apply"

# Migrations in Docker
make docker-migrate CMD="status"
make docker-migrate CMD="up"
make docker-migrate CMD="down"

# Cleanup
make docker-down                  # Stop containers
make docker-clean                 # Remove all Docker resources
```

## File Structure

```
kubernetes-stack/
├── terraform/                    # Terraform configuration directory
│   ├── main.tf                   # Root Terraform config
│   ├── variables.tf              # Input variables
│   ├── outputs.tf                # Output values
│   ├── terraform.tfvars          # Variable values (git-ignored)
│   └── modules/                  # Terraform modules
│       ├── iam/                  # IAM orchestration
│       ├── iam-role/             # Reusable IAM role
│       ├── iam-user/             # Reusable IAM user
│       └── vpc/                  # VPC infrastructure
│
├── migrations/                   # State migration system
│   ├── main.go                   # Migration tool source
│   ├── migrate                   # Compiled binary
│   ├── files/                    # Migration files
│   └── .migration_state.json     # Applied migrations
│
├── docker-compose.yml            # Docker Compose config
├── Dockerfile                    # Production image
├── Dockerfile.dev                # Development image
├── .env.example                  # Environment variables template
│
├── migrate.sh                    # Migration wrapper script
├── set-user-password.sh          # IAM user password helper
├── Makefile                      # Make commands
│
└── README.md                     # Project documentation
```

## Workflow Examples

### Initial Setup (Local)

```bash
# 1. Configure variables
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
vim terraform/terraform.tfvars

# 2. Initialize
cd terraform && terraform init

# 3. Check migrations
./migrate.sh status

# 4. Apply migrations (if needed)
./migrate.sh up

# 5. Plan infrastructure
cd terraform && terraform plan

# 6. Apply infrastructure
cd terraform && terraform apply
```

### Initial Setup (Docker)

```bash
# 1. Configure environment
cp .env.example .env
vim .env

# 2. Build images
make docker-build

# 3. Start container
make docker-shell

# Inside container:
terraform init
./migrate.sh status
terraform plan
terraform apply
```

### Creating a Migration

```bash
# 1. Create migration file
./migrate.sh create move_resource_to_module

# 2. Edit migration
vim migrations/files/000X_move_resource_to_module.go

# 3. Test migration
./migrate.sh up

# 4. Verify no changes
cd terraform && terraform plan

# 5. Rollback if needed
./migrate.sh down
```

### Refactoring Workflow

```bash
# 1. Create backup
cp terraform.tfstate terraform.tfstate.backup

# 2. Create migration
./migrate.sh create refactor_modules

# 3. Edit Terraform files
vim terraform/main.tf
vim terraform/modules/*/main.tf

# 4. Define migration operations
vim migrations/files/000X_refactor_modules.go

# 5. Apply migration
./migrate.sh up

# 6. Verify
cd terraform && terraform plan  # Should show no changes

# 7. If issues, rollback
./migrate.sh down
```

### CI/CD Pipeline

```yaml
# Simplified workflow
- Build Docker image
- Run migrations
- Terraform plan
- [Manual approval]
- Terraform apply
```

## Environment Variables

### AWS Configuration

```bash
# Option 1: AWS Profile
export AWS_PROFILE=my-profile
export AWS_REGION=us-east-1

# Option 2: Direct credentials
export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
export AWS_SECRET_ACCESS_KEY=wJalrXUtn...
export AWS_REGION=us-east-1
```

### Terraform Configuration

```bash
# Enable debug logging
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log

# Set workspace
export TF_WORKSPACE=production
```

## Troubleshooting

### Terraform State Locked

```bash
# Force unlock (use carefully!)
terraform force-unlock <lock-id>
```

### Migration Failed

```bash
# Check status
./migrate.sh status

# Rollback
./migrate.sh down

# Manual state fix
terraform state list
terraform state mv <source> <destination>
```

### Docker Issues

```bash
# View logs
docker-compose logs terraform

# Rebuild without cache
docker-compose build --no-cache

# Clean everything
make docker-clean
docker system prune -a
```

### AWS Credentials in Docker

```bash
# Check credentials
docker-compose run --rm terraform aws sts get-caller-identity

# Mount different AWS config
docker-compose run --rm -v ~/.aws:/root/.aws:ro terraform /bin/bash
```

## Module Usage

### IAM Module

```hcl
module "iam" {
  source = "./terraform/modules/iam"

  account_alias             = "my-account"
  require_mfa              = true
  enforce_mfa_for_users    = true
}
```

### VPC Module

```hcl
module "vpc" {
  source = "./terraform/modules/vpc"

  vpc_cidr           = "10.0.0.0/16"
  availability_zones = 2
  enable_nat_gateway = true
  project_name       = "my-project"
  environment        = "dev"
}
```

## Security Best Practices

1. **Never commit secrets**
   - Use `.gitignore` for sensitive files
   - Use environment variables or AWS Secrets Manager

2. **Use remote state**
   - Configure S3 backend for team collaboration
   - Enable state locking with DynamoDB

3. **Enable MFA**
   - Set `require_mfa = true` in IAM module
   - Configure MFA for all users

4. **Regular backups**
   - Automatic backups before migrations
   - Manual backups before major changes

5. **Least privilege**
   - Use assume role instead of direct permissions
   - Regular audit of IAM policies

## Useful Commands

```bash
# Terraform
terraform state list                          # List all resources
terraform state show <resource>               # Show resource details
terraform output                              # Show all outputs
terraform output -raw <output>                # Get raw output value
terraform graph | dot -Tpng > graph.png      # Visualize dependencies

# Migrations
./migrate.sh version                          # Current version
./migrate.sh reset                           # Reset tracking (careful!)

# AWS
aws sts get-caller-identity                  # Check AWS identity
aws iam list-users                           # List IAM users
aws ec2 describe-vpcs                        # List VPCs

# Docker
docker-compose ps                            # List containers
docker-compose exec terraform /bin/bash      # Execute in running container
docker-compose run --rm terraform <cmd>      # Run one-off command
```

## Additional Resources

- [README.md](README.md) - Project overview
- [DOCKER.md](DOCKER.md) - Docker documentation
- [GIT-HOOKS.md](GIT-HOOKS.md) - Git hooks and pre-commit setup
- [CONTRIBUTING.md](CONTRIBUTING.md) - Contribution guidelines
- [migrations/README.md](migrations/README.md) - Migration system guide
- [STATE-MIGRATION.md](STATE-MIGRATION.md) - State migration guide
- [PASSWORD-SETUP.md](PASSWORD-SETUP.md) - Password management
