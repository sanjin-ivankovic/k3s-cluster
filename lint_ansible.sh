#!/bin/bash
# Script to run ansible-lint on the project

set -e

echo "=== Running Ansible Lint ==="

# Check if ansible-lint is installed
if ! command -v ansible-lint &> /dev/null; then
    echo "ansible-lint not found. Installing..."
    pip install ansible-lint
fi

# Move to the ansible directory
cd "$(dirname "$0")/ansible"

# Run ansible-lint
ansible-lint --config .ansible-lint

# Return to original directory
cd - > /dev/null

echo "=== Ansible Lint completed! ==="
