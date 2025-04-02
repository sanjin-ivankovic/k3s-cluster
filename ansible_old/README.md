# K3s Ansible Configuration

This directory contains Ansible playbooks and roles for deploying and configuring a K3s Kubernetes cluster.

## Directory Structure

- `inventory/`: Contains the inventory file (symlinked from Terraform output)
- `group_vars/`: Variables applied to groups of hosts
- `host_vars/`: Variables applied to specific hosts
- `roles/`: Ansible roles for different node types
- `playbooks/`: Playbooks that combine roles to accomplish tasks
- `lint-config.yml`: Configuration for ansible-lint
- `linting.sh`: Script to run linting checks

## Usage

### Pre-flight Validation

Before deploying, validate your Ansible code with:

```bash
cd ansible
chmod +x linting.sh
./linting.sh
```

### Deployment

After running Terraform to provision the infrastructure, deploy K3s with:

```bash
cd ansible
ansible-playbook playbooks/deploy-k3s.yml
```

### Uninstallation

To completely uninstall K3s from all nodes:

```bash
cd ansible
ansible-playbook playbooks/uninstall-k3s.yml
```

This will:

1. Remove K3s from worker nodes first
2. Then remove K3s from the master node
3. Clean up all remaining K3s and container-related files
4. The uninstall is designed to be idempotent and safe to run multiple times

## Security Considerations

The configuration includes sensitive values like the CloudFlare API token. In a production environment, you should secure these values using Ansible Vault:

```bash
# Encrypt the entire group vars file
ansible-vault encrypt group_vars/master.yml

# Or, create a separate encrypted file for sensitive values
ansible-vault create group_vars/secure.yml
```

Then reference the encrypted file in your playbook or include it in your group_vars.

To run playbooks with vault-encrypted files:

```bash
ansible-playbook playbooks/setup-k3s.yml --ask-vault-pass
# OR with a password file (not recommended for high security environments)
ansible-playbook playbooks/setup-k3s.yml --vault-password-file ~/.vault_pass.txt
```

## Managing Sensitive Variables

This project uses Ansible Vault to store sensitive variables like API tokens in an encrypted file.

### Setting Up Secure Variables

1. Create an encrypted variables file:

   ```bash
   ansible-vault create group_vars/secure.yml
   ```

2. Add your sensitive variables to this file:

   ```yaml
   ---
   # Cloudflare API token for cert-manager DNS01 challenge
   cloudflare_api_token: 'your-secret-token-here'
   ```

3. To edit the file later:
   ```bash
   ansible-vault edit group_vars/secure.yml
   ```

### Running Playbooks with Encrypted Variables

When you run playbooks that use these encrypted variables, you'll need to provide the vault password:

```bash
# Provide password via prompt
ansible-playbook playbooks/setup-k3s.yml --ask-vault-pass

# OR use a password file
ansible-playbook playbooks/setup-k3s.yml --vault-password-file ~/.vault_pass.txt
```

For CI/CD environments, consider using `--vault-password-file` with appropriate security measures.

## TLS Certificates with cert-manager

This project automatically sets up cert-manager with Cloudflare DNS01 challenge to secure your cluster services with valid TLS certificates.

### Certificate Configuration

The automation:

1. Installs cert-manager via Helm
2. Configures DNS01 challenge using CloudFlare API token
3. Creates a ClusterIssuer for Let's Encrypt
4. Requests a wildcard certificate for your domain

### Checking Certificate Status

To check the status of your certificates:

```bash
ansible-playbook playbooks/cert-manager.yml --ask-vault-pass
```

### Manual Certificate Management

If you need to manually manage certificates, you can use these commands:

```bash
# Check certificate status
kubectl get certificate -n default
kubectl describe certificate phizio-wildcard-cert -n default

# Troubleshooting
kubectl get challenges -A
kubectl get events -n default --sort-by=.metadata.creationTimestamp
```

### Using Certificates in Applications

