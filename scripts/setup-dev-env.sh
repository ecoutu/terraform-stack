#!/usr/bin/env bash
#
# Quick setup script for git hooks and development environment
#
# Usage: ./scripts/setup-dev-env.sh
#

set -e

echo "🚀 Setting up development environment..."
echo ""

# Check for pre-commit
if ! command -v pre-commit &> /dev/null; then
    echo "❌ pre-commit is not installed"
    echo ""
    echo "Please install pre-commit:"
    echo "  pip install pre-commit"
    echo "  or"
    echo "  brew install pre-commit"
    echo ""
    exit 1
fi

echo "✅ pre-commit is installed ($(pre-commit --version))"

# Check for Terraform
if ! command -v terraform &> /dev/null; then
    echo "⚠️  Terraform is not installed - some hooks may fail"
    echo "   Install from: https://www.terraform.io/downloads"
else
    echo "✅ Terraform is installed ($(terraform version | head -n1 | awk '{print $2}' | tr -d 'v'))"
fi

# Check for tflint
if ! command -v tflint &> /dev/null; then
    echo "⚠️  tflint is not installed - linting hooks will be skipped"
    echo "   Install with: brew install tflint"
    echo "   or see: https://github.com/terraform-linters/tflint"
else
    echo "✅ tflint is installed ($(tflint --version | head -n 1))"
    echo "   Initializing tflint plugins..."
    tflint --init 2>/dev/null || true
fi

# Check for Go (for migrations)
if ! command -v go &> /dev/null; then
    echo "⚠️  Go is not installed - Go linting will be skipped"
    echo "   Install from: https://golang.org/dl/"
else
    echo "✅ Go is installed ($(go version | awk '{print $3}'))"
fi

echo ""
echo "📝 Installing git hooks..."
pre-commit install
pre-commit install --hook-type commit-msg

echo ""
echo "✅ Git hooks installed successfully!"
echo ""
echo "📚 Next steps:"
echo "  1. Copy terraform.tfvars.example: cp terraform/terraform.tfvars.example terraform/terraform.tfvars"
echo "  2. Edit terraform.tfvars with your values"
echo "  3. Initialize Terraform: cd terraform && terraform init"
echo "  4. Make a commit to test the hooks!"
echo ""
echo "📖 For more information, see:"
echo "  - GIT-HOOKS.md for detailed hook documentation"
echo "  - CONTRIBUTING.md for contribution guidelines"
echo "  - README.md for project overview"
echo ""
echo "💡 Tip: Run 'make help' to see all available commands"
