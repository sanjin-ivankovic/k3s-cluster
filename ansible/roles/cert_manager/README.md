# Cert-Manager Role

This role installs and configures cert-manager on a Kubernetes cluster, sets up a ClusterIssuer
using Cloudflare DNS for ACME validation, and issues wildcard certificates.

## Requirements

- A running Kubernetes cluster
- Helm installed
- A Cloudflare API token with Zone:DNS:Edit permissions
- DNS domain configured in Cloudflare

## Role Variables

```yaml
# cert-manager version
cert_manager_version: 'v1.17.1'

# Default issuer settings
cert_manager_issuer_name: 'acme-clusterissuer'
cert_manager_acme_server: 'https://acme-v02.api.letsencrypt.org/directory'

# Default certificate settings
cert_manager_certificate_name: 'example-wildcard-cert'
cert_manager_certificate_namespace: 'default'
cert_manager_tls_secret_name: 'example-wildcard-tls'

# Cloudflare settings (required)
cloudflare_api_token: 'your-api-token' # Store this securely in vault
cloudflare_email: 'admin@example.com'
cloudflare_domain: 'example.com'
```

## Dependencies

None.

## Example Playbook

```yaml
- name: Deploy and configure cert-manager
  hosts: k3s_master
  become: false
  roles:
    - cert_manager
```

## Certificates

The role will create a wildcard certificate for your domain by default. This certificate
will work for both the root domain (example.com) and all subdomains (\*.example.com).

To check certificate status:

```bash
kubectl get certificates -n default
```

## Troubleshooting

1. Check certificate status:

   ```bash
   kubectl describe certificate -n default phizio-wildcard-cert
   ```

2. Check CertificateRequest status:

   ```bash
   kubectl get certificaterequests -n default
   ```

3. Check ACME Challenge status:

   ```bash
   kubectl get challenges -A
   ```

4. Check cert-manager logs:

   ```bash
   kubectl logs -n cert-manager -l app=cert-manager
   ```

5. Verify ClusterIssuer status:
   ```bash
   kubectl describe clusterissuer acme-clusterissuer
   ```
