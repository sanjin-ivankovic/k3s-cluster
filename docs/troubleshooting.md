# Troubleshooting Guide

This guide covers common issues you might encounter with your K3s cluster and how to resolve them.

## Table of Contents

- [Infrastructure (Terraform) Issues](#infrastructure-terraform-issues)
- [Cluster (K3s) Issues](#cluster-k3s-issues)
- [Application Issues](#application-issues)
- [Networking Issues](#networking-issues)
- [Storage Issues](#storage-issues)
- [Common Commands](#common-commands)
- [Logs and Debugging](#logs-and-debugging)

## Infrastructure (Terraform) Issues

### Proxmox API Connection Failures

**Symptoms**: Terraform can't connect to the Proxmox API

**Solutions**:

1. Check the API URL format and credentials in `terraform.tfvars`:
   ```
   proxmox_api_url = "https://10.0.0.2:8006/api2/json"
   ```
2. Ensure the Proxmox user has API permissions:
   ```bash
   # On Proxmox server
   pveum user token add terraform@pve terraform-token --privsep=0
   pveum aclmod / -user terraform@pve -role Administrator
   ```
3. If using self-signed certificates, set `pm_tls_insecure = true` in the provider configuration

### VM Creation Failures

**Symptoms**: VMs fail to create or get stuck in creating state

**Solutions**:

1. Check if the VM ID is already in use:
   ```bash
   # On Proxmox server
   qm list
   ```
2. Verify sufficient resources (CPU, RAM, disk space):
   ```bash
   # Check disk space
   df -h
   ```
3. Ensure the template exists:
   ```bash
   # List templates
   qm list | grep template
   ```

### SSH Connectivity Issues

**Symptoms**: Terraform can't connect to VMs via SSH

**Solutions**:

1. Verify the SSH key pair exists and has correct permissions:
   ```bash
   ls -la ~/.ssh/k3s_id_ed25519*
   chmod 600 ~/.ssh/k3s_id_ed25519
   ```
2. Check cloud-init configuration:
   ```bash
   # Run from inside the VM
   cat /var/log/cloud-init-output.log
   ```
3. Test SSH connection manually:
   ```bash
   ssh -i ~/.ssh/k3s_id_ed25519 sanjin@10.0.0.6
   ```

## Cluster (K3s) Issues

### K3s Failed to Start

**Symptoms**: K3s service doesn't start or keeps restarting

**Solutions**:

1. Check K3s service status:
   ```bash
   sudo systemctl status k3s
   ```
2. View K3s logs:
   ```bash
   sudo journalctl -u k3s -f
   ```
3. Verify prerequisites:

   ```bash
   # Check swap is disabled
   free -h

   # Check required kernel modules
   lsmod | grep -E 'br_netfilter|overlay'
   ```

### Node Not Joining Cluster

**Symptoms**: Worker nodes aren't appearing in `kubectl get nodes`

**Solutions**:

1. Check K3s agent status on the worker:
   ```bash
   sudo systemctl status k3s-agent
   ```
2. Verify the node token is correct:
   ```bash
   # On master
   sudo cat /var/lib/rancher/k3s/server/node-token
   ```
3. Check connectivity between master and worker:
   ```bash
   # From worker to master
   curl -k https://MASTER_IP:6443
   ```

### Cluster in Unhealthy State

**Symptoms**: Nodes showing NotReady or components constantly restarting

**Solutions**:

1. Check node conditions:
   ```bash
   kubectl describe node <node-name>
   ```
2. Look for evicted or crashed pods:
   ```bash
   kubectl get pods --all-namespaces -o wide | grep -v Running
   ```
3. Check system resources:
   ```bash
   kubectl top nodes
   ```

## Application Issues

### Pods Stuck in Pending

**Symptoms**: Pods never reach Running state

**Solutions**:

1. Check if nodes have sufficient resources:
   ```bash
   kubectl describe pod <pod-name> -n <namespace>
   ```
2. Verify node taints and pod tolerations:
   ```bash
   kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints
   ```
3. Check if PersistentVolumeClaims are bound:
   ```bash
   kubectl get pvc -n <namespace>
   ```

### Pods Crashing or Restarting

**Symptoms**: Pods frequently restart or show CrashLoopBackOff

**Solutions**:

1. Check pod logs:
   ```bash
   kubectl logs <pod-name> -n <namespace>
   kubectl logs -p <pod-name> -n <namespace>  # Previous instance
   ```
2. Check resource constraints:
   ```bash
   kubectl describe pod <pod-name> -n <namespace> | grep -A 3 Limits
   ```

### Services Not Accessible

**Symptoms**: Applications deployed but not reachable

**Solutions**:

1. Check service definition:
   ```bash
   kubectl get svc -n <namespace>
   ```
2. Verify endpoints:
   ```bash
   kubectl get endpoints <service-name> -n <namespace>
   ```
3. Test connectivity using a temporary pod:
   ```bash
   kubectl run -it --rm debug --image=busybox:1.28 -- /bin/sh
   # Then: wget -qO- <service-name>.<namespace>.svc.cluster.local
   ```

## Networking Issues

### Ingress Not Working

**Symptoms**: Services defined in Ingress not accessible

**Solutions**:

1. Verify Ingress controller is running:
   ```bash
   kubectl get pods -n traefik
   ```
2. Check Ingress resource:
   ```bash
   kubectl describe ingress <ingress-name> -n <namespace>
   ```
3. Test with curl from within a pod:
   ```bash
   kubectl exec -it <pod-name> -n <namespace> -- curl -H "Host: <host>" http://localhost
   ```

### Inter-Pod Communication Issues

**Symptoms**: Pods cannot communicate with each other

**Solutions**:

1. Check CNI plugin status:
   ```bash
   kubectl get pods -n kube-system | grep flannel
   ```
2. Verify network policies aren't blocking traffic:
   ```bash
   kubectl get networkpolicies --all-namespaces
   ```
3. Test network connectivity:
   ```bash
   kubectl exec -it <pod-name> -- ping <another-pod-ip>
   ```

### MetalLB Issues

**Symptoms**: LoadBalancer services don't get external IP

**Solutions**:

1. Check MetalLB controller:
   ```bash
   kubectl -n metallb-system get pods
   kubectl -n metallb-system logs deploy/metallb-controller
   ```
2. Verify IP address pool:
   ```bash
   kubectl -n metallb-system get ipaddresspools
   ```
3. Check service configuration:
   ```bash
   kubectl get svc <service-name> -n <namespace> -o yaml
   ```

## Storage Issues

### PVCs Stuck in Pending

**Symptoms**: PersistentVolumeClaims never bind to a PV

**Solutions**:

1. Check storage class:
   ```bash
   kubectl get storageclass
   kubectl get sc <storage-class-name> -o yaml
   ```
2. Verify PVC definition:
   ```bash
   kubectl describe pvc <pvc-name> -n <namespace>
   ```
3. For Longhorn, check Longhorn manager:
   ```bash
   kubectl -n longhorn-system get pods | grep longhorn-manager
   ```

### Data Persistence Problems

**Symptoms**: Data lost after pod restarts

**Solutions**:

1. Verify volume mounts:
   ```bash
   kubectl describe pod <pod-name> -n <namespace> | grep -A 10 Volumes
   ```
2. Check if the right PVC is being used:
   ```bash
   kubectl get pvc -n <namespace>
   kubectl get pv
   ```
3. Make sure data is being written to the mount path:
   ```bash
   kubectl exec -it <pod-name> -n <namespace> -- ls -la /path/to/mount
   ```

## Common Commands

### Cluster Information

```bash
# Get cluster info
kubectl cluster-info

# Check node status
kubectl get nodes -o wide

# View namespace resources
kubectl get all -n <namespace>
```

### Pod Management

```bash
# Force delete a stuck pod
kubectl delete pod <pod-name> -n <namespace> --grace-period=0 --force

# Getting shell access
kubectl exec -it <pod-name> -n <namespace> -- /bin/sh

# View pod logs
kubectl logs <pod-name> -n <namespace> -f
```

### System Debugging

```bash
# Node system logs
kubectl get --raw /api/v1/nodes/<node-name>/proxy/logs/syslog

# Check API server logs
sudo journalctl -u k3s | grep apiserver

# View events across all namespaces
kubectl get events --all-namespaces --sort-by='.metadata.creationTimestamp'
```

## Logs and Debugging

### Important Log Locations

**K3s Logs**:

```bash
# Server logs
sudo journalctl -u k3s -f

# Agent logs
sudo journalctl -u k3s-agent -f

# K3s configuration
sudo cat /etc/rancher/k3s/config.yaml
```

**Component Logs**:

```bash
# Get Traefik logs
kubectl logs -n traefik -l app.kubernetes.io/name=traefik

# Get MetalLB logs
kubectl logs -n metallb-system -l app=metallb

# Get Prometheus logs
kubectl logs -n monitoring -l app=prometheus
```

### Diagnostic Tools

**Network Diagnostics**:

```bash
# Network policy tester
kubectl run -it network-test --image=nicolaka/netshoot -- zsh

# DNS troubleshooting
kubectl run -it dnsutils --image=tutum/dnsutils --restart=Never -- bash
```

**System Information**:

```bash
# Get cluster usage stats
kubectl top nodes
kubectl top pods --all-namespaces

# Check component status
kubectl get componentstatuses
```

**Resource Validation**:

```bash
# Validate YAML against server
kubectl apply --validate=true --dry-run=server -f my-manifest.yaml
```

Remember to clean up diagnostic pods after use:

```bash
kubectl delete pod network-test dnsutils
```

## Recovery Procedures

### Rebuilding a Node

If a node becomes unrecoverable:

1. Drain the node (if it's still part of the cluster):

   ```bash
   kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data
   ```

2. Delete the node from the cluster:

   ```bash
   kubectl delete node <node-name>
   ```

3. Rebuild the VM using Terraform:

   ```bash
   cd terraform
   terraform apply -var="rebuild_nodes=[\"<node-name>\"]"
   ```

4. Reset and rejoin the node using Ansible:
   ```bash
   cd ansible
   ansible-playbook -l <node-name> playbooks/k3s_reset.yml
   ansible-playbook -l <node-name> playbooks/k3s_install.yml
   ```

### Recovering from etcd Data Loss

For HA setups with embedded etcd:

1. Identify the node with valid data:

   ```bash
   # On each master
   sudo k3s etcd-snapshot list
   ```

2. Start K3s with the `--cluster-reset` flag on one node:

   ```bash
   sudo systemctl stop k3s
   sudo K3S_DATASTORE_ENDPOINT='https://127.0.0.1:2379' k3s server --cluster-reset
   sudo systemctl start k3s
   ```

3. Rejoin other masters:
   ```bash
   ansible-playbook -l 'master:!k3s-srv-1' playbooks/k3s_reset.yml
   ansible-playbook -l 'master:!k3s-srv-1' playbooks/k3s_install.yml
   ```
