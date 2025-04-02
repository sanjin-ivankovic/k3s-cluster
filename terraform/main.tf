# Main Terraform configuration for K3s home lab cluster

# Local variables
locals {
  vm_settings = merge(flatten([for i in fileset(".", "vars/nodes.yaml") : yamldecode(file(i))["nodes"]])...)
  network     = yamldecode(file("vars/network.yaml"))

  # Validate disk sizes
  invalid_disk_sizes = [for name, node in local.vm_settings :
    name if(lookup(node, "disk_size", null) != null &&
  !can(regex(var.disk_size_validation, node.disk_size)))]

  # Use existing validation checks from data_validation.tf
  # Invalid IPs and MACs are already defined there

  # NOTE: Removed duplicate validation_checks definition since it's already defined in data_validation.tf
  # The validation_checks in data_validation.tf already includes invalid_disk_sizes

  # Use existing SSH key - NEVER generate a new one
  ssh_key_path   = pathexpand("~/.ssh/${var.ssh_key_name}_id_ed25519")
  ssh_public_key = file("${local.ssh_key_path}.pub") # Always read from the existing key

  common_config = {
    target_node       = var.proxmox_target_node
    storage_type      = var.vm_storage_type
    default_disk_size = var.vm_disk_size
    default_image     = var.vm_image # Using the specified ubuntu-cloud image
    cicustom          = "vendor=local:snippets/qemu-guest-agent.yaml"
    network = {
      dns     = local.network.dns
      bridge  = local.network.bridge
      vlan    = local.network.vlan
      gateway = local.network.gateway
    }
    vm_user        = var.vm_user # Using sanjin as specified
    ssh_public_key = local.ssh_public_key
  }
}

# We'll keep this resource but set count to 0 since we're always using an existing key
resource "tls_private_key" "ssh_key" {
  count     = 0 # Never generate a new key
  algorithm = "ED25519"
}

# Similarly, we'll disable these resources by setting count to 0
resource "local_file" "private_key" {
  count           = 0 # Never save a generated key
  content         = tls_private_key.ssh_key[0].private_key_pem
  filename        = local.ssh_key_path
  file_permission = "0600"
}

resource "local_file" "public_key" {
  count           = 0 # Never save a generated key
  content         = tls_private_key.ssh_key[0].public_key_openssh
  filename        = "${local.ssh_key_path}.pub"
  file_permission = "0644"
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
    os        = lookup(each.value, "os", var.vm_image) # Use node-specific OS or default to vm_image
    cores     = each.value.cores
    ram       = each.value.ram
    macaddr   = each.value.macaddr
    disk_size = lookup(each.value, "disk_size", var.vm_disk_size) # Use node-specific disk size or default
  }

  common_config = local.common_config
}

# Generate a single Ansible inventory
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

  # Create a symlink to ansible/inventory/hosts.ini with absolute paths for reliability
  provisioner "local-exec" {
    command = "mkdir -p ../ansible/inventory && ln -sf \"$(pwd)/inventory/hosts.ini\" \"$(pwd)/../ansible/inventory/hosts.ini\""
  }
}

# Prepare VMs for Ansible (validate connectivity)
module "vm_prep" {
  source = "./modules/vm_prep"

  master_ips = [for name, node in local.vm_settings : node.ip if node.type == "server" || node.type == "master"]
  worker_ips = [for name, node in local.vm_settings : node.ip if node.type == "worker"]

  user                 = var.vm_user
  ssh_private_key_path = pathexpand(replace(var.ssh_key_file, ".pub", "")) # Get the private key path from the public key path
  cluster_name         = var.cluster_name

  # Only check connectivity without installing anything
  check_connectivity    = var.run_validation
  generate_ansible_vars = true

  # Use the inventory file we just created so we don't generate a duplicate
  inventory_file = "${path.root}/inventory/hosts.ini"

  depends_on = [module.k3s_nodes, local_file.ansible_inventory] # Added dependency on the inventory file
}
