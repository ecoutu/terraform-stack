# Helm Chart Deployment Automation

This document provides detailed information about the automated Helm chart deployment system for the media stack.

## Overview

The repository includes an automated CI/CD pipeline for deploying the media stack Helm chart to Minikube using GitHub Actions. The pipeline provides validation, deployment, verification, and rollback capabilities.

## Features

- ✅ **Automated Linting:** Helm chart validation before deployment
- ✅ **Template Validation:** Ensures all templates render correctly
- ✅ **Minikube Integration:** Automated setup and teardown of Minikube
- ✅ **Deployment Verification:** Post-deployment health checks
- ✅ **Rollback Support:** Easy rollback to previous revisions
- ✅ **Manual Control:** Workflow dispatch for on-demand operations
- ✅ **PR Previews:** Shows deployment changes in pull requests
- ✅ **Error Handling:** Automatic cleanup on failure

## Workflow Structure

The workflow consists of three main jobs:

### 1. Lint and Validate (`lint-and-validate`)

Runs on all events (push, PR, manual):
- Validates Helm chart syntax using `helm lint`
- Tests template rendering with `helm template`
- Extracts chart version
- Creates validation summary

### 2. Deploy to Minikube (`deploy-to-minikube`)

Runs on:
- Push to `develop` branch (automatic)
- Manual workflow dispatch
- After successful validation

Actions:
- Sets up Minikube with metrics-server
- Checks for existing releases
- Performs install, upgrade, rollback, or uninstall
- Verifies deployment health
- Shows access information
- Captures logs on failure

### 3. Helm Diff Preview (`helm-diff-preview`)

Runs on pull requests only:
- Generates complete Helm template output
- Posts preview as PR comment
- Shows resource count and changes

## Trigger Configurations

### Automatic Deployment (Push)

Triggers on push to `main` or `develop` branches when:
- Changes are made to `helm/media-stack/**`
- Changes are made to `.github/workflows/helm-deploy.yml`

```bash
# Example: Deploy by pushing to develop
git checkout develop
git add helm/media-stack/values.yaml
git commit -m "feat: update media stack configuration"
git push origin develop
```

### Pull Request Validation

Triggers on PRs to `main` or `develop` branches when:
- Changes are made to Helm chart files
- No deployment occurs, only validation and preview

```bash
# Example: Create PR to preview changes
git checkout -b feature/update-helm-chart
# Make changes to helm/media-stack/
git push origin feature/update-helm-chart
# Create PR to main or develop
```

### Manual Deployment (Workflow Dispatch)

Trigger manually from GitHub Actions:

1. Navigate to **Actions** → **Helm Chart Deployment**
2. Click **Run workflow**
3. Select options:
   - **Environment:** development, staging, or production
   - **Action:** install-or-upgrade, rollback, or uninstall
4. Click **Run workflow**

## Deployment Actions

### Install or Upgrade

Default action that:
- Installs the chart if not present
- Upgrades existing installation
- Uses `--atomic` flag for automatic rollback on failure
- Cleans up resources on failure

```yaml
# Triggered via workflow dispatch
environment: development
action: install-or-upgrade
```

### Rollback

Reverts to the previous revision:
- Checks if release exists
- Validates previous revision is available
- Rolls back to previous state
- Waits for rollback to complete

```yaml
# Triggered via workflow dispatch
environment: development
action: rollback
```

**Command line equivalent:**
```bash
helm rollback media-stack <revision>
```

### Uninstall

Removes the Helm release:
- Checks if release exists
- Uninstalls the release
- Waits for cleanup to complete
- Does NOT delete PVCs (manual deletion required)

```yaml
# Triggered via workflow dispatch
environment: development
action: uninstall
```

**Note:** Persistent volumes are not automatically deleted. Delete manually if needed:
```bash
kubectl delete pvc -l app.kubernetes.io/name=media-stack
```

## Deployment Verification

The workflow performs comprehensive verification:

### 1. Release Status
```bash
helm status media-stack
```

### 2. Pod Status
- Lists all media-stack pods
- Waits for pods to be ready (5-minute timeout)
- Checks pod phase (Running/Succeeded)

### 3. Service Verification
- Lists all media-stack services
- Verifies NodePort services are exposed

### 4. Storage Verification
- Lists all PVCs
- Ensures volumes are bound

### 5. Health Checks
- Counts running pods vs expected (5 pods)
- Identifies pods in error states
- Fails deployment if pods have errors

## Rollback Procedure

### Automatic Rollback

The workflow uses `helm upgrade --atomic`, which automatically rolls back on failure.

### Manual Rollback via Workflow

1. Go to GitHub Actions
2. Select "Helm Chart Deployment" workflow
3. Click "Run workflow"
4. Choose action: "rollback"
5. Run the workflow

### Manual Rollback via CLI

```bash
# List release history
helm history media-stack

# Rollback to previous revision
helm rollback media-stack

# Rollback to specific revision
helm rollback media-stack 3
```

## Error Handling

### Deployment Failures

On failure, the workflow:
1. Automatically rolls back (due to `--atomic` flag)
2. Captures pod descriptions
3. Collects pod logs (last 50 lines)
4. Shows release history
5. Marks workflow as failed

### Common Issues

**Insufficient resources:**
```
Solution: Increase Minikube resources
minikube start --cpus=4 --memory=8192m
```

