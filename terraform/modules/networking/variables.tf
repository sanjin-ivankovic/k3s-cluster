# Variables for networking module

variable "proxmox_node" {
  description = "Proxmox node name"
  type        = string
}

variable "create_network" {
  description = "Whether to create a new network or use an existing one"
  type        = bool
  default     = false
}

variable "network_name" {
  description = "Name of the network to use or create"
  type        = string
  default     = "default"
}

variable "network_bridge" {
  description = "Bridge interface to use"
  type        = string
  default     = "vmbr0"
}

variable "network_cidr" {
  description = "CIDR for the node network"
  type        = string
  default     = "192.168.1.0/24"
}

variable "network_gateway" {
  description = "Gateway IP for the network"
  type        = string
  default     = null
}

variable "dns_domain" {
  description = "Domain name for the cluster"
  type        = string
  default     = "k3s.local"
}

variable "create_dns_records" {
  description = "Whether to create DNS records"
  type        = bool
  default     = false
}

variable "node_records" {
  description = "List of node records to create"
  type = list(object({
    name = string
    ip   = string
  }))
  default = []
}

variable "hosts_file_path" {
  description = "Path for generated hosts file"
  type        = string
  default     = "/tmp/k3s-dns.hosts"
}

variable "firewall_enabled" {
  description = "Whether to configure firewall rules"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
