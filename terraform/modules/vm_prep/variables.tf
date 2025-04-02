# Variables for VM preparation module

variable "master_ips" {
  description = "IP addresses of master nodes"
  type        = list(string)
  validation {
    condition     = length(var.master_ips) >= 1
    error_message = "At least one master node is required."
  }
}

variable "worker_ips" {
  description = "IP addresses of worker nodes"
  type        = list(string)
  default     = []
}

variable "user" {
  description = "SSH user for node access"
  type        = string
  default     = "ubuntu"
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key file"
  type        = string
}

variable "connection_timeout" {
  description = "Timeout for SSH connections"
  type        = string
  default     = "2m"
}

variable "check_connectivity" {
  description = "Whether to check connectivity to nodes"
  type        = bool
  default     = true
}

variable "generate_ansible_vars" {
  description = "Whether to generate Ansible variable files"
  type        = bool
  default     = false
}

variable "cluster_name" {
  description = "Name of the K3s cluster"
  type        = string
  default     = "k3s-homelab"
}

variable "inventory_path" {
  description = "Path to save Ansible inventory and vars"
  type        = string
  default     = "../ansible"
}

# New variable for inventory file
variable "inventory_file" {
  description = "Path to the Ansible inventory file"
  type        = string
  default     = null # Default to null to allow conditional behavior
}
