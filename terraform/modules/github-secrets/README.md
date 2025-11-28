# GitHub Secrets Management Module

This Terraform module automatically configures GitHub repository secrets and variables required for AWS OIDC authentication with the `configure-aws-credentials` action.

## Features

- ✅ Automatically sets `AWS_ROLE_TO_ASSUME` secret
- ✅ Sets `AWS_REGION` as a repository variable
- ✅ Supports additional custom secrets and variables
- ✅ Validates repository access before making changes
- ✅ Idempotent - safe to run multiple times

## Usage

### Basic Example

```hcl
module "github_secrets" {
  source = "./modules/github-secrets"

  github_token    = var.github_token
  repository_name = "ecoutu/kubernetes-stack"
  aws_role_arn    = module.github_actions_role.role_arn
  aws_region      = "us-east-1"
}
```

### With Additional Secrets

```hcl
module "github_secrets" {
  source = "./modules/github-secrets"

  github_token    = var.github_token
  repository_name = "ecoutu/kubernetes-stack"
  aws_role_arn    = module.github_actions_role.role_arn
  aws_region      = "us-east-1"

  additional_secrets = {
    SLACK_WEBHOOK_URL = var.slack_webhook
    DATADOG_API_KEY   = var.datadog_key
  }

  additional_variables = {
    ENVIRONMENT = "production"
    APP_VERSION = "v1.0.0"
  }
}
```

## Prerequisites

### 1. GitHub Personal Access Token

Create a token with the following permissions:

**For Fine-Grained Tokens** (Recommended):
- Repository access: Select the target repository
- Permissions:
  - Secrets: Read and write
  - Variables: Read and write

**For Classic Tokens**:
- Scopes: `repo` (Full control of private repositories)

Create token at: https://github.com/settings/tokens

### 2. GitHub Provider Configuration

Add to your root `main.tf`:

```hcl
terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

provider "github" {
  token = var.github_token
}
```

### 3. Set Environment Variable

```bash
export TF_VAR_github_token="ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| github_token | GitHub personal access token | string | - | yes |
| repository_name | Full repository name (owner/repo) | string | - | yes |
| aws_role_arn | ARN of the AWS IAM role to assume | string | - | yes |
| aws_region | AWS region for workflows | string | "us-east-1" | no |
| additional_secrets | Map of additional secrets to set | map(string) | {} | no |
| additional_variables | Map of additional variables to set | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| repository_name | Name of the GitHub repository |
| repository_full_name | Full name of the repository |
| secrets_configured | List of secrets that were configured |
| variables_configured | List of variables that were configured |
| aws_role_arn | The AWS role ARN that was configured |

## What Gets Created

When you apply this module, it creates:

1. **Secret: `AWS_ROLE_TO_ASSUME`**
   - Value: The IAM role ARN
   - Used by: `aws-actions/configure-aws-credentials@v4`
   - Encrypted at rest by GitHub

2. **Variable: `AWS_REGION`**
   - Value: The AWS region
   - Used by: Workflows for region selection
   - Not encrypted (not sensitive data)

3. **Additional Secrets** (optional)
   - Any custom secrets you specify
   - Encrypted at rest by GitHub

4. **Additional Variables** (optional)
   - Any custom variables you specify
   - Plain text (for non-sensitive data)

## Integration with OIDC Role Module

Complete example combining both modules:

```hcl
# Create the OIDC role
module "github_actions_role" {
  source = "./modules/github-oidc-role"

  role_name       = "GitHubActionsTerraformRole"
  github_org      = "ecoutu"
  github_repo     = "kubernetes-stack"
  github_branches = ["main", "develop"]

  inline_policies = {
    TerraformAccess = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect   = "Allow"
        Action   = ["s3:*", "dynamodb:*"]
        Resource = "*"
      }]
    })
  }
}

# Configure GitHub secrets automatically
module "github_secrets" {
  source = "./modules/github-secrets"

  github_token    = var.github_token
  repository_name = "ecoutu/kubernetes-stack"
  aws_role_arn    = module.github_actions_role.role_arn
  aws_region      = var.aws_region
}
```

## Verification

After applying, verify the secrets were created:

```bash
# Using GitHub CLI
gh secret list -R ecoutu/kubernetes-stack

# Expected output:
# AWS_ROLE_TO_ASSUME  Updated YYYY-MM-DD

# Check variables
gh variable list -R ecoutu/kubernetes-stack

# Expected output:
# AWS_REGION  us-east-1  Updated YYYY-MM-DD
```

Or check in the GitHub UI:
- Secrets: https://github.com/ecoutu/kubernetes-stack/settings/secrets/actions
- Variables: https://github.com/ecoutu/kubernetes-stack/settings/variables/actions

## Workflow Usage

Once configured, use in your workflow:

```yaml
permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_TO_ASSUME }}
          aws-region: ${{ vars.AWS_REGION }}

      - run: aws sts get-caller-identity
