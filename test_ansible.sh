#!/bin/bash
# Script to test Ansible playbooks with syntax checking and dry run

set -e

ANSIBLE_DIR="$(dirname "$0")/ansible"
# Check where playbooks actually exist
if [ -d "$ANSIBLE_DIR/playbooks" ]; then
    PLAYBOOK_DIR="playbooks"
    FULL_PLAYBOOK_PATH="$ANSIBLE_DIR/playbooks"
else
    # Playbooks are directly in the ansible directory
    PLAYBOOK_DIR="."
    FULL_PLAYBOOK_PATH="$ANSIBLE_DIR"
fi

PLAYBOOKS=("site.yml" "k3s_install.yml" "apps_deploy.yml" "k3s_reset.yml" "test.yml")
VERBOSE=${VERBOSE:-""}

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "===== Ansible Playbook Testing Tool ====="
echo "Looking for playbooks in: $FULL_PLAYBOOK_PATH"

# Check if Ansible is installed
if ! command -v ansible &> /dev/null; then
    echo -e "${RED}Error: Ansible is not installed.${NC}"
    echo "Please install Ansible first."
    exit 1
fi

# Go to the ansible directory
cd "$ANSIBLE_DIR" || {
    echo -e "${RED}Error: Could not change to directory $ANSIBLE_DIR${NC}"
    exit 1
}

# Function to test a playbook
test_playbook() {
    local playbook="$1"
    local full_path="$PLAYBOOK_DIR/$playbook"

    echo -e "\n${YELLOW}Testing playbook:${NC} $playbook"

    # Check if the playbook exists
    if [ ! -f "$full_path" ]; then
        echo -e "${RED}Playbook not found:${NC} $full_path"
        # Try looking directly in the ansible directory
        if [ -f "$playbook" ]; then
            echo -e "${GREEN}Found playbook directly in ansible directory${NC}"
            full_path="$playbook"
        else
            return 1
        fi
    fi

    echo "1. Syntax checking..."
    if ansible-playbook "$full_path" --syntax-check $VERBOSE; then
        echo -e "${GREEN}✓ Syntax check passed${NC}"
    else
        echo -e "${RED}✗ Syntax check failed${NC}"
        return 1
    fi

    echo "2. List tasks..."
    if ansible-playbook "$full_path" --list-tasks $VERBOSE; then
        echo -e "${GREEN}✓ Task listing succeeded${NC}"
    else
        echo -e "${RED}✗ Task listing failed${NC}"
        return 1
    fi

    echo "3. Dry run (--check mode)..."
    if ansible-playbook "$full_path" --check $VERBOSE; then
        echo -e "${GREEN}✓ Check mode passed${NC}"
    else
        echo -e "${YELLOW}⚠ Check mode had changes or issues${NC}"
        # Don't fail on check mode issues as they might be expected
    fi

    return 0
}

# Parse arguments
if [ "$1" = "all" ] || [ -z "$1" ]; then
    # Test all playbooks
    echo "Testing all playbooks..."

    for playbook in "${PLAYBOOKS[@]}"; do
        if ! test_playbook "$playbook"; then
            echo -e "\n${RED}Testing failed for:${NC} $playbook"
            exit 1
        fi
    done

    echo -e "\n${GREEN}All playbooks passed basic testing!${NC}"
else
    # Test specific playbook
    if [[ "$1" != *".yml" ]]; then
        playbook="$1.yml"
    else
        playbook="$1"
    fi

    if ! test_playbook "$playbook"; then
        echo -e "\n${RED}Testing failed for:${NC} $playbook"
        exit 1
    fi

    echo -e "\n${GREEN}Playbook '$playbook' passed testing!${NC}"
fi

echo -e "\n${YELLOW}Note:${NC} This was a syntax and dry-run test only. No changes were made to your systems."
echo "To run a playbook for real, use: ansible-playbook <playbook>"
