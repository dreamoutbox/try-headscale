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

echo "[debug][setup.sh] creating user: ${USER_NAME}" >&2
docker exec headscale headscale users create "$USER_NAME" >&2 || true

echo "[debug][setup.sh] listing users:" >&2
docker exec headscale headscale users list >&2

echo "[debug][setup.sh] creating 1h VPS preauthkey..." >&2
docker exec headscale headscale preauthkeys create --user "$USER_NAME" --expiration 1h

echo "[debug][setup.sh] creating 24h reusable PC preauthkey..." >&2
docker exec headscale headscale preauthkeys create --user "$USER_NAME" --expiration 24h --reusable
