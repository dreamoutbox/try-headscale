#!/usr/bin/env bash
# Create a user in Headscale (locally on VPS or remotely via SSH when VPS_IP is set).
#
# Inputs:
#   $1 / HEADSCALE_USER: Username to create (default: myuser).
#   VPS_IP        (env): Optional VPS IPv4 address if running from a remote machine.
#
# Example usage:
#   ./headscale-server/scripts/create-user.sh alice
#   VPS_IP=104.248.156.42 ./headscale-server/scripts/create-user.sh alice

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/common.sh"

USER_NAME="${1:-${HEADSCALE_USER:-myuser}}"

create_headscale_user "$USER_NAME"
USER_ID=$(get_headscale_user_id "$USER_NAME")

echo "User ready: username=${USER_NAME} id=${USER_ID}"
run_headscale users list

