# Outputs for VM preparation module

output "master_node" {
  description = "Details of the primary master node"
  value = {
    ip       = element(var.master_ips, 0)
    role     = "master"
    ssh_user = var.user
  }
}

output "worker_nodes" {
  description = "Details of the worker nodes"
  value = [
    for ip in var.worker_ips : {
      ip       = ip
      role     = "worker"
      ssh_user = var.user
    }
  ]
}

output "inventory_file" {
  description = "Path to the generated inventory file"
  value       = "${var.inventory_path}/k3s-inventory.ini"
}

output "all_nodes" {
  description = "List of all nodes"
  value       = concat(var.master_ips, var.worker_ips)
}

output "node_count" {
  description = "Total number of nodes"
  value       = length(var.master_ips) + length(var.worker_ips)
}
