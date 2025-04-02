# Current variables that are actively used in the project

# Provider configuration
variable "proxmox_api_url" {
  description = "URL to the Proxmox API"
  type        = string
  validation {
    condition     = can(regex("^https?://.*", var.proxmox_api_url))
    error_message = "The proxmox_api_url must be a valid URL starting with http:// or https://."
  }
}

variable "proxmox_user" {
  description = "Proxmox user to authenticate with"
  type        = string
}

variable "proxmox_password" {
  description = "Password for the Proxmox user; consider retrieving this from environment variables or a vault for better security"
  type        = string
  sensitive   = true
}

variable "proxmox_target_node" {
  description = "Target Proxmox node name"
  type        = string
}

# Cluster configuration
variable "cluster_name" {
  description = "Name of the K3s cluster"
  type        = string
  default     = "homelab"
}

# VM configuration
variable "vm_user" {
  description = "Username for VM access"
  type        = string
  default     = "sanjin" # Using sanjin as default
}

variable "vm_image" {
  description = "Base VM image template name"
  type        = string
  default     = "ubuntu-cloud" # Using the ubuntu-cloud template that has cloud-init configured
}

variable "vm_storage_type" {
  description = "Storage type for VM disks"
  type        = string
  default     = "local-zfs"
}

variable "vm_disk_size" {
  description = "Default size of the VM disk if not specified at the node level"
  type        = string
  default     = "40G"
}

variable "disk_size_validation" {
  description = "Regular expression to validate disk size format"
  type        = string
  default     = "^[0-9]+[MGT]$"
}

# SSH configuration
variable "ssh_key_name" {
  description = "Name for the SSH key pair"
  type        = string
  default     = "k3s"
}

variable "ssh_key_file" {
  description = "Path to SSH public key file"
  type        = string
  default     = "~/.ssh/k3s_id_ed25519.pub"
}

# Validation and integration
variable "run_validation" {
  description = "Whether to run validation tests after VM creation"
  type        = bool
  default     = false
}
