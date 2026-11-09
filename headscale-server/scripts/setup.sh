#!/bin/sh
# Create a Headscale user and generate two preauth keys (1h for VPS, 24h reusable for PC).
#
# Inputs:
#   $1 (optional): Headscale username (falls back to HEADSCALE_USER or "myuser").
#
# Example usage:
#   ./scripts/setup.sh myuser

set -e

USER_NAME="${1:-${HEADSCALE_USER:-myuser}}"

docker exec headscale headscale users create "$USER_NAME" >/dev/null 2>&1 || true

# One key per line, nothing else — host script parses these directly
docker exec headscale headscale preauthkeys create --user "$USER_NAME" --expiration 1h
docker exec headscale headscale preauthkeys create --user "$USER_NAME" --expiration 24h --reusable
