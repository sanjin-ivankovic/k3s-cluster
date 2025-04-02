# Application Stack Guide

This document details the applications that are deployed on your K3s cluster and how to configure them.

## Core Applications Overview

The following core applications can be deployed on your K3s cluster:

| Application        | Purpose                | Default Status |
| ------------------ | ---------------------- | -------------- |
| Traefik            | Ingress controller     | Enabled        |
| MetalLB            | Load balancer          | Enabled        |
| Prometheus/Grafana | Monitoring             | Disabled       |
| Longhorn           | Distributed storage    | Disabled       |
| cert-manager       | Certificate management | Enabled        |

## Configuration Options

Application deployment is controlled through variables in `ansible/roles/kubernetes_apps/defaults/main.yml`:

```yaml
# Helm configuration
helm_version: 'v3.14.3'

# Core components
deploy_metrics_server: true
deploy_coredns: false
deploy_cert_manager: true

# Storage options
deploy_storage: true
storage_class: 'local-path'
deploy_longhorn: false

# Ingress options
deploy_ingress: true
ingress_controller: 'traefik'
traefik_version: '24.1.0'

# Load balancer
deploy_metallb: true
metallb_ip_range: '10.0.0.200-10.0.0.250'

# Monitoring options
deploy_monitoring: false
monitoring_stack: 'kube-prometheus'
```

## Traefik Ingress Controller

Traefik provides ingress services for your cluster, allowing external access to applications.

### Configuration

Traefik is deployed with these default settings:

- Deployed as a DaemonSet
- Exposes ports 80 (HTTP) and 443 (HTTPS)
- Includes a dashboard for monitoring
- Uses LoadBalancer service type (requires MetalLB)

### Accessing the Dashboard

The Traefik dashboard is available at:

```bash
# Using port-forward
kubectl port-forward -n traefik svc/traefik 9000:9000

# Then visit http://localhost:9000/dashboard/
```

### Adding Ingress Rules

Define ingress resources for your applications:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  annotations:
    kubernetes.io/ingress.class: traefik
spec:
  rules:
    - host: app.k3s.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: app-service
                port:
                  number: 80
```

## MetalLB Load Balancer

MetalLB provides LoadBalancer services for bare-metal Kubernetes clusters.

### Configuration

MetalLB is configured with:

- L2 advertisement mode (ARP/NDP)
- IP address pool from the defined range in `metallb_ip_range`

### Address Pool Configuration

The default address pool is `10.0.0.200-10.0.0.250`, but you can change this in `ansible/roles/kubernetes_apps/defaults/main.yml`.

### Usage

Services can use MetalLB by specifying `type: LoadBalancer`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-app
spec:
  type: LoadBalancer
  ports:
    - port: 80
      targetPort: 8080
  selector:
    app: my-app
```

## Prometheus/Grafana Monitoring

The monitoring stack includes Prometheus for metrics collection and Grafana for visualization.

### Configuration

When enabled, the monitoring stack includes:

- Prometheus for metrics collection
- Grafana for dashboards
- Alertmanager for alerts
- Node Exporter for system metrics
- Kube State Metrics for Kubernetes metrics

### Accessing Grafana

Grafana is available at:

```bash
# Using port-forward
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80

# Then visit http://localhost:3000/
```

Default credentials:

- Username: admin
- Password: admin (configurable via `grafana_admin_password`)

### Key Dashboards

Pre-configured dashboards include:

1. Kubernetes Cluster Overview
2. Node Exporter Full
3. Kubernetes Resource Usage

## Storage Solutions

### Local-Path (Default)

The local-path provisioner is enabled by default and provides storage using the node's local filesystem.

### Longhorn (Optional)

Longhorn provides distributed, replicated storage for your cluster.

To enable Longhorn:

```yaml
deploy_longhorn: true
longhorn_replica_count: 3 # Number of replicas for high availability
```

Accessing the Longhorn UI:

```bash
kubectl port-forward -n longhorn-system svc/longhorn-frontend 8000:80
# Then visit http://localhost:8000/
```

## Certificate Management

cert-manager handles TLS certificates for your applications.

### Configuration

cert-manager is deployed with:

- ClusterIssuers for Let's Encrypt (staging and production)
- Support for DNS and HTTP validation

### Creating Certificates

Create certificates using Certificate resources:

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: example-com
  namespace: default
spec:
  secretName: example-com-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
    - example.com
    - www.example.com
```

## Deploying Your Own Applications

### Using Helm

```bash
# Add a Helm repository
helm repo add bitnami https://charts.bitnami.com/bitnami

# Update repositories
helm repo update

# Install a chart
helm install my-release bitnami/wordpress \
  --namespace my-namespace \
  --create-namespace
```

### Using Kubernetes YAML

```bash
# Apply a YAML manifest
kubectl apply -f my-application.yaml
```

### Using Ansible

For more complex deployments, create a custom role in the Ansible project:

```bash
mkdir -p ansible/roles/my-application/tasks
```

Create `ansible/roles/my-application/tasks/main.yml` with your deployment steps.

## Monitoring Your Applications

### Resource Usage

```bash
# CPU and memory usage by namespace
kubectl top namespace

# Usage by pod
kubectl top pods -n my-namespace
```

### Logs

```bash
# Get container logs
kubectl logs -n my-namespace deployment/my-app

# Follow logs
kubectl logs -f -n my-namespace deployment/my-app
```

### Prometheus Metrics

For applications that expose Prometheus metrics, create a ServiceMonitor:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: my-app-metrics
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: my-app
  endpoints:
    - port: metrics
      interval: 30s
  namespaceSelector:
    matchNames:
      - my-namespace
```

## Backup and Restore

For important applications, consider implementing backup solutions:

1. For stateful applications, use Velero for cluster backups
2. For databases, use application-specific backup tools
3. For persistent volumes, use snapshot capabilities if available

## Additional Resources

- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [MetalLB Configuration](https://metallb.universe.tf/configuration/)
- [Prometheus Operator Guide](https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/user-guides/getting-started.md)
- [Longhorn Documentation](https://longhorn.io/docs/)
