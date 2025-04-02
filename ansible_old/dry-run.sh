#!/usr/bin/env bash

# First check if inventory file exists
if [ ! -f "inventory/hosts.ini" ]; then
  echo "Error: inventory/hosts.ini does not exist!"
  echo "Make sure to run 'terraform apply' first to generate the inventory file."
  exit 1
fi

# List variables that would be used
echo "Checking variables that would be used..."
ansible -i inventory/hosts.ini -m debug -a "var=k3s_version" all

# Run ansible-playbook in check mode with verbose output
echo "Running playbook in check mode..."
ansible-playbook -i inventory/hosts.ini playbooks/setup-k3s.yml --check -v
