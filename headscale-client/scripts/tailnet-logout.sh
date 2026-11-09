#!/usr/bin/env bash
# Disconnect and log the current machine or container out of the Headscale tailnet.
#
# Inputs: none
# Example usage:
#   /scripts/tailnet-logout.sh

set -euo pipefail

if ! command -v tailscale >/dev/null 2>&1; then
  echo "Tailscale is not installed."
  exit 0
fi

echo "Logging out of tailnet..."
tailscale logout 2>/dev/null || true
tailscale down 2>/dev/null || true

if command -v systemctl >/dev/null 2>&1 && [ -d /run/systemd/system ]; then
  systemctl stop tailscaled || true
  rm -f /var/lib/tailscale/tailscaled.state
  systemctl start tailscaled
else
  pkill -x tailscaled 2>/dev/null || true
  sleep 1
  if [ -f /.dockerenv ]; then
    grep -q '127.0.0.11' /etc/resolv.conf 2>/dev/null || printf 'nameserver 127.0.0.11\noptions ndots:0\n' > /etc/resolv.conf
  fi
  rm -f /var/lib/tailscale/tailscaled.state /var/run/tailscale/tailscaled.sock
  mkdir -p /var/lib/tailscale /var/run/tailscale
  TS_FORCE_NOISE_443=false nohup tailscaled --state=/var/lib/tailscale/tailscaled.state </dev/null >/var/log/tailscaled.log 2>&1 &
fi

echo "Logged out and disconnected from tailnet."

