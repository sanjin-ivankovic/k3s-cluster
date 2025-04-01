terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.1-rc4"
    }
  }
}

resource "proxmox_vm_qemu" "vm" {
  name        = var.node_config.name
  vmid        = var.node_config.vmid
  target_node = var.common_config.target_node
  clone       = var.node_config.os
  full_clone  = true

  # VM basic configuration
  boot     = "order=scsi0"
  agent    = 1
  tags     = "k3s,${var.node_config.type}"
  vm_state = "running"

  # Cloud-init configuration
  cicustom   = var.common_config.cicustom
  ciupgrade  = true
  nameserver = var.common_config.network.dns
  ipconfig0  = "ip=${var.node_config.ip}/24,gw=${var.common_config.network.gateway}"
  ciuser     = var.common_config.vm_user
  sshkeys    = var.common_config.ssh_public_key

  # Hardware configuration
  cores    = var.node_config.cores
  memory   = var.node_config.ram
  scsihw   = "virtio-scsi-single"
  bootdisk = "scsi0"
  hotplug  = 0
  cpu      = "host"
  balloon  = 0
  onboot   = true

  # Storage configuration
  disks {
    scsi {
      scsi0 {
        disk {
          storage = var.common_config.storage_type
          size    = var.node_config.disk_size
        }
      }
    }
    ide {
      ide0 {
        cloudinit {
          storage = var.common_config.storage_type
        }
      }
    }
  }

  # Network configuration
  network {
    model   = "virtio"
    bridge  = var.common_config.network.bridge
    tag     = var.common_config.network.vlan
    macaddr = var.node_config.macaddr
  }

  # Resource timeouts
  timeouts {
    create = "20m"
    delete = "10m"
    update = "15m"
  }

  # Add lifecycle management
  lifecycle {
    create_before_destroy = true
  }
}
