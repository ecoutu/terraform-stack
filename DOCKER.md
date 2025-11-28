# Docker Setup for Terraform Stack

This project includes Docker support for running Terraform and migrations in a containerized environment.

## Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+

## Quick Start

### 1. Build Images

```bash
make docker-build
```

Or:

```bash
docker compose build
```

### 2. Configure AWS Credentials

Create a `.env` file from the example:

```bash
cp .env.example .env
```

Edit `.env` with your AWS configuration:

```env
AWS_REGION=us-east-1
AWS_PROFILE=default
```

### 3. Run Terraform in Docker

```bash
# Open an interactive shell
make docker-shell

# Or use docker compose directly
docker compose run --rm terraform /bin/bash
```

Inside the container:

```bash
# Initialize Terraform
terraform init

# Check migration status
./migrate.sh status

# Run plan
terraform plan

# Apply changes
terraform apply
```

## Available Images

### 1. Production Image (`Dockerfile`)

- Based on `hashicorp/terraform:1.6`
- Includes built migration tool
- Minimal size
- Use for CI/CD and production

**Build:**
```bash
docker compose build terraform
```

### 2. Development Image (`Dockerfile.dev`)

- Based on `golang:1.21-alpine`
- Includes Go, Terraform, AWS CLI, tflint
- Hot-reload support
- Use for active development

**Build:**
```bash
docker compose build terraform-dev
```

## Usage Examples

### Interactive Shell

```bash
# Production container
make docker-shell

# Development container
make docker-dev
```

### Run Terraform Commands

```bash
# Using make
make docker-terraform CMD="init"
make docker-terraform CMD="plan"
make docker-terraform CMD="apply -auto-approve"

# Using docker compose
docker compose run --rm terraform terraform init
docker compose run --rm terraform terraform plan
```

### Run Migration Commands

```bash
# Using make
make docker-migrate CMD="status"
make docker-migrate CMD="up"
make docker-migrate CMD="down"

# Using docker compose
docker compose run --rm terraform ./migrate.sh status
docker compose run --rm terraform ./migrate.sh up
```

### Start Long-Running Container

```bash
# Start container in background
docker compose up -d terraform

# Execute commands in running container
docker compose exec terraform terraform plan
docker compose exec terraform ./migrate.sh status

# View logs
docker compose logs -f terraform

# Stop container
docker compose down
```

## Docker Compose Services

### `terraform`

Main production service for running Terraform operations.

```bash
docker compose up -d terraform
docker compose exec terraform /bin/bash
```

### `terraform-dev`

Development service with additional tools.

```bash
docker compose up -d terraform-dev
docker compose exec terraform-dev /bin/bash
```

### `migrate`

Dedicated migration runner (profile: tools).

```bash
docker compose --profile tools run migrate status
docker compose --profile tools run migrate up
```

## Volume Mounts

The docker compose setup includes several volumes:

1. **Project Files**: Current directory → `/workspace`
2. **AWS Credentials**: `~/.aws` → `/root/.aws` (read-only)
3. **Terraform Plugins**: Persistent volume for plugins cache
4. **Migration State**: Persistent volume for `.migration_state.json`
5. **Go Cache**: Persistent volume for Go modules (dev only)

## Environment Variables

Configure via `.env` file:

```env
# AWS Configuration
AWS_REGION=us-east-1
AWS_PROFILE=default

# Terraform Logging
TF_LOG=DEBUG
TF_LOG_PATH=/workspace/terraform.log

# Optional: Direct AWS credentials
AWS_ACCESS_KEY_ID=your_key
AWS_SECRET_ACCESS_KEY=your_secret
```

## AWS Credentials

### Option 1: Mount AWS Config (Recommended)

The default setup mounts `~/.aws` directory:

```yaml
volumes:
  - ~/.aws:/root/.aws:ro
```

This allows using AWS profiles configured on your host machine.

### Option 2: Environment Variables

Set credentials in `.env`:

```env
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
AWS_SESSION_TOKEN=optional_session_token
```

### Option 3: IAM Role (ECS/EC2)

When running on AWS services, the container will automatically use the instance/task role.

## Common Workflows

### Initial Setup

```bash
# Build images
make docker-build

# Start development container
make docker-dev

# Inside container:
terraform init
./migrate.sh status
terraform plan
```

### Development Cycle

```bash
# Edit Terraform files on host
vim main.tf

# Test in container
docker compose exec terraform-dev terraform plan

# Apply changes
docker compose exec terraform-dev terraform apply
```

### Running Migrations

```bash
# Check status
make docker-migrate CMD="status"

# Create new migration
make docker-shell
# Inside container:
./migrate.sh create my_new_migration

# Edit migration file on host
vim migrations/files/0002_my_new_migration.go

# Apply migration
make docker-migrate CMD="up"
```

### CI/CD Integration

```yaml
# Example GitHub Actions
name: Terraform
on: [push]

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Build Docker image
        run: docker compose build terraform

      - name: Run migrations
        run: docker compose run --rm terraform ./migrate.sh up
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}

      - name: Terraform plan
        run: docker compose run --rm terraform terraform plan
```

## Makefile Commands

```bash
# Docker commands
make docker-build        # Build Docker images
make docker-up           # Start containers
make docker-down         # Stop containers
make docker-shell        # Interactive shell (production)
make docker-dev          # Interactive shell (development)
make docker-terraform    # Run terraform command
make docker-migrate      # Run migration command
make docker-clean        # Clean up Docker resources
```

## Troubleshooting

### AWS Credentials Not Found

```bash
# Check if credentials are mounted
docker compose run --rm terraform ls -la /root/.aws/

# Check environment variables
docker compose run --rm terraform env | grep AWS
```

### Permission Issues

```bash
# Run with specific user
docker compose run --rm --user $(id -u):$(id -g) terraform terraform plan
```

### Terraform Plugin Cache

Clear the plugin cache if you encounter issues:

```bash
docker compose down -v
docker volume rm kubernetes-stack_terraform-plugins
make docker-build
```

### Container Won't Start

Check logs:

```bash
docker compose logs terraform
```

Rebuild without cache:

```bash
docker compose build --no-cache terraform
```

## Best Practices

1. **Version Control**: Commit `.env.example` but not `.env`
2. **Credentials**: Never commit AWS credentials to git
3. **State Files**: Use remote state (S3) for team collaboration
4. **Image Updates**: Regularly update base images for security
5. **Resource Cleanup**: Use `make docker-clean` periodically
6. **Development**: Use `terraform-dev` for development, `terraform` for production
7. **CI/CD**: Use production image for automated pipelines

## Security Considerations

1. **Read-only AWS Config**: AWS credentials are mounted read-only
2. **No Credentials in Image**: Credentials are never baked into images
3. **Minimal Base Image**: Production image is based on Alpine
4. **User Permissions**: Consider running as non-root user in production
5. **Network Isolation**: Containers use isolated bridge network

## Advanced Usage

### Custom Entrypoint

```bash
docker compose run --rm --entrypoint /bin/bash terraform
```

### Run Specific Command

```bash
docker compose run --rm terraform terraform output
```

### Debug Mode

```bash
docker compose run --rm -e TF_LOG=DEBUG terraform terraform plan
```

### Mount Additional Directories

Edit `docker compose.yml`:

```yaml
volumes:
  - .:/workspace
  - ~/terraform-modules:/modules:ro
```

## Clean Up

Remove all Docker resources:

```bash
# Stop and remove containers
make docker-down

# Remove volumes and images
make docker-clean

# Complete cleanup
docker compose down -v --rmi all
```
