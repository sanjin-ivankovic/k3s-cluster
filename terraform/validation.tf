resource "null_resource" "validation" {
  count      = var.run_validation ? 1 : 0
  depends_on = [module.k3s_nodes]

  # Configuration validation - run first and fail fast
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    on_failure  = fail
    command     = <<-EOT
      # Data validation checks
      errors=0

      # Validate IP addresses
      for ip in ${join(" ", [for node in local.vm_settings : node.ip])}; do
        if ! [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
          echo "Error: Invalid IP address: $ip"
          errors=$((errors+1))
        fi
      done

      # Validate MAC addresses
      for mac in ${join(" ", [for node in local.vm_settings : node.macaddr])}; do
        if ! [[ $mac =~ ^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$ ]]; then
          echo "Error: Invalid MAC address: $mac"
          errors=$((errors+1))
        fi
      done

      # Check for duplicates
      if [ $(echo "${join(" ", [for node in local.vm_settings : node.ip])}" | tr ' ' '\n' | sort | uniq -d | wc -l) -gt 0 ]; then
        echo "Error: Duplicate IP addresses found"
        errors=$((errors+1))
      fi

      if [ $(echo "${join(" ", [for node in local.vm_settings : node.macaddr])}" | tr ' ' '\n' | sort | uniq -d | wc -l) -gt 0 ]; then
        echo "Error: Duplicate MAC addresses found"
        errors=$((errors+1))
      fi

      if [ $(echo "${join(" ", [for node in local.vm_settings : tostring(node.vmid)])}" | tr ' ' '\n' | sort | uniq -d | wc -l) -gt 0 ]; then
        echo "Error: Duplicate VMIDs found"
        errors=$((errors+1))
      fi

      # Fail if validation errors are found
      if [ $errors -gt 0 ]; then
        echo "Validation failed with $errors errors"
        exit 1
      fi

      echo "Configuration validation passed"
    EOT
  }

  # Wait for VMs and test connectivity
  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for VMs to initialize..."
      sleep 30

      echo "Testing SSH connectivity..."
      for ip in ${join(" ", [for node in local.vm_settings : node.ip])}; do
        echo "Checking $ip..."
        ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -i ~/.ssh/${var.ssh_key_name}_id_ed25519 ${var.vm_user}@$ip exit 0 || echo "Warning: Could not connect to $ip"
      done
    EOT
  }
}
