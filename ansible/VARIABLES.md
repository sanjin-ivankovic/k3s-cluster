# K3s Cluster Variable Reference

This document provides a comprehensive list of all variables used in the K3s cluster automation.

## Global Variables

| Variable            | Default               | Description                  | Location              |
| ------------------- | --------------------- | ---------------------------- | --------------------- |
| `cloudflare_domain` | phizio.net            | Domain name for all services | group_vars/all.yml    |
| `k3s_version`       | v1.31.7+k3s1          | K3s version to install       | group_vars/all.yml    |
| `metallb_addresses` | 10.0.0.200-10.0.0.220 | IP range for load balancers  | group_vars/master.yml |

## Cert Manager Variables

| Variable                        | Default              | Description                  | Location                       |
| ------------------------------- | -------------------- | ---------------------------- | ------------------------------ |
| `cert_manager_version`          | v1.17.1              | cert-manager version         | cert_manager/defaults/main.yml |
| `cert_manager_email`            | admin@phizio.net     | Email for Let's Encrypt      | cert_manager/defaults/main.yml |
| `cert_manager_certificate_name` | phizio-wildcard-cert | Name of wildcard certificate | cert_manager/defaults/main.yml |

## Longhorn Variables

| Variable                 | Default | Description                | Location                   |
| ------------------------ | ------- | -------------------------- | -------------------------- |
| `longhorn_version`       | v1.8.1  | Longhorn version           | longhorn/defaults/main.yml |
| `longhorn_replica_count` | 3       | Number of storage replicas | longhorn/defaults/main.yml |

## Traefik Variables

| Variable                    | Default | Description              | Location                  |
| --------------------------- | ------- | ------------------------ | ------------------------- |
| `traefik_version`           | v3.3.4  | Traefik version          | traefik/defaults/main.yml |
| `traefik_dashboard_enabled` | true    | Enable Traefik dashboard | traefik/defaults/main.yml |

## Monitoring Variables

| Variable                            | Default | Description              | Location                     |
| ----------------------------------- | ------- | ------------------------ | ---------------------------- |
| `kube_prometheus_stack_version`     | 70.3.0  | Prometheus stack version | monitoring/defaults/main.yml |
| `grafana_admin_user`                | admin   | Grafana admin username   | monitoring/defaults/main.yml |
| `grafana_resources.requests.memory` | 256Mi   | Grafana memory request   | monitoring/defaults/main.yml |

## Rancher Variables

| Variable           | Default                       | Description                | Location                  |
| ------------------ | ----------------------------- | -------------------------- | ------------------------- |
| `rancher_version`  | 2.10.3                        | Rancher version            | rancher/defaults/main.yml |
| `rancher_hostname` | rancher.{{cloudflare_domain}} | Rancher hostname           | rancher/defaults/main.yml |
| `rancher_replicas` | 1                             | Number of Rancher replicas | rancher/defaults/main.yml |

## Sensitive Variables (stored in secure.yml)

| Variable                     | Description                    | Used By      |
| ---------------------------- | ------------------------------ | ------------ |
| `cloudflare_api_token`       | API token for Cloudflare DNS   | cert-manager |
| `grafana_admin_password`     | Grafana admin password         | monitoring   |
| `rancher_bootstrap_password` | Initial Rancher admin password | rancher      |
