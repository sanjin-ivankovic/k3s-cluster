# Networking resources for K3s home lab
# Manages network configuration, firewall rules, and DNS records

locals {
  network_tags = merge(var.tags, {
    Component = "networking"
  })
}

# Network configuration - uses Proxmox network if available
# For home lab, often we're just connecting to existing networks
resource "proxmox_network" "k3s_network" {
  count   = var.create_network ? 1 : 0
  node    = var.proxmox_node
  name    = var.network_name
  bridge  = var.network_bridge
  cidr    = var.network_cidr
  gateway = var.network_gateway
}

# Firewall configuration (optional)
resource "proxmox_firewall_rules" "k3s_firewall" {
  count = var.firewall_enabled ? 1 : 0
  node  = var.proxmox_node

  # K3s required ports
  # Allow K3s API server
  rule {
    type    = "in"
    action  = "ACCEPT"
    proto   = "tcp"
    dport   = "6443"
    comment = "K3s API Server"
  }

  # Allow required K3s ports
  rule {
    type    = "in"
    action  = "ACCEPT"
    proto   = "tcp"
    dport   = "2379:2380"
    comment = "etcd client and peer"
  }

  # Node communication
  rule {
    type    = "in"
    action  = "ACCEPT"
    proto   = "tcp"
    dport   = "10250"
    comment = "Kubelet"
  }

  # Required for Canal/Flannel VXLAN
  rule {
    type    = "in"
    action  = "ACCEPT"
    proto   = "udp"
    dport   = "8472"
    comment = "Canal/Flannel VXLAN"
  }

  # Default deny to ensure explicit rules
  rule {
    type    = "in"
    action  = "REJECT"
    comment = "Default deny"
  }
}

# DNS Records (Optional - for home labs with DNS servers)
resource "local_file" "dns_hosts" {
  count = var.create_dns_records ? 1 : 0

  content = templatefile("${path.module}/templates/hosts.tmpl", {
    domain       = var.dns_domain
    node_records = var.node_records
  })

  filename = var.hosts_file_path
}
