# Outputs for networking module

output "network_id" {
  description = "ID of the created/configured network"
  value       = var.create_network ? proxmox_network.k3s_network[0].id : null
}

output "network_details" {
  description = "Details about the configured network"
  value = {
    name    = var.network_name
    bridge  = var.network_bridge
    cidr    = var.network_cidr
    gateway = var.network_gateway
  }
}

output "dns_domain" {
  description = "DNS domain for the cluster"
  value       = var.dns_domain
}

output "firewall_enabled" {
  description = "Whether firewall rules are enabled"
  value       = var.firewall_enabled
}
