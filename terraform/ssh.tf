# Check if key exists on disk
locals {
  ssh_key_exists = fileexists(pathexpand("~/.ssh/${var.ssh_key_name}_id_ed25519"))
}

# Generate an SSH key if either:
# 1. No key exists and we need to create one
# 2. A key exists but we want to overwrite it
resource "tls_private_key" "k3s_ssh" {
  algorithm = "ED25519"
  count     = (!local.ssh_key_exists || var.overwrite_ssh_keys) ? 1 : 0
}

# Read existing key from disk if:
# 1. A key exists
# 2. We don't want to overwrite it
data "local_file" "existing_ssh_key" {
  count    = (local.ssh_key_exists && !var.overwrite_ssh_keys) ? 1 : 0
  filename = pathexpand("~/.ssh/${var.ssh_key_name}_id_ed25519.pub")
}

# Write the private key to disk if:
# 1. We generated a new key (either no key existed or overwrite was true)
resource "local_file" "private_key" {
  count           = (!local.ssh_key_exists || var.overwrite_ssh_keys) ? 1 : 0
  content         = tls_private_key.k3s_ssh[0].private_key_openssh
  filename        = pathexpand("~/.ssh/${var.ssh_key_name}_id_ed25519")
  file_permission = "0600"
}

# Write the public key to disk if:
# 1. We generated a new key (either no key existed or overwrite was true)
resource "local_file" "public_key" {
  count           = (!local.ssh_key_exists || var.overwrite_ssh_keys) ? 1 : 0
  content         = tls_private_key.k3s_ssh[0].public_key_openssh
  filename        = pathexpand("~/.ssh/${var.ssh_key_name}_id_ed25519.pub")
  file_permission = "0644"
}

# Choose the appropriate public key based on whether we generated a new one or are using existing
locals {
  ssh_public_key = ((!local.ssh_key_exists || var.overwrite_ssh_keys) ?
    tls_private_key.k3s_ssh[0].public_key_openssh :
  data.local_file.existing_ssh_key[0].content)
}

# Resource to handle cleanup on terraform destroy, but only if:
# 1. Cleanup is enabled via the cleanup_ssh_keys variable
# 2. We actually generated keys (didn't use existing ones)
resource "null_resource" "ssh_key_cleanup" {
  count = var.cleanup_ssh_keys && (!local.ssh_key_exists || var.overwrite_ssh_keys) ? 1 : 0

  # Store the SSH key name in a local variable
  triggers = {
    ssh_key_path = pathexpand("~/.ssh/${var.ssh_key_name}")
  }

  # This provisioner only runs during destroy
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      echo "Removing SSH keys at cleanup..."
      rm -f ${self.triggers.ssh_key_path}_id_ed25519 ${self.triggers.ssh_key_path}_id_ed25519.pub
    EOT
  }

  # Ensure this resource is created after keys are written
  depends_on = [
    local_file.private_key,
    local_file.public_key
  ]
}
