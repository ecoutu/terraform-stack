# Contributing to Terraform Infrastructure Stack

Thank you for your interest in contributing! This document provides guidelines for contributing to this project.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/your-username/terraform-stack.git`
3. Create a feature branch: `git checkout -b feature/your-feature-name`
4. Make your changes
5. Test your changes locally
6. Commit with conventional commit messages
7. Push to your fork and submit a pull request

## Development Setup

### Prerequisites
- Terraform >= 1.13.5
- AWS CLI configured with appropriate credentials
- Go 1.21+ (for migration tool development)
- Docker (optional, for containerized development)
- **pre-commit** (strongly recommended for automated checks)

### Install Git Hooks

We use pre-commit hooks to enforce code quality automatically. Install them before making changes:

```bash
# Install pre-commit (if not already installed)
pip install pre-commit
# or
brew install pre-commit

# Install the git hooks
make pre-commit-install
```

The hooks will automatically:
- Format Terraform code with `terraform fmt`
- Validate Terraform configuration
- Check commit message format
- Run linting checks
- Generate module documentation

See [GIT-HOOKS.md](GIT-HOOKS.md) for complete documentation.

### Local Testing
```bash
# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# Run migration checks
./migrate.sh status

# Build migration tool
make build

# Run pre-commit checks manually
make pre-commit-run
```

## Commit Convention

We follow [Conventional Commits](https://www.conventionalcommits.org/) for clear and semantic commit messages. This is **enforced by git hooks** when you commit.

### Valid Commit Types
- `feat:` New features
- `fix:` Bug fixes
- `docs:` Documentation changes
- `style:` Code style changes (formatting, etc.)
- `refactor:` Code refactoring
- `perf:` Performance improvements
- `test:` Test additions or modifications
- `build:` Build system or dependency changes
- `ci:` CI/CD configuration changes
- `chore:` Maintenance tasks
- `revert:` Reverting previous commits

### Examples
✅ **Good:**
```
feat: add EC2 instance module
fix: correct security group CIDR blocks
docs: update README with new variables
refactor: simplify IAM role structure
```

❌ **Bad (will be rejected):**
```
added EC2 module
Fixed security groups
Update docs
```

### Bypassing Hooks

Only bypass hooks when absolutely necessary (e.g., emergency fixes):
```bash
git commit --no-verify -m "fix: emergency security patch"
```

**Note:** PRs with bypassed checks may face additional scrutiny during review.

## Pull Request Process

1. **Update Documentation**: Ensure README.md and module documentation reflect your changes
2. **Test Thoroughly**: Run `terraform validate` and test in a development environment
3. **Update Variables**: Add new variables to `variables.tf` and `terraform.tfvars.example`
4. **Migration Files**: If modifying state structure, create a migration file
5. **PR Description**: Clearly describe the problem and solution
6. **Link Issues**: Reference any related issues with `Closes #123`

### PR Review Process
- PRs require approval before merging
- CI/CD pipeline must pass all checks
- Address reviewer feedback promptly
- Keep PRs focused and reasonably sized

## Code Style

### Terraform
- Use 2 spaces for indentation
- Follow [Terraform style conventions](https://www.terraform.io/docs/language/syntax/style.html)
- Run `terraform fmt` before committing
- Use meaningful resource names
- Add descriptions to all variables and outputs
- Group related resources together

### Go (Migration Tool)
- Follow standard Go formatting with `gofmt`
- Add comments for exported functions
- Include error handling
- Write tests for new migration functions

## Module Development

When creating or modifying modules:

1. **Structure**: Follow the standard module structure
   ```
   module-name/
   ├── main.tf
   ├── variables.tf
   ├── outputs.tf
   └── README.md
   ```

2. **Documentation**: Include comprehensive README with:
   - Module description
   - Usage examples
   - Input variables table
   - Output variables table

3. **Variables**:
   - Provide sensible defaults where possible
   - Use clear, descriptive names
   - Add validation rules for complex inputs

4. **Outputs**: Export useful values for consumers

## State Migrations

When changes require state modifications:

1. Create a migration file in `migrations/files/`
2. Follow naming convention: `NNNN_descriptive_name.go`
3. Implement both `Up()` and `Down()` methods
4. Test migration with `./migrate.sh up` and `./migrate.sh down`
5. Document the migration in the PR description

## Testing

### Local Testing
```bash
# Initialize Terraform
terraform init

# Plan changes
terraform plan

# Apply in test environment (not production)
terraform apply

# Verify outputs
terraform output
```

### CI/CD Testing
- All PRs trigger automated validation
- Terraform plan runs automatically
- Review plan output in PR comments
- Merge only after approval and passing checks

## Reporting Issues

### Bug Reports
Use the Bug Report template and include:
- Clear description of the issue
- Steps to reproduce
- Expected vs actual behavior
- Terraform version
- Relevant error messages
- Environment details

### Feature Requests
Use the Feature Request or Infrastructure template and include:
- Problem statement
- Proposed solution
- Use cases
- Alternative approaches considered

## Security

- **Never commit secrets**: Use variables and `.tfvars` files (gitignored)
- **CIDR Restrictions**: Always recommend restricting CIDR blocks in production
- **IAM Permissions**: Follow principle of least privilege
- **State Security**: Use encrypted S3 backend with restricted access

## Questions?

- Open a GitHub Discussion for questions
- Check existing issues and documentation
- Review module READMEs for module-specific guidance

Thank you for contributing!
