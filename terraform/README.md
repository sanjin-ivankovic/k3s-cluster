# Proxmox VM Deployment for K3s Cluster

This Terraform project creates virtual machines on Proxmox as preparation for K3s cluster deployment via Ansible.

## Prerequisites

- Terraform >= 1.0.0
- Proxmox server with API access
- Ubuntu cloud image template in Proxmox

## Usage

1. Create a `terraform.tfvars` file with your Proxmox credentials:

```hcl
proxmox_api_url     = "https://proxmox.example.com:8006/api2/json"
proxmox_user        = "user@pam"
proxmox_password    = "your-password"
proxmox_target_node = "pve"
```

2. Initialize Terraform:

```bash
terraform init
```

3. Plan the deployment:

```bash
terraform plan
```

4. Apply the configuration:

```bash
terraform apply
```

5. Use Ansible for K3s deployment:

```bash
cd ../ansible
ansible-playbook -i inventory/hosts.ini site.yml
```

## Configuration Files

- `main.tf`: Main configuration for VMs
- `variables.tf`: Input variables
- `outputs.tf`: Output values
- `vars/nodes.yaml`: Node definitions
- `vars/network.yaml`: Network configuration

## Customization

- Edit `vars/nodes.yaml` to modify VM specifications
- Edit `vars/network.yaml` to change network settings

## SSH Key Handling

The configuration handles SSH keys with the following logic:

1. **If SSH keys don't exist** in `~/.ssh/${ssh_key_name}_id_ed25519`:

   - New keys will be generated and written to disk automatically
   - These keys will be used to configure the VMs

2. **If SSH keys already exist**:
   - By default (`overwrite_ssh_keys = false`), existing keys will be reused
   - If `overwrite_ssh_keys = true`, new keys will be generated and will overwrite the existing ones

## Security Considerations

- For production use, enable proper TLS verification
- Consider using a secret management system for credentials
- Configure remote state backend for team environments
