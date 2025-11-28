# Quick Setup Guide - GitHub OIDC Authentication

## What Was Created

✅ **AWS IAM OIDC Provider** - Trusts GitHub Actions tokens
✅ **IAM Role**: `GitHubActionsTerraformRole` - For your workflows to assume
✅ **GitHub Actions Workflow** - Example workflow using OIDC authentication
✅ **Terraform Module** - `terraform/modules/github-oidc-role/` for OIDC setup

## Deploy in 3 Steps

### Step 1: Apply Terraform

```bash
cd terraform && terraform init
cd terraform && terraform apply
```

This creates:

- GitHub OIDC provider in AWS
- IAM role with Terraform permissions
- Trust policy restricting to `ecoutu/kubernetes-stack` from `main`/`develop` branches

### Step 2: Add GitHub Secret

Get the role ARN:

```bash
cd terraform && terraform output github_actions_role_arn
```

Add to GitHub (choose one method):

**Method A - GitHub CLI:**

```bash
gh secret set AWS_ROLE_TO_ASSUME \
     --body "$(cd terraform && terraform output -raw github_actions_role_arn)" \
  --repo ecoutu/kubernetes-stack
```

**Method B - Web UI:**

1. Go to: https://github.com/ecoutu/kubernetes-stack/settings/secrets/actions
2. Click "New repository secret"
3. Name: `AWS_ROLE_TO_ASSUME`
4. Value: (paste the ARN)
5. Click "Add secret"

### Step 3: Use the Workflow

The workflow `.github/workflows/terraform-oidc.yml` is ready to use:

```bash
git add .github/workflows/terraform-oidc.yml
git commit -m "Add OIDC authentication workflow"
git push origin main
```

Watch it run: https://github.com/ecoutu/kubernetes-stack/actions

## How to Use in Your Workflows

Add these to any workflow file:

```yaml
permissions:
  id-token: write # Required for OIDC
  contents: read

jobs:
  your-job:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_TO_ASSUME }}
          aws-region: us-east-1

      # Now you can use AWS CLI or Terraform!
      - run: aws sts get-caller-identity
```

## Security Features

- 🔒 No long-lived AWS credentials
- ⏱️ Credentials expire after 1 hour
- 🌿 Only `main` and `develop` branches can authenticate
- 📊 Full CloudTrail audit trail
- 🔄 Automatic credential rotation per workflow run

## Verification

Check the role was created:

```bash
aws iam get-role --role-name GitHubActionsTerraformRole
```

View outputs:

```bash
cd terraform && terraform output
```

## Troubleshooting

**Error: "Not authorized to perform: sts:AssumeRoleWithWebIdentity"**

- Ensure you're running from `main` or `develop` branch
- Check repository name matches exactly: `ecoutu/kubernetes-stack`

**Error: "Missing required permissions"**

- Add `id-token: write` permission to workflow
- Add `contents: read` permission to workflow

**Secret not found**

- Verify secret exists: `gh secret list -R ecoutu/kubernetes-stack`
- Re-add using Step 2 above

## Next Steps

1. ✅ Test the workflow by pushing to `main` branch
2. 📝 Customize permissions in `main.tf` if needed
3. 🗑️ Remove any old AWS access keys from GitHub secrets
4. 📚 Read `modules/github-oidc-role/README.md` for more details

## Configuration Variables

Customize in `terraform.tfvars`:

```hcl
github_org      = "ecoutu"              # Your GitHub org
github_repo     = "kubernetes-stack"     # Your repository name
github_branches = ["main", "develop"]   # Allowed branches
```

---

**Status**: ✅ Ready to use
**Security**: ✅ No AWS credentials in GitHub
**Time to setup**: ~3 minutes
