output "vm" {
  value = proxmox_vm_qemu.vm
}

output "name" {
  value = proxmox_vm_qemu.vm.name
}

output "ip" {
  value = var.node_config.ip
}

output "type" {
  value = var.node_config.type
}

output "id" {
  value = proxmox_vm_qemu.vm.id
}
