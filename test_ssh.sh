#!/bin/bash

# Set variables
SSH_USER="sanjin"  # Updated to match your cloud-init user
SSH_KEY="~/.ssh/k3s_id_ed25519"
HOSTS=("10.0.0.6" "10.0.0.7" "10.0.0.8")

# Test SSH connection to each host
echo "Testing SSH connections..."
for host in "${HOSTS[@]}"; do
  echo -n "Connecting to $host... "
  ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o BatchMode=yes -o ConnectTimeout=5 "$SSH_USER@$host" echo "Success" && echo "✅" || echo "❌"
done

echo ""
echo "If any connections failed, check:"
echo "1. The key path: $SSH_KEY - Does it exist and have proper permissions (600)?"
echo "2. Does the public key match what was deployed to the VMs?"
echo "3. Are the VMs reachable? Try: ping <IP>"
echo "4. Is the SSH service running on the VMs?"
