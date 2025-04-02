# K3s Home Lab Architecture

This document describes the architecture of the K3s home lab cluster.

## System Architecture

The architecture follows a standard Kubernetes pattern with control plane and worker nodes:

```ascii
                    ┌───────────────────┐
                    │     Proxmox       │
                    │     Server        │
                    └─────────┬─────────┘
                              │
           ┌─────────────────┼─────────────────┐
           │                 │                 │
┌──────────▼───────┐ ┌───────▼────────┐ ┌──────▼───────────┐
│  K3s Server VM   │ │   K3s Worker   │ │    K3s Worker    │
│ (Control Plane)  │ │      VM        │ │       VM         │
└──────────┬───────┘ └───────┬────────┘ └──────┬───────────┘
           │                 │                 │
           └─────────────────┼─────────────────┘
                             │
                   ┌─────────▼──────────┐
                   │   Virtual Network  │
                   │   (10.0.0.0/24)    │
                   └────────────────────┘
```

## Component Overview

### Infrastructure Layer (Terraform)

The infrastructure layer uses Terraform to provision VMs on Proxmox with the following components:

1. **Virtual Machines**:

   - Master node(s): Runs the K3s server
   - Worker nodes: Run the K3s agent

2. **Networking**:

   - Private network for cluster communication
   - Static IP assignment for all nodes

3. **Storage**:
   - Local storage for each node
   - Optional shared storage for persistent volumes

### Kubernetes Layer (Ansible + K3s)

The Kubernetes layer is deployed using Ansible with the following components:

1. **Control Plane**:

   - K3s server (lightweight Kubernetes control plane)
   - etcd for state storage (embedded or external)
   - API server, scheduler, and controller manager

2. **Worker Nodes**:

   - K3s agent
   - Container runtime (containerd)
   - kubelet and kube-proxy

3. **Networking**:
   - Flannel CNI plugin (default)
   - Option for Calico or other CNI plugins

### Application Layer

Core applications deployed on the cluster:

1. **Ingress & Load Balancing**:

   - Traefik ingress controller
   - MetalLB for load balancer services

2. **Storage**:

   - Local-path storage class (default)
   - Optional Longhorn for distributed storage

3. **Monitoring**:

   - Prometheus for metrics collection
   - Grafana for visualization
   - Node exporter for system metrics

4. **Security**:
   - cert-manager for certificate management

## Deployment Workflow

The deployment process follows this sequence:

1. **Provision Infrastructure** - Terraform creates VMs on Proxmox
2. **Install K3s** - Ansible deploys K3s on all nodes
3. **Deploy Core Applications** - Ansible installs essential Kubernetes applications
4. **Configure Access** - Generate and distribute kubeconfig for cluster access

## High Availability Considerations

For HA deployments:

- Multiple K3s server nodes can be deployed
- An embedded database (etcd) or external database can be used
- Load balancing of API server endpoints

## Home Lab Optimizations

This architecture includes considerations specific to home labs:

- Resource-efficient design for limited hardware
- Simple networking suitable for home environments
- Optional components that can be enabled/disabled based on available resources
- Local development and testing capabilities
