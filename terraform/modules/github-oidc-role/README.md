# GitHub Actions OIDC Authentication Setup

This module creates an AWS IAM role that allows GitHub Actions to authenticate using OpenID Connect (OIDC), eliminating the need to store AWS credentials as secrets.

## What Was Created

### AWS Resources

1. **OIDC Provider**: `token.actions.githubusercontent.com`
   - Allows AWS to trust GitHub Actions tokens
   - Configured with GitHub's thumbprints

2. **IAM Role**: `GitHubActionsTerraformRole`
   - Can only be assumed by workflows from `ecoutu/kubernetes-stack`
   - Restricted to `main` and `develop` branches
   - Includes permissions for Terraform operations (S3, DynamoDB, EC2, VPC, IAM, etc.)
   - Session duration: 1 hour

### Outputs

- `github_actions_role_arn` - The role ARN to use in workflows
- `github_actions_role_name` - The role name
- `github_oidc_provider_arn` - The OIDC provider ARN

## Setup Instructions

### Step 1: Deploy the Infrastructure

```bash
cd /home/ecoutu/ecoutu/src/kubernetes-stack
terraform init
terraform apply
```

### Step 2: Configure GitHub Secret

After applying, get the role ARN:

```bash
terraform output github_actions_role_arn
```

Add it as a repository secret:

1. Go to: https://github.com/ecoutu/kubernetes-stack/settings/secrets/actions
2. Click "New repository secret"
3. Name: `AWS_ROLE_TO_ASSUME`
4. Value: (paste the role ARN from above)
5. Click "Add secret"

Or use GitHub CLI:

```bash
gh secret set AWS_ROLE_TO_ASSUME \
  --body "$(terraform output -raw github_actions_role_arn)" \
  --repo ecoutu/kubernetes-stack
```

### Step 3: Use in GitHub Actions

The workflow file `.github/workflows/terraform-oidc.yml` is already configured. Key sections:

```yaml
permissions:
  id-token: write   # Required for OIDC
  contents: read

steps:
  - uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: ${{ secrets.AWS_ROLE_TO_ASSUME }}
      aws-region: us-east-1
```

## How It Works

1. **GitHub Actions** requests an OIDC token from GitHub
2. **GitHub** issues a JWT token with claims (repository, branch, etc.)
3. **Workflow** presents the token to AWS STS
4. **AWS** validates the token against the OIDC provider
5. **AWS** checks the trust policy conditions:
   - ✅ Repository matches: `ecoutu/kubernetes-stack`
   - ✅ Branch is `main` or `develop`
6. **AWS** issues temporary credentials (valid for 1 hour)
7. **Workflow** uses credentials to run Terraform

## Security Benefits

- ✅ **No long-lived credentials** - Everything is temporary
- ✅ **No secrets to rotate** - Credentials auto-rotate per workflow run
- ✅ **Branch-level control** - Only specific branches can assume the role
- ✅ **Time-limited** - Credentials expire after 1 hour
- ✅ **Audit trail** - Each assumption is logged in CloudTrail

## Verification

Test the authentication:

```bash
# Trigger the workflow
git push origin main

# Watch it run
# Visit: https://github.com/ecoutu/kubernetes-stack/actions

# Check CloudTrail for OIDC events
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=AssumeRoleWithWebIdentity \
  --max-results 5
```

## Customization

### Add More Branches

Edit `variables.tf` or `terraform.tfvars`:

```hcl
github_branches = ["main", "develop", "staging"]
```

### Modify Permissions

Edit the `inline_policies` in `main.tf` to add or restrict AWS permissions.

## Troubleshooting

### "Not authorized to perform: sts:AssumeRoleWithWebIdentity"

**Cause**: Branch or repository doesn't match trust policy

**Solution**: Verify you're running from `main` or `develop` branch

### "Missing id-token permission"

**Cause**: Workflow lacks OIDC permissions

**Solution**: Add to workflow:
```yaml
permissions:
  id-token: write
  contents: read
```

### "Secret AWS_ROLE_TO_ASSUME not found"

**Cause**: GitHub secret not configured

**Solution**: Follow Step 2 above to add the secret

## References

- [GitHub OIDC Documentation](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
- [AWS OIDC Provider](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)
- [configure-aws-credentials Action](https://github.com/aws-actions/configure-aws-credentials)
