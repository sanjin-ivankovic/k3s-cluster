output "vm_names" {
  value       = [for k, v in module.k3s_nodes : v.name]
  description = "List of created VM names"
}

output "vm_ips" {
  value       = [for k, v in module.k3s_nodes : "ip=${v.ip}/24,gw=${local.network.gateway}"]
  description = "List of VM IP configurations"
}

output "master_node" {
  value = {
    name = "k3s-srv-1"
    ip   = local.vm_settings["k3s-srv-1"].ip
  }
  description = "Master node details"
}

output "worker_nodes" {
  value = [
    for name, j in local.vm_settings :
    { name = name, ip = j.ip }
    if j.type == "worker"
  ]
  description = "Worker nodes details"
}

output "ansible_inventory_path" {
  value       = "inventory/hosts.ini"
  description = "Path to the generated Ansible inventory file"
}

output "ssh_key_path" {
  value       = pathexpand("~/.ssh/${var.ssh_key_name}_id_ed25519")
  description = "Path to the SSH private key"
  sensitive   = true
}
