locals {
  # Validate IP addresses
  invalid_ips = [for name, node in local.vm_settings : name if !can(regex("^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$", node.ip))]

  # Validate MAC addresses
  invalid_macs = [for name, node in local.vm_settings : name if(lookup(node, "macaddr", null) != null && !can(regex("^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$", node.macaddr)))]

  # Validate VMIDs
  invalid_vmids = [for name, node in local.vm_settings : name if node.vmid < 100 || node.vmid > 999]

  # Validate VM types
  invalid_types = [for name, node in local.vm_settings : name if !contains(["master", "worker", "server"], node.type)]

  # Check for duplicate IP addresses
  ip_counts     = { for ip in [for name, node in local.vm_settings : node.ip] : ip => length([for name, node in local.vm_settings : node.ip if node.ip == ip]) }
  duplicate_ips = [for ip, count in local.ip_counts : ip if count > 1]

  # Check for duplicate MAC addresses
  mac_counts     = { for mac in [for name, node in local.vm_settings : node.macaddr] : mac => length([for name, node in local.vm_settings : node.macaddr if node.macaddr == mac]) }
  duplicate_macs = [for mac, count in local.mac_counts : mac if count > 1]

  # Check for duplicate VMIDs
  vmid_counts     = { for vmid in [for name, node in local.vm_settings : node.vmid] : vmid => length([for name, node in local.vm_settings : node.vmid if node.vmid == vmid]) }
  duplicate_vmids = [for vmid, count in local.vmid_counts : vmid if count > 1]

  # Aggregate all validation issues
  validation_checks = concat(
    local.invalid_ips,
    local.invalid_macs,
    local.invalid_vmids,
    local.invalid_types,
    local.duplicate_ips,
    local.duplicate_macs,
    local.duplicate_vmids,
    local.invalid_disk_sizes # Added disk size validation
  )
}

resource "null_resource" "validation_errors" {
  count = length(local.validation_checks) > 0 ? 1 : 0

  provisioner "local-exec" {
    command = "echo 'Validation errors: ${join(", ", local.validation_checks)}' && exit 1"
  }

  lifecycle {
    precondition {
      condition     = length(local.validation_checks) == 0
      error_message = "Validation failed: ${join(", ", local.validation_checks)}"
    }
  }
}
