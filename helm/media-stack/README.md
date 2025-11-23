# Media Stack Helm Chart

A complete media automation and streaming stack for Minikube, including:

- **SABnzbd**: Usenet downloader
- **Sonarr**: TV show management and automation
- **Radarr**: Movie management and automation
- **Bazarr**: Subtitle management
- **Jellyfin**: Media server for streaming

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- Minikube with sufficient resources
- At least 80Gi of available storage

### ⚠️ Important: Storage Access Mode

This chart uses **shared persistent volumes** that are mounted by multiple pods:

- **Media PVC**: Shared by sonarr, radarr, bazarr, and jellyfin
- **Downloads PVC**: Shared by sabnzbd, sonarr, and radarr

By default, these volumes use `ReadWriteOnce` access mode, which **only works on single-node clusters** like Minikube or microk8s. In multi-node clusters, pods may be scheduled on different nodes and fail to mount the volumes.

**For multi-node clusters**, you must:

1. Use a storage class that supports `ReadWriteMany` (NFS, CephFS, GlusterFS, etc.)
2. Set `persistence.sharedAccessMode: ReadWriteMany` in your values.yaml

## Installation

### Quick Start

```bash
# Install the complete media stack
helm install media-stack ./helm/media-stack

# Install with custom values
helm install media-stack ./helm/media-stack -f my-values.yaml
```

### Accessing the Applications

After installation, the applications will be available at:

| Application | URL                          | NodePort |
| ----------- | ---------------------------- | -------- |
| SABnzbd     | http://\<minikube-ip\>:30081 | 30081    |
| Sonarr      | http://\<minikube-ip\>:30082 | 30082    |
| Radarr      | http://\<minikube-ip\>:30083 | 30083    |
| Bazarr      | http://\<minikube-ip\>:30084 | 30084    |
| Jellyfin    | http://\<minikube-ip\>:30085 | 30085    |

Get your Minikube IP:

```bash
minikube ip
```

Or use Minikube service commands:

```bash
minikube service media-stack-sabnzbd
minikube service media-stack-sonarr
minikube service media-stack-radarr
minikube service media-stack-bazarr
minikube service media-stack-jellyfin
```

## Configuration

### Storage

The chart creates shared persistent volumes for:

- **Media**: 50Gi (shared by sonarr, radarr, bazarr, jellyfin)
- **Downloads**: 20Gi (shared by sabnzbd, sonarr, radarr)
- **Config**: Individual volumes for each application (1-2Gi each)

Adjust storage sizes in `values.yaml`:

```yaml
persistence:
  media:
    size: 100Gi
  downloads:
    size: 50Gi
```

#### Access Modes

**Single-node clusters (default - Minikube, microk8s)**:

```yaml
persistence:
  sharedAccessMode: ReadWriteOnce
```

**Multi-node clusters (requires ReadWriteMany-capable storage)**:

```yaml
persistence:
  sharedAccessMode: ReadWriteMany
global:
  storageClass: "nfs-client" # or cephfs, glusterfs, etc.
```

### Resources

Default resource limits per application:

- SABnzbd: 1.5 CPU, 2Gi RAM
- Sonarr/Radarr: 800m CPU, 1Gi RAM
- Bazarr: 600m CPU, 768Mi RAM
- Jellyfin: 2 CPU, 3Gi RAM

Adjust in `values.yaml`:

```yaml
sonarr:
  resources:
    limits:
      cpu: 1000m
      memory: 1Gi
```

### Timezone

Set timezone globally:

```yaml
global:
  timezone: "America/Los_Angeles"
```

### Disable Components

Disable individual applications:

```yaml
bazarr:
  enabled: false
```

## Initial Setup

### 1. SABnzbd Setup

1. Access SABnzbd at port 30081
2. Complete the initial setup wizard
3. Configure your Usenet provider
4. Set download folder to `/downloads`

### 2. Sonarr Setup

> **Note:** All applications share the same PersistentVolumeClaim (PVC) root. The chart automatically creates `tv` and `movies` subdirectories at startup using init containers. Each app then mounts specific subdirectories: Sonarr uses `/tv`, Radarr uses `/movies`, and Jellyfin can access both. This ensures proper content organization.

1. Access Sonarr at port 30082
2. Complete the initial setup wizard
3. Settings → Media Management → Root Folders → Add: `/tv`
4. Settings → Download Clients → Add SABnzbd
   - Host: `media-stack-sabnzbd`
   - Port: `8080`

### 3. Radarr Setup

1. Access Radarr at port 30083
2. Settings → Media Management → Root Folders → Add: `/movies`
3. Settings → Download Clients → Add SABnzbd
   - Host: `media-stack-sabnzbd`
   - Port: `8080`

### 4. Bazarr Setup

1. Access Bazarr at port 30084
2. Settings → Sonarr → Add server
   - Address: `http://media-stack-sonarr:8989`
3. Settings → Radarr → Add server
   - Address: `http://media-stack-radarr:7878`

### 5. Jellyfin Setup

1. Access Jellyfin at port 30085
2. Complete initial setup wizard
3. Add media libraries:
   - TV Shows: `/tv`
   - Movies: `/movies`

## Volume Structure

```
/config           # Application configuration (per-app)
/downloads        # Shared downloads folder (SABnzbd output)
/tv               # TV shows (Sonarr, Jellyfin)
/movies           # Movies (Radarr, Jellyfin)
```

## Upgrading

```bash
# Upgrade with new values
helm upgrade media-stack ./helm/media-stack -f values.yaml

# Rollback if needed
helm rollback media-stack
```

## Uninstallation

```bash
# Uninstall the chart
helm uninstall media-stack

# Persistent volumes are not automatically deleted
# Delete them manually if needed:
kubectl delete pvc -l app.kubernetes.io/name=media-stack
```

## Troubleshooting

### Check Pod Status

```bash
kubectl get pods -l app.kubernetes.io/name=media-stack
```

### View Logs

```bash
kubectl logs -l app.kubernetes.io/component=sonarr
kubectl logs -l app.kubernetes.io/component=radarr
kubectl logs -l app.kubernetes.io/component=jellyfin
```

### Storage Issues

```bash
# Check PVCs
kubectl get pvc

# Check available storage in Minikube
minikube ssh
df -h
```

### Permission Issues

The containers run as PUID/PGID 1000 by default. If you encounter permission errors, ensure your storage supports this.

## Advanced Configuration

### Using External Storage

To use NFS or other external storage:

```yaml
global:
  storageClass: "nfs-client"
```

### Custom Image Tags

Use specific versions:

```yaml
sonarr:
  image:
    tag: "4.0.0"
```

### Port Forwarding

For local development, forward ports:

```bash
kubectl port-forward svc/media-stack-jellyfin 8096:8096
```

## Network Architecture

All applications communicate via Kubernetes service names:

- `media-stack-sabnzbd:8080`
- `media-stack-sonarr:8989`
- `media-stack-radarr:7878`
- `media-stack-bazarr:6767`
- `media-stack-jellyfin:8096`

## Security Notes

⚠️ **Important**: This configuration uses NodePort services for easy access on Minikube. For production:

- Use Ingress with TLS
- Implement authentication
- Use NetworkPolicies
- Consider VPN access

## Support

For issues specific to individual applications, consult their documentation:

- [SABnzbd Docs](https://sabnzbd.org/wiki/)
- [Sonarr Wiki](https://wiki.servarr.com/sonarr)
- [Radarr Wiki](https://wiki.servarr.com/radarr)
- [Bazarr Wiki](https://wiki.bazarr.media/)
- [Jellyfin Docs](https://jellyfin.org/docs/)
