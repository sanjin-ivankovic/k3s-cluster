#!/bin/bash
# Script to verify SSH key format and permissions

SSH_KEY_PATH="$HOME/.ssh/k3s_id_ed25519"
PUB_KEY_PATH="${SSH_KEY_PATH}.pub"

echo "=== Verifying SSH key format and permissions ==="

# Check if key exists
if [ ! -f "$SSH_KEY_PATH" ]; then
  echo "❌ SSH private key not found at $SSH_KEY_PATH"
  exit 1
else
  echo "✓ SSH private key found at $SSH_KEY_PATH"

  # Check permissions
  KEY_PERMS=$(stat -f "%Lp" "$SSH_KEY_PATH")
  if [ "$KEY_PERMS" != "600" ]; then
    echo "⚠️  Private key has incorrect permissions: $KEY_PERMS (should be 600)"
    echo "   Fixing permissions..."
    chmod 600 "$SSH_KEY_PATH"
  else
    echo "✓ Private key has correct permissions (600)"
  fi

  # Verify it's a valid ED25519 key
  if ! ssh-keygen -l -f "$SSH_KEY_PATH" | grep -q ED25519; then
    echo "❌ The key is not a valid ED25519 key"
  else
    echo "✓ Valid ED25519 key format confirmed"

    # Print key fingerprint
    KEY_FINGERPRINT=$(ssh-keygen -l -f "$SSH_KEY_PATH")
    echo "   Key fingerprint: $KEY_FINGERPRINT"
  fi
fi

# Check public key
if [ ! -f "$PUB_KEY_PATH" ]; then
  echo "❌ SSH public key not found at $PUB_KEY_PATH"
  echo "   Generating public key from private key..."
  ssh-keygen -y -f "$SSH_KEY_PATH" > "$PUB_KEY_PATH"
  chmod 644 "$PUB_KEY_PATH"
else
  echo "✓ SSH public key found at $PUB_KEY_PATH"

  # Check permissions
  PUB_PERMS=$(stat -f "%Lp" "$PUB_KEY_PATH")
  if [ "$PUB_PERMS" != "644" ]; then
    echo "⚠️  Public key has incorrect permissions: $PUB_PERMS (should be 644)"
    echo "   Fixing permissions..."
    chmod 644 "$PUB_KEY_PATH"
  else
    echo "✓ Public key has correct permissions (644)"
  fi
fi

# Print public key for verification
echo -e "\nPublic key content (should match what's deployed to servers):"
cat "$PUB_KEY_PATH"

echo -e "\n=== Testing SSH connection to servers ==="
# Test connectivity to servers
HOSTS=("10.0.0.6" "10.0.0.7" "10.0.0.8")
for HOST in "${HOSTS[@]}"; do
  echo -n "Testing connection to $HOST... "
  if ssh -i "$SSH_KEY_PATH" -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=5 "sanjin@$HOST" "echo 'Success'" &>/dev/null; then
    echo "✓ Connected successfully"
  else
    echo "❌ Connection failed"
  fi
done

echo -e "\nIf connections failed, you may need to:"
echo "1. Re-deploy your VMs with the correct key"
echo "2. Make sure your VM has the 'ubuntu' user"
echo "3. Try manually connecting with: ssh -i $SSH_KEY_PATH ubuntu@SERVER_IP"
echo "4. Check if your private key matches the public key deployed to the server"
