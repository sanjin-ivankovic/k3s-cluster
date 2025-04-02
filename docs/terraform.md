# Terraform Configuration Guide

This guide explains how to configure and use the Terraform code to provision the infrastructure for your K3s cluster.

## Directory Structure

The directory structure for the Terraform configuration is as follows:

```
terraform/
├── modules/                # Reusable Terraform modules
│   ├── proxmox_vm/         # VM creation module
│   ├── networking/         # Network configuration module
│   ├── storage/            # Storage configuration module
│   └── vm_prep/            # VM preparation module
├── main.tf                 # Main configuration
├── variables.tf            # Variable definitions
├── outputs.tf              # Output values
├── providers.tf            # Provider configuration
├── versions.tf             # Terraform version constraints
├── data_validation.tf      # Input validation logic
├── templates/              # Configuration templates
│   └── hosts.tmpl          # Ansible inventory template
├── vars/                   # Configuration variables
│   ├── nodes.yaml          # Node specifications
│   └── network.yaml        # Network settings
├── scripts/                # Utility scripts
│   ├── validate.sh         # Validation script
│   └── cleanup.sh          # Resource cleanup script
└── remote-state/           # Remote state configuration
```

## Prerequisites

Before you begin, ensure you have the following prerequisites:

- Terraform installed on your local machine
- Access to the cloud provider's account (e.g., AWS, Azure, GCP)
- SSH key pair for accessing the K3s nodes

## Configuration

### main.tf

The `main.tf` file contains the main configuration for provisioning the infrastructure. Here is an example configuration:

```hcl
provider "aws" {
  region = var.aws_region
}

resource "aws_instance" "k3s_node" {
  ami           = var.ami_id
  instance_type = var.instance_type
  count         = var.node_count

  tags = {
    Name = "k3s-node"
  }
}
```

### variables.tf

The `variables.tf` file defines the variables used in the Terraform configuration. Here is an example:

```hcl
variable "aws_region" {
  description = "The AWS region to deploy the infrastructure"
  type        = string
}

variable "ami_id" {
  description = "The AMI ID for the K3s nodes"
  type        = string
}

variable "instance_type" {
  description = "The instance type for the K3s nodes"
  type        = string
}

variable "node_count" {
  description = "The number of K3s nodes to provision"
  type        = number
}
```

### outputs.tf

The `outputs.tf` file defines the outputs of the Terraform configuration. Here is an example:

```hcl
output "k3s_node_ips" {
  description = "The IP addresses of the K3s nodes"
  value       = aws_instance.k3s_node.*.public_ip
}
```

## Usage

To use the Terraform configuration, follow these steps:

1. Initialize the Terraform configuration:

```sh
terraform init
```

2. Review the Terraform plan:

```sh
terraform plan
```

3. Apply the Terraform configuration to provision the infrastructure:

```sh
terraform apply
```

4. Verify the infrastructure is provisioned correctly:

```sh
terraform output
```

## Cleanup

To clean up the infrastructure provisioned by Terraform, run the following command:

```sh
terraform destroy
```

This will remove all the resources created by the Terraform configuration. For a more comprehensive cleanup that handles special cases, use the provided script:

```bash
./scripts/cleanup.sh
```

## Conclusion

This guide provided an overview of how to configure and use Terraform to provision the infrastructure for your K3s cluster. By following the steps outlined, you should be able to successfully set up and manage your K3s nodes using Terraform.

## Configuration Files

### terraform.tfvars

This file contains your specific environment settings. Create it from the example:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Important settings to configure:

- `proxmox_api_url`: URL to your Proxmox API
- `proxmox_user`: Proxmox username with API permissions
- `proxmox_password`: Proxmox password
- `proxmox_target_node`: Name of the Proxmox node
- `vm_storage_type`: Storage pool for VM disks
- `ssh_key_file`: Path to SSH public key for VM access

### vars/nodes.yaml

This file defines the specifications for each node in your cluster:

```yaml
nodes:
  k3s-srv-1: # Node name
    vmid: 201 # Proxmox VM ID
    ip: '10.0.0.6' # Static IP address
    type: 'server' # Node type (server or worker)
    os: 'ubuntu-cloud' # OS template name
    cores: 2 # CPU cores
    ram: 4096 # Memory in MB
    macaddr: '52:54:00:00:00:01' # MAC address
    disk_size: '40G' # Disk size

  k3s-wkr-1:
    vmid: 202
    ip: '10.0.0.7'
    type: 'worker'
    os: 'ubuntu-cloud'
    cores: 2
    ram: 2048
    macaddr: '52:54:00:00:00:02'
    disk_size: '40G'
```

