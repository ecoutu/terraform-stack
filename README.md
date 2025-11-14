# Terraform Project

This project creates a complete AWS infrastructure with VPC, subnets, and networking components using a modular architecture.

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured with appropriate credentials
- AWS account with necessary permissions
- **Optional**: Docker & Docker Compose (for containerized development)

## Features

- Modular architecture for reusability and maintainability
- VPC with public and private subnets across multiple availability zones
- Internet Gateway for public subnet connectivity
- NAT Gateways for private subnet internet access
- Configurable number of availability zones
- Comprehensive tagging strategy

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

## Project Structure

```
.
├── main.tf                      # Root module - orchestrates infrastructure
├── variables.tf                 # Root module input variables
├── outputs.tf                   # Root module outputs
├── terraform.tfvars.example     # Example variable values
├── migrate.sh                   # Migration tool wrapper script
├── migrations/                  # State migration system
│   ├── main.go                  # Migration tool source
│   ├── go.mod                   # Go module definition
│   ├── migrate                  # Compiled migration binary
│   ├── .migration_state.json    # Migration tracking (git-ignored)
│   ├── README.md                # Migration system documentation
│   └── files/                   # Migration files
│       └── 0001_*.go            # Individual migrations
├── modules/
│   ├── iam/                     # IAM module (users, roles, policies)
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── iam-role/                # Reusable IAM role module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── iam-user/                # Reusable IAM user module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   └── vpc/                     # VPC module
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── README.md
└── README.md                    # This file
```

## Modules

### IAM Module

Orchestrates IAM resources including:
- IAM user with console and programmatic access
- Administrator role with full AWS access
- Assume role permissions
- Console self-service capabilities (password, MFA, access keys)
- Instance profile for EC2

See [modules/iam/README.md](modules/iam/README.md) for detailed module documentation.

### VPC Module

Creates a complete VPC infrastructure with:
- VPC with configurable CIDR
- Public and private subnets
- Internet Gateway
- NAT Gateways (optional)
- Route tables and associations

See [modules/vpc/README.md](modules/vpc/README.md) for detailed module documentation.

### IAM Role Module

Reusable module for creating IAM roles with:
- Flexible trust policies
- Managed and custom policy attachments
- Instance profile support

See [modules/iam-role/README.md](modules/iam-role/README.md) for detailed module documentation.

### IAM User Module

Reusable module for creating IAM users with:
- Console and programmatic access
- Policy attachments
- Group memberships
- SSH key support

See [modules/iam-user/README.md](modules/iam-user/README.md) for detailed module documentation.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| aws_region | AWS region for resources | string | us-east-1 | no |
| environment | Environment name | string | dev | no |
| project_name | Project name for tagging | string | my-project | no |
| vpc_cidr | CIDR block for VPC | string | 10.0.0.0/16 | no |
| az_count | Number of availability zones | number | 2 | no |
| enable_nat_gateway | Enable NAT Gateways | bool | true | no |

## Outputs

### VPC Outputs
| Name | Description |
|------|-------------|
| vpc_id | ID of the VPC |
| public_subnet_ids | List of public subnet IDs |
| private_subnet_ids | List of private subnet IDs |
| nat_gateway_ids | List of NAT Gateway IDs |
| internet_gateway_id | Internet Gateway ID |

### IAM Outputs
| Name | Description |
|------|-------------|
| user_ecoutu_arn | ARN of the IAM user |
| user_ecoutu_name | Name of the IAM user |
| user_ecoutu_access_key_id | Access key ID (sensitive) |
| user_ecoutu_access_key_secret | Access key secret (sensitive) |
| admin_role_arn | ARN of the admin role |
| admin_role_name | Name of the admin role |
| admin_role_instance_profile_arn | Instance profile ARN |
| admin_role_instance_profile_name | Instance profile name |

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

## Documentation

- **[QUICK-REFERENCE.md](QUICK-REFERENCE.md)** - Quick reference for common commands and workflows
- **[DOCKER.md](DOCKER.md)** - Complete Docker usage guide
- **[PASSWORD-SETUP.md](PASSWORD-SETUP.md)** - IAM user password management
- **[STATE-MIGRATION.md](STATE-MIGRATION.md)** - State migration guide
- **[migrations/README.md](migrations/README.md)** - Migration system documentation
- **[migrations/MIGRATION-SYSTEM.md](migrations/MIGRATION-SYSTEM.md)** - Migration system overview
