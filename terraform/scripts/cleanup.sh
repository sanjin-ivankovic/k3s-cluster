#!/bin/bash
# Script to clean up resources and prepare for a fresh deployment

set -e

echo "=== Cleaning up Terraform resources ==="

# Function to confirm actions
confirm() {
  read -r -p "${1:-Are you sure? [y/N]} " response
  case "$response" in
    [yY][eE][sS]|[yY])
      true
      ;;
    *)
      false
      ;;
  esac
}

# Check if we're in the terraform directory
if [ ! -f "main.tf" ]; then
  echo "Please run this script from the terraform root directory."
  exit 1
fi

# Delete local state if it exists
if [ -f "terraform.tfstate" ]; then
  echo "Local state file found."
  if confirm "Do you want to delete the local state file? This is DANGEROUS and cannot be undone. [y/N]"; then
    echo "Deleting local state file..."
    rm -f terraform.tfstate*
    echo "Local state deleted."
  else
    echo "Keeping local state file."
  fi
fi

# Clean .terraform directory
echo "Cleaning .terraform directory..."
rm -rf .terraform

# Remove backend configuration if it exists
if [ -f "backend.tf" ]; then
  echo "Backend configuration found."
  if confirm "Do you want to remove the backend configuration? [y/N]"; then
    echo "Removing backend.tf file..."
    rm -f backend.tf
    echo "Backend configuration removed."
  else
    echo "Keeping backend configuration."
  fi
fi

# Clean generated files
echo "Cleaning generated files..."
find . -name "*-generated.*" -delete

# Clean lock file
echo "Removing .terraform.lock.hcl file..."
rm -f .terraform.lock.hcl

# Check for SSH keys that might have been generated
SSH_KEY_NAME="${SSH_KEY_NAME:-k3s}"
SSH_KEY_PATH="$HOME/.ssh/${SSH_KEY_NAME}_id_ed25519"

if [ -f "$SSH_KEY_PATH" ]; then
  echo "SSH keys found at $SSH_KEY_PATH"
  if confirm "Do you want to remove the SSH keys? [y/N]"; then
    echo "Removing SSH keys..."
    rm -f "${SSH_KEY_PATH}"
    rm -f "${SSH_KEY_PATH}.pub"
    echo "SSH keys removed."
  else
    echo "Keeping SSH keys."
  fi
fi

echo "=== Cleanup completed ==="
echo "You can now run 'terraform init' to reinitialize the project."
