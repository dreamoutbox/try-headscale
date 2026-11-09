#!/bin/sh
# Create a Headscale user and generate two preauth keys (1h for VPS, 24h reusable for PC).
# Resolves the numeric user ID from `headscale users list` for Headscale v0.25+ compatibility.
#
# Inputs:
#   $1 (optional): Headscale username (falls back to HEADSCALE_USER or "myuser").
#
# Example usage:
#   ./scripts/setup.sh myuser

set -e

USER_NAME="${1:-${HEADSCALE_USER:-myuser}}"

echo "[debug][setup.sh] creating user: ${USER_NAME}" >&2
docker exec -e NO_COLOR=1 headscale headscale users create "$USER_NAME" >&2 || true

USERS_TABLE=$(docker exec -e NO_COLOR=1 headscale headscale users list | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g')
echo "[debug][setup.sh] listing users:" >&2
echo "$USERS_TABLE" >&2

USER_ID=$(echo "$USERS_TABLE" | grep -E "[|[:space:]]${USER_NAME}[|[:space:]]" | grep -oE '^[[:space:]]*[0-9]+' | tr -d '[:space:]' | head -n 1)

if [ -z "$USER_ID" ]; then
  echo "[error][setup.sh] could not find numeric user ID for ${USER_NAME}" >&2
  exit 1
fi

echo "[debug][setup.sh] resolved USER_ID=${USER_ID} for ${USER_NAME}" >&2

echo "[debug][setup.sh] creating 1h VPS preauthkey..." >&2
docker exec -e NO_COLOR=1 headscale headscale preauthkeys create --user "$USER_ID" --expiration 1h

echo "[debug][setup.sh] creating 24h reusable PC preauthkey..." >&2
docker exec -e NO_COLOR=1 headscale headscale preauthkeys create --user "$USER_ID" --expiration 24h --reusable
