#!/usr/bin/env bash
# Deploy and start Headscale on a remote VPS via SSH and rsync.
#
# Inputs:
#   VPS_IP         (env): Target VPS IPv4 address (required).
#   SSH_PRIV_KEY   (env): Path to SSH private key (default: ~/.ssh/id_ed25519).
#   SSH_PUB_KEY    (env): Path to SSH public key  (default: ~/.ssh/id_ed25519.pub).
#   SSH_USER       (env): Remote SSH user         (default: root).
#   HEADSCALE_USER (env): Headscale user name     (default: myuser).
#
# Example usage:
#   VPS_IP="203.0.113.10" ./server-setup.sh
#   VPS_IP="203.0.113.10" SSH_PRIV_KEY=~/.ssh/custom_key ./server-setup.sh

set -euo pipefail

: "${VPS_IP:?Set VPS_IP, e.g. VPS_IP=203.0.113.10 ./server-setup.sh}"
SSH_PRIV_KEY="${SSH_PRIV_KEY:-${HOME}/.ssh/id_ed25519}"
SSH_PUB_KEY="${SSH_PUB_KEY:-${HOME}/.ssh/id_ed25519.pub}"
SSH_USER="${SSH_USER:-root}"
HEADSCALE_USER="${HEADSCALE_USER:-myuser}"
REMOTE_DIR="~/headscale-server"

# Validate that required local files exist before connecting.
# Args: none (reads SSH_PRIV_KEY, SSH_PUB_KEY).
# Example:
#   validate_keys
validate_keys() {
  if [ ! -f "$SSH_PRIV_KEY" ]; then
    echo "Error: SSH private key not found at $SSH_PRIV_KEY" >&2
    exit 1
  fi
  if [ ! -f "$SSH_PUB_KEY" ]; then
    echo "Error: SSH public key not found at $SSH_PUB_KEY" >&2
    exit 1
  fi
}

# Execute a command on the remote VPS over SSH.
# Args:
#   "$@": Remote command and arguments to run.
# Example:
#   run_ssh "docker --version"
run_ssh() {
  ssh -i "$SSH_PRIV_KEY" \
    -o StrictHostKeyChecking=accept-new \
    "${SSH_USER}@${VPS_IP}" "$@"
}

validate_keys

echo "[1/3] Installing Docker on ${SSH_USER}@${VPS_IP}..."
run_ssh "command -v docker >/dev/null 2>&1 || (curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh)"

echo "[2/3] Syncing ./headscale-server to ${SSH_USER}@${VPS_IP}:${REMOTE_DIR}..."
rsync -avz \
  -e "ssh -i ${SSH_PRIV_KEY} -o StrictHostKeyChecking=accept-new" \
  ./headscale-server/ "${SSH_USER}@${VPS_IP}:${REMOTE_DIR}/"

echo "[3/3] Running headscale-server-up.sh on VPS..."
run_ssh "cd ${REMOTE_DIR} && chmod +x headscale-server-up.sh && VPS_IP='${VPS_IP}' HEADSCALE_DOMAIN='${HEADSCALE_DOMAIN:-${VPS_IP}}' HEADSCALE_USER='${HEADSCALE_USER}' ./headscale-server-up.sh"
