# Git Hooks Setup Guide

This document provides comprehensive information about the git hooks system used in this project.

## Overview

This project uses [pre-commit](https://pre-commit.com/) to manage git hooks that enforce code quality and commit message standards. The hooks run automatically before commits are created, catching issues early in the development workflow.

## Installation

### 1. Install pre-commit

**Using pip:**
```bash
pip install pre-commit
```

**Using Homebrew (macOS/Linux):**
```bash
brew install pre-commit
```

**Using apt (Ubuntu/Debian):**
```bash
sudo apt install pre-commit
```

### 2. Install Git Hooks

From the repository root:
```bash
make pre-commit-install
```

This installs hooks for:
- `pre-commit` - runs before creating a commit
- `commit-msg` - validates commit message format

### 3. Verify Installation

```bash
pre-commit --version
```

## Hooks in This Project

### Pre-commit Hooks

These run automatically when you execute `git commit`:

#### General Checks
- **trailing-whitespace**: Removes trailing whitespace from files
- **end-of-file-fixer**: Ensures files end with a newline
- **check-yaml**: Validates YAML syntax
- **check-added-large-files**: Prevents committing files larger than 1MB
- **check-merge-conflict**: Detects merge conflict markers
- **mixed-line-ending**: Ensures consistent line endings

#### Terraform Checks
- **terraform_fmt**: Formats all Terraform files recursively
- **terraform_validate**: Validates Terraform configuration syntax and logic
- **terraform_docs**: Auto-generates documentation for Terraform modules
- **terraform_tflint**: Lints Terraform code for best practices and errors

#### Go Checks (for migrations)
- **golangci-lint**: _(Currently disabled)_ Lints Go code in the `migrations/` directory
  - _Note: Temporarily disabled due to Go version compatibility issues. Will be re-enabled after upgrading to a compatible Go version._

### Commit Message Hook

Validates that commit messages follow the [Conventional Commits](https://www.conventionalcommits.org/) format:

```
<type>: <description>

[optional body]

[optional footer]
```

**Allowed types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, missing semicolons, etc.)
- `refactor`: Code refactoring without changing functionality
- `perf`: Performance improvements
- `test`: Adding or updating tests
- `build`: Changes to build system or dependencies
- `ci`: Changes to CI/CD configuration
- `chore`: Other changes that don't modify src or test files
- `revert`: Reverting a previous commit

## Usage Examples

### Good Commit Messages

```bash
git commit -m "feat: add VPC peering module"
git commit -m "fix: correct IAM policy for GitHub Actions role"
git commit -m "docs: update README with git hooks documentation"
git commit -m "refactor: reorganize terraform module structure"
git commit -m "chore: update pre-commit hook versions"
```

### Bad Commit Messages

These will be rejected:
```bash
git commit -m "added new feature"  # Missing type prefix
git commit -m "Fixed bug"          # Capitalized (should be lowercase)
git commit -m "feat added vpc"     # Missing colon after type
```

### Multi-line Commits

For detailed commits:
```bash
git commit -m "feat: add RDS module for database management

This module creates an RDS PostgreSQL instance with:
- Multi-AZ deployment for high availability
- Automated backups with 7-day retention
- Enhanced monitoring enabled

Closes #123"
```

## Working with Hooks

### Manual Execution

Run all hooks on all files (useful for CI or catching up):
```bash
make pre-commit-run
```

Run specific hook:
```bash
pre-commit run terraform_fmt --all-files
```

Run on staged files only:
```bash
pre-commit run
```

### Bypassing Hooks

**⚠️ Use sparingly - only when necessary!**

Skip all hooks:
```bash
git commit --no-verify -m "feat: emergency hotfix"
```

Skip specific hooks:
```bash
SKIP=terraform_validate git commit -m "feat: WIP - validation will fail"
SKIP=terraform_fmt,terraform_validate git commit -m "feat: skip multiple hooks"
```

### When to Bypass

Legitimate reasons to bypass hooks:
- Emergency production fixes that need immediate deployment
- Work-in-progress commits on feature branches
- Known validation failures that need to be addressed separately
- Commits that modify hook configuration itself

**Never bypass for code being merged to main/production branches.**

## Maintenance

### Update Hooks

Keep hooks up to date with latest versions:
```bash
make pre-commit-update
```

This updates the `rev` field in `.pre-commit-config.yaml` for each hook repository.

### Uninstall Hooks

Remove git hooks (doesn't affect `.pre-commit-config.yaml`):
```bash
make pre-commit-uninstall
```

To reinstall later:
```bash
make pre-commit-install
```

## Troubleshooting

### Terraform Validation Fails

**Problem:** `terraform_validate` hook fails with "Terraform not initialized"

**Solution:**
```bash
cd terraform
terraform init
```

The hook will attempt to initialize automatically with `-backend=false`, but some configurations may require manual initialization.

### Terraform Format Issues

**Problem:** Files are not properly formatted

**Solution:** The `terraform_fmt` hook automatically formats files. Just re-run:
```bash
git add .
git commit -m "feat: your message"
```

### TFLint Errors

**Problem:** `terraform_tflint` hook fails or is not found

**Solutions:**
1. Install tflint:
   ```bash
   # macOS
   brew install tflint

   # Linux
   curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

   # Windows
   choco install tflint
   ```

2. Initialize tflint plugins:
   ```bash
   tflint --init
   ```

### Slow Hook Execution

**Problem:** Hooks take too long to run

**Solutions:**
1. Run hooks only on changed files (default behavior):
   ```bash
   git commit  # Only checks staged files
   ```

2. Skip expensive hooks for WIP commits:
   ```bash
   SKIP=terraform_validate,terraform_tflint git commit -m "feat: WIP"
   ```

3. Disable specific hooks by commenting them out in `.pre-commit-config.yaml`

### Docker Environment

**Problem:** Want to use hooks inside Docker container

**Solution:** Install pre-commit in the Docker image and mount the git directory:

```dockerfile
RUN pip install pre-commit
```

Then run hooks inside the container:
```bash
docker compose exec terraform pre-commit run --all-files
```

## Configuration

### Customizing Hooks

Edit `.pre-commit-config.yaml` to:
- Add or remove hooks
- Change hook versions
- Modify hook arguments
- Add file exclusions

Example - exclude specific paths:
```yaml
- id: terraform_fmt
  exclude: ^terraform/legacy/
```

Example - change maximum file size:
```yaml
- id: check-added-large-files
  args: ['--maxkb=5000']  # Allow 5MB files
```

### TFLint Configuration

Edit `.tflint.hcl` to customize linting rules:

```hcl
rule "terraform_naming_convention" {
  enabled = false  # Disable specific rule
}
```

## Integration with CI/CD

The same hooks can run in CI/CD pipelines:

```yaml
# .github/workflows/pre-commit.yml
name: Pre-commit Checks

on: [push, pull_request]

jobs:
  pre-commit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
      - uses: pre-commit/action@v3.0.1
```

## Best Practices

1. **Install hooks immediately** after cloning the repository
2. **Don't bypass hooks** unless absolutely necessary
3. **Keep hooks updated** regularly with `make pre-commit-update`
4. **Run hooks manually** with `make pre-commit-run` after configuration changes
5. **Commit hook configuration** changes to version control
6. **Document team expectations** around hook usage
7. **Use conventional commits** for clear project history
8. **Test hooks locally** before pushing to CI/CD

## Resources

- [pre-commit documentation](https://pre-commit.com/)
- [Conventional Commits specification](https://www.conventionalcommits.org/)
- [pre-commit-terraform hooks](https://github.com/antonbabenko/pre-commit-terraform)
- [TFLint documentation](https://github.com/terraform-linters/tflint)
- [golangci-lint documentation](https://golangci-lint.run/)

## Support

If you encounter issues with git hooks:

1. Check this documentation for common troubleshooting steps
2. Review the [pre-commit documentation](https://pre-commit.com/)
3. Open an issue in this repository with:
   - Hook that's failing
   - Complete error message
   - Steps to reproduce
   - Output of `pre-commit run <hook-id> --verbose`
