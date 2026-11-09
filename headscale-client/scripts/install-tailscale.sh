#!/bin/sh
# Ensure curl and Tailscale are installed on an Ubuntu/Debian container or host.
# Uses flock on a file descriptor to prevent concurrent apt/dpkg lock conflicts.
#
# Inputs: none
# Example usage:
#   /scripts/install-tailscale.sh

set -e

if command -v flock >/dev/null 2>&1; then
  exec 9>/tmp/install-tailscale.lock
  flock 9
fi

if command -v tailscale >/dev/null 2>&1 && command -v curl >/dev/null 2>&1; then
  exit 0
fi

if ! command -v curl >/dev/null 2>&1; then
  apt-get update
  apt-get install -y curl ca-certificates iproute2 procps
fi

if ! command -v tailscale >/dev/null 2>&1; then
  curl -fsSL https://tailscale.com/install.sh | sh
fi
