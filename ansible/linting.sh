#!/usr/bin/env bash

set -euo pipefail

# Ensure ansible-lint is installed
if ! command -v ansible-lint &> /dev/null; then
    echo "ansible-lint not found. Installing..."
    pip install ansible-lint
fi

# Create a temporary inventory file if needed
INVENTORY_DIR="./inventory"
INVENTORY_FILE="${INVENTORY_DIR}/hosts.ini"

# Ensure the inventory directory exists
mkdir -p "$INVENTORY_DIR"

# Create a temporary inventory file if none exists yet
if [ ! -f "$INVENTORY_FILE" ]; then
    echo "Creating temporary inventory for syntax checking..."
    cat > "$INVENTORY_FILE" << EOF
[master]
k3s-srv-1 ansible_host=127.0.0.1 ansible_connection=local

[workers]
k3s-wkr-1 ansible_host=127.0.0.1 ansible_connection=local
k3s-wkr-2 ansible_host=127.0.0.1 ansible_connection=local

[k3s_cluster:children]
master
workers
EOF
    TEMP_INVENTORY=1
else
    TEMP_INVENTORY=0
fi

# Run linting on existing files
echo "Linting playbooks and roles..."
EXISTING_PLAYBOOKS=$(find playbooks -name "*.yml" -type f | sort)
EXISTING_ROLES=$(find roles -maxdepth 2 -name "tasks" -type d | sed 's|/tasks$||')

ansible-lint -c lint-config.yml $EXISTING_PLAYBOOKS $EXISTING_ROLES

# Syntax check all playbooks
echo "Performing syntax check on playbooks..."
for playbook in $EXISTING_PLAYBOOKS; do
    echo "Checking syntax for $playbook"
    ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook --syntax-check "$playbook" \
        -i inventory/hosts.ini --vault-password-file="$HOME/.vault_pass.txt"
done

# Clean up temporary inventory file if we created one
if [ "$TEMP_INVENTORY" -eq 1 ]; then
    echo "Removing temporary inventory file..."
    rm -f "$INVENTORY_FILE"
fi

echo "✅ Lint checks completed successfully!"
