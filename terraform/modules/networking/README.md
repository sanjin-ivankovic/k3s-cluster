# Networking Module

This module manages networking configurations for the K3s cluster in a home lab environment.

## Resources Created

- Network configuration for K3s nodes
- Firewall rules for cluster communication
- DNS records (optional)

## Input Variables

| Name                 | Description                         | Type     | Default            | Required |
| -------------------- | ----------------------------------- | -------- | ------------------ | :------: |
| `network_name`       | Name of the network to use          | `string` | `"default"`        |    no    |
| `network_bridge`     | Bridge interface to use             | `string` | `"vmbr0"`          |    no    |
| `network_cidr`       | CIDR for the node network           | `string` | `"192.168.1.0/24"` |    no    |
| `dns_domain`         | Domain name for the cluster         | `string` | `"k3s.local"`      |    no    |
| `create_dns_records` | Whether to create DNS records       | `bool`   | `false`            |    no    |
| `firewall_enabled`   | Whether to configure firewall rules | `bool`   | `true`             |    no    |

## Output Values

| Name              | Description                          |
| ----------------- | ------------------------------------ |
| `network_id`      | ID of the created/configured network |
| `network_details` | Details about the configured network |
| `dns_servers`     | DNS servers for the network          |

## Example Usage

```hcl
module "k3s_network" {
  source = "../modules/networking"

  network_name = "k3s_net"
  network_cidr = "192.168.10.0/24"
  dns_domain = "k3s.home"
  create_dns_records = true
}
```

## Home Lab Considerations

- Configured for typical home network environments
- Options for integrating with home routers/DNS
- Conservative firewall defaults suitable for home environments
