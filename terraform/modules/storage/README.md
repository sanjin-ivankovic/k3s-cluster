# Storage Module

This module manages persistent storage resources for the K3s cluster in a home lab environment.

## Resources Created

- Storage volumes for persistent data
- Mounting configurations for VMs
- Optional backups for critical data

## Input Variables

| Name             | Description                        | Type     | Default       | Required |
| ---------------- | ---------------------------------- | -------- | ------------- | :------: |
| `storage_pool`   | Proxmox storage pool to use        | `string` | `"local-lvm"` |    no    |
| `volume_size`    | Size of persistent volumes in GB   | `number` | `10`          |    no    |
| `backup_enabled` | Whether to enable backups          | `bool`   | `false`       |    no    |
| `mount_point`    | Path where volumes will be mounted | `string` | `"/mnt/data"` |    no    |

## Output Values

| Name              | Description                             |
| ----------------- | --------------------------------------- |
| `volume_ids`      | IDs of the created storage volumes      |
| `storage_details` | Details about the storage configuration |

## Example Usage

```hcl
module "k3s_storage" {
  source = "../modules/storage"

  storage_pool = "local-zfs"
  volume_size = 20
  backup_enabled = true
}
```

## Home Lab Considerations

- Options for SSDs or HDDs based on performance needs
- Conservative defaults suitable for home hardware
- Simple backup strategies for home use
