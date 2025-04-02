# Proxmox VM Deployment for K3s Cluster

This Terraform project creates virtual machines on Proxmox as preparation for K3s cluster deployment via Ansible.

## Prerequisites

- Terraform >= 1.0.0
- Proxmox server with API access
- Ubuntu cloud image template in Proxmox

## Setup

### Preparing the Proxmox Environment

1. Ensure you have a Ubuntu cloud image template in Proxmox

   ```bash
   # Example of downloading and creating a template
   wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
   qm create 9000 --name ubuntu-cloud --memory 2048 --net0 virtio,bridge=vmbr0
   qm importdisk 9000 jammy-server-cloudimg-amd64.img local-lvm
   qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
   qm set 9000 --ide2 local-lvm:cloudinit
   qm set 9000 --boot c --bootdisk scsi0
   qm set 9000 --serial0 socket --vga serial0
   qm template 9000
   ```

2. Create a Proxmox API token:
   ```bash
   # On Proxmox server
   pveum user token add terraform@pve terraform-token --privsep=0
   pveum aclmod / -user terraform@pve -role Administrator
   ```

### Configuration

1. Create a `terraform.tfvars` file with your Proxmox credentials:

```hcl
proxmox_api_url     = "https://proxmox.example.com:8006/api2/json"
proxmox_user        = "terraform@pve"
proxmox_password    = "your-password"
proxmox_target_node = "pve"
```

2. Configure VM specifications in `vars/nodes.yaml`:

```yaml
nodes:
  k3s-srv-1:
    vmid: 201
    ip: '10.0.0.6'
    type: 'server'
    cores: 2
    ram: 4096
    disk_size: '40G'

  k3s-wkr-1:
    vmid: 202
    ip: '10.0.0.7'
    type: 'worker'
    cores: 2
    ram: 2048
    disk_size: '40G'
```

3. Configure network settings in `vars/network.yaml`:

```yaml
dns: '1.1.1.1'
bridge: 'vmbr0'
gateway: '10.0.0.1'
```

## Usage

1. Initialize Terraform:

```bash
terraform init
```

2. Plan the deployment:

```bash
terraform plan
```

3. Apply the configuration:

```bash
terraform apply
```

4. Use the generated inventory for Ansible:

```bash
cd ../ansible
ansible-playbook -i inventory/hosts.ini site.yml
```

## Module Usage

The project uses several modules that can be customized:

- **proxmox_vm**: Creates the virtual machines with cloud-init configuration
- **vm_prep**: Validates VM connectivity and generates Ansible inventory
- **networking**: Configures network settings (when enabled)
- **storage**: Sets up persistent storage (when enabled)

Modify the module parameters in `main.tf` to adjust the configuration.

## SSH Key Management

By default, the project uses an existing SSH key at `~/.ssh/k3s_id_ed25519`. To generate a new key:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/k3s_id_ed25519 -N ""
chmod 600 ~/.ssh/k3s_id_ed25519
```

## Verification

After deployment, verify the created resources:

```bash
# List all VMs
terraform output vm_names

# Get VM IP addresses
terraform output vm_ips

# Check Ansible inventory path
terraform output ansible_inventory_path
```

## Cleanup

To remove all resources:

```bash
terraform destroy
```

For a more comprehensive cleanup, use the provided script:

```bash
./scripts/cleanup.sh
```

## Troubleshooting

If you encounter issues:

1. Check the Proxmox API URL and credentials
2. Verify the template exists in Proxmox
3. Ensure there are no VMID conflicts
4. Run validation with `./scripts/validate.sh`
5. Check the [troubleshooting guide](../docs/troubleshooting.md)

## Advanced Configuration

See the [Terraform Configuration Guide](../docs/terraform.md) for advanced configuration options and architecture details.
