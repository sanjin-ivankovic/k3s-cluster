# Variables for storage module

variable "proxmox_node" {
  description = "Proxmox node name"
  type        = string
}

# Storage pool configuration
variable "create_storage" {
  description = "Whether to create a new storage pool"
  type        = bool
  default     = false
}

variable "storage_name" {
  description = "Name of the storage to create or use"
  type        = string
  default     = "k3s-data"
}

variable "storage_type" {
  description = "Type of storage to create"
  type        = string
  default     = "dir"
  validation {
    condition     = contains(["dir", "lvm", "lvmthin", "zfspool", "nfs", "cifs"], var.storage_type)
    error_message = "Storage type must be one of: dir, lvm, lvmthin, zfspool, nfs, cifs."
  }
}

variable "storage_content" {
  description = "Content types allowed on the storage"
  type        = string
  default     = "images,rootdir"
}

variable "storage_shared" {
  description = "Whether the storage is shared between nodes"
  type        = bool
  default     = false
}

# Storage type specific options
variable "zfs_pool_name" {
  description = "Name of the ZFS pool to use (when storage_type is zfspool)"
  type        = string
  default     = null
}

variable "lvm_group_name" {
  description = "Name of the LVM group to use (when storage_type is lvm or lvmthin)"
  type        = string
  default     = null
}

variable "dir_path" {
  description = "Path for the directory storage (when storage_type is dir)"
  type        = string
  default     = "/mnt/k3s-data"
}

# Volume configuration
variable "create_volumes" {
  description = "Whether to create persistent volumes"
  type        = bool
  default     = true
}

variable "storage_pool" {
  description = "Storage pool for volumes"
  type        = string
  default     = "local-lvm"
}

variable "volume_count" {
  description = "Number of volumes to create"
  type        = number
  default     = 1
}

variable "volume_size" {
  description = "Size of persistent volumes in GB"
  type        = number
  default     = 10
  validation {
    condition     = var.volume_size > 0
    error_message = "Volume size must be greater than 0."
  }
}

variable "disk_format" {
  description = "Format for the disk"
  type        = string
  default     = "raw"
  validation {
    condition     = contains(["raw", "qcow2", "vmdk"], var.disk_format)
    error_message = "Disk format must be raw, qcow2, or vmdk."
  }
}

variable "attach_to_vmid" {
  description = "VM ID to attach the volumes to (0 means don't attach)"
  type        = number
  default     = 0
}

variable "mount_point" {
  description = "Path where volumes will be mounted"
  type        = string
  default     = "/mnt/data"
}

# Backup configuration
variable "backup_enabled" {
  description = "Whether to enable backups"
  type        = bool
  default     = false
}

variable "create_backup_job" {
  description = "Whether to create a backup job"
  type        = bool
  default     = false
}

variable "backup_storage" {
  description = "Storage to store backups"
  type        = string
  default     = "local"
}

variable "backup_mode" {
  description = "Backup mode: snapshot, suspend, or stop"
  type        = string
  default     = "snapshot"
  validation {
    condition     = contains(["snapshot", "suspend", "stop"], var.backup_mode)
    error_message = "Backup mode must be snapshot, suspend, or stop."
  }
}

variable "backup_starttime" {
  description = "Time to start the backup job (format: HH:MM)"
  type        = string
  default     = "02:00"
}

variable "backup_dow" {
  description = "Days of week for backups (format: mon,tue,wed,thu,fri,sat,sun)"
  type        = string
  default     = "sat"
}

variable "backup_vmid" {
  description = "VM ID to backup (0 means all VMs)"
  type        = number
  default     = 0
}

variable "backup_compress" {
  description = "Whether to compress backups"
  type        = bool
  default     = true
}

variable "backup_retention" {
  description = "Number of backups to retain"
  type        = number
  default     = 4
}

# Monitoring
variable "enable_monitoring" {
  description = "Whether to enable monitoring for storage"
  type        = bool
  default     = false
}

variable "monitoring_path" {
  description = "Path to store monitoring configurations"
  type        = string
  default     = "../kubernetes/monitoring"
}

variable "storage_alert_threshold" {
  description = "Threshold percentage for storage alerts"
  type        = number
  default     = 10
  validation {
    condition     = var.storage_alert_threshold > 0 && var.storage_alert_threshold < 100
    error_message = "Storage alert threshold must be between 0 and 100."
  }
}

# Tags
variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
