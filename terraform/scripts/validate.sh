#!/bin/bash
# Script to validate the Terraform configuration

set -e

echo "=== Validating Terraform configuration ==="

# Check Terraform formatting
echo "Checking Terraform formatting..."
terraform fmt -check -recursive || {
  echo "ERROR: Terraform formatting issues found."
  echo "Run 'terraform fmt -recursive' to fix."
  exit 1
}

# Validate Terraform files
echo "Validating Terraform files..."
terraform validate || {
  echo "ERROR: Terraform validation failed."
  exit 1
}

# Run tflint if available
if command -v tflint &> /dev/null; then
  echo "Running TFLint for additional checks..."
  tflint --config=.tflint.hcl || {
    echo "WARNING: TFLint reported issues."
  }
else
  echo "TFLint not found. Consider installing it for additional validation."
fi

# Check for hardcoded secrets (simplified version)
echo "Checking for hardcoded secrets..."
grep -r "password" --include="*.tf" . | grep -v "variable" | grep -v "sensitive" && {
  echo "WARNING: Possible hardcoded secrets found. Review the lines above."
} || echo "No obvious hardcoded secrets found."

echo "=== Validation completed successfully! ==="
exit 0