### vars/network.yaml

Network configuration settings:

```yaml
dns: '1.1.1.1' # DNS server
bridge: 'vmbr0' # Bridge interface
vlan: null # VLAN ID (null for none)
gateway: '10.0.0.1' # Network gateway
```

## Deployment Process

1. Initialize Terraform

```sh
cd terraform
terraform init
```

2. Validate Configuration

```sh
terraform validate
terraform plan
```

3. Apply Configuration

```sh
terraform apply
```

4. Access Outputs

```sh
terraform output
```

Important outputs:

- `master_node`: Details of the master node
- `worker_nodes`: Details of worker nodes
- `ansible_inventory_path`: Path to the generated Ansible inventory file

## SSH Key Handling

The configuration handles SSH keys with the following logic:

- If SSH keys don't exist in `~/.ssh/${ssh_key_name}_id_ed25519`:
  - The deployment will fail as the system is set to use existing keys only
  - You should create keys manually using `ssh-keygen -t ed25519 -f ~/.ssh/k3s_id_ed25519`
- If SSH keys already exist:
  - Existing keys will be used for VM authentication
  - The public key will be added to `authorized_keys` on all VMs

You can verify SSH keys using the `verify_ssh_keys.sh` script included in the repository.

When troubleshooting SSH key problems:

1. Check the permissions with `ls -la ~/.ssh/k3s_id_ed25519*`
2. Fix permissions if needed using `chmod 600 ~/.ssh/k3s_id_ed25519`
3. Verify that the public key content is correctly added to the VMs

## Customization

### Adding More Nodes

To add more nodes, update the `vars/nodes.yaml` file with additional node definitions following the same pattern.

### Using Different Storage

Modify the `vm_storage_type` variable in `terraform.tfvars` to use a different storage pool available on your Proxmox host.

### Custom VM Templates

Set the `vm_image` variable to your custom template name. Ensure the template has cloud-init configured properly.

## Modules

### proxmox_vm

This module creates virtual machines with:

- Cloud-init configuration for automatic setup
- Static IP assignment
- SSH key-based authentication

### networking

Configures network settings for VMs:

- Static IP allocation
- Optional firewall rules
- DNS configuration

### vm_prep

Prepares VMs for Ansible deployment:

- Checks connectivity
- Generates Ansible inventory
- Creates configuration files

### storage

Manages storage resources:

- Storage volumes
- Persistent volume configuration
- Backup mechanisms for persistence

## Remote State

For team environments, configure remote state using the provided example:

- Set up MinIO or another S3-compatible storage
- Copy and configure `remote-state/backend.tf.example` to `backend.tf`
- Run `terraform init` to initialize with the remote backend

## Troubleshooting

### API Connection Issues

Ensure your Proxmox API URL is correct and the API user has sufficient permissions:

```sh
# On Proxmox server
pveum user token add terraform@pve terraform-token --privsep=0
pveum aclmod / -user terraform@pve -role Administrator
```

### VM Creation Errors

Common issues:

- VMID conflicts: Check for existing VMs with `qm list`
- Resource limits: Verify sufficient CPU, RAM, and disk space
- Template issues: Make sure the template exists and is correctly named

Common VM creation errors include:

- VMID conflicts (check with `qm list` on Proxmox)
- Insufficient resources (CPU, RAM, disk space)
- Template issues (verify template exists and is correctly named)

### SSH Key Problems

If SSH keys aren't working:

- Check permissions with `ls -la ~/.ssh/k3s_id_ed25519*`
- Fix permissions with `chmod 600 ~/.ssh/k3s_id_ed25519`
- Verify the public key content

## Cleanup

To remove all resources created by Terraform:

```sh
terraform destroy
```

For a more thorough cleanup, use the provided script:

```sh
./scripts/cleanup.sh
```

For improved security in production environments, consider rotating your API credentials regularly and implementing least-privilege access for your Terraform processes.

## Security Considerations

- Store sensitive variables in a `.tfvars` file excluded from version control
- Consider using Terraform Vault provider for credential management
- Use TLS for Proxmox API connections in production environments
- Regularly rotate API credentials
