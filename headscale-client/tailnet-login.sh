#!/usr/bin/env bash
# Install Tailscale (if missing) and join a Linux machine or container to the Headscale tailnet.
#
# Inputs:
#   VPS_IP      (env): VPS IPv4 address running Headscale (required if HEADSCALE_URL is unset).
#   HEADSCALE_URL(env): Full control server URL (default: http://${VPS_IP}:8080).
#   TS_AUTHKEY  (env): Preauth token from create-token.sh (required).
#   TS_HOSTNAME (env): Hostname to register in tailnet (default: system hostname).
#
# Example usage:
#   VPS_IP=104.248.156.42 TS_AUTHKEY=hskey-auth-... ./headscale-client/tailnet-login.sh
#   VPS_IP=104.248.156.42 TS_AUTHKEY=hskey-auth-... TS_HOSTNAME=laptop ./headscale-client/tailnet-login.sh

set -euo pipefail

: "${VPS_IP:?Set VPS_IP, e.g. VPS_IP=104.248.156.42}"
: "${TS_AUTHKEY:?Set TS_AUTHKEY from create-token.sh}"
HEADSCALE_URL="${HEADSCALE_URL:-http://${VPS_IP}:8080}"
NODE_HOSTNAME="${TS_HOSTNAME:-$(hostname)}"

# Ensure Tailscale is installed on the machine.
# Args: none
# Example:
#   ensure_tailscale_installed
ensure_tailscale_installed() {
  if command -v tailscale >/dev/null 2>&1; then
    return 0
  fi

  if ! command -v curl >/dev/null 2>&1; then
    if command -v apt-get >/dev/null 2>&1; then
      apt-get update && apt-get install -y curl ca-certificates
    else
      echo "Error: curl is required to install Tailscale." >&2
      exit 1
    fi
  fi

  echo "Installing Tailscale..."
  curl -fsSL https://tailscale.com/install.sh | sh
}

# Reset tailscaled state so HTTP control servers never hit the forced port 443 fallback.
# Supports both systemd hosts and container environments.
# Args: none
# Example:
#   reset_and_start_tailscaled
reset_and_start_tailscaled() {
  if command -v systemctl >/dev/null 2>&1 && [ -d /run/systemd/system ]; then
    systemctl stop tailscaled || true
    rm -f /var/lib/tailscale/tailscaled.state
    systemctl start tailscaled
  else
    pkill -x tailscaled 2>/dev/null || true
    sleep 1
    rm -f /var/lib/tailscale/tailscaled.state /var/run/tailscale/tailscaled.sock
    mkdir -p /var/lib/tailscale /var/run/tailscale
    TS_FORCE_NOISE_443=false nohup tailscaled --state=/var/lib/tailscale/tailscaled.state </dev/null >/var/log/tailscaled.log 2>&1 &
    until [ -S /var/run/tailscale/tailscaled.sock ]; do
      sleep 1
    done
  fi
}

ensure_tailscale_installed
reset_and_start_tailscaled

echo "Joining tailnet at ${HEADSCALE_URL} as '${NODE_HOSTNAME}'..."
tailscale up \
  --login-server="${HEADSCALE_URL}" \
  --authkey="${TS_AUTHKEY}" \
  --hostname="${NODE_HOSTNAME}" \
  --accept-routes

echo ""
echo "Connected. Tailnet IPv4: $(tailscale ip -4)"
tailscale status