```

## Security Considerations

### ✅ Best Practices

1. **Token Security**
   - Never commit GitHub token to version control
   - Use environment variables: `TF_VAR_github_token`
   - Rotate tokens regularly (30-90 days)
   - Use fine-grained tokens with minimal permissions

2. **Secret Management**
   - GitHub encrypts secrets at rest
   - Secrets are not visible after creation
   - Use GitHub's secret scanning to detect leaks
   - Audit secret access in repository settings

3. **Access Control**
   - Limit token scope to specific repositories
   - Use repository-specific fine-grained tokens
   - Review token permissions regularly
   - Revoke tokens when no longer needed

### ⚠️ Important Notes

- **GitHub token is sensitive**: Treat it like a password
- **State file contains token**: Use remote state with encryption
- **Token in memory**: Terraform keeps sensitive values in memory during apply
- **Audit trail**: All secret updates are logged in repository audit log

## Troubleshooting

### Error: "404 Not Found"

**Cause**: Token doesn't have access to the repository

**Solution**:
- Verify repository name is correct: `owner/repo`
- Check token has access to the repository
- For fine-grained tokens, ensure repository is selected

### Error: "403 Forbidden"

**Cause**: Token lacks required permissions

**Solution**:
- For fine-grained tokens: Add "Secrets: Read and write" permission
- For classic tokens: Ensure `repo` scope is enabled
- Regenerate token if necessary

### Error: "Resource not accessible by integration"

**Cause**: Token type doesn't support the operation

**Solution**:
- Use a personal access token (PAT)
- GitHub App tokens have limited secret access
- Switch to fine-grained or classic PAT

### Secrets Not Updating

**Cause**: Terraform doesn't detect changes to secret values

**Solution**:
```bash
# Force replacement of the secret
terraform taint module.github_secrets.github_actions_secret.aws_role_to_assume
terraform apply
```

### Token Expired

**Cause**: GitHub token has expired

**Solution**:
1. Create new token at https://github.com/settings/tokens
2. Update environment variable
3. Re-run `terraform apply`

## Maintenance

### Rotating GitHub Token

```bash
# 1. Create new token
# Visit: https://github.com/settings/tokens

# 2. Update environment variable
export TF_VAR_github_token="ghp_NEW_TOKEN_HERE"

# 3. Re-apply (no infrastructure changes)
terraform apply
```

### Updating AWS Role ARN

When the IAM role changes:

```bash
# Terraform will automatically detect and update the secret
terraform apply
```

### Removing Secrets

To remove secrets managed by this module:

```bash
# Remove the module block from main.tf
terraform apply

# Or manually delete
gh secret delete AWS_ROLE_TO_ASSUME -R ecoutu/kubernetes-stack
```

## Advanced Usage

### Conditional Secret Creation

Only create secrets when token is provided:

```hcl
module "github_secrets" {
  source = "./modules/github-secrets"
  count  = var.github_token != "" ? 1 : 0

  github_token    = var.github_token
  repository_name = "ecoutu/kubernetes-stack"
  aws_role_arn    = module.github_actions_role.role_arn
  aws_region      = var.aws_region
}
```

### Multiple Repositories

Configure secrets for multiple repositories:

```hcl
locals {
  repositories = ["ecoutu/repo1", "ecoutu/repo2", "ecoutu/repo3"]
}

module "github_secrets" {
  source   = "./modules/github-secrets"
  for_each = toset(local.repositories)

  github_token    = var.github_token
  repository_name = each.value
  aws_role_arn    = module.github_actions_role.role_arn
  aws_region      = var.aws_region
}
```

### Different Roles per Repository

```hcl
module "github_secrets_terraform" {
  source = "./modules/github-secrets"

  github_token    = var.github_token
  repository_name = "ecoutu/kubernetes-stack"
  aws_role_arn    = module.github_actions_terraform_role.role_arn
  aws_region      = "us-east-1"
}

module "github_secrets_app" {
  source = "./modules/github-secrets"

  github_token    = var.github_token
  repository_name = "ecoutu/my-app"
  aws_role_arn    = module.github_actions_app_role.role_arn
  aws_region      = "us-west-2"
}
```

## Examples

See the [examples](../../examples/) directory for:
- Basic OIDC setup
- Multi-repository configuration
- Custom secrets and variables
- CI/CD pipeline examples

## References

- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [GitHub Actions Variables](https://docs.github.com/en/actions/learn-github-actions/variables)
- [GitHub Provider Documentation](https://registry.terraform.io/providers/integrations/github/latest/docs)
- [configure-aws-credentials Action](https://github.com/aws-actions/configure-aws-credentials)
