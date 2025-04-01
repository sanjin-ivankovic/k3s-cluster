# Proxmox VM Module

This module creates and manages virtual machines in Proxmox for the K3s cluster.

## Resources Created

- Proxmox VMs for K3s control plane and worker nodes
- Cloud-init configuration for automated VM setup
- Network configuration with static IPs

## Input Variables

| Name                | Description                       | Type     | Default | Required |
| ------------------- | --------------------------------- | -------- | ------- | :------: |
| `node_config`       | VM configuration object           | `object` | n/a     |   yes    |
| `common_config`     | Shared configuration for all VMs  | `object` | n/a     |   yes    |
| `boot_wait`         | Time to wait for VM boot          | `string` | `"60s"` |    no    |
| `wait_for_lease`    | Whether to wait for DHCP lease    | `bool`   | `true`  |    no    |
| `cloudinit_timeout` | Timeout for cloud-init completion | `number` | `300`   |    no    |

### node_config Object

| Name        | Description             | Type     | Required |
| ----------- | ----------------------- | -------- | :------: |
| `name`      | Name of the VM          | `string` |   yes    |
| `vmid`      | ID for the VM           | `number` |   yes    |
| `ip`        | Static IP address       | `string` |   yes    |
| `type`      | VM type (server/worker) | `string` |   yes    |
| `os`        | OS template to use      | `string` |   yes    |
| `cores`     | Number of CPU cores     | `number` |   yes    |
| `ram`       | Memory in MB            | `number` |   yes    |
| `macaddr`   | MAC address             | `string` |    no    |
| `disk_size` | Disk size               | `string` |    no    |

### common_config Object

| Name                | Description                  | Type     | Required |
| ------------------- | ---------------------------- | -------- | :------: |
| `target_node`       | Proxmox node                 | `string` |   yes    |
| `storage_type`      | Storage type                 | `string` |   yes    |
| `default_disk_size` | Default disk size            | `string` |   yes    |
| `cicustom`          | Cloud-init custom config     | `string` |    no    |
| `network`           | Network configuration        | `object` |   yes    |
| `vm_user`           | VM default user              | `string` |   yes    |
| `ssh_public_key`    | SSH public key for VM access | `string` |   yes    |

## Output Values

| Name   | Description                      |
| ------ | -------------------------------- |
| `name` | Name of the created VM           |
| `id`   | ID of the created VM             |
| `ip`   | IP address of the VM             |
| `type` | Type of the node (server/worker) |

## Example Usage

```hcl
module "k3s_server" {
  source = "../modules/proxmox_vm"

  node_config = {
    name      = "k3s-server-1"
    vmid      = 101
    ip        = "192.168.1.101"
    type      = "server"
    os        = "ubuntu-20.04"
    cores     = 2
    ram       = 4096
    macaddr   = "52:54:00:00:01:01"
    disk_size = "40G"
  }

  common_config = {
    target_node    = "proxmox-1"
    storage_type   = "local-lvm"
    default_disk_size = "40G"
    vm_user        = "ubuntu"
    ssh_public_key = file("~/.ssh/id_rsa.pub")
    network = {
      bridge  = "vmbr0"
      vlan    = null
      gateway = "192.168.1.1"
      dns     = "8.8.8.8"
    }
  }
}
```

## Home Lab Considerations

- Optimized for typical Proxmox home lab environments
- Configurable resource allocation to match home hardware capabilities
- Support for both DHCP and static IP addressing
- Customizable cloud-init configuration for easy VM provisioning
