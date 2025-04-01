# Storage resources for K3s home lab
# Manages persistent volumes for cluster data

locals {
  storage_tags = merge(var.tags, {
    Component = "storage"
  })
}

# Storage volume configuration
resource "proxmox_storage" "k3s_storage" {
  count   = var.create_storage ? 1 : 0
  node    = var.proxmox_node
  storage = var.storage_name
  type    = var.storage_type
  content = var.storage_content
  shared  = var.storage_shared
  disable = false

  # ZFS specific options
  dynamic "zfs_pool" {
    for_each = var.storage_type == "zfspool" ? [1] : []
    content {
      name = var.zfs_pool_name
    }
  }

  # LVM specific options
  dynamic "lvm_group" {
    for_each = var.storage_type == "lvm" ? [1] : []
    content {
      name = var.lvm_group_name
    }
  }

  # Directory specific options
  dynamic "dir" {
    for_each = var.storage_type == "dir" ? [1] : []
    content {
      path = var.dir_path
    }
  }
}

# Create data volumes for persistent storage
resource "proxmox_vm_disk" "data_volume" {
  count   = var.create_volumes ? var.volume_count : 0
  node    = var.proxmox_node
  storage = var.storage_pool
  size    = "${var.volume_size}G"
  vmid    = var.attach_to_vmid > 0 ? var.attach_to_vmid : null
  format  = var.disk_format
  backup  = var.backup_enabled

  # This ensures volumes are deletable
  lifecycle {
    create_before_destroy = true
  }
}

# Create backup job (optional)
resource "proxmox_backup" "k3s_backup" {
  count     = var.backup_enabled && var.create_backup_job ? 1 : 0
  node      = var.proxmox_node
  starttime = var.backup_starttime
  storage   = var.backup_storage
  mode      = var.backup_mode
  compress  = var.backup_compress
  vmid      = var.backup_vmid
  enabled   = true

  # Backup schedule
  dow   = var.backup_dow
  quiet = true

  # Retention
  maxfiles = var.backup_retention
}

# Monitoring resource for storage alerts (optional)
resource "null_resource" "storage_monitoring" {
  count = var.enable_monitoring ? 1 : 0

  # Simple script to create monitoring config
  provisioner "local-exec" {
    command = <<-EOT
      mkdir -p ${var.monitoring_path}
      cat > ${var.monitoring_path}/storage-alerts.yaml <<EOF
      apiVersion: monitoring.coreos.com/v1
      kind: PrometheusRule
      metadata:
        name: storage-alerts
      spec:
        groups:
        - name: storage
          rules:
          - alert: StorageNearlyFull
            expr: node_filesystem_avail_bytes{mountpoint="${var.mount_point}"} / node_filesystem_size_bytes{mountpoint="${var.mount_point}"} * 100 < ${var.storage_alert_threshold}
            for: 5m
            labels:
              severity: warning
            annotations:
              summary: "Storage nearly full (< ${var.storage_alert_threshold}%)"
              description: "Storage usage for ${var.mount_point} is at {{ $value }}%."
      EOF
    EOT
  }

  # Clean up monitoring config when resource is destroyed
  provisioner "local-exec" {
    when       = destroy
    command    = "rm -f ${var.monitoring_path}/storage-alerts.yaml"
    on_failure = continue
  }
}
