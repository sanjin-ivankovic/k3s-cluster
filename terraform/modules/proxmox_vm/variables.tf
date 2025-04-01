variable "node_config" {
  description = "Configuration for the VM node"
  type = object({
    name      = string
    vmid      = number
    ip        = string
    type      = string
    os        = string
    cores     = number
    ram       = number
    macaddr   = string
    disk_size = string
  })
}

variable "common_config" {
  description = "Common configuration for all VMs"
  type = object({
    target_node       = string
    storage_type      = string
    default_disk_size = string
    cicustom          = string
    network = object({
      dns     = string
      bridge  = string
      vlan    = any
      gateway = string
    })
    vm_user        = string
    ssh_public_key = string
  })
}
