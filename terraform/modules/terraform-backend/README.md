# Terraform Backend Module

This module creates the necessary AWS resources for Terraform remote state backend:
- S3 bucket for state storage
- DynamoDB table for state locking
- Security configurations (encryption, versioning, public access blocking)

## Features

- ✅ S3 bucket with versioning enabled
- ✅ Server-side encryption (AES256)
- ✅ Public access blocked
- ✅ DynamoDB table for state locking
- ✅ SSL/TLS enforcement
- ✅ Lifecycle policies for old versions
- ✅ Pay-per-request billing for DynamoDB

## Usage

### Step 1: Create Backend Resources

First, create the S3 bucket and DynamoDB table:

```hcl
# In main.tf
module "terraform_backend" {
  source = "./modules/terraform-backend"

  bucket_name          = "my-terraform-state"
  dynamodb_table_name  = "my-terraform-state-lock"
  enable_versioning    = true
  enable_encryption    = true

  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
```

Apply to create resources:
```bash
terraform init
terraform apply
```

### Step 2: Configure Backend

After the resources are created, add backend configuration to your terraform block:

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "my-terraform-state-lock"
    encrypt        = true
  }
}
```

### Step 3: Migrate State

```bash
terraform init -migrate-state
```

Terraform will ask to migrate your local state to S3. Type `yes` to confirm.

## Complete Setup Process

```bash
# 1. Enable remote state in terraform.tfvars
enable_remote_state = true
terraform_state_bucket = "ecoutu-kubernetes-stack-state"

# 2. Apply to create S3 and DynamoDB resources
terraform init
terraform apply

# 3. Get backend configuration
terraform output backend_config

# 4. Add backend block to main.tf (see below)

# 5. Migrate state
terraform init -migrate-state
```

## Backend Configuration Template

After creating resources, add this to your `main.tf`:

```hcl
terraform {
  required_version = ">= 1.0"

  backend "s3" {
    bucket         = "ecoutu-kubernetes-stack-state"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "ecoutu-kubernetes-stack-lock"
    encrypt        = true
  }

  required_providers {
    # ... your providers
  }
}
```

## Security Features

### S3 Bucket Protection
- **Versioning**: Enabled by default, keeps history of state changes
- **Encryption**: AES256 server-side encryption
- **Public Access**: Completely blocked
- **SSL/TLS**: Enforced via bucket policy
- **Lifecycle**: Old versions deleted after 90 days

### DynamoDB Table
- **Billing**: Pay-per-request (no provisioned capacity needed)
- **Purpose**: Prevents concurrent state modifications
- **Cost**: ~$0.0000013 per request (very low cost)

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| bucket_name | Name of the S3 bucket | string | - | yes |
| dynamodb_table_name | Name of the DynamoDB table | string | "terraform-state-lock" | no |
| enable_versioning | Enable S3 versioning | bool | true | no |
| enable_encryption | Enable S3 encryption | bool | true | no |
| tags | Tags to apply | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| s3_bucket_id | The ID of the S3 bucket |
| s3_bucket_arn | The ARN of the S3 bucket |
| dynamodb_table_name | The name of the DynamoDB table |
| backend_config | Complete backend configuration |

## Important Notes

### Chicken and Egg Problem

⚠️ **You cannot create backend resources AND use them in the same configuration initially.**

**Solution - Two-Step Process:**

1. **First Run**: Create backend resources (WITHOUT backend block)
   ```bash
   terraform apply  # Creates S3 + DynamoDB
   ```

2. **Second Run**: Add backend block and migrate
   ```bash
   # Add backend block to main.tf
   terraform init -migrate-state
   ```

### State File Location

- **Before migration**: `terraform.tfstate` (local file)
- **After migration**: `s3://bucket-name/terraform.tfstate`
- **Backup**: `terraform.tfstate.backup` (keep this until migration verified)

### Cost Estimate

- **S3**: ~$0.023/GB/month + API requests
- **DynamoDB**: Pay-per-request (~$0.0000013 per request)
- **Typical monthly cost**: < $1 for small projects

### Deletion Warning

⚠️ **Do NOT delete the S3 bucket or DynamoDB table while using remote state!**

To safely remove remote state:
1. Migrate state back to local: `terraform init -migrate-state`
2. Remove backend block from main.tf
3. Delete the backend resources: `terraform destroy`

## Troubleshooting

### Error: "Failed to get existing workspaces"

**Cause**: Backend resources don't exist yet

**Solution**: Create resources first (without backend block), then configure backend

### Error: "Error acquiring the state lock"

**Cause**: Another process is using the state, or stale lock

**Solution**:
```bash
# Force unlock (use with caution!)
terraform force-unlock <lock-id>
```

### Error: "NoSuchBucket"

**Cause**: Bucket name in backend config doesn't match actual bucket

**Solution**: Verify bucket name matches:
```bash
terraform output terraform_state_bucket
```

## Examples

### Minimal Setup
```hcl
module "terraform_backend" {
  source = "./modules/terraform-backend"

  bucket_name = "my-project-tfstate"
}
```

### Full Setup with Custom Settings
```hcl
module "terraform_backend" {
  source = "./modules/terraform-backend"

  bucket_name          = "my-project-tfstate"
  dynamodb_table_name  = "my-project-tfstate-lock"
  enable_versioning    = true
  enable_encryption    = true

  tags = {
    Environment = "production"
    Team        = "infrastructure"
    CostCenter  = "engineering"
  }
}
```

## Best Practices

1. ✅ **Unique bucket names**: Use prefix like `company-project-tfstate`
2. ✅ **Enable versioning**: Allows rollback if state corrupts
3. ✅ **Enable encryption**: Protects sensitive data in state
4. ✅ **Block public access**: State files can contain secrets
5. ✅ **Use state locking**: Prevents concurrent modifications
6. ✅ **Regular backups**: S3 versioning provides automatic backups
7. ✅ **Access control**: Use IAM policies to restrict access

## State File Security

⚠️ **State files can contain sensitive data:**
- Secrets
- Private keys
- Database passwords
- API tokens

**Protect your state:**
- ✅ Enable encryption at rest
- ✅ Enable encryption in transit (SSL/TLS)
- ✅ Restrict IAM access
- ✅ Enable CloudTrail logging
- ✅ Use bucket versioning

## References

- [Terraform S3 Backend](https://www.terraform.io/docs/language/settings/backends/s3.html)
- [State Locking](https://www.terraform.io/docs/language/state/locking.html)
- [Backend Migration](https://www.terraform.io/docs/cli/commands/init.html#backend-initialization)
