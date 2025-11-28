# GitHub Secrets Module - Quick Start

This module automatically configures GitHub repository secrets for AWS OIDC authentication.

## What It Does

Automatically sets these in your GitHub repository:

- **Secret**: `AWS_ROLE_TO_ASSUME` (the IAM role ARN)
- **Variable**: `AWS_REGION` (the AWS region)

## Setup

### Step 1: Create GitHub Token

1. Visit: https://github.com/settings/tokens?type=beta
2. Click "Generate new token" (fine-grained)
3. Configure:
   - **Repository**: Select `ecoutu/kubernetes-stack`
   - **Permissions**:
     - Secrets: Read and write ✅
     - Variables: Read and write ✅
4. Generate and copy the token

### Step 2: Set Environment Variable

```bash
export TF_VAR_github_token="ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

### Step 3: Apply Terraform

````bash
cd terraform && terraform init
cd terraform && terraform apply
```

This will:
1. Create the AWS IAM OIDC role
2. Automatically set `AWS_ROLE_TO_ASSUME` secret in GitHub
3. Automatically set `AWS_REGION` variable in GitHub

### Step 4: Verify

```bash
# Check secrets were created
gh secret list -R ecoutu/kubernetes-stack

# Check variables were created
gh variable list -R ecoutu/kubernetes-stack

# View Terraform outputs
cd terraform && terraform output github_secrets_configured
````

## How It Works

The module uses the GitHub Terraform provider to manage repository secrets:

```hcl
# In terraform/main.tf - Already configured for you
module "github_secrets" {
  source = "./modules/github-secrets"
  count  = var.github_token != "" ? 1 : 0

  github_token    = var.github_token
  repository_name = "${var.github_org}/${var.github_repo}"
  aws_role_arn    = module.github_actions_role.role_arn
  aws_region      = var.aws_region
}
```

**Note**: The `count` conditional means:

- ✅ If `github_token` is set → secrets are created automatically
- ⏭️ If `github_token` is empty → skips secret creation (you can set manually)

## Without GitHub Token

If you prefer not to provide a GitHub token, you can manually set the secret:

```bash
# 1. Get the role ARN
terraform apply  # Creates role without setting secrets
terraform output github_actions_role_arn

# 2. Manually set in GitHub
gh secret set AWS_ROLE_TO_ASSUME \
     --body "$(cd terraform && terraform output -raw github_actions_role_arn)" \
  --repo ecoutu/kubernetes-stack
```

## Verification

After applying, your workflow will automatically use the secrets:

```yaml
# In .github/workflows/terraform.yml - Already configured
steps:
  - name: Configure AWS Credentials via OIDC
    uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: ${{ secrets.AWS_ROLE_TO_ASSUME }} # ← Set by Terraform
      aws-region: ${{ vars.AWS_REGION }} # ← Set by Terraform
```

## Updating Secrets

When the IAM role ARN changes, simply run:

````bash
cd terraform && terraform apply
```

Terraform will automatically update the secret in GitHub.

## Security

- ✅ GitHub token is marked `sensitive` in Terraform
- ✅ Secrets are encrypted at rest by GitHub
- ✅ Token is only used during `terraform apply`
- ✅ Token is not stored in state (only token hash)
- ⚠️ Use fine-grained tokens with minimal permissions
- ⚠️ Rotate tokens every 30-90 days

## Troubleshooting

### "404 Not Found"
- Verify repository name: `ecoutu/kubernetes-stack`
# Check token has access to the repository


### "403 Forbidden"
- Token needs "Secrets: Read and write" permission
- Token needs "Variables: Read and write" permission

### Secrets not updating
```bash
# Force update
terraform taint 'module.github_secrets[0].github_actions_secret.aws_role_to_assume'
terraform apply
````

## Module Files

```
modules/github-secrets/
├── main.tf         # Creates secrets and variables
├── variables.tf    # Module inputs
├── outputs.tf      # Module outputs
└── README.md       # Detailed documentation
```

## See Also

- Full documentation: `terraform/modules/github-secrets/README.md`
- OIDC setup guide: `OIDC-SETUP.md`
- Workflow configuration: `.github/workflows/terraform.yml`
