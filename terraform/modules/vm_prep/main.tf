# VM preparation module for K3s Ansible deployment
# This module prepares VMs for subsequent Ansible-based K3s deployment

locals {
  # First master is the primary control plane
  master_ip = element(var.master_ips, 0)

  # Set node information for inventory generation
  nodes = {
    masters = [for ip in var.master_ips : {
      ip   = ip
      role = "master"
    }]
    workers = [for ip in var.worker_ips : {
      ip   = ip
      role = "worker"
    }]
  }
}

# Check connectivity to nodes
resource "null_resource" "check_connectivity" {
  count = var.check_connectivity ? length(concat(var.master_ips, var.worker_ips)) : 0

  # Use direct expressions for connection parameters rather than a nested locals block
  connection {
    type        = "ssh"
    host        = count.index < length(var.master_ips) ? var.master_ips[count.index] : var.worker_ips[count.index - length(var.master_ips)]
    user        = var.user
    private_key = file(var.ssh_private_key_path)
    timeout     = var.connection_timeout
  }

  # Try to connect using SSH
  provisioner "remote-exec" {
    # Simple command to check connectivity
    inline = [
      "echo 'Successfully connected to ${count.index < length(var.master_ips) ? var.master_ips[count.index] : var.worker_ips[count.index - length(var.master_ips)]} (${count.index < length(var.master_ips) ? "master" : "worker"} node)'",
      "hostname",
      "cat /etc/os-release | grep PRETTY_NAME"
    ]

    # Don't fail the deployment if connection fails
    # Ansible will retry later anyway
    on_failure = continue
  }
}

# Generate Ansible inventory
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.tmpl", {
    master_nodes = local.nodes.masters
    worker_nodes = local.nodes.workers
    ssh_user     = var.user
    cluster_name = var.cluster_name
  })

  filename = "${var.inventory_path}/k3s-inventory.ini"

  # Ensure directory exists
  provisioner "local-exec" {
    command = "mkdir -p ${var.inventory_path}"
  }
}

# Generate Ansible vars file (optional)
resource "local_file" "ansible_vars" {
  count = var.generate_ansible_vars ? 1 : 0

  content = templatefile("${path.module}/templates/vars.tmpl", {
    master_ip    = local.master_ip
    master_ips   = var.master_ips
    worker_ips   = var.worker_ips
    ssh_user     = var.user
    cluster_name = var.cluster_name
    enable_ha    = length(var.master_ips) > 1
  })

  filename = "${var.inventory_path}/group_vars/all.yml"

  # Ensure directory exists
  provisioner "local-exec" {
    command = "mkdir -p ${var.inventory_path}/group_vars"
  }
}
