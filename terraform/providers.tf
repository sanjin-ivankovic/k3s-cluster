# Provider configuration
terraform {
  # Require at least Terraform v1.0.0
  required_version = ">= 1.0.0"

  required_providers {
    # Proxmox Provider
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc4"
    }

    # Local Provider for file operations
    local = {
      source  = "hashicorp/local"
      version = ">= 2.2.0"
    }

    # TLS Provider for SSH key generation
    tls = {
      source  = "hashicorp/tls"
      version = ">= 3.1.0"
    }

    # Null Provider for orchestration and dependencies
    null = {
      source  = "hashicorp/null"
      version = ">= 3.1.0"
    }

    # Replace template provider with variables_for_templating to use with Apple Silicon
    # The template provider is deprecated anyway, and local templates using templatefile()
    # function are recommended instead
  }

  # Uncomment to enable remote state
  # backend "s3" {
  #   endpoint = "https://minio.local"
  #   bucket   = "terraform-state"
  #   key      = "k3s-cluster/terraform.tfstate"
  #   region   = "us-east-1"  # Can be any value for MinIO
  #   skip_credentials_validation = true
  #   skip_region_validation      = true
  #   skip_requesting_account_id  = true
  #   skip_s3_checksum            = true
  #   force_path_style            = true
  # }
}

# Provider configuration for Proxmox
provider "proxmox" {
  pm_api_url      = var.proxmox_api_url
  pm_user         = var.proxmox_user
  pm_password     = var.proxmox_password
  pm_tls_insecure = true # Consider changing to false for production and configuring proper certificates

  # Add timeout and error handling for API calls
  pm_timeout    = 600
  pm_parallel   = 4
  pm_log_enable = false
  pm_log_file   = "terraform-plugin-proxmox.log"
  pm_debug      = false
  pm_log_levels = {
    _default    = "debug"
    _capturelog = ""
  }
}
