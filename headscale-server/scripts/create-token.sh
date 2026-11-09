#!/usr/bin/env bash
# Generate a Headscale preauth login token for a user.
# Creates the user automatically if it does not exist yet.
#
# Inputs:
#   $1 / HEADSCALE_USER: Username to generate token for (default: myuser).
#   $2 / EXPIRATION:     Token expiration duration (default: 24h).
#   VPS_IP        (env): Optional VPS IPv4 address if running from a remote machine.
#
# Example usage:
#   ./headscale-server/scripts/create-token.sh alice 24h
#   VPS_IP=104.248.156.42 ./headscale-server/scripts/create-token.sh alice 24h

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/common.sh"

USER_NAME="${1:-${HEADSCALE_USER:-myuser}}"
EXPIRATION="${2:-${EXPIRATION:-24h}}"

create_headscale_user "$USER_NAME"
USER_ID=$(get_headscale_user_id "$USER_NAME")
TOKEN=$(create_headscale_preauthkey "$USER_ID" "$EXPIRATION" "--reusable")

echo "User:       ${USER_NAME} (ID: ${USER_ID})"
echo "Expiration: ${EXPIRATION} (reusable)"
echo "Token:      ${TOKEN}"

if [ -n "${VPS_IP:-}" ]; then
  echo ""
  echo "Login command for client:"
  echo "  VPS_IP=${VPS_IP} TS_AUTHKEY=${TOKEN} ./headscale-client/tailnet-login.sh"
fi

