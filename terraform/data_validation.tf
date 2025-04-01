locals {
  # Validate IP addresses
  invalid_ips = [for name, node in local.vm_settings : name if !can(regex("^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$", node.ip))]

  # Validate MAC addresses
  invalid_macs = [for name, node in local.vm_settings : name if !can(regex("^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$", node.macaddr))]

  # Validate VMIDs
  invalid_vmids = [for name, node in local.vm_settings : name if node.vmid < 100 || node.vmid > 999]

  # Validate VM types
  invalid_types = [for name, node in local.vm_settings : name if !contains(["master", "worker"], node.type)]

  # Check for duplicate IP addresses
  ip_counts     = { for ip in [for name, node in local.vm_settings : node.ip] : ip => length([for name, node in local.vm_settings : node.ip if node.ip == ip]) }
  duplicate_ips = [for ip, count in local.ip_counts : ip if count > 1]

  # Check for duplicate MAC addresses
  mac_counts     = { for mac in [for name, node in local.vm_settings : node.macaddr] : mac => length([for name, node in local.vm_settings : node.macaddr if node.macaddr == mac]) }
  duplicate_macs = [for mac, count in local.mac_counts : mac if count > 1]

  # Check for duplicate VMIDs
  vmid_counts     = { for vmid in [for name, node in local.vm_settings : node.vmid] : vmid => length([for name, node in local.vm_settings : node.vmid if node.vmid == vmid]) }
  duplicate_vmids = [for vmid, count in local.vmid_counts : vmid if count > 1]
}

resource "null_resource" "validation_errors" {
  count = length(local.invalid_ips) + length(local.invalid_macs) + length(local.invalid_vmids) + length(local.invalid_types) + length(local.duplicate_ips) + length(local.duplicate_macs) + length(local.duplicate_vmids) > 0 ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      echo "Validation errors found in node configuration:"
      echo "Invalid IP addresses: ${join(", ", local.invalid_ips)}"
      echo "Invalid MAC addresses: ${join(", ", local.invalid_macs)}"
      echo "Invalid VMIDs: ${join(", ", local.invalid_vmids)}"
      echo "Invalid node types: ${join(", ", local.invalid_types)}"
      echo "Duplicate IPs: ${join(", ", local.duplicate_ips)}"
      echo "Duplicate MACs: ${join(", ", local.duplicate_macs)}"
      echo "Duplicate VMIDs: ${join(", ", local.duplicate_vmids)}"
      echo "Please fix these errors and try again."
      exit 1
    EOT

    interpreter = ["bash", "-c"]
    on_failure  = fail
  }

  triggers = {
    always_run = "${timestamp()}"
    fail       = "Validation errors found in node configuration. See output for details."
  }
}
