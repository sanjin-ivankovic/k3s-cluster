# VM Preparation Module

This module handles the preparation of VMs for subsequent Ansible-based K3s deployment.

## Resources Created

- VM configuration validation
- Network connectivity testing
- Ansible inventory generation

## Input Variables

| Name                   | Description                         | Type           | Default        | Required |
| ---------------------- | ----------------------------------- | -------------- | -------------- | :------: |
| `master_ips`           | IP addresses of control plane nodes | `list(string)` | n/a            |   yes    |
| `worker_ips`           | IP addresses of worker nodes        | `list(string)` | n/a            |   yes    |
| `user`                 | SSH user for nodes                  | `string`       | `"ubuntu"`     |    no    |
| `ssh_private_key_path` | Path to SSH private key             | `string`       | n/a            |   yes    |
| `inventory_path`       | Path to save Ansible inventory      | `string`       | `"../ansible"` |    no    |

## Output Values

| Name             | Description                        |
| ---------------- | ---------------------------------- |
| `master_node`    | Details of the primary master node |
| `worker_nodes`   | Details of the worker nodes        |
| `inventory_file` | Path to the generated inventory    |

## Example Usage

```hcl
module "vm_prep" {
  source = "../modules/kubernetes"

  master_ips           = ["192.168.1.10"]
  worker_ips           = ["192.168.1.11", "192.168.1.12"]
  ssh_private_key_path = "~/.ssh/id_ed25519"
  inventory_path       = "../ansible/inventory"
}
```

## Home Lab Considerations

- Simple connectivity tests to ensure VMs are ready for Ansible
- Creates Ansible inventory in the expected format
- Supports both single and multi-node cluster configurations
