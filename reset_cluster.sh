#!/bin/bash
# Script to cleanly reset the K3s cluster

echo "===== K3s Cluster Reset Script ====="
echo "This will completely remove K3s from all nodes in the cluster."
echo "WARNING: All cluster data will be lost!"
echo ""

# Prompt for confirmation
read -p "Are you sure you want to proceed? (yes/no): " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
  echo "Aborted. No changes were made."
  exit 0
fi

# Change to the ansible directory
cd "$(dirname "$0")/ansible"

# Run the reset playbook
echo "Starting K3s cluster reset..."
ansible-playbook playbooks/k3s_reset.yml -v

# Display completion message
if [ $? -eq 0 ]; then
  echo ""
  echo "K3s cluster has been reset successfully."
  echo "You can redeploy the cluster using:"
  echo "./deploy_cluster.sh"
else
  echo ""
  echo "Reset encountered some issues. Check the output above for errors."
  echo "You may need to manually clean up some nodes."
fi