To use the wildcard certificate in your applications, reference it in ingress resources:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: traefik
spec:
  tls:
    - hosts:
        - app.phizio.net
      secretName: phizio-wildcard-tls # This is your wildcard cert secret
  rules:
    - host: app.phizio.net
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: your-service
                port:
                  number: 80
```

## Traefik Ingress Controller

This project deploys Traefik as the ingress controller for routing external traffic to services in your cluster.

### Deploying Traefik

To deploy Traefik independently:

```bash
# Deploy using the dedicated playbook
ansible-playbook -i inventory/hosts.ini playbooks/deploy-traefik.yml --ask-vault-pass

# Or during full cluster setup with the tag
ansible-playbook -i inventory/hosts.ini playbooks/setup-k3s.yml --tags "traefik" --ask-vault-pass
```

### Traefik Configuration

Traefik is configured with:

- HTTPS redirection enabled by default
- Dashboard secured with TLS using your wildcard certificate
- Dashboard accessible at: https://traefik.phizio.net

The Traefik dashboard provides access to:

- Real-time traffic visualization
- Health status of your services
- Router and middleware configuration

### Customizing Traefik

You can customize Traefik by editing the variables in:

- `roles/traefik/defaults/main.yml` - Default settings
- `group_vars/master.yml` - Override settings for your environment

For advanced configurations, you can define additional Traefik resources directly as Kubernetes CRDs:

```yaml
# Example: Creating a Traefik middleware for authentication
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: basic-auth
  namespace: default
spec:
  basicAuth:
    secret: basic-auth-secret
```

## Rancher Management Platform

This project includes deployment of Rancher as a cluster management platform.

### Deploying Rancher

To deploy Rancher independently:

```bash
# Deploy using the dedicated playbook
ansible-playbook -i inventory/hosts.ini playbooks/deploy-rancher.yml --ask-vault-pass
```

### Rancher Configuration

Rancher is configured with:

- TLS secured with your wildcard certificate
- Web interface accessible at: https://rancher.phizio.net
- Integration with Traefik for ingress
- Initial bootstrap password for first-time setup

After deployment, you can access Rancher and complete the initial setup:

1. Navigate to https://rancher.phizio.net in your browser
2. Retrieve the initial bootstrap password with:
   ```bash
   kubectl get secret --namespace cattle-system bootstrap-secret -o go-template='{{.data.bootstrapPassword | base64decode}}'
   ```
3. Log in and set your admin password

### Customizing Rancher

You can customize Rancher by editing the variables in:

- `roles/rancher/defaults/main.yml` - Default settings
- `group_vars/master.yml` - Override settings for your environment

For production environments, consider:

- Increasing the replica count for high availability
- Configuring external databases for persistence
- Setting up LDAP/AD integration for authentication

## Application Deployments

### Pi-hole DNS Server

This project includes a Pi-hole deployment for network-wide ad blocking and local DNS services.

#### Deploying Pi-hole

To deploy Pi-hole on your K3s cluster:

```bash
# Deploy using the dedicated playbook
ansible-playbook -i inventory/hosts.ini playbooks/deploy-pihole.yml --ask-vault-pass

# Or during the full cluster setup by adding the --tags argument
ansible-playbook -i inventory/hosts.ini playbooks/setup-k3s.yml --tags "pihole" --ask-vault-pass
```

#### Configuration

Pi-hole is configured with the following default settings:

- Web interface available at: http://10.0.0.53/admin
- Admin password: Set in group_vars/secure.yml
- DNS service available at: 10.0.0.53:53
- Uses CloudFlare and Google DNS as upstream resolvers (1.1.1.1, 8.8.8.8)

You can customize Pi-hole by editing the variables in:

- `roles/pihole/defaults/main.yml` - Default settings
- `group_vars/master.yml` - Override settings for your environment
- `group_vars/secure.yml` - Secure settings like the admin password (encrypted)
