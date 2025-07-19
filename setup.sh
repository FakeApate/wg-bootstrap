#!/usr/bin/env bash
# setup.sh — bootstrap a fresh VM for WireGuard

set -euo pipefail
IFS=$'\n\t'

# If not root, re-run with sudo
if [ "$EUID" -ne 0 ]; then
  exec sudo bash "$0" "$@"
fi

# Configuration
REPO_URL="https://github.com/FakeApate/wg-bootstrap.git"
CLONE_DIR="/tmp/wireguard-config"
PLAYBOOK_FILE="site.yml"

# Ensure prerequisites
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y git python3 python3-apt software-properties-common

# Install Ansible from PPA for latest version
if ! command -v ansible &>/dev/null; then
  echo "✔ Adding Ansible PPA and installing"
  add-apt-repository --yes --update ppa:ansible/ansible
  apt-get install -y ansible
fi

# Clone or update WireGuard config repo
if [ -d "$CLONE_DIR/.git" ]; then
  echo "Updating existing repo in $CLONE_DIR"
  git -C "$CLONE_DIR" pull
else
  echo "Cloning repo to $CLONE_DIR"
  git clone "$REPO_URL" "$CLONE_DIR"
fi

echo "Running ansible-pull from $CLONE_DIR"
ansible-pull -U "$REPO_URL" "$PLAYBOOK_FILE" \
  --directory "$CLONE_DIR" \
  --inventory localhost, \
  --connection local \
  --accept-host-key

echo "Bootstrap complete"
