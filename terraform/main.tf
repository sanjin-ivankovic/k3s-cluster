# Main Terraform configuration for K3s home lab cluster

# Provider configuration
terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = ">= 2.9.0"
    }
  }

  # Uncomment to enable remote state
  # backend "s3" {
  #   endpoint = "https://minio.local"
  #   bucket   = "terraform-state"
  #   key      = "k3s-cluster/terraform.tfstate"
  #   region   = "us-east-1"  # Can be any value for MinIO
  #   skip_credentials_validation = true
  #   skip_region_validation      = true
  #   skip_requesting_account_id  = true
  #   skip_s3_checksum            = true
  #   force_path_style            = true
  # }
}

provider "proxmox" {
  pm_api_url      = var.proxmox_api_url
  pm_user         = var.proxmox_user
  pm_password     = var.proxmox_password
  pm_tls_insecure = true # Consider changing to false for production and configuring proper certificates

  # Add timeout and error handling for API calls
  pm_timeout    = 600
  pm_parallel   = 4
  pm_log_enable = false
  pm_log_file   = "terraform-plugin-proxmox.log"
  pm_debug      = false
  pm_log_levels = {
    _default    = "debug"
    _capturelog = ""
  }
}

# Local variables
locals {
  vm_settings = merge(flatten([for i in fileset(".", "vars/nodes.yaml") : yamldecode(file(i))["nodes"]])...)
  network     = yamldecode(file("vars/network.yaml"))

  # Validate disk sizes
  invalid_disk_sizes = [for name, node in local.vm_settings :
    name if(lookup(node, "disk_size", null) != null &&
  !can(regex(var.disk_size_validation, node.disk_size)))]

  # Define validation checks
  invalid_ips  = []
  invalid_macs = []

  # Add disk_size validation to the validation_checks
  validation_checks = concat(
    local.invalid_ips,
    local.invalid_macs,
    local.invalid_disk_sizes
  )

  common_config = {
    target_node       = var.proxmox_target_node
    storage_type      = var.vm_storage_type
    default_disk_size = var.vm_disk_size
    cicustom          = "vendor=local:snippets/qemu-guest-agent.yaml"
    network = {
      dns     = local.network.dns
      bridge  = local.network.bridge
      vlan    = local.network.vlan
      gateway = local.network.gateway
    }
    vm_user        = var.vm_user
    ssh_public_key = file(var.ssh_key_file) # SSH public key file
  }
}

module "k3s_nodes" {
  source   = "./modules/proxmox_vm"
  for_each = local.vm_settings

  # Provider configuration
  providers = {
    proxmox = proxmox
  }

  node_config = {
    name      = each.key
    vmid      = each.value.vmid
    ip        = each.value.ip
    type      = each.value.type
    os        = each.value.os
    cores     = each.value.cores
    ram       = each.value.ram
    macaddr   = each.value.macaddr
    disk_size = lookup(each.value, "disk_size", var.vm_disk_size) # Use node-specific disk size or default
  }

  common_config = local.common_config
}

resource "local_file" "ansible_inventory" {
  content = templatefile("templates/hosts.tmpl",
    {
      primary = {
        name = "k3s-srv-1"
        ip   = local.vm_settings["k3s-srv-1"].ip
      }

      workers = [
        for name, j in local.vm_settings :
        { name = name, ip = j.ip }
        if j.type == "worker"
      ]
    }
  )
  filename = "inventory/hosts.ini"

  # Ensure directory exists
  provisioner "local-exec" {
    command = "mkdir -p inventory"
  }

  # Create a symlink to ../ansible/inventory/hosts.ini
  provisioner "local-exec" {
    command = "ln -sf ../../terraform/inventory/hosts.ini ../ansible/inventory/hosts.ini"
  }
}

# Prepare VMs for Ansible (validate connectivity)
module "vm_prep" {
  source = "./modules/kubernetes"

  master_ips = [for name, node in local.vm_settings : node.ip if node.type == "server"]
  worker_ips = [for name, node in local.vm_settings : node.ip if node.type == "worker"]

  user                 = var.vm_user
  ssh_private_key_path = var.ssh_key_file
  cluster_name         = var.cluster_name

  # Only check connectivity without installing anything
  check_connectivity    = var.run_validation
  generate_ansible_vars = true
  inventory_path        = "inventory"

  depends_on = [module.k3s_nodes]
}
