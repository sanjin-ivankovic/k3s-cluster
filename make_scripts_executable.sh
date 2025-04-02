#!/bin/bash
# Make all scripts executable

# Find all bash scripts in the repository
find . -name "*.sh" | while read script; do
  echo "Setting executable permission for: $script"
  chmod +x "$script"
done

# Also make these specific scripts executable in case they don't have .sh extension
chmod +x deploy_cluster.sh
chmod +x reset_cluster.sh
chmod +x verify_ssh_keys.sh
chmod +x test_ansible.sh
chmod +x test_ssh.sh
chmod +x lint_ansible.sh
chmod +x terraform/scripts/validate.sh
chmod +x terraform/scripts/cleanup.sh
chmod +x terraform/scripts/setup-remote-state.sh

echo "All script permissions updated."
