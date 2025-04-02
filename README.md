# K3s Home Lab Cluster

A complete infrastructure-as-code solution for deploying a production-ready K3s Kubernetes cluster on Proxmox virtual machines.

## Overview

This project automates the deployment of a Kubernetes cluster using K3s on Proxmox VMs. It combines:

- **Terraform** to provision virtual machines on Proxmox
- **Ansible** to install and configure K3s and core applications
- **Helm** to deploy essential Kubernetes applications

## Features

- **Infrastructure as Code** - Complete automation with Terraform and Ansible
- **High Availability** - Optional multi-master setup for control plane resilience
- **Core Application Stack** - Ingress controller, load balancer, monitoring, and storage
- **Security** - Best practices for SSH, TLS certificates, and Kubernetes RBAC
- **Customizable** - Easily adjust configuration to match your home lab environment
- **Documentation** - Comprehensive guides for deployment, troubleshooting, and maintenance

## Quick Start

### Prerequisites

- Proxmox server (tested with version 7.x+)
- Ubuntu cloud image template configured in Proxmox
- SSH access to Proxmox node
- Terraform 1.0.0+
- Ansible 2.10+

### Deployment Steps

1. **Clone the repository**:

   ```bash
   git clone https://github.com/yourusername/k3s-cluster.git
   cd k3s-cluster
   ```

2. **Configure your environment**:

   - Copy and modify `terraform/terraform.tfvars.example` to `terraform/terraform.tfvars`
   - Adjust VM specifications in `terraform/vars/nodes.yaml`
   - Modify network settings in `terraform/vars/network.yaml`

3. **Prepare SSH keys**:

   ```bash
   # Generate an ED25519 key pair for cluster access
   ssh-keygen -t ed25519 -f ~/.ssh/k3s_id_ed25519 -N ""
   chmod 600 ~/.ssh/k3s_id_ed25519
   ```

4. **Deploy VMs with Terraform**:

   ```bash
   cd terraform
   terraform init
   terraform apply
   ```

5. **Deploy K3s with Ansible**:

   ```bash
   cd ../ansible
   ansible-playbook playbooks/site.yml
   ```

6. **Access your cluster**:
   ```bash
   export KUBECONFIG=$(pwd)/kubeconfig
   kubectl get nodes
   ```

## Additional Deployment Options

### Deploy Only Core Applications

```bash
cd ansible
ansible-playbook playbooks/apps_deploy.yml
```

### Reset Cluster

```bash
cd ansible
ansible-playbook playbooks/k3s_reset.yml
```

### Test Connectivity

```bash
cd ansible
ansible-playbook playbooks/test.yml
```

## Project Structure

k3s-cluster/
├── ansible/ # Ansible configuration and playbooks
│ ├── inventory/ # Cluster node inventory
│ ├── playbooks/ # Ansible playbooks
│ └── roles/ # Role definitions
├── docs/ # Documentation
│ ├── architecture.md # Architecture overview
│ ├── terraform.md # Terraform guide
│ ├── ansible.md # Ansible guide
│ ├── applications.md # Application stack details
│ └── troubleshooting.md # Troubleshooting guide
└── terraform/ # Terraform configurations
├── modules/ # Reusable Terraform modules
├── scripts/ # Helper scripts
└── vars/ # Variable definitions

## Documentation

- [Architecture Overview](docs/architecture.md)
- [Terraform Configuration Guide](docs/terraform.md)
- [Ansible Deployment Guide](docs/ansible.md)
- [Application Stack Guide](docs/applications.md)
- [Project Overview](docs/project_overview.md)
- [Troubleshooting Guide](docs/troubleshooting.md)

## Core Applications

The following applications can be deployed as part of the cluster:

- **Traefik** - Ingress controller
- **MetalLB** - Load balancer for bare metal
- **Cert-Manager** - TLS certificate automation
- **Prometheus/Grafana** - Monitoring and visualization
- **Longhorn** - Distributed block storage

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
