# Terraform and provider version constraints

terraform {
  # Require at least Terraform v1.0.0
  required_version = ">= 1.0.0"

  required_providers {
    # Proxmox Provider
    proxmox = {
      source  = "telmate/proxmox"
      version = ">= 2.9.0, < 3.0.0"
    }

    # Local Provider for file operations
    local = {
      source  = "hashicorp/local"
      version = ">= 2.2.0"
    }

    # Random Provider for generating random values
    random = {
      source  = "hashicorp/random"
      version = ">= 3.3.0"
    }

    # Null Provider for orchestration and dependencies
    null = {
      source  = "hashicorp/null"
      version = ">= 3.1.0"
    }

    # Template Provider for template rendering
    template = {
      source  = "hashicorp/template"
      version = ">= 2.2.0"
    }
  }
}

# This block is for checking compatibility with the environment
# It helps catch common issues before they cause problems
resource "null_resource" "environment_check" {
  provisioner "local-exec" {
    command = <<-EOT
      echo "Checking environment compatibility..."
      terraform_version=$(terraform version -json | jq -r '.terraform_version')
      echo "Terraform version: $terraform_version"

      # Check if required commands are available
      for cmd in ssh-keygen curl jq; do
        if ! command -v $cmd &> /dev/null; then
          echo "WARNING: $cmd is required but not found in PATH"
        fi
      done

      # Check for connectivity to Proxmox API
      if [ -n "$PM_API_URL" ]; then
        echo "Checking connectivity to Proxmox API..."
        if curl -k -s "$PM_API_URL/version" > /dev/null; then
          echo "Proxmox API is reachable."
        else
          echo "WARNING: Proxmox API is not reachable. Check your configuration."
        fi
      else
        echo "PM_API_URL not set, skipping Proxmox API connectivity check."
      fi
    EOT
  }

  # Only run this check during initial apply
  triggers = {
    always_run = "${timestamp()}"
  }

  # This won't block the deployment if checks fail
  provisioner "local-exec" {
    on_failure = continue
    command    = "echo 'Environment check completed with warnings.'"
  }
}
