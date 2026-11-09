#!/bin/sh
# Create a Headscale user and generate two preauth keys (1h for VPS, 24h reusable for PC).
#
# Inputs:
#   $1 (optional): Headscale username (falls back to HEADSCALE_USER or "myuser").
#
# Example usage:
#   ./scripts/setup.sh myuser

set -e

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/common.sh"

USER_NAME="${1:-${HEADSCALE_USER:-myuser}}"

echo "[debug][setup.sh] creating user: ${USER_NAME}" >&2
create_headscale_user "$USER_NAME"

USER_ID=$(get_headscale_user_id "$USER_NAME")
echo "[debug][setup.sh] resolved USER_ID=${USER_ID} for ${USER_NAME}" >&2

echo "[debug][setup.sh] creating 1h VPS preauthkey..." >&2
create_headscale_preauthkey "$USER_ID" "1h"

echo "[debug][setup.sh] creating 24h reusable PC preauthkey..." >&2
create_headscale_preauthkey "$USER_ID" "24h" "--reusable"
