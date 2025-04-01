# Terraform Modules for K3s Home Lab

This directory contains reusable Terraform modules for the K3s home lab infrastructure.

## Module Structure

The modules are organized by resource function:

- **compute**: Virtual machines and compute resources for K3s nodes
- **networking**: Network configuration, including VLANs and firewall rules
- **storage**: Persistent storage solutions for the cluster
- **kubernetes**: K3s installation and configuration

## Usage Guidelines

1. Each module should be focused on a specific function
2. Maintain consistent input/output variable patterns
3. Include a README.md in each module with:
   - Description
   - Required inputs
   - Optional inputs
   - Outputs
   - Example usage

## Best Practices for Home Lab Modules

- Include reasonable defaults appropriate for home environments
- Document resource requirements clearly
- Add comments for any home-specific optimizations
- Consider power management and noise factors for home deployment
