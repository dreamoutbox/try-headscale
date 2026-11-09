#!/bin/sh
# Install curl and Tailscale inside the Ubuntu container, start tailscaled, and join the Headscale tailnet.
#
# Inputs:
#   HEADSCALE_URL   (env): Headscale control server URL (required).
#   TS_AUTHKEY      (env): Reusable preauth key from Headscale (required).
#   UBUNTU_HOSTNAME (env): Tailnet hostname for Ubuntu node (default: ubuntu).
#
# Example usage:
#   HEADSCALE_URL=http://203.0.113.10:8080 TS_AUTHKEY=<key> /scripts/connect-ubuntu.sh

set -e

: "${HEADSCALE_URL:?HEADSCALE_URL not set}"
: "${TS_AUTHKEY:?TS_AUTHKEY not set}"

if ! command -v curl >/dev/null 2>&1; then
  apt-get update
  apt-get install -y curl ca-certificates iproute2 procps
fi

if ! command -v tailscale >/dev/null 2>&1; then
  curl -fsSL https://tailscale.com/install.sh | sh
fi

if [ ! -S /var/run/tailscale/tailscaled.sock ]; then
  TS_FORCE_NOISE_443=false nohup tailscaled --state=/var/lib/tailscale/tailscaled.state </dev/null >/var/log/tailscaled.log 2>&1 &
  until [ -S /var/run/tailscale/tailscaled.sock ]; do
    sleep 1
  done
fi

tailscale up \
  --login-server="${HEADSCALE_URL}" \
  --authkey="${TS_AUTHKEY}" \
  --hostname="${UBUNTU_HOSTNAME:-ubuntu}" \
  --accept-routes \
  --force-reauth \
  --reset

tailscale status

