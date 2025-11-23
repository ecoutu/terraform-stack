# Metrics Server Helm Chart

This Helm chart deploys the Kubernetes Metrics Server, which provides resource usage metrics for pods and nodes.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+

## Installation

```bash
# Install the metrics server
helm install metrics-server ./helm/metrics-server --namespace kube-system

# Or upgrade if already installed
helm upgrade metrics-server ./helm/metrics-server --namespace kube-system
```

## Verification

After installation, verify that the metrics server is working:

```bash
# Check deployment status
kubectl get deployment metrics-server -n kube-system

# Test node metrics
kubectl top nodes

# Test pod metrics
kubectl top pods -A
```

## Configuration

The following table lists the configurable parameters:

| Parameter                   | Description                                  | Default                                         |
| --------------------------- | -------------------------------------------- | ----------------------------------------------- |
| `image.repository`          | Metrics server image repository              | `registry.k8s.io/metrics-server/metrics-server` |
| `image.tag`                 | Metrics server image tag                     | `v0.7.2`                                        |
| `image.pullPolicy`          | Image pull policy                            | `IfNotPresent`                                  |
| `insecureTLS`               | Skip TLS verification (for dev environments) | `true`                                          |
| `extraArgs`                 | Additional arguments for metrics-server      | `[]`                                            |
| `resources.requests.cpu`    | CPU request                                  | `150m`                                          |
| `resources.requests.memory` | Memory request                               | `256Mi`                                         |
| `resources.limits.cpu`      | CPU limit                                    | `300m`                                          |
| `resources.limits.memory`   | Memory limit                                 | `512Mi`                                         |

## Uninstallation

```bash
helm uninstall metrics-server --namespace kube-system
```

## Notes

- The metrics server is deployed in the `kube-system` namespace
- For production environments, set `insecureTLS: false` and configure proper TLS certificates
- The chart includes all necessary RBAC resources (ServiceAccount, ClusterRoles, ClusterRoleBindings)
