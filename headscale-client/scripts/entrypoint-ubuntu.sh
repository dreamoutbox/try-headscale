#!/bin/sh
# Entrypoint for Ubuntu tailnet client containers.
# Installs curl + Tailscale (if not yet installed), starts tailscaled, and keeps the container alive
# without joining a tailnet automatically.
#
# Inputs: none
# Example usage:
#   /scripts/entrypoint-ubuntu.sh

set -e

/scripts/install-tailscale.sh

mkdir -p /var/lib/tailscale /var/run/tailscale
TS_FORCE_NOISE_443=false tailscaled --state=/var/lib/tailscale/tailscaled.state &

sleep infinity
