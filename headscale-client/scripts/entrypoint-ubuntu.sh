#!/bin/sh
# Entrypoint for the Ubuntu tailnet client container.
# Starts tailscaled if already installed and keeps the container alive.
#
# Inputs: none
# Example usage:
#   /scripts/entrypoint-ubuntu.sh

set -e

if command -v tailscaled >/dev/null 2>&1; then
  tailscaled --state=/var/lib/tailscale/tailscaled.state &
fi

sleep infinity

