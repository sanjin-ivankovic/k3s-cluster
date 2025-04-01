# Outputs for storage module

output "storage_id" {
  description = "ID of the created storage pool"
  value       = var.create_storage ? proxmox_storage.k3s_storage[0].id : null
}

output "volume_ids" {
  description = "IDs of the created storage volumes"
  value       = var.create_volumes ? proxmox_vm_disk.data_volume[*].id : []
}

output "storage_details" {
  description = "Details about the storage configuration"
  value = {
    name        = var.storage_name
    type        = var.storage_type
    content     = var.storage_content
    shared      = var.storage_shared
    backup      = var.backup_enabled
    volumes     = var.create_volumes ? var.volume_count : 0
    volume_size = var.volume_size
    mount_point = var.mount_point
    monitoring  = var.enable_monitoring
  }
}

output "backup_info" {
  description = "Backup configuration information"
  value = var.backup_enabled && var.create_backup_job ? {
    enabled   = true
    storage   = var.backup_storage
    mode      = var.backup_mode
    schedule  = "${var.backup_starttime} on ${var.backup_dow}"
    retention = var.backup_retention
    } : {
    enabled = false
  }
}

output "monitoring_enabled" {
  description = "Whether monitoring is enabled for storage"
  value       = var.enable_monitoring
}
