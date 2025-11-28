# Terraform State Migration Guide

> **⚠️ IMPORTANT:** This project now uses a Go-based migration system in the `migrations/` directory.
>
> See [migrations/README.md](migrations/README.md) for the new system documentation.
>
> The old bash-based `migrate-state.sh` is preserved below for reference but is considered deprecated.

---

## New Migration System

The new Go-based migration system provides:
- ✅ Up/Down migrations (like database migrations)
- ✅ Version tracking
- ✅ Automatic state backups
- ✅ Declarative migration files

### Quick Start with New System

```bash
# Check status
./migrate.sh status

# Apply migrations
./migrate.sh up

# Rollback migrations
./migrate.sh down

# Create new migration
./migrate.sh create my_migration_name
```

See [migrations/README.md](migrations/README.md) for complete documentation.

---

## Old Migration Tool (Deprecated)

The `migrate-state.sh` script provides an interactive interface for common state management operations.

### Usage

```bash
./migrate-state.sh
```

### Features

#### 1. List All Resources
View all resources currently tracked in the Terraform state.

#### 2. Move Resource
Move a resource from one address to another. Useful when:
- Refactoring resources into modules
- Renaming resources
- Reorganizing infrastructure

Example:
```bash
# Moving account alias into IAM module
terraform state mv aws_iam_account_alias.alias module.iam.aws_iam_account_alias.alias[0]
```

#### 3. Remove Resource
Remove a resource from state without destroying it in AWS. Use when:
- Resource was created outside Terraform
- Moving resource to different state file
- Decommissioning tracking of a resource

#### 4. Import Resource
Import an existing AWS resource into Terraform state. Use when:
- Adopting existing infrastructure
- Recovering from state loss
- Adding manually created resources

#### 5. Show Resource Details
View detailed information about a specific resource in state.

#### 6. Migrate Account Alias
Automated migration specifically for moving the account alias into the IAM module.

#### 7. Backup State
Create a timestamped backup of the current state file.

#### 8. Restore State
Restore state from a previous backup.

#### 9. Show Statistics
Display statistics about your Terraform state including:
- Total resource count
- Resources by type
- Module distribution
- State file size and version

## Common Migration Scenarios

### Moving Resources into Modules

When refactoring standalone resources into modules:

1. **Backup your state:**
   ```bash
   ./migrate-state.sh
   # Choose option 7
   ```

2. **Update your Terraform code** to use modules

3. **Move resources in state:**
   ```bash
   ./migrate-state.sh
   # Choose option 2
   # Or use option 6 for account alias
   ```

4. **Verify no changes:**
   ```bash
   terraform plan
   # Should show "No changes"
   ```

### Example: Account Alias Migration

The account alias was moved from a standalone resource to the IAM module:

**Before:**
```hcl
resource "aws_iam_account_alias" "alias" {
  account_alias = "ecoutu"
}
```

**After:**
```hcl
# In modules/iam/main.tf
resource "aws_iam_account_alias" "alias" {
  count = var.account_alias != null ? 1 : 0
  account_alias = var.account_alias
}

# In main.tf
module "iam" {
  source = "./modules/iam"
  account_alias = "ecoutu"
  # ... other variables
}
```

**Migration command:**
```bash
terraform state mv \
  aws_iam_account_alias.alias \
  module.iam.aws_iam_account_alias.alias[0]
```

Or use the automated option 6 in the migration tool.

## Manual State Operations

### List Resources
```bash
terraform state list
```

### Show Resource
```bash
terraform state show <resource_address>
```

### Move Resource
```bash
terraform state mv <source> <destination>
```

### Remove Resource
```bash
terraform state rm <resource_address>
```

### Import Resource
```bash
terraform import <resource_address> <aws_id>
```

### Pull Current State
```bash
terraform state pull > terraform.tfstate.backup
```

### Push State (Advanced)
```bash
terraform state push terraform.tfstate.backup
```

## Best Practices

1. **Always backup** before major state operations
2. **Test in dev** environment first
3. **Run `terraform plan`** after migrations to verify
4. **Document** state changes in version control
5. **Use remote state** with locking for team environments
6. **Keep backups** organized with timestamps
7. **Verify** resources in AWS Console after migrations

## Troubleshooting

### Resource Not Found in State
If a resource exists in AWS but not in state:
```bash
terraform import <resource_type>.<name> <aws_id>
```

### Duplicate Resources
If Terraform tries to create existing resources:
1. Import the existing resource, or
2. Remove from code and manage outside Terraform

### State Drift
If state doesn't match AWS reality:
```bash
terraform refresh  # Update state to match AWS
terraform plan     # See what would change
```

## Remote State Configuration

For team environments, configure remote state:

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "kubernetes-stack/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

## Safety Tips

- ⚠️ **Never edit state files manually** unless absolutely necessary
- ⚠️ **Always use state commands** for modifications
- ⚠️ **Keep state files secure** - they contain sensitive information
- ⚠️ **Use state locking** to prevent concurrent modifications
- ⚠️ **Regular backups** are essential
- ⚠️ **Test migrations** in non-production first

## Related Commands

```bash
# Validate configuration
terraform validate

# Format code
terraform fmt -recursive

# Show execution plan
terraform plan

# Apply changes
terraform apply

# Destroy resources
terraform destroy

# Refresh state
terraform refresh
```
