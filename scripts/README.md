# Scripts

This directory contains helper scripts for managing the infrastructure.

## Available Scripts

### setup-dev-env.sh

Quick setup script for configuring the development environment and installing git hooks.

**Usage:**
```bash
./scripts/setup-dev-env.sh
```

**What it does:**
- Checks for required tools (pre-commit, Terraform, tflint, Go)
- Installs git hooks for pre-commit and commit-msg validation
- Initializes tflint plugins
- Provides helpful next steps and tips

**Requirements:**
- pre-commit must be installed (`pip install pre-commit` or `brew install pre-commit`)
- Recommended: Terraform, tflint, Go for full hook functionality

**First-time setup:**
```bash
# Install pre-commit
pip install pre-commit

# Run setup script
./scripts/setup-dev-env.sh

# Follow the next steps printed by the script
```

See [GIT-HOOKS.md](../GIT-HOOKS.md) for detailed git hooks documentation.

### ssh-minikube.sh

SSH into the Minikube EC2 instance with automatic port forwarding for Kubernetes services.

**Usage:**
```bash
# SSH with default port forwarding
./scripts/ssh-minikube.sh

# SSH without port forwarding
./scripts/ssh-minikube.sh --no-forward

# SSH with custom SSH key
./scripts/ssh-minikube.sh --key ~/.ssh/minikube_rsa

# SSH with custom port forwarding
./scripts/ssh-minikube.sh --custom-ports

# Show help
./scripts/ssh-minikube.sh --help
```

**Default Port Forwarding:**
- `8443:8443` - Kubernetes API Server (minikube)
- `30080:30080` - Sample app NodePort service
- `30000:30000` - NodePort range start
- `32767:32767` - NodePort range end

**Features:**
- Automatically retrieves instance IP from Terraform output
- Configurable SSH key and user
- Multiple port forwarding presets
- Custom port forwarding support
- Colored output for better readability
- Built-in help documentation

**Requirements:**
- Terraform must be initialized and applied
- SSH key must exist (default: `~/.ssh/id_rsa`)
- Instance must be running and accessible

**After Connecting:**
```bash
# Check minikube status
minikube status

# View Kubernetes resources
kubectl get nodes
kubectl get pods -A

# Access services locally (with port forwarding)
# Open http://localhost:30080 in browser for sample app
```

## Adding New Scripts

When adding new scripts to this directory:

1. Make the script executable: `chmod +x scripts/your-script.sh`
2. Add a shebang: `#!/usr/bin/env bash`
3. Include error handling: `set -euo pipefail`
4. Add help documentation: `--help` flag
5. Update this README with usage instructions
