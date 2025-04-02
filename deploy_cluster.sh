#!/bin/bash
# Script to deploy the full K3s cluster (infrastructure + platform)

# Set some variables
TERRAFORM_DIR="$(dirname "$0")/terraform"
ANSIBLE_DIR="$(dirname "$0")/ansible"

echo "===== K3s Cluster Deployment Script ====="
echo "This will deploy a full K3s cluster using Terraform and Ansible."
echo ""

# Step 1: Verify SSH keys
echo "Step 1: Verifying SSH keys..."
./verify_ssh_keys.sh || {
  echo "Error: SSH key verification failed."
  exit 1
}

# Step 2: Run Terraform to provision infrastructure
echo -e "\nStep 2: Provisioning infrastructure with Terraform..."
cd "$TERRAFORM_DIR" || {
  echo "Error: Failed to change directory to $TERRAFORM_DIR"
  exit 1
}

terraform init
if ! terraform plan -out=k3s_plan; then
  echo "Error: Terraform plan failed."
  exit 1
fi

echo -e "\nTerraform will now create the following resources:"
terraform show k3s_plan | grep -E 'resource|data'

echo -e "\nProceeding with infrastructure creation..."
read -p "Continue? (yes/no): " CONTINUE

if [[ "$CONTINUE" != "yes" ]]; then
  echo "Aborted infrastructure deployment."
  exit 0
fi

if ! terraform apply k3s_plan; then
  echo "Error: Terraform apply failed."
  exit 1
fi

echo -e "\nInfrastructure successfully provisioned."
echo -e "Waiting 30 seconds for VMs to complete boot process...\n"
sleep 30

# Step 3: Run Ansible to deploy K3s and applications
echo "Step 3: Deploying K3s with Ansible..."
cd "$ANSIBLE_DIR" || {
  echo "Error: Failed to change directory to $ANSIBLE_DIR"
  exit 1
}

echo -e "First, testing connectivity to all nodes...\n"
ansible-playbook playbooks/test.yml || {
  echo "Error: Connection test failed. Some nodes may not be reachable."
  echo "Check your networking and try again, or proceed with caution."
  read -p "Continue with deployment anyway? (yes/no): " FORCE_CONTINUE
  if [[ "$FORCE_CONTINUE" != "yes" ]]; then
    echo "Aborted K3s deployment."
    exit 1
  fi
}

echo -e "\nDeploying K3s cluster and applications..."
if ! ansible-playbook playbooks/site.yml; then
  echo "Error: Ansible deployment failed."
  exit 1
fi

# Step 4: Verify cluster is running
echo -e "\nStep 4: Verifying cluster is operational..."
export KUBECONFIG="$(pwd)/../kubeconfig"
if ! kubectl get nodes; then
  echo "Warning: Unable to get cluster nodes. Check if kubeconfig was properly generated."
  exit 1
fi

echo -e "\n===== K3s Cluster Deployment Complete! ====="
echo "Your K3s cluster has been successfully deployed."
echo ""
echo "To use kubectl with this cluster:"
echo "export KUBECONFIG=$(pwd)/../kubeconfig"
echo ""
echo "To verify deployed applications:"
echo "kubectl get pods --all-namespaces"
echo ""
echo "For more information, refer to the documentation in the docs/ directory."
