#!/usr/bin/env bash
# List all users registered in Headscale (locally on VPS or remotely via SSH when VPS_IP is set).
#
# Inputs:
#   VPS_IP   (env): Optional VPS IPv4 address if running from a remote machine.
#   "$@" (optional): Extra flags passed to `headscale users list` (e.g. -o json).
#
# Example usage:
#   ./headscale-server/scripts/list-users.sh
#   VPS_IP=104.248.156.42 ./headscale-server/scripts/list-users.sh

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/common.sh"

run_headscale users list "$@"