**Storage issues:**
```
Solution: Check available storage
minikube ssh "df -h"
```

**Pod startup timeout:**
```
Solution: Pods may need more time to pull images
Check pod status: kubectl describe pod <pod-name>
```

## Configuration

### Workflow Variables

Edit `.github/workflows/helm-deploy.yml`:

```yaml
env:
  HELM_VERSION: v3.19.1        # Helm CLI version
  KUBECTL_VERSION: v1.31.4     # kubectl version
  MINIKUBE_VERSION: v1.35.0    # Minikube version
  CHART_PATH: helm/media-stack # Path to chart
  RELEASE_NAME: media-stack    # Helm release name
```

### Minikube Configuration

Adjust resources in the workflow:

```yaml
- name: Start Minikube
  uses: medyagh/setup-minikube@latest
  with:
    cpus: 2           # Increase for better performance
    memory: 4096      # Increase for larger workloads
    addons: metrics-server,storage-provisioner
```

### Deployment Timeouts

Adjust wait times:

```yaml
helm upgrade ... --timeout 10m  # Increase for slow pulls
kubectl wait ... --timeout=300s # Increase for slow startups
```

## Access Information

After successful deployment, access applications at:

| Application | URL                          | NodePort |
|-------------|------------------------------|----------|
| SABnzbd     | http://\<minikube-ip\>:30081 | 30081    |
| Sonarr      | http://\<minikube-ip\>:30082 | 30082    |
| Radarr      | http://\<minikube-ip\>:30083 | 30083    |
| Bazarr      | http://\<minikube-ip\>:30084 | 30084    |
| Jellyfin    | http://\<minikube-ip\>:30085 | 30085    |

Get Minikube IP:
```bash
minikube ip
```

Or use port forwarding:
```bash
kubectl port-forward svc/media-stack-jellyfin 8096:8096
```

## Monitoring Deployments

### View Workflow Runs

1. Navigate to **Actions** tab
2. Select **Helm Chart Deployment** workflow
3. Click on a specific run to view details

### Check Deployment Summary

Each workflow run provides a summary with:
- Validation results
- Deployment status
- Resource counts
- Error details (if any)

### View Logs

Logs are available in:
- Workflow run details (GitHub Actions)
- Job step outputs
- Failed pod logs (captured on error)

## Best Practices

### 1. Use Feature Branches
```bash
git checkout -b feature/helm-updates
# Make changes
git push origin feature/helm-updates
# Create PR for review
```

### 2. Test in Development First
- Always deploy to development environment first
- Verify all pods are healthy
- Test application functionality

### 3. Review PR Previews
- Check the template output in PR comments
- Verify expected resources will be created
- Review any configuration changes

### 4. Monitor Deployments
- Watch workflow execution in real-time
- Check deployment summary for issues
- Review pod logs if problems occur

### 5. Keep Backups
- Helm automatically keeps revision history
- Export important configurations
- Document custom values

### 6. Version Your Charts
- Bump chart version in `Chart.yaml` for releases
- Tag releases in Git
- Document breaking changes

## Troubleshooting

### Workflow Won't Trigger

Check:
- Branch name matches trigger configuration
- Files changed match path filters
- Workflow file has no syntax errors

### Deployment Hangs

Possible causes:
- Insufficient Minikube resources
- Image pull issues
- Storage provisioning delays

Solutions:
```bash
# Check pod status
kubectl get pods -l app.kubernetes.io/name=media-stack

# Describe problematic pods
kubectl describe pod <pod-name>

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp
```

### Rollback Fails

Ensure:
- Previous revision exists
- Sufficient resources available
- No conflicting resources

```bash
# Check revision history
helm history media-stack

# View revision details
helm get values media-stack --revision 2
```

### Manual Override Required

If workflow fails and you need to fix manually:

```bash
# Access the deployed cluster (local Minikube)
# This won't work from GitHub Actions, but locally:
kubectl get all -l app.kubernetes.io/name=media-stack

# Manual rollback
helm rollback media-stack

# Force delete stuck resources
kubectl delete pod <pod-name> --force --grace-period=0
```

## Security Considerations

### Secrets Management

Currently, the workflow doesn't require secrets as:
- Minikube runs in GitHub Actions runner
- No external cluster credentials needed
- Public Docker images used

For production:
- Use Kubernetes secrets for sensitive data
- Configure secure registries
- Implement RBAC
- Use network policies

### Access Control

- Workflow requires `contents: read` permission
- PR comments require `pull-requests: write`
- No elevated privileges needed

## Future Enhancements

Potential improvements:
- [ ] Support for multiple environments
- [ ] Integration tests post-deployment
- [ ] Slack/Discord notifications
- [ ] Helm chart testing framework
- [ ] Blue-green deployment strategy
- [ ] Canary releases
- [ ] External cluster support (EKS, GKE, AKS)

## Related Documentation

- [Helm Chart README](helm/media-stack/README.md) - Chart-specific documentation
- [Main README](README.md#helm-deployment-automation) - Project overview
- [GitHub Actions Workflow](.github/workflows/helm-deploy.yml) - Workflow source

## Support

For issues:
1. Check workflow logs for error messages
2. Review this documentation
3. Check Helm chart documentation
4. Open an issue with:
   - Workflow run link
   - Error messages
   - Expected vs actual behavior
